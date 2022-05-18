package game.scenes.survival5.chase.scenes
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scene.template.SceneUIGroup;
	import game.ui.hud.Hud;
	import game.util.MotionUtils;
	import game.utils.LoopingSceneUtils;
	
	public class EndlessRunnerScene extends GameScene
	{
		protected var cameraStationary:Boolean = true;
		protected var player:Entity;
		protected var _audioGroup:AudioGroup;
		protected var _characterGroup:CharacterGroup;
		
		protected var referenceMotionEntity:Entity;
		
		public function EndlessRunnerScene()
		{
			super();
		} 
		
		override protected function addGroups():void
		{
			super.addGroups();
			super.addChildGroup( new SceneUIGroup( super.overlayContainer, this.uiLayer ) );
		}
		
		override protected function addCollisions( audioGroup:AudioGroup ):void
		{
			super.addCollisions( audioGroup );
			_audioGroup = audioGroup;
		}
		
		override public function loaded():void
		{
			super.shellApi.defaultCursor = ToolTipType.TARGET;
			var hud:Hud = super.getGroupById( Hud.GROUP_ID ) as Hud;
			hud.disableButton( Hud.COSTUMIZER );
			hud.disableButton( Hud.INVENTORY );
			
			player = shellApi.player;
			
			// Make the player follow input (the mouse or touch input).
			MotionUtils.followInputEntity( super.shellApi.player, super.shellApi.inputEntity, true );
			super.shellApi.inputEntity.add( new TargetSpatial( super.shellApi.player.get( Spatial )));	// This is necessary for nav cursor
			
			// don't want the player to block clicks and move him to the back of the interactive layer.
			var display:Display = player.get( Display );
			display.displayObject.mouseEnabled = false;
			
			super.loaded();
		}
			
		/** 
		 * 	Create <code>Motion Master</code> component for player and add looper collider
		 * 	@param	fileName : <code>String</code> xml file name for motion master data.
		 */
		protected function setupPlayer( fileName:String = "motionMaster.xml" ):void
		{
			// use generic looping scene function
			LoopingSceneUtils.setupPlayer( this, fileName );
		}
		
		/**
		 * 	Activate <code>Motion Master</code> component and starts the motion for all <code>Motion Wrap Node</code> nodes.
		 */
		protected function triggerLayers():void
		{
			// use generic looping scene function
			LoopingSceneUtils.triggerLayers( this );
		}
		
		/**
		 * 	Adds required systems for looper motion and collision.
		 */
		protected function triggerObstacles():void
		{
			// use generic looping scene function
			LoopingSceneUtils.triggerObstacles( this );
		}
		
		/**
		 * 	Toggles <code>Looper Hit Node</code> activity based on event.
		 * 
		 * 	@param	event : <code>String</code> event that determines which loopers are active.
		 */
		protected function toggleLooperEvent( event:String ):void
		{
			// use generic looping scene function
			LoopingSceneUtils.toggleLooperEvent( this, event );
		}
		
		/**
		 * 	Halts scene asset and looper obstacle motion.
		 */
		protected function stopSceneMotion( includeLoopers:Boolean = true ):void
		{
			// use generic looping scene function
			LoopingSceneUtils.stopSceneMotion( this, includeLoopers );
		}
		
		/**
		 * 	Restarts scene asset and looper obstacle motion.
		 */
		protected function restartSceneMotion():void
		{
			// use generic looping scene function
			LoopingSceneUtils.restartSceneMotion( this );
		}
		
		protected function addStates():void
		{}
		
		/**
		 * 	Interface for handling xml driven segment completion.
		 */
		protected function finishedRace( ...args ):void
		{}	
	}
}