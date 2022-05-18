package game.scenes.survival1.woods.states
{
	import flash.geom.Point;
	
	import engine.components.Audio;
	import engine.managers.SoundManager;
	
	import game.components.motion.MotionTarget;
	import game.data.sound.SoundModifier;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.Utils;
	
	public class WoodPeckerIdleState extends MovieclipState
	{
		public function WoodPeckerIdleState()
		{
			super.type = MovieclipState.STAND;
		}
		
		override public function start():void
		{			
			this.setLabel("idle");
			
			if(node.motionTarget.targetDeltaX > 0)
				node.spatial.scaleX = 1;
			else
				node.spatial.scaleX = -1;
			
			node.spatial.x = node.motionTarget.targetX;
			node.spatial.y = node.motionTarget.targetY;
			
			node.timeline.handleLabel("peck", onPeck, false);
		}
		
		override public function update(time:Number):void
		{
			var target:MotionTarget = node.motionTarget;
			
			node.motion.velocity = new Point(0,0);
			node.motion.acceleration = new Point(0,0);
			
			if(Math.abs(target.targetDeltaX) > 100)
			{
				node.fsmControl.setState("beginFlight");
			}	
		}
		
		private function onPeck():void
		{
			var audio:Audio = node.entity.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "small_wood_cut_0" + Utils.randInRange(1, 6).toString() + ".mp3" , false, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
	}
}