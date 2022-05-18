package game.scenes.poptropolis.coliseum.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.data.ui.TransitionData;
	import game.scenes.poptropolis.mainStreet.MainStreet;
	import game.ui.popup.Popup;
	
	public class GameOverPopup extends Popup
	{
		private var events:PoptropolisEvents = new PoptropolisEvents();
	
		public function GameOverPopup(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		// pre load setup
		public override function init(container:DisplayObjectContainer = null):void
		{
			this.transitionIn = new TransitionData();
			this.transitionIn.startPos = new Point(0, -shellApi.viewportHeight);
			this.transitionIn.duration = 0.3;
			this.transitionOut = super.transitionIn.duplicateSwitch();
			this.darkenBackground = true;
			
			this.groupPrefix = "scenes/poptropolis/coliseum/";
			this.screenAsset = "gameOverPopup.swf";
			
			super.init(container);
			super.load();
		}		

	
		// all assets ready
		public override function loaded():void
		{
			super.loaded();
			
			this.centerWithinDimensions(this.screen.content);
			
			loadCloseButton();
			
			ButtonCreator.createButtonEntity(this.screen.content.gameOver.tryAgain, this, this.restartIsland);
		}
		
		private function restartIsland(button:Entity):void
		{
			this.shellApi.gameEventManager.reset("poptropolis");
			this.shellApi.itemManager.reset("poptropolis");
			this.shellApi.profileManager.save();
			
			this.shellApi.loadScene(MainStreet);
		}
		
		public override function destroy():void
		{
			super.destroy();
		}
	}
}