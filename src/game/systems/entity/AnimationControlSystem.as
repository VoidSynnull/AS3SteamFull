package game.systems.entity
{
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.AnimationControlNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.ClassUtils;

	
	/**
	 * Updates all animation slots for a given Entity, checking whether they should be deactivated.
	 * It also turns on auto for the primary slot, if it is set to deactivate.
	 * If a non-primary slot is deactivated, the other existing slots are flagged to reload ( reload happens in RigAnimationSsytem)
	 * 
	 * An 'animation slot' represents an animation level for a particular character.
	 * An Entity is created for each animation slot by the AnimationSlotCreator.
	 * Each of these enties contains an AnimationSlot component, with information about the slot.
	 * 
	 * The AnimationSlot component contains:
	 * priority - the 'level' of the slot.  Higher priority slots are played over lower priority slots, with 0 being the lowest.
	 * active - if the slot should be active, an inactive slot is ignored.
	 * reload - flag for RigAnimationLoader to determine if the slot should be reload, set to true when another slot has become inactive.
	 */

	public class AnimationControlSystem extends GameSystem
	{
		public function AnimationControlSystem()
		{
			super( AnimationControlNode, updateNode );
			super._defaultPriority = SystemPriorities.checkAnimActive;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
		}
		
		/**
		 * Flag other animation slots to reload, now that the current slot is inactive
		 * Call when anim slot is made inactive
		 * @param	node
		 */
		private function updateNode( node:AnimationControlNode, time:Number ):void
		{		
			/**
			 * This system updates slots, checking whether they should be deactivated
			 * It also turns on auto for the primary slot, if it is set to deactivate
			 * If a non-primary slot is deactivated, th eother existing slots are flagged to reload ( reload happens in RigAnimationSsytem)
			 */
			
			var animSlot:AnimationSlot = node.animSlot;

			if ( !checkActive( node ) )
			 {
				// if slot is inactive
				if ( animSlot.priority == 0 )			// if primary slot, turn on auto
				{
					var rigAnim:RigAnimation = node.rigAnim;
					
					if( rigAnim.queue.length > 0 )		// while queue is full, pull next animation from queue
					{
						rigAnim.next = rigAnim.queue.shift();
					}
					else
					{
						if( node.fsmControl )
						{
							node.fsmControl.active = true;
							return;
						}
	
						/**
						 * If an animation ends with no next aniamtion being specified, or FSM avaialble
						 * Then the logic is to revert to the previous animation.
						 * If there is no previous animation, then the current aniamtion is restarted.
						 */
						if( rigAnim.previous )	// revert to previous
						{
							rigAnim.next = ClassUtils.getClassByObject( rigAnim.previous);
						}
						else					// restart current
						{
							node.timeline.reset();
							rigAnim.end = false;
						}
					}
				}
				else if ( animSlot.active )			// if not primary, deactivate slot and flag other slots to relaod
				{
					var otherAnimSlot:AnimationSlot;	
					var animControl:AnimationControl = node.animControl;
					
					var k:int = 0;
					for ( k; k < animControl.numSlots; k++ )		
					{
						if ( k != animSlot.priority )
						{
							otherAnimSlot = animControl.getSlotAt(k);
							if ( otherAnimSlot.active )
							{
								otherAnimSlot.reload = true;
							}
						}
					}
					animSlot.active = false;
				}
			}
			else
			{
				node.animSlot.active = true;
			}
		}
		
		/**
		 * Checks whether the slot should be set to active or inactive
		 * @param	node
		 */
		private function checkActive( node:AnimationControlNode ):Boolean
		{
			if ( node.rigAnim.current && !node.rigAnim.end )
			{
				return true;		// slot is active is it has a current animation that is not at end
			}
			else if ( node.rigAnim.next )
			{
				return true;		// slot is active if it has a next animation
			}
			
			return false;
		}
	}
}
