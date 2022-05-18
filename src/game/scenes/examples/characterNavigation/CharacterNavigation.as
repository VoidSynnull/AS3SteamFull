package game.scenes.examples.characterNavigation{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.MotionControl;
	import game.components.scene.SceneInteraction;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.entity.character.states.ClimbState;
	import game.systems.entity.character.states.FallState;
	import game.systems.entity.character.states.LandState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.touch.SkidState;
	import game.systems.entity.character.states.touch.StandState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.touch.JumpState;
	import game.systems.motion.NavigationSystem;
	import game.util.CharUtils;
	
	public class CharacterNavigation extends PlatformerGameScene
	{
		public function CharacterNavigation()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/characterNavigation/";
			super.showHits = true;
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
			
			// add some simple test buttons
			addTestButton("navButton", handleNavButtonClicked);
			addTestButton("navLoopButton", handleNavLoopButtonClicked);
			
			// must add colliders to an npc we want to move around the scene so that gravity and hits are applied.
			var npc:Entity = super.getEntityById("npc");

			// define states npc will use, note that the JumpState for touch is used, which allows targeted jumping.
			var states:Vector.<Class> = new <Class>[ ClimbState, FallState, JumpState, LandState, RunState, SkidState, StandState, WalkState ]; 
			CharacterGroup(super.getGroupById( CharacterGroup.GROUP_ID )).addFSM( npc, true, states );	
			
			// deactivate sleep so the npc follows points offscreen
			Sleep(npc.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(npc.get(Sleep)).sleeping = false;

			// override this npc's standard scene interaction
			var sceneInteraction:SceneInteraction = npc.get(SceneInteraction);
			sceneInteraction.reached.removeAll();
			// add a custom handler.
			sceneInteraction.reached.add(npcReached);
			
			// for debug, so that you can see the navigation points, you can also turn this on via the console through tje 'showPath" command
			var navSystem:NavigationSystem = super.getSystem( NavigationSystem ) as NavigationSystem;
			navSystem.debug = true;
		}
		
		private function npcReached(player:Entity, npc:Entity):void
		{
			Dialog(npc.get(Dialog)).say("Ya betta check yo-self...");
			Dialog(player.get(Dialog)).say("...before ya wreck yo-self.");
		}
		
		private function addTestButton(name:String, handler:Function):void
		{
			var buttonEntity:Entity = new Entity();
			
			buttonEntity.add(new Display(super._hitContainer[name]));
			buttonEntity.add(new Spatial());
			// this creator adds the necessary signals for interaction
			var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [InteractionCreator.DOWN]);
			interaction.down.add(handler);
			
			super.addEntity(buttonEntity);
		}
		
		private function handleNavButtonClicked(entity:Entity):void	
		{
			var npc:Entity = super.getEntityById("npc");
			CharUtils.moveToTarget(npc, 784, 740, true, reachedTarget).ignorePlatformTarget = true;
		}
		
		private function handleNavLoopButtonClicked(entity:Entity):void	
		{
			//if(!followingPath)
			//{
				followingPath = true;
				
				// lock the players movement while we're following this npc's path.
				//var motionControl:MotionControl = super.shellApi.player.get(MotionControl)
				//motionControl.lockInput = true;
			
				var totalNavPoints:uint = 8;
				
				var path:Vector.<Point> = new Vector.<Point>();
				var navClip:MovieClip;
				
				// build a Vector of all the nav points inside the hit container.  This is just so they can be visually laid out for this test, but all that is required is a vector of points.
				for(var n:uint = 1; n < totalNavPoints + 1; n++)
				{
					navClip = super._hitContainer["nav" + n];
					navClip.label.text = n;
					path.push(new Point(navClip.x, navClip.y));
				}
				
				// This utils method starts up the character following the path.  This method allows you to change the camera target, adjust the minimum distance for a point to be reached
				//   as well as specify the final facing direction of the charater.  See CharUtils.followPath for more details.
				var npc:Entity = super.getEntityById("npc");
				CharUtils.followPath(npc, path, pathComplete, true, false, new Point(30, 50)).setDirectionOnReached( "left" );
				
				// limit the max speed of the character in state control...
				var charMotionCtrl:CharacterMotionControl = npc.get(CharacterMotionControl);
				charMotionCtrl.maxVelocityX = 400;
				charMotionCtrl.maxAirVelocityX = 400;
				//motion.maxVelocity = new Point(10, 1200);
				

				// make the camera follow the npc
				//SceneUtil.setCameraTarget( this, npc );
			//}
		}
		
		private function reachedTarget(entity:Entity):void
		{
			Dialog(entity.get(Dialog)).say("I made it!");
		}
		
		private function pathComplete(entity:Entity):void
		{
			followingPath = false;
			
			// once the final point has been reached, reset the camera to follow the player and unlock the player's motion control.
			super.shellApi.camera.target = super.shellApi.player.get(Spatial);
			var motionControl:MotionControl = super.shellApi.player.get(MotionControl)
			motionControl.lockInput = false;
		}
		
		private var followingPath:Boolean = false;
	}
}