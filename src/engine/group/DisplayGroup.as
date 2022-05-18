package engine.group
{
	/**
	 * A group which is meant to load and display assets.  Has a 'groupContainer' associated with it which will container all its DisplayObjects.
	 */
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.NodeList;
	
	import game.data.display.BitmapWrapper;
	import game.nodes.ViewportNode;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.GroupUtils;
	
	public class DisplayGroup extends Group
	{
		public function DisplayGroup(container:DisplayObjectContainer = null)
		{			
			super();
			
			_container = container;
			_bitmapWrappers = new Vector.<BitmapWrapper>;
		}
		
		/**
		 * Cleans up the group and removes its display container.  This should not be called directly...groups should be added and removed with GroupManager which will call destroy after
		 * all associated systems, uielements and entities are removed.
		 */
		override public function destroy():void
		{
			disposeSceneryBitmaps();
			
			if( super.shellApi != null )
			{
				super.shellApi.fileLoadComplete.remove(loaded);
			}
			
			if ((_groupContainer != null) && (_container.contains(_groupContainer)))
			{
				_container.removeChild(_groupContainer);
			}
			
			while(this._bitmapDatas.length > 0)
			{
				this._bitmapDatas.pop().dispose();
			}
			
			super.destroy();
			
			_groupContainer = null;
			_container = null;
		}
		
		/**
		 * Create the groupContainer and add it to the base container.  All group displayObjects should be added to the groupContainer, NOT the base 'container.'
		 */
		public function init(container:DisplayObjectContainer = null):void
		{
			if( container && _container == null)
			{
				_container = container;
			}
			
			if(_groupContainer == null)
			{
				_groupContainer = new Sprite();
				_groupContainer.name = 'groupContainer';
				_container.addChild(_groupContainer);
			}
		}
				
		/**
		 * Get an asset within this groups asset folder structure.  If a file outside this folder structure is needed ShellApi.getFile(url) should be used.
		 * @param   url : Path to asset.  Automatically prepends the assetPrefix defined in Shell ("assets/") as well any prefix used for all of this groups files (ex : carrot/mainStreet).
		 * @param   [clear] : Clear a cached file after retrieval. 
		 */
		public function getAsset(url:String, clear:Boolean = false, useAbsoluteFilePaths:Boolean = false, prependTypePath:Boolean = true):*
		{
			var fullUrl:String = getFullUrl(url, useAbsoluteFilePaths, prependTypePath);
			
			return(super.shellApi.getFile(fullUrl, clear));
		}
		
		/**
		 * Get an xml file within this groups asset folder structure.  If a file outside this folder structure is needed ShellApi.getFile(url) should be used.
		 * @param   url : Path to xml.  Automatically prepends the dataPrefix defined in Shell ("data/") as well any prefix used for all of this groups files (ex : carrot/mainStreet).
		 * @param   [clear] : Clear a cached file after retrieval. 
		 */
		public function getData(url:String, clear:Boolean = false, useAbsoluteFilePaths:Boolean = false, prependTypePath:Boolean = true):XML
		{
			var fullUrl:String = getFullUrl(url, useAbsoluteFilePaths, prependTypePath);
			
			return(super.shellApi.getFile(fullUrl, clear));
		}	
		
		/**
		 * Returns the full path for xml or asset file.
		 * @param	url : Paths to asset and xml file.  Automatically prepends the assetPrefix defined in Shell ("assets/") and dataPrefix ("data/") for xml
		 * as well any prefix used for all of this groups files (ex : carrot/mainStreet).
		 * @return
		 */
		public function getFullUrl(url:String, useAbsoluteFilePaths:Boolean = false, prependTypePath:Boolean = true):String
		{
			// this will replace any instance of GROUP_PREFIX with the actual group prefix.  The goal is to eliminate the 'absolutePaths' param everywhere.
			var fullUrl:String = GroupUtils.replaceGroupPrefixString(url, this);
		
			if (!useAbsoluteFilePaths)
			{
				fullUrl = groupPrefix + url;
			}
			
			if(prependTypePath)
			{
				var prefix:String = super.shellApi.assetPrefix;
				
				if (String(url).indexOf(".xml") > -1)
				{
					prefix = super.shellApi.dataPrefix;
				}
				
				fullUrl = prefix + fullUrl;
			}

			return fullUrl;
		}
		
		/**
		 * Load a xml or asset, adds appropriate prefix for url, asset is returned with handler.
		 * @param	url : Paths to asset and xml file.  Automatically prepends the assetPrefix defined in Shell ("assets/") and dataPrefix ("data/") for xml
		 * as well any prefix used for all of this groups files (ex : carrot/mainStreet).  To load a file outside the common group folder structure use ShellApi.loadFile(url).
		 * @param	callback
		 * @param	...args
		 */
		public function loadFile( url:String, callback:Function=null, ...args ):void
		{
			args.splice(0, 0, getFullUrl( url ), callback );
			super.shellApi.loadFile.apply( null, args );
		}
		
		// temp duplicate of above until it is safe to merge
		public function loadFileDeluxe( url:String, useAbsoluteFilePaths:Boolean = false, prependTypePath:Boolean = true, callback:Function=null, ...args ):void
		{
			args.splice(0, 0, getFullUrl( url, useAbsoluteFilePaths, prependTypePath ), callback );
			super.shellApi.loadFile.apply( null, args );
		}
		
		/**
		 * Load a mix of xml and asset files, assets are not returned with handler.
		 * @param   urls : An array with paths to assets and xml files.  Automatically prepends the assetPrefix defined in Shell ("assets/") and dataPrefix ("data/") for xml
		 * as well any prefix used for all of this groups files (ex : carrot/mainStreet).  To load an array of files outside the common group folder structure use ShellApi.loadFiles(urls).
		 */
		public function loadFiles(urls:Array, useAbsoluteFilePaths:Boolean = false, prependTypePath:Boolean = true, callback:Function=null, ...args):void
		{
			var fullUrls:Array = new Array();
			var url:String;
			
			for (var n:Number = 0; n < urls.length; n++)
			{
				url = getFullUrl(urls[n], useAbsoluteFilePaths, prependTypePath);
				
				fullUrls[n] = url;
			}
			
			args.splice(0, 0, fullUrls, callback);
			
			super.shellApi.loadFiles.apply(null, args);
		}
				
		public function stopFileLoad(urls:Array, useAbsoluteFilePaths:Boolean = false, prependTypePath:Boolean = true):void
		{
			var fullUrls:Array = new Array();
			var url:String;
			
			for (var n:Number = 0; n < urls.length; n++)
			{
				url = getFullUrl(urls[n], useAbsoluteFilePaths, prependTypePath);
				
				fullUrls[n] = url;
			}
			
			super.shellApi.stopFileLoad(fullUrls);
		}
		
		/**
		 * Handle the resizing of the games base container.
		 * @param   viewportWidth : New width.
		 * @param   viewportHeight : New height.
		 */
		public function resize(viewportWidth:Number, viewportHeight:Number):void
		{
			// TODO :: This is kind of hacky, can fix it later - Bard
			// update all ViewPort components
			var nodeList:NodeList = super.systemManager.getNodeList( ViewportNode )
			for( var node : ViewportNode = nodeList.head; node; node = node.next )
			{
				node.viewport.setDimensions( viewportWidth, viewportHeight );
			}
		}
				
		/**
		 * The loading of a groups assets should happen here.  It listens for ShellApi.fileloadComplete signal to trigger 'loaded()'.
		 */
		public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
		}
		
		/**
		 * Called when all assets and data for this group have been loaded.
		 */
		public function loaded():void
		{
			super.groupReady();
		}
		
		public function convertContainer(container:DisplayObjectContainer, quality:Number = 1):void
		{
			BitmapUtils.convertContainer(container, quality, this._bitmapDatas);
		}
		
		public function createBitmapData(display:DisplayObject, quality:Number = 1, bounds:Rectangle = null, transparent:Boolean = true, fillColor:uint = 0):BitmapData
		{
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(display, quality, bounds, transparent, fillColor);
			
			this._bitmapDatas.push(bitmapData);
			
			return bitmapData;
		}
		
		public function createBitmap(display:DisplayObject, quality:Number = 1, bounds:Rectangle = null, transparent:Boolean = true, fillColor:uint = 0, swap:Boolean = true):Bitmap
		{
			var bitmap:Bitmap = BitmapUtils.createBitmap(display, quality, bounds, transparent, fillColor);
			
			var bitmapData:BitmapData = bitmap.bitmapData;
			this._bitmapDatas.push(bitmapData);
			
			if(swap)
			{
				DisplayUtils.swap(bitmap, display);
			}
			
			return bitmap;
		}
		
		public function createBitmapSprite(display:DisplayObject, quality:Number = 1, bounds:Rectangle = null, transparent:Boolean = true, fillColor:uint = 0, data:BitmapData = null, swap:Boolean = true):Sprite
		{
			var sprite:Sprite = BitmapUtils.createBitmapSprite(display, quality, bounds, transparent, fillColor,data);
			
			if(data == null)
			{
				var bitmapData:BitmapData = Bitmap(sprite.getChildAt(0)).bitmapData;
				this._bitmapDatas.push(bitmapData);
			}
			if(swap)
			{
				DisplayUtils.swap(sprite, display);
			}
			
			return sprite;
		}
		
		public function createBitmapSpriteTiled(display:DisplayObject, tileWidth:uint, tileHeight:uint, quality:Number = 1, bounds:Rectangle = null, transparent:Boolean = true, fillColor:uint = 0, overlap:uint = 0, swap:Boolean = true):Sprite
		{
			var sprite:Sprite = BitmapUtils.createBitmapSpriteTiled(display, tileWidth, tileHeight, quality, bounds, transparent, fillColor, overlap);
			
			var numChildren:uint = sprite.numChildren;
			for(var index:int = 0; index < numChildren; ++index)
			{
				var bitmapData:BitmapData = Bitmap(sprite.getChildAt(index)).bitmapData;
				this._bitmapDatas.push(bitmapData);
			}
			
			if(swap)
			{
				DisplayUtils.swap(sprite, display);
			}
			
			return sprite;
		}
		
		public function convertToBitmap(displayObject:DisplayObject, quality:Number = 1):BitmapWrapper
		{
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmap(displayObject, true, 0, null, null, true, quality);
			
			_bitmapWrappers.push(wrapper);
			
			return(wrapper);
		}
		
		public function convertToBitmapSprite(displayObject:DisplayObject, container:DisplayObjectContainer = null, swapDisplay:Boolean = true, scale:Number = 1):BitmapWrapper
		{
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite(displayObject, null, scale, swapDisplay, container);
			
			_bitmapWrappers.push(wrapper);
			
			return(wrapper);
		}
		
		protected function storeBitmapWrapper( wrapper:BitmapWrapper ):void
		{
			_bitmapWrappers.push(wrapper);
		}
		
		private function disposeSceneryBitmaps():void
		{
			if( _bitmapWrappers )
			{
				for(var n:int = 0; n < _bitmapWrappers.length; n++)
				{
					BitmapWrapper(_bitmapWrappers[n]).destroy();
				}
				
				_bitmapWrappers.length = 0;
				_bitmapWrappers = null;
			}
		}
		// allows you to clear bitmap data with out destroying the group
		protected function ResetBitmaps():void
		{
			disposeSceneryBitmaps();
			_bitmapWrappers = new Vector.<BitmapWrapper>();
		}
		
		/**
		 * 'groupContainer' holds all of a groups assets and can be added to directly.
		 */
		public function set groupContainer(groupContainer:DisplayObjectContainer):void { _groupContainer = groupContainer; }
		public function get groupContainer():DisplayObjectContainer { return(_groupContainer); }
		/**
		 * 'container' is the base displayObject for a group and contains the groupContainer.  For scenes this serves as the 'camera.'  This should not be added to directly.
		 */
		public function set container(container:DisplayObjectContainer):void { _container = container; }
		public function get container():DisplayObjectContainer { return(_container); }
		
		private var _groupContainer:DisplayObjectContainer;
		private var _container : DisplayObjectContainer;
		private var _bitmapWrappers:Vector.<BitmapWrapper>;
		private var _bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>();
		public var groupPrefix:String = "";
	}
}
