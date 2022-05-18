package game.systems.animation
{
	import game.components.animation.FSMControl;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.animation.FSMNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	/**
	 * Automates a characters animation based on controls &amp; collisions.
	 * Can process once for each character, if their AniamtionControl component's autoAnimate flag is true.
	 * Works in conjunction with the charStateSystem &amp; MotionControlSystem
	 */
	public class FSMSystem extends GameSystem
	{
		public function FSMSystem()
		{
			super( FSMNode, updateNode );
			super._defaultPriority = SystemPriorities.autoAnim;	
			
			// NOTE :: Since states are determined by collider, which are determined by motion, this needs to be in the motion loop
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		/**
		 * Determines what 'animation state' character should be in based on charState varaiables.
		 * The order that the states are check is necessary, as some states override other if they are on.
		 * @param	node
		 * @param	time
		 */
		private function updateNode(node:FSMNode, time:Number):void
		{
			// NOTE :: Current if/else order is required
			if ( node.fsmControl.active )			// update animation based on motion & hits	
			{	
				// this is where update character motion was
				updateState( node, time );
			}
		}
		
		private function updateState(node:FSMNode, time:Number):void
		{
			var fsmControl:FSMControl = node.fsmControl;
			
			// check for new state
			if ( fsmControl._invalidate )
			{
				//trace( "FSM :: start state: " + fsmControl.state );
				if(fsmControl.stateChange)	// if Signal has been instantiated, check for dispatch condition
				{
					fsmControl.stateChange.dispatch(fsmControl.state.type, node.entity);
					if( !fsmControl.active )	{ return; }	// possible that handlers set active to false, if so end update
				}
				fsmControl._invalidate = false;
				fsmControl.state.start();
				if ( fsmControl._invalidate )
				{
					updateState( node, time );
					return;
				}
			}
			
			// update current state
			if( fsmControl.state )
			{
				fsmControl.state.update( time );
				if ( fsmControl._invalidate )
				{
					updateState( node, time);
					return;
				}
			}
		}
	}
}
