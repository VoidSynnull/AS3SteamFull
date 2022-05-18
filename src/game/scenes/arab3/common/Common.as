package game.scenes.arab3.common{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.hub.chooseGame.ChooseGame;
	import game.scenes.reality2.mainStreet.MainStreet;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.CharUtils;
	
	public class Common extends PlatformerGameScene
	{
		private var _holdConnection:Boolean;
		
		public function Common()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab3/common/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			// start multiplayer
			shellApi.smartFoxManager.disconnected.addOnce(onDisconnect);
			shellApi.sceneManager.enableMultiplayer(false, true, false);
			
			var entity:Entity = ButtonCreator.createButtonEntity(_hitContainer["kiosk"], this, Command.create(gotoGame, "kiosk"));
			entity.get(Display).alpha = 0;
			
			// tracking
			shellApi.track("EnteredCommonRoom");
			
			super.loaded();
		}
		
		override public function destroy():void
		{
			// leave room
			shellApi.smartFoxManager.leaveRoom();
			
			shellApi.smartFoxManager.disconnected.remove(onDisconnect);
			shellApi.smartFoxManager.loginError.removeAll();
			shellApi.smartFoxManager.loggedIn.removeAll();
			if(!_holdConnection)
			{
				shellApi.smartFox.disconnect();
			}
			super.destroy();
		}
		
		private function gotoGame(buttonEntity:Entity, game:String):void
		{
			var spatial:Spatial = buttonEntity.get(Spatial);
			CharUtils.followPath( player, new <Point>[new Point(spatial.x, spatial.y)], confirmGame, false, false, new Point(100,100), true  );
		}
		
		private function confirmGame($entity:Entity):void
		{
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(2, "Leave the arcade to play other players?", chooseGames)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= false;
			dialogBox.init(this.overlayContainer);
		}
		
		// go to choose game screen
		private function chooseGames():void
		{
			_holdConnection = true;
			shellApi.loadScene(ChooseGame);
		}
		
		private function onDisconnect():void
		{	
			// display disconnect popup
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Disconnected from server!", leaveCommonRoom)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		private function leaveCommonRoom():void
		{
			shellApi.loadScene(MainStreet, 1969, 984);
		}
	}
}