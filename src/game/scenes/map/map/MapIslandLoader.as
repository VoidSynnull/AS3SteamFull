package game.scenes.map.map
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.EntityCreator;
	import engine.group.DisplayGroup;
	
	import game.creators.ui.ButtonCreator;
	import game.scenes.map.map.components.IslandInfo;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;

	public class MapIslandLoader
	{
		private var _group:DisplayGroup;
		private var _mapIsland:String;
		private var numEpisodes:int = 0;
		private var _islandScale:Number;
		
		private var _showProgress:Boolean = true;
		
		public var loaded:Signal = new Signal();
		
		public var islandSWF:MovieClip;
		public var islandXML:XML;
		
		public var entity:Entity;
		
		public function MapIslandLoader(group:DisplayGroup, mapIsland:String, showProgress:Boolean = true, islandScale = 1)
		{
			_group = group;
			_mapIsland = mapIsland;
			_showProgress = showProgress;
			_islandScale = islandScale;
		}
		
		public function destroy():void
		{
			_group = null;
			_mapIsland = null;
			islandSWF = null;
			islandXML = null;
			
			loaded.removeAll();
		}
		
		public function load():void
		{
			if(_mapIsland != "custom")
				_group.shellApi.loadFile(_group.shellApi.assetPrefix + "scenes/map/map/islands/" + _mapIsland + "/island.swf", islandSWFLoaded);
		}
		
		private function islandSWFLoaded(clip:MovieClip):void
		{
			islandSWF = clip;
			_group.shellApi.loadFile(_group.shellApi.dataPrefix + "scenes/map/map/islands/" + _mapIsland + "/island.xml", islandXMLLoaded);
		}
		
		private function islandXMLLoaded(xml:XML):void
		{
			islandXML = xml;
			this.setupIsland();
		}
		
		private function setupIsland():void
		{
			if(islandSWF != null && islandXML != null)
			{
				var sprite:Sprite = new Sprite();
				sprite.addChild(islandSWF);
				
				var islandName:String = String(islandXML.island);
				var gameVersion:String = String(islandXML.gameVersion);
				var numEpisodes:int = DataUtils.getNumber(islandXML.numEpisodes);
				
				entity = EntityUtils.createSpatialEntity(_group, sprite);
				entity.add(new Id(islandName));
				entity.add(new IslandInfo(islandName, gameVersion, numEpisodes));
				
				Spatial(entity.get(Spatial)).scale = _islandScale; // 0229 scale island
				
				var island:Entity = ButtonCreator.createButtonEntity(islandSWF, _group, null, null, null, null, false, true, _islandScale);	
				island.add(new Id("island"));
				
				EntityUtils.addParentChild(island, entity);
				
				if(islandXML.hasOwnProperty("components"))
				{
					var componentsXML:XML = XML(islandXML.components);
					EntityCreator.addComponents(componentsXML, island);
				}
				
				this.setupIslandName();
				
				if(DataUtils.getBoolean(islandXML.showProgress) && _showProgress)
				{
					var progressLoader:IslandProgressLoader = new IslandProgressLoader(_group.shellApi, islandName, numEpisodes);
					progressLoader.loaded.add(progressesLoaded);
					progressLoader.load();
				}
				else
				{
					loaded.dispatch(this);
				}
			}
			else
			{
				loaded.dispatch(this);
			}
		}
		
		private function setupIslandName():void
		{
			var display:DisplayObjectContainer = Display(entity.get(Display)).displayObject;
			var spatial:Spatial = entity.get(Spatial);
			
			var textField:TextField = new TextField();
			textField.embedFonts = true;
			textField.defaultTextFormat = new TextFormat("CreativeBlock BB", 15, 0x00000000, null, null, null, null, null, TextFormatAlign.CENTER);
			textField.width = 150;
			textField.autoSize = TextFieldAutoSize.LEFT;
			textField.wordWrap = true;
			textField.selectable = false;
			textField.mouseEnabled = false;
			textField.text = DataUtils.getString(islandXML.name);
			textField.alpha = 0.4;
			
			textField.x = (-textField.width) / 2;
			textField.y = 10;
			display.addChild(textField);
		}
		
		private function progressesLoaded(islandProgressLoader:IslandProgressLoader):void
		{
			_group.shellApi.loadFile(_group.shellApi.assetPrefix + "scenes/map/map/shared/islandProgress.swf", islandProgressBarLoaded, islandProgressLoader);
		}
		
		private function islandProgressBarLoaded(clip:MovieClip, islandProgressLoader:IslandProgressLoader):void
		{
			var display:DisplayObjectContainer = Display(entity.get(Display)).displayObject;
			var spatial:Spatial = entity.get(Spatial);
			var islandInfo:IslandInfo = entity.get(IslandInfo);
			islandInfo.progresses = islandProgressLoader.progresses.concat();
			
			var backgroundClip:MovieClip = clip.getChildByName("background") as MovieClip;
			var dividerClip:MovieClip = clip.getChildByName("divider") as MovieClip;
			var progressClip:MovieClip = clip.getChildByName("progress") as MovieClip;
			
			var progressIndex:int = progressClip.parent.getChildIndex(progressClip);
			var dividerIndex:int = dividerClip.parent.getChildIndex(dividerClip);
			
			var progressLength:Number = backgroundClip.width / islandProgressLoader.progresses.length;
			var index:int;
			
			//Add dividers to split up episode progress if it's an episodic island.
			for(index = 1; index < islandProgressLoader.progresses.length; ++index)
			{
				var dividerSprite:Sprite = _group.createBitmapSprite(dividerClip, 1, null, true, 0, null, false);
				dividerSprite.x = backgroundClip.x + progressLength * index;
				clip.addChildAt(dividerSprite, dividerIndex);
			}
			
			//Add progress bar(s) to island.
			for(index = 0; index < islandProgressLoader.progresses.length; ++index)
			{
				var progressSprite:Sprite = _group.createBitmapSprite(progressClip, 1, null, true, 0, null, false);
				progressSprite.name = "progress" + (index + 1);
				progressSprite.x = backgroundClip.x + progressLength * index;
				progressSprite.width = progressLength * islandProgressLoader.progresses[index];
				clip.addChildAt(progressSprite, progressIndex);
			}
			
			progressClip.parent.removeChild(progressClip);
			dividerClip.parent.removeChild(dividerClip);
			
			clip.x = 0;
			clip.y = clip.height/2;
			display.addChild(clip);
			
			var progress:Entity = EntityUtils.createSpatialEntity(entity.group, clip);
			progress.add(new Id("progress"));
			EntityUtils.addParentChild(progress, entity);
			
			islandProgressLoader.destroy();
			
			loaded.dispatch(this);
		}
	}
}