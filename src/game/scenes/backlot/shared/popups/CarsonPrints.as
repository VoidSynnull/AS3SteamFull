package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.scenes.backlot.BacklotEvents;
	import game.ui.popup.Popup;
	
	public class CarsonPrints extends Popup
	{
		public function CarsonPrints(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/sunriseStreet/";
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["walkOfFame.swf"]);
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset("walkOfFame.swf", true) as MovieClip;
			
			var clip:MovieClip = super.screen as MovieClip;
			clip.content.y -= 10;
			clip.content.width = this.parent.shellApi.camera.camera.viewportWidth * 1.033;//scale of the swfs width to screens width
			clip.content.height = this.parent.shellApi.camera.camera.viewportHeight * 1.08;//scale of the swfs height to screens height
			
			super.loaded();
			super.loadCloseButton();
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.shellApi.triggerEvent( _events.LOOK_AWAY_FROM_SIDEWALK );
			super.close();
		}
		
		private var _events:BacklotEvents;
	}
}