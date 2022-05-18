package game.scenes.survival5.ending
{
	import flash.display.MovieClip;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Threshold;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Jump;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Wave;
	import game.data.comm.PopResponse;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.scene.template.CutScene;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class Ending extends CutScene
	{
		public function Ending()
		{
			super();
			configData("scenes/survival5/ending/", null);
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM)
				JUMP_GRAVITY -= 100;
			
			_sceneTimeline = this.sceneEntity.get(Timeline);
			_sceneTimeline.gotoAndStop("helicopterFlyIn");
			
			_charGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			
			addSystem(new MotionSystem());
			addSystem(new PositionSmoothingSystem());
			addSystem(new ThresholdSystem());
			
			var jump1:MovieClip = screen.jump1;
			EntityUtils.turnOffSleep(player);
			_charGroup.addFSM(player);
			
			// Start the first jump right away
			var threshold:Threshold = new Threshold("y", ">=");
			threshold.threshold = jump1.y;
			threshold.entered.add(playerAtFirstPlatform);
			player.add(threshold);
			
			player.get(MotionTarget).targetX = jump1.x;
			player.get(MotionTarget).targetY = jump1.y;
			CharUtils.setState(player, CharacterState.JUMP);			
			player.get(Motion).acceleration.y = JUMP_GRAVITY;
		}
		
		// Landed on the first platform, now walk over
		private function playerAtFirstPlatform():void
		{
			if(player.get(Motion).velocity.y > 0)
			{
				player.get(Motion).zeroMotion("y");				
				player.get(FSMControl).setState(CharacterState.WALK);
				
				var threshold:Threshold = player.get(Threshold);
				threshold.entered.removeAll();
				
				threshold.property = "x";
				threshold.operator = "<";
				threshold.threshold = screen.walk1.x;
				threshold.entered.addOnce(stopPlayerWalk);
			}
		}
		
		private function stopPlayerWalk():void
		{
			player.get(Motion).zeroMotion("x");
			CharUtils.setDirection(player, true);
			
			var jump2:MovieClip = screen.jump2;
			var threshold:Threshold = player.get(Threshold);
			threshold.property = "y";
			threshold.operator = ">=";
			threshold.threshold = jump2.y;
			threshold.entered.add(playerAtTop);
			
			player.get(MotionTarget).targetX = jump2.x;
			player.get(MotionTarget).targetY = jump2.y;
			CharUtils.setState(player, CharacterState.JUMP);
			player.get(Motion).acceleration.y = JUMP_GRAVITY;
		}
		
		private function playerAtTop():void
		{
			if(player.get(Motion).velocity.y > 0)
			{
				player.get(FSMControl).setState(CharacterState.STAND);
				player.get(Motion).zeroMotion();				
				CharUtils.setDirection(player, false);
				CharUtils.setAnim(player, Wave);
				
				var threshold:Threshold = player.get(Threshold);
				threshold.entered.removeAll();
				
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "helicopter_01_loop.mp3", 1, true, [SoundModifier.FADE]);
				
				_sceneTimeline.gotoAndPlay("helicopterFlyIn");
				_sceneTimeline.handleLabel("openDoor", Command.create(shellApi.triggerEvent, "open_door"));
				_sceneTimeline.handleLabel("hover", readyToJumpIn);
			}
		}
		
		private function readyToJumpIn():void
		{
			var copterLoc:MovieClip = screen.copterJump;
			CharUtils.setAnim(player, Jump);
			TweenUtils.globalTo(this, player.get(Spatial), .5, {x:copterLoc.x, y:copterLoc.y, onComplete:playerInCopter});
		}
		
		private function playerInCopter():void
		{
			CharUtils.setAnim(player, Stand);
			setEntityContainer(player, screen.copterJump);
			var spatial:Spatial = player.get(Spatial);
			spatial.x = 0;
			spatial.y = 0;
			
			shellApi.triggerEvent("close_door");
			_sceneTimeline.gotoAndPlay("closeDoor");
			_sceneTimeline.handleLabel("doorClosed", copterClosed);
			_sceneTimeline.handleLabel("waterfall", secondHalf);
			_sceneTimeline.handleLabel("end", showVictoryPopup);
		}
		
		private function secondHalf():void
		{
			shellApi.triggerEvent("play_waterfall");
			AudioUtils.getAudio(this).fade(SoundManager.EFFECTS_PATH + "helicopter_01_loop.mp3", 0, .0016, 1);
		}
		
		private function showVictoryPopup():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "helicopter_01_loop.mp3");
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false);
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
			//addChildGroup(new VictoryPopup(overlayContainer));
		}
		
		private function copterClosed():void
		{
			this.removeEntity(player);	
		}		
		
		private var _sceneTimeline:Timeline;
		private var _charGroup:CharacterGroup;
		
		private var JUMP_GRAVITY:Number = MotionUtils.GRAVITY - 600;
	}
}