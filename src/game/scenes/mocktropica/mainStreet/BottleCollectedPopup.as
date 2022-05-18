package game.scenes.mocktropica.mainStreet
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;

	
	import game.data.TimedEvent;
	import game.data.ui.TransitionData;

	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	
	public class BottleCollectedPopup extends Popup
	{
		public function BottleCollectedPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		public override function init(container:DisplayObjectContainer=null):void {
			transitionIn = new TransitionData();
			transitionIn.duration = .625;
			transitionIn.startPos = new Point(0, -shellApi.viewportHeight);
			transitionOut = transitionIn.duplicateSwitch();	// this shortcut method flips the start and end position of the transitionIn
			
			darkenBackground = true;
			groupPrefix = "scenes/mocktropica/mainStreet/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		public override function load():void {
			shellApi.fileLoadComplete.addOnce(loaded);
			loadFiles(["bottleCollectedPopup.swf"]);
		}
		
		// all assets ready
		public override function loaded():void {			
			screen = getAsset("bottleCollectedPopup.swf", true) as MovieClip;
			this.centerWithinDimensions(this.screen.content);
			this.layout.centerUI(super.screen.content);
			super.loaded();
			SceneUtil.addTimedEvent(this,new TimedEvent(4,1,timeToClose,true));
		}
		
		public override function destroy():void {
			super.destroy();
		}
		
		protected function timeToClose(...args):void {
			shellApi.triggerEvent("bottleAchievement");
			this.close();
		}
	}
}