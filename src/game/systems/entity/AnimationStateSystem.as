package game.systems.entity
{
	import game.components.entity.State;
	import game.data.StateData;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.StateNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	/**
	 * Manages states, is updated as part of the animation time step.
	 * If a state is changed it sets the hasChanged flag to true for one update cycle.
	 */
	public class AnimationStateSystem extends GameSystem
	{
		public function AnimationStateSystem()
		{
			super( StateNode, updateNode, null, nodeRemoved );
			super._defaultPriority = SystemPriorities.update;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
		}
		
		private function nodeRemoved( node:StateNode ):void
		{
			node.state.updateComplete.removeAll();
			node.state.updateComplete = null;
		}
				
		private function updateNode(node:StateNode, time:Number):void
		{
			var state:State = node.state;

			if ( state.invalidate )
			{
				if( updateValue( node ) )
				{
					state.invalidate = false
					state.hasChanged = true;	// hasChanged is used as a flag that exists for a single update cycle.
					return;
				}
			}
			
			if( state.hasChanged )
			{
				state.hasChanged = false;	// once hasChanged has passed through a full update cycle set it is set back to false
				if( state.updateComplete )
				{
					state.updateComplete.dispatch( node.entity );	// dispatch to notify that state has finished 
				}
			}
		}
		
		/**
		 * Update value.
		 * @param	node
		 * @return
		 */
		private function updateValue(node:StateNode):Boolean
		{
			var i:int;
			var j:int
			var childState:StateData;
			var validated:Boolean = true;
			for each ( var stateData:StateData in node.state.states )
			{
				if ( stateData.invalidate )	
				{
					//if has parentState, retrieve value from parent once parent is valid
					if ( stateData.parentStateData )
					{
						if ( stateData.parentStateData.invalidate )
						{
							// don't apply value until parent has
							validated = false;
							continue;
						}
						else 
						{
							stateData.value = stateData.parentStateData.value;
						}
					}
					
					//update children
					if ( stateData.childrenStates )
					{
						for ( j = 0; j < stateData.childrenStates.length; j++ )
						{
							childState = stateData.childrenStates[j];
							childState.value = stateData.value;
							childState.invalidate = true;
						}
					}
					
					stateData.invalidate = false;
				}
			}
			return validated;
		}
	}
}