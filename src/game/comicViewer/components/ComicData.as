package game.comicViewer.components
{
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import engine.group.DisplayGroup;
	
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;
	
	public class ComicData extends Component
	{	
		public var comicId:String;		
		public var title:String;
		
		public var iconAsset:String;
		public var headerAsset:String;
		public var headerUrl:String;
		
		public var bgPath:String;
		
		public var frameAsset:String;

		private var pageCount:uint;
		public var pagePaths:Vector.<String> = new Vector.<String>();
		
		public var comicPage:int = 0;// current page id/number
		private var comicXml:XMLList;
		
		private var pagePath:String;
		private var pageName:String;
		
		private var _group:DisplayGroup;
		
		public var bufferReady:Boolean = false;
		public var bufferLoaded:Signal = new Signal();
		private var pageBuffer:Dictionary  = new Dictionary();
		private var bufferAges:Array = new Array();
		private const bufferSizeLimit:int  = 3;
		
		/**
		 * ComicData stores and manages information needed to load and create pages and custom settings comics/books
		 */
		public function ComicData(group:DisplayGroup, xml:XML = null)
		{			
			this._group = group;
			if(xml)
			{
				parseXML(xml);
			}
		}
		
		public function parseXML(xml:XML):void
		{
			comicId = xml.attribute('id');
			title = DataUtils.getString(xml.title);
			
			iconAsset = DataUtils.getString(xml.folderPath) + "/" + DataUtils.getString(xml.pageId) + "_Icon.jpg";
			headerAsset = DataUtils.getString(xml.headerPath);
			headerUrl = DataUtils.getString(xml.headerUrl);
			
			pageCount = DataUtils.getUint(xml.pageCount);
			pagePath = DataUtils.getString(xml.folderPath);
			pageName = DataUtils.getString(xml.pageId);
			pageCount = DataUtils.getUint(xml.pageCount);
			
			bgPath = DataUtils.getString(xml.bgPath);
			
			pagePaths = new Vector.<String>();
			var name:String;
			// save asset path for each page of comic
			for (var i:int = 0; i < pageCount; i++) 
			{
				name = pagePath + pageName + (i+1) +DataUtils.getString(xml.ext);
				pagePaths.push(name);
			}
			loadPageBuffer(_group);
		}
		
		// prepair buffer at current comic page
		public function loadPageBuffer(group:DisplayGroup = null):void
		{
			//purge buffer
			for each (var key:int in pageBuffer) 
			{
				if(pageBuffer[key]){
					if(pageBuffer[key].parent){
						pageBuffer[key].parent.removeChild(pageBuffer[key]);
					}
					removeFromBuffer(key);
				}
			}
			pageBuffer = new Dictionary();
			// load
			if(!this._group != group){
				this._group = group;
			}		
			// array.slice() is non inclusive with ending param so add one more
			if(comicPage <= 0){
				// first page
				comicPage = 0;
				_group.loadFiles(toArray(pagePaths.slice(comicPage,comicPage+2)), false, true, firstPageLoaded);
			}				
			else if(comicPage >= pagePaths.length-1){
				// last page
				comicPage = pagePaths.length-1;
				_group.loadFiles(toArray(pagePaths.slice(comicPage-1,comicPage+1)), false, true, lastPageLoaded);
			}
			else{
				// any page other than the start and end
				_group.loadFiles(toArray(pagePaths.slice(comicPage-1,comicPage+2)), false, true, centerPageLoaded);
			}
		}
		
		private function toArray(vector:Vector.<String>):Array
		{
			var array:Array = new Array();
			for (var i:int = 0; i < vector.length; i++) 
			{
				array.push(vector[i]);
			}
			return array;
		}
		
		private function firstPageLoaded():void
		{
			var asset:DisplayObject;
			// no prev
			// curr
			asset = _group.getAsset(pagePaths[comicPage],true);
			addToBuffer(comicPage,asset);
			// next
			asset = _group.getAsset(pagePaths[comicPage+1],true);
			addToBuffer(comicPage+1,asset);
			bufferReady = true;
			bufferLoaded.dispatch();
		}		
		
		private function centerPageLoaded(assetPath:String):void
		{
			var asset:DisplayObject;
			// prev
			asset = _group.getAsset(pagePaths[comicPage-1],true);
			addToBuffer(comicPage-1,asset);
			// curr
			asset = _group.getAsset(pagePaths[comicPage],true);
			addToBuffer(comicPage,asset);
			// next
			asset = _group.getAsset(pagePaths[comicPage+1],true);
			addToBuffer(comicPage+1,asset);
			bufferReady = true;
			bufferLoaded.dispatch();
		}	
		
		private function lastPageLoaded(assetPath:String):void
		{
			var asset:DisplayObject;
			// prev
			asset = _group.getAsset(pagePaths[comicPage-1],true);
			addToBuffer(comicPage-1,asset);
			// curr
			asset = _group.getAsset(pagePaths[comicPage],true);
			addToBuffer(comicPage,asset);
			// no next
			bufferReady = true;
			bufferLoaded.dispatch();
		}	
		
		public function getBufferedPage(callBack:Function = null):DisplayObject
		{
			//trace("PAGE TURN:: "+comicNumber+" OF: " +(pagePaths.length-1))
			limitBuffer(bufferSizeLimit);
			// return requested asset, advance buffer
			var asset:DisplayObject;
			asset = pageBuffer[comicPage];
			if(!asset){
				//trace("LOADING PAGE "+comicNumber)
				_group.loadFile(pagePaths[comicPage],bufferedPageLoaded, callBack, comicPage);
				loadNext(comicPage);
			}
			else{
				//trace("FOUND LOADED PAGE "+comicNumber);
				if(callBack){
					callBack(asset);
				}
				loadNext(comicPage);
			}
			
			return asset;
		}
		
		private function loadNext(page:int):void
		{
			if(page < pagePaths.length-1 && !pageBuffer[comicPage+1]){
				//trace("LOADING NEXT PAGE "+(comicNumber+1))
				_group.loadFile(pagePaths[comicPage+1],bufferedPageLoaded,null,comicPage+1);
			}
			if(page > 0  && !pageBuffer[comicPage-1]){
				//trace("LOADING PREV PAGE "+(comicNumber-1))
				_group.loadFile(pagePaths[comicPage-1],bufferedPageLoaded,null,comicPage-1);
			}
		}
		
		private function bufferedPageLoaded(asset:DisplayObject, callBack:Function=null, page:int = 0):void
		{
			addToBuffer(page, asset);
			if(callBack){
				callBack(asset);
			}
		}
		
		private function limitBuffer(buffLimit:int):void
		{	
			//trace("BUFFER SIZE: "+bufferAges.length+"/"+buffLimit)
			// if buffer dictionary too big, remove oldest page
			while(bufferAges.length > buffLimit)
			{
				var deadKey:int = bufferAges.shift();
				if(deadKey){
					removeFromBuffer(deadKey);
				}
			}
		}		
		
		private function addToBuffer(key:int,value:DisplayObject):void
		{
			pageBuffer[key] = value;
			bufferAges.length++;
			bufferAges.push(key);
			//trace("ADDED BUFFER::"+key)
		}
		
		private function removeFromBuffer(key:int):void
		{
			if(pageBuffer[key]){
				if(pageBuffer[key].parent){
					pageBuffer[key].parent.removeChild(pageBuffer[key]);
				}
				delete pageBuffer[key];
				bufferAges.splice(bufferAges.indexOf(key),1);
				//trace("REMOVED BUFFER:: "+key)
			}
		}
		
		public override function destroy():void
		{
			// purge buffer
			for each (var key:int in pageBuffer) 
			{
				if(pageBuffer[key]){
					if(pageBuffer[key].parent){
						pageBuffer[key].parent.removeChild(pageBuffer[key]);
					}
					removeFromBuffer(key);
				}
			}
			pageBuffer = null
			bufferAges.splice(0, bufferAges.length);
			bufferAges = null;
			pagePaths.splice(0, pagePaths.length);
			pagePaths = null;
			super.destroy();
		}
		
		
		
		
		
	}
}