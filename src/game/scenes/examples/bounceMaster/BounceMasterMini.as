package game.scenes.examples.bounceMaster
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	
	import game.components.entity.Sleep;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ToolTipType;
	import game.systems.SystemPriorities;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.PositionSmoothingSystem;
	
	public class BounceMasterMini extends Scene
	{
		public function BounceMasterMini()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/bounceMaster/";
			
			super.init(container);
			
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["minigame.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_displayContainer = super.groupContainer.addChild(super.getAsset("minigame.swf", true)) as MovieClip;
		
			super.addSystem(new FollowTargetSystem(), SystemPriorities.move);
			super.addSystem(new RenderSystem(), SystemPriorities.render);
			
			super.addSystem(new MotionSystem(), SystemPriorities.move);
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			super.addSystem(new BoundsCheckSystem(), SystemPriorities.resolveCollisions);
			super.addSystem(new InteractionSystem(), SystemPriorities.update);
			
			_bounceMasterGroup = new BounceMasterGroup();
			super.addChildGroup(_bounceMasterGroup);
			//_bounceMasterGroup.setupGroup(this, super.groupContainer, _displayContainer.hud, 
				//super.shellApi.viewportWidth, super.shellApi.viewportHeight + 100);
			_bounceMasterGroup.createCatcher(_displayContainer.paddle, super.shellApi.inputEntity.get(Spatial));
			_bounceMasterGroup.gameOver.add(gameOver);
			
			setupButtons();
			
			super.shellApi.defaultCursor = ToolTipType.TARGET;
		}
		
		private function setupButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			_startButton = ButtonCreator.createButtonEntity( _displayContainer["startGameButton"], this, startGame );
			Sleep(_startButton.get(Sleep)).ignoreOffscreenSleep = true;
			ButtonCreator.addLabel( _displayContainer["startGameButton"], "Start Game", labelFormat, ButtonCreator.ORIENT_CENTERED );
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
		
		private var _displayContainer:MovieClip;
		private var _bounceMasterGroup:BounceMasterGroup;
		private var _startButton:Entity;
	}
}