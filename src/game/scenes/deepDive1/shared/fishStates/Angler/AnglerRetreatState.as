package game.scenes.deepDive1.shared.fishStates.Angler
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.scenes.deepDive1.shared.components.Angler;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.TimelineUtils;
	
	public class AnglerRetreatState extends MovieclipState
	{
		public function AnglerRetreatState()
		{
			super.type = "retreat";
		}
		
		override public function start():void
		{
			node.motion.pause = false; // unlock motion
			angler = node.entity.get(Angler);
			node.motion.acceleration.x = -angler.swimAccel;
			
			var fish:Entity = TimelineUtils.getChildClip(node.entity, "angler");
			var light:Entity = TimelineUtils.getChildClip(fish, "light");
			var lightTL:Timeline = light.get(Timeline);
			lightTL.gotoAndPlay("turnoff");

			angler.lightOn = false;
			
			trace("[ANGLER STATE]: Retreat");
		}
		
		override public function update(time:Number):void
		{
			if(angler.originalLoc.x >= node.spatial.x)
			{
				node.motion.velocity.x = 0;
				node.motion.velocity.y = 0;
				node.motion.acceleration.x = 0;
				node.motion.acceleration.y = 0;
				node.fsmControl.setState(MovieclipState.STAND);
			}
		}
		
		private var angler:Angler;
	}
}