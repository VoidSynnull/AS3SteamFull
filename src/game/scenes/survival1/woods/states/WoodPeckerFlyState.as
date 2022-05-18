package game.scenes.survival1.woods.states
{
	import flash.geom.Point;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.motion.MotionTarget;
	import game.data.sound.SoundModifier;
	import game.scenes.survival1.woods.components.WoodPecker;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class WoodPeckerFlyState extends MovieclipState
	{
		public function WoodPeckerFlyState()
		{
			super.type = "fly";
		}
		
		override public function start():void
		{
			super.setLabel("flying");
			var woodPecker:WoodPecker = node.entity.get(WoodPecker);
			node.motion.acceleration.y = 0;
			node.motion.velocity = new Point(0, 0);
			
			var spatial:Spatial = node.spatial;
			var target:MotionTarget = node.motionTarget;
			
			var angle:Number = Math.atan2((target.targetY - 60 - spatial.y), (target.targetX - spatial.x));
			node.motion.velocity.x = woodPecker.flySpeed * Math.cos(angle);
			node.motion.velocity.y = woodPecker.flySpeed * Math.sin(angle);
			
			node.timeline.handleLabel("flap", onFlap, false);
		}
		
		override public function update(time:Number):void
		{
			var target:MotionTarget = node.motionTarget;
			var woodPecker:WoodPecker = node.entity.get(WoodPecker);
			
			if(Math.abs(target.targetDeltaX) < woodPecker.landDist)
			{
				node.motion.acceleration.x = -node.motion.velocity.x * 2;
			}
			
			if((node.motion.velocity.x < 0 && node.motion.velocity.x > -20) ||
				(node.motion.velocity.x > 0 && node.motion.velocity.x < 20))
			{
				node.motion.velocity = new Point(0,0);
				node.motion.acceleration = new Point(0,0);
				node.fsmControl.setState(MovieclipState.LAND);
			}
		}
		
		private function onFlap():void
		{
			var audio:Audio = node.entity.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "wing_flap_small_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
	}
}