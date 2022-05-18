package game.scenes.deepDive1.shared.fishStates.Angler
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.scenes.deepDive1.shared.components.Angler;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.TimelineUtils;
	
	public class AnglerIdleState extends MovieclipState
	{
		public function AnglerIdleState()
		{
			super.type = MovieclipState.STAND;
		}
		
		override public function start():void
		{
			counter = 0;
			
			var fish:Entity = TimelineUtils.getChildClip(node.entity, "angler");
			var jaw:Entity = TimelineUtils.getChildClip(fish, "jaw");
			var light:Entity = TimelineUtils.getChildClip(fish, "light");
			var jawTL:Timeline = jaw.get(Timeline);
			var lightTL:Timeline = light.get(Timeline);
			
			jawTL.gotoAndPlay("idle");
			lightTL.gotoAndStop("off");
			
			//setChildLabel("jaw", "idle");
			//setChildLabel("light", "off", false);
			
			angler = node.entity.get(Angler);
			angler.lightOn = false;
			
			trace("[ANGLER STATE]: Idle");
		}
		
		override public function update(time:Number):void
		{
			node.motion.velocity.x = 0;
			node.motion.velocity.y = 0;
			node.motion.acceleration.x = 0;
			node.motion.acceleration.y = 0;
			
			if(angler.fishToEat != null && angler.inZone)
			{
				node.fsmControl.setState("swim");
				return;
			}
		}
		
		private var angler:Angler;
		private var waitTime:Number;
		private var counter:Number = 0;
	}
}