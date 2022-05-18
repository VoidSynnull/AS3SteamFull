package game.scenes.ghd.shared.mushroomBouncer
{
	import engine.components.Id;
	
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class MushroomBouncerSystem extends GameSystem
	{
		public function MushroomBouncerSystem()
		{
			super(MushroomBouncerNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			this._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:MushroomBouncerNode, time:Number):void
		{
			if(node.currentHit.hit)
			{
				var id:Id = node.currentHit.hit.get(Id);
				
				//If the current hit is a mushroom...
				//All hits that are mushrooms should have "mushroom" somewhere in their ids in XML.
				if(id && id.id.indexOf("mushroom") > -1)
				{
					//...and we haven't bounced yet...
					if(!node.mushroom.bouncing)
					{
						/*
						...set bouncing to true and lock mouse input so CharacterMovementSystem
						doesn't override the velocity/direction of the bounce hit.
						*/
						node.mushroom.bouncing = true;
						node.motionControl.lockInput = true;
					}
				}
				//If the current hit doesn't have an id or it isn't a mushroom...
				else
				{
					//...and we've been bouncing...
					if(node.mushroom.bouncing)
					{
						/*
						...set bouncing to false and unlock input so the player can move around 
						using standard mouse input.
						*/
						node.mushroom.bouncing = false;
						node.motionControl.lockInput = false;
					}
				}
			}
		}
	}
}