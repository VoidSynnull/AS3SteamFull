package game.scenes.deepDive1.shared.fishStates.Angler
{
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.scenes.deepDive1.maze.components.FoodFish;
	import game.scenes.deepDive1.shared.components.Angler;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.TimelineUtils;
	
	public class AnglerEatState extends MovieclipState
	{
		public function AnglerEatState()
		{
			super.type = "eat";
		}
		
		override public function start():void
		{
			//setChildLabel("jaw", "chomp");
			var fish:Entity = TimelineUtils.getChildClip(node.entity, "angler");
			var jaw:Entity = TimelineUtils.getChildClip(fish, "jaw");
			var timeline:Timeline = jaw.get(Timeline);
			
			timeline.gotoAndPlay("chomp");
			
			timeline.handleLabel("ending", jawClosed);
			
			trace("[ANGLER STATE]: Eat");
		}
		
		private function jawClosed():void
		{
			var angler:Angler = node.entity.get(Angler);
			//node.owningGroup.group.removeEntity(angler.fishToEat);
			
			// have fish return to initial area
			if(angler.fishToEat){
				FoodFish(angler.fishToEat.get(FoodFish)).returnToOrigin();
			}
			
			angler.fishToEat = null;
			angler.onEaten.dispatch();
		}
	}
}