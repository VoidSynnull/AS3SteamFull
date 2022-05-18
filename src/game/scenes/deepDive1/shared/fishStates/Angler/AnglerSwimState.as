package game.scenes.deepDive1.shared.fishStates.Angler
{
	import engine.components.Spatial;
	
	import game.scenes.deepDive1.maze.components.FoodFish;
	import game.scenes.deepDive1.shared.components.Angler;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.util.Utils;
	
	public class AnglerSwimState extends MovieclipState
	{
		public function AnglerSwimState()
		{
			super.type = "swim";
		}
		
		override public function start():void
		{
			node.motion.pause = false // unlock motion
			counter = 0;
			angler = node.entity.get(Angler);
			node.motion.acceleration.x = angler.swimAccel;
			waitTime = Utils.randNumInRange(angler.minWait, angler.maxWait);
			
			trace("[ANGLER STATE]: Swim");
		}
		
		override public function update(time:Number):void
		{
			// If the fish to eat is set then wait until he is in the mouth then eat it
			if(angler.fishToEat != null && angler.inZone)
			{
				if(Math.abs(node.spatial.x - angler.originalLoc.x) >= 30){
					node.motion.acceleration.x = 0;
				}
				
				if(Math.abs(node.spatial.x - angler.originalLoc.x) >= 70 && node.motion.velocity.x != 0)
				{
					trace("[ANGLER STATE]: Swim - At Stop Point");
					node.motion.velocity.x = 0;
					node.motion.velocity.y = 0;
					node.motion.acceleration.x = 0;
					node.motion.acceleration.y = 0;
					node.fsmControl.setState("eatIdle");
					return;
				}
			}
			else
			{
				// retreat if the player comes near
				if(!angler.inZone)
				{
					node.motion.velocity.x = 0;
					node.motion.velocity.y = 0;
					node.motion.acceleration.x = 0;
					node.motion.acceleration.y = 0;
					node.fsmControl.setState("retreat");
					return;
				}
				
				if(Math.abs(node.spatial.x - angler.originalLoc.x) >= 60 && node.motion.velocity.x != 0)
				{
					node.motion.velocity.x = 0;
					node.motion.velocity.y = 0;
					node.motion.acceleration.x = 0;
					node.motion.acceleration.y = 0;
				}
	
				if(node.motion.velocity.x == 0)
				{
					counter += time;
					if(counter >= waitTime)
						node.fsmControl.setState("retreat");
				}
			}
		}
		
		private var angler:Angler;
		private var waitTime:Number;
		private var counter:Number = 0;
	}
}