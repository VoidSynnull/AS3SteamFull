package game.scenes.map.map.groups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.creators.EntityCreator;
	import engine.creators.ObjectCreator;
	import engine.group.DisplayGroup;
	
	import game.util.DataUtils;
	import game.util.DisplayAlignment;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	
	public class IslandPopupPage extends DisplayGroup
	{
		protected var assetsToLoad:int = 0;
		
		public const MAP_FOLDER:String 		= "scenes/map/map/"
		public const ISLANDS_FOLDER:String 	= "islands/";
		public const SHARED_FOLDER:String 	= "shared/";
		
		/**
		 * The width of an IslandPopupPage.
		 */
		public static const PAGE_WIDTH:int = 836;
		
		/**
		 * The height of an IslandPopupPage.
		 */
		public static const PAGE_HEIGHT:int = 512;
		
		/**
		 * The hardcoded x distance between the end of one IslandPage and the beginning of the next.
		 * TO-DO :: This could be different if we want to adjust the buffer for different screen sizes.
		 */
		public static const PAGE_BUFFER_X:int = 30;
		
		public var islandFolder:String;
		public var pageFolder:String;
		public var page:int;
		private var layout:String;
		
		protected var layoutXML:XML;
		protected var pageXML:XML;
		protected var pageContainer:DisplayObjectContainer;
		
		public function IslandPopupPage(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			this.pageXML = null;
			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			
			var page:int 			= this.page - 1;
			this.groupContainer.x 	= (page * PAGE_WIDTH) + (page * PAGE_BUFFER_X);
			
			this.groupPrefix = this.islandFolder + this.pageFolder;
			
			this.loadFile("page.xml", this.pageXMLLoaded);
		}
		
		private function pageXMLLoaded(pageXML:XML):void
		{
			this.pageXML = pageXML;
			
			var layouts:Array = DataUtils.getArray(pageXML.layout);
			var index:int = 0;
			if(layouts.length >1)
			{
				if(PlatformUtils.isDesktop)// if we provide an alternate for our future redesign
				{
					index = 1;
				}
			}
			layout = layouts[index];
			this.shellApi.loadFile(this.shellApi.dataPrefix + "scenes/map/map/layouts/" + layout +".xml", this.layoutXMLLoaded);
		}
		
		private function layoutXMLLoaded(layoutXML:XML):void
		{
			this.layoutXML = layoutXML;
			
			this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/map/map/layouts/" + layout +".swf", this.layoutSWFLoaded);
		}
		
		private function layoutSWFLoaded(clip:MovieClip):void
		{
			this.pageContainer = clip;
			this.pageContainer.visible = false;
			this.groupContainer.addChild(clip);
			
			this.createDisplayObjects(this.layoutXML);
			this.createDisplayObjects(this.pageXML);
			this.loadAssets(this.layoutXML);
			this.loadAssets(this.pageXML);
		}
		
		private function createDisplayObjects(xml:XML):void
		{
			var assetsXML:XMLList = xml.displayObjects.children();
			for each(var assetXML:XML in assetsXML)
			{
				var displayObject:DisplayObject = ObjectCreator.parseConstructorXML(assetXML);
				this.setupAsset(displayObject, assetXML);
			}
		}
		
		private function loadAssets(xml:XML):void
		{
			var assetsXML:XMLList = xml.assets.children();
			for each(var assetXML:XML in assetsXML)
			{
				var prefix:String = this.getAssetPrefix(assetXML);
				++this.assetsToLoad;
				
				this.shellApi.loadFile(prefix + assetXML.name, this.assetLoaded, assetXML);
			}
		}
		
		protected function setupAsset(clip:DisplayObject, assetXML:XML):Entity
		{
			if(!clip) return null;
			
			this.pageContainer.addChild(clip);
			
			ObjectCreator.parsePropertiesXML(assetXML, clip);
			
			if(this.pageXML.hasOwnProperty("formats"))
			{
				var formatsXML:XMLList = this.pageXML.formats.children();
				for each(var formatXML:XML in formatsXML)
				{
					if(clip.name == String(formatXML.name))
					{
						ObjectCreator.parsePropertiesXML(formatXML, clip);
						break;
					}
				}
			}
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			
			if(assetXML.hasOwnProperty("components"))
			{
				var componentsXML:XML = XML(assetXML.components);
				EntityCreator.addComponents(componentsXML, entity);
			}
			
			if(assetXML.hasOwnProperty("align"))
			{
				var alignXML:XML = XML(assetXML.align);
				var child:DisplayObject = this.pageContainer.getChildByName(String(alignXML.name));
				if(child != null)
				{
					var area:Rectangle = child.getBounds(child.parent);
					
					var display:DisplayObject = Display(entity.get(Display)).displayObject;
					var spatial:Spatial = entity.get(Spatial);
					
					var alignment:String = String(alignXML.alignment);
					
					if(display is TextField)
					{
						display.width = area.width;
						DisplayAlignment.alignToArea(display, area, null, alignment);
					}
					else
					{
						DisplayAlignment.fitAndAlign(display, area, null, alignment);
					}
					
					display.parent.setChildIndex(display, child.parent.getChildIndex(child) + 1);
					
					spatial.x = display.x;
					spatial.y = display.y;
					spatial.scaleX = display.scaleX;
					spatial.scaleY = display.scaleY;
				}
			}
			return entity;
		}
		
		private function assetLoaded(clip:MovieClip, assetXML:XML):void
		{
			this.setupAsset(clip, assetXML);
			this.checkLoading();
		}
		
		/**
		 * When all of the basic asset loading is done, call load(). This let's subclasses do their
		 * loading and modifying of what IslandPage has loaded once it's all set.
		 */
		protected function checkLoading():void
		{
			if(--this.assetsToLoad == 0)
			{
				this.allXMLAssetsLoaded();
				this.pageContainer.visible = true;
				this.load();
			}
		}
		
		protected function allXMLAssetsLoaded():void
		{
			
		}
		
		protected function getAssetPrefix(assetXML:XML):String
		{
			var prefix:String = this.shellApi.assetPrefix;
			
			var folder:String = assetXML.folder;
			
			if(folder == "map")
			{
				prefix += MAP_FOLDER;
			}
			else if(folder == "shared")
			{
				prefix += MAP_FOLDER + SHARED_FOLDER;
			}
			else if(folder == "islands")
			{
				prefix += MAP_FOLDER + ISLANDS_FOLDER;
			}
			else if(folder == "island")
			{
				prefix += this.islandFolder;
			}
			else if(folder == "page")
			{
				prefix += this.islandFolder + this.pageFolder;
			}
			
			return prefix;
		}
	}
}