package game.scenes.map.map
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ads.AdData;
	import game.managers.ads.AdManager;
	import game.util.EntityUtils;


	public class AppOfTheDayLoader
	{
		public var entity:Entity;
		
		private var _group:DisplayGroup;
		private var _data:AdData;
		private var _container:DisplayObjectContainer;
		
		public function AppOfTheDayLoader(group:DisplayGroup, data:AdData, container:DisplayObjectContainer)
		{
			_group = group;
			_data = data;
			_container = container;
		}
		
		public function destroy():void
		{
			_group = null;
			_data = null;
			_container = null;
		}
		
		public function load():void
		{
			_group.shellApi.loadFile(_group.shellApi.assetPrefix + "scenes/map/map/custom/aotd/aotd.swf", setupPlacement);
		}
		
		private function setupPlacement(clip:MovieClip):void
		{
			if(clip != null)
			{
				// 1. encase unit into a sprite
				var sprite:Sprite = new Sprite();
				sprite.addChild(clip);
				
				// 2. get components
				var title:TextField = clip["title"];
				var banner:DisplayObject = clip["banner"];
				var contentContainer:DisplayObjectContainer = clip["content"]["container"];
				
				// 3. create entity
				entity = EntityUtils.createSpatialEntity(_group, sprite);
				entity.add(new Id("aotd"));
				
				// 4. set text
				title.autoSize = TextFieldAutoSize.CENTER;
				title.text = _data.campaign_name;
				
				// 5. resize banner to fit
				var width:Number = title.width + 45;
				if(width > banner.width)
					banner.width = width;
				
				// 6. set path for image
				var imagePath:String = _data.campaign_file1;
				var path:String = "https://www.poptropica.com/images/aotd/" + _data.campaign_file1;
				
				// 7. set image loader event handlers
				var imagesLoader:Loader = new Loader();
				imagesLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void{
					var li:LoaderInfo = LoaderInfo(e.target)
					var loader:Loader = li.loader
					var content:* = loader.content;
						
					if(content == null)
					{
						trace("App of the day :: ERROR : Image file not loaded at "+path);
						destroy();
						return;
					}
						
					// a. smooth and add image to content container
					if(content is Bitmap)
					{
						Bitmap(content).smoothing = true;
					}
					contentContainer.addChild(content);
						
					// b. place unit in map
					var spatial:Spatial = entity.get(Spatial);
					var displayObject:DisplayObjectContainer = Display(entity.get(Display)).displayObject;
					var mapContainer:DisplayObjectContainer = _container["map"];
					mapContainer.addChild(displayObject);
						
					// c. scale and position unit
					spatial.scale = 0.9;
					spatial.x = mapContainer["background"].width * 0.87;
					spatial.y = mapContainer["background"].height * 0.88;
						
					// d. setup click
					var placement:Entity = ButtonCreator.createButtonEntity(clip, _group, onClicked, null, null, null, false, true, spatial.scale);
					placement.add(new Id("placement"));
					EntityUtils.addParentChild(placement, entity);
						
					// e. cleanup
					imagesLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, arguments.callee);
				});
				
				imagesLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void{
					trace("App of the day :: ERROR : Image file not loaded at "+path);
					imagesLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, arguments.callee);
					destroy();
				});
				
				// 8. load image
				imagesLoader.load(new URLRequest(path));
			}
		}
		
		private function onClicked(entity:Entity):void
		{
			AdManager(_group.shellApi.adManager).visitSponsor(_data.campaign_name, true);
		}
		
	}
}