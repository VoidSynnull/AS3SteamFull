package game.scenes.mocktropica.mainStreet
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class Day2JordansPDAPopup extends Popup
	{
		public function Day2JordansPDAPopup(container:DisplayObjectContainer=null)
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
			loadFiles(["Day2JordansPDA.swf"]);
		}
		
		// all assets ready
		public override function loaded():void {			
			screen = getAsset("Day2JordansPDA.swf", true) as MovieClip;
			this.centerWithinDimensions(this.screen.content);
			this.layout.centerUI(super.screen.content);
			this.loadCloseButton();
			this.closeClicked.add(handleClose);
			super.loaded();
		}
		
		private function handleClose(...p):void
		{
			//parent.shellApi.triggerEvent("showedPda");
		}
		
		public override function destroy():void {
			super.destroy();
		}

	}
}