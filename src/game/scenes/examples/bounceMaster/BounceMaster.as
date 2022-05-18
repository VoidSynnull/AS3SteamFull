package game.scenes.examples.bounceMaster
{
	import flash.display.DisplayObjectContainer;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.creators.ui.ButtonCreator;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	
	public class BounceMaster extends PlatformerGameScene
	{
		public function BounceMaster()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/bounceMaster/";
			
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
			super.loaded();
			
			_bounceMasterGroup = new BounceMasterGroup();
			super.addChildGroup(_bounceMasterGroup);
			//_bounceMasterGroup.setupGroup(this, super._hitContainer, super._hitContainer["hud"], 
				//super.sceneData.cameraLimits.width, super.sceneData.cameraLimits.height);
			_bounceMasterGroup.gameOver.add(gameOver);
			_bounceMasterGroup.makeCatcher(super.player, 100, 50);
			_bounceMasterGroup.makeCatcher(super.getEntityById("npc"), 100, 50);
			CharUtils.followEntity(super.getEntityById("npc"), super.player);
			setupButtons();
		}
		
		private function setupButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			_startButton = ButtonCreator.createButtonEntity( super._hitContainer["startGameButton"], this, startGame );
			Sleep(_startButton.get(Sleep)).ignoreOffscreenSleep = true;
			ButtonCreator.addLabel( super._hitContainer["startGameButton"], "Start Game", labelFormat, ButtonCreator.ORIENT_CENTERED );
		}
		
		private function startGame(...args):void
		{
			Sleep(_startButton.get(Sleep)).sleeping = true;
			_bounceMasterGroup.startGame();
		}
		
		private function gameOver(...args):void
		{
			Sleep(_startButton.get(Sleep)).sleeping = false;
		}
		
		private var _bounceMasterGroup:BounceMasterGroup;
		private var _startButton:Entity;
	}
}