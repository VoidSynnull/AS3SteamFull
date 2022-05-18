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
	
	public class CustomPlacementLoader
	{
		public var entity:Entity;
		public var loaded:Signal = new Signal();
		
		private var _group:DisplayGroup;
		private var _placement:String;
		
		public function CustomPlacementLoader(group:DisplayGroup, placement:String)
		{
			_group = group;
			_placement = placement;
		}
		
		public function destroy():void
		{
			_group = null;
			_placement = null;
			
			loaded.removeAll();
		}
		
		public function load():void
		{
			_group.shellApi.loadFile(_group.shellApi.assetPrefix + "scenes/map/map/custom/" + _placement + "/graphic.swf", setupPlacement);
		}
		
		
		private function setupPlacement(clip:MovieClip):void
		{
			if(clip != null)
			{
				var sprite:Sprite = new Sprite();
				sprite.addChild(clip);
				
				entity = EntityUtils.createSpatialEntity(_group, sprite);
				entity.add(new Id(_placement));
				
				var placement:Entity = ButtonCreator.createButtonEntity(clip, _group, null, null, null, null, false, true);
				placement.add(new Id("placement"));
				
				EntityUtils.addParentChild(placement, entity);
				
				loaded.dispatch(this);
			}
			else
			{
				loaded.dispatch(this);
			}
		}
	}
}