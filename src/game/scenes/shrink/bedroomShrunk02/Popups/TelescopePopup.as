package game.scenes.shrink.bedroomShrunk02.Popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.shrink.ShrinkEvents;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	
	public class TelescopePopup extends Popup
	{
		public function TelescopePopup(container:DisplayObjectContainer=null, x:Number = 0, y:Number = 0)
		{
			xCoordinate = x;
			yCoordinate = y;
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/shrink/bedroomShrunk02/";
			super.screenAsset = "telescope.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			setUp();
			
			super.loadCloseButton();
		}
		
		private var content:MovieClip;
		private var xCoordinate:Number;
		private var yCoordinate:Number;
		private var shrink:ShrinkEvents;
		
		private function setUp():void
		{
			content = screen.content;
			content.x = shellApi.camera.camera.viewportWidth / 2;
			content.y = shellApi.camera.camera.viewportHeight / 2;
			
			var scene:Entity = EntityUtils.createSpatialEntity(this, content.scene, content);
			Display(scene.get(Display)).displayObject.mask = content.lense;
			var sceneSpatial:Spatial = scene.get(Spatial);
			
			var spaceX:Number = content.scene.sky.width - 640;
			var spaceY:Number = content.scene.sky.height - 480;
			
			sceneSpatial.x = -xCoordinate / 100 * spaceX - 320;
			sceneSpatial.y = yCoordinate / 100 * spaceY - spaceY - 240;
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			shellApi.triggerEvent(shrink.LOOK_AWAY_TELESCOPE);
			super.close();
		}
	}
}