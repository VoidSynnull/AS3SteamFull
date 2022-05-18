package game.scenes.deepDive1.shared.fishStates.Angler
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.scenes.deepDive1.shared.components.Angler;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.TimelineUtils;
	
	public class AnglerEatIdleState extends MovieclipState
	{
		public function AnglerEatIdleState()
		{
			super.type = "eatIdle";
		}
		
		override public function start():void
		{
			angler = node.entity.get(Angler);
			
			node.motion.acceleration.x = -angler.swimAccel;
			
			var fish:Entity = TimelineUtils.getChildClip(node.entity, "angler");
			var jaw:Entity = TimelineUtils.getChildClip(fish, "jaw");
			var light:Entity = TimelineUtils.getChildClip(fish, "light");
			var jawTL:Timeline = jaw.get(Timeline);
			var lightTL:Timeline = light.get(Timeline);
			
			jawTL.gotoAndPlay("open");
			lightTL.gotoAndPlay("turnon");
			
			//setChildLabel("jaw", "open");
			//setChildLabel("light", "turnon");
			
			angler.lightOn = true;
			
			trace("[ANGLER STATE]: EatIdle");
		}
		
		override public function update(time:Number):void
		{
			// settle angler
			if(node.motion.velocity.x < 0){
				node.motion.velocity.x = 0;
				node.motion.velocity.y = 0;
				node.motion.acceleration.x = 0;
				node.motion.acceleration.y = 0;
			}
			if(angler.fishToEat == null && angler.inZone == false){
				node.fsmControl.setState("retreat");
			}
		}
		
		private var angler:Angler;
	}
}