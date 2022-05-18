package game.scenes.prison.yard.states
{
	import flash.geom.Point;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.motion.MotionTarget;
	import game.data.sound.SoundModifier;
	import game.scenes.prison.yard.components.Seagull;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class SeagullFlyState extends MovieclipState
	{
		public function SeagullFlyState()
		{
			this.type = "fly";
		}
		
		override public function start():void
		{
			super.setLabel("flying");
			
			var seagull:Seagull = node.entity.get(Seagull);
			var spatial:Spatial = node.spatial;
			var target:MotionTarget = node.motionTarget;
			node.motion.acceleration.y = 0;
			node.motion.velocity = new Point(0,0);
			
			if(target.targetDeltaX > 0)
				node.spatial.scaleX = -1;
			else
				node.spatial.scaleX = 1;
			
			var angle:Number = Math.atan2((target.targetY - 60 - spatial.y), (target.targetX - spatial.x));
			node.motion.velocity.x = seagull.flySpeed * Math.cos(angle);
			node.motion.velocity.y = seagull.flySpeed * Math.sin(angle);
			
			node.timeline.handleLabel("flap", onFlap, false); // to play flap sound
		}
		
		override public function update(time:Number):void
		{
			var target:MotionTarget = node.motionTarget;
			var seagull:Seagull = node.entity.get(Seagull);
			
			if(Math.abs(target.targetDeltaX) < seagull.landDist)
			{
				node.motion.acceleration.x = -node.motion.velocity.x*2;
				node.motion.acceleration.y = -node.motion.velocity.y*2;
			}
			
			if(Math.abs(target.targetDeltaX) < 25)
			{
				node.motion.velocity = new Point(0,0);
				node.motion.acceleration = new Point(0,0);
				node.fsmControl.setState(MovieclipState.LAND);
			}			
		}
		
		private function onFlap():void
		{
			var audio:Audio = node.entity.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "wing_flaps_solo_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
	}
}