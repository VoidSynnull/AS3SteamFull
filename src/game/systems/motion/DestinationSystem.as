package game.systems.motion
{
	import game.components.entity.collider.PlatformCollider;
	import game.components.motion.Destination;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.TargetEntity;
	import game.nodes.motion.DestinationNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.DataUtils;

	/**
	 * System that manages the destination part of navigation logic, essentially whether an entiy has reached it's destination of not.
	 * This sytem correlates different ways of reaching a destination and does additional conditional testing that the destination may require.
	 * For example, additional testing may require the Entiy to be in a particular state when reaching destination.
	 * In additon certain conditons may be forced upon reach the destination, such as negating motion or forcing a state.
	 * @author umckiba
	 * 
	 */
	public class DestinationSystem extends GameSystem
	{
		public function DestinationSystem()
		{
			super( DestinationNode, nodeUpdate, null, nodeRemoved);
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function nodeRemoved( node:DestinationNode ):void
		{
			var destination:Destination = node.destination;
			destination.onFinalReached.removeAll();
			destination.onInterrupted.removeAll();
		}
		
		private function nodeUpdate( node:DestinationNode, time:Number ):void
		{
			var destination:Destination = node.destination;
			
			// if active check for interruption or destination reached
			if( destination.active )
			{
				var motionTarget:MotionTarget = node.motionTarget;
				var motionControl:MotionControl = node.motionControl;
				
				// setup newly activated destination
				if( destination._activated )	
				{
					destination._activated = false;
					motionControl.forceTarget = true;	// when trying to reach destination, motion towards target is being forced
					motionTarget.targetReached = false;	// set targetReached as precaution. Is this necessary? - bard
					
					// lockInput, if already locked then ignore destination's lockControl, and do not unlock on completion
					if( destination.lockControl )	
					{ 
						if( !motionControl.lockInput )
						{
							motionControl.lockInput = true; 
						}
						else
						{
							destination.lockControl = false;
						}
					}
					
					// turn on & off appropriate components depending on method of reaching destination
					if( destination.useType == Destination.USE_PATH )
					{
						motionTarget.checkReached = false;	// stop target check, until navigation activates
						node.navigation.activate = true;
						if( node.targetEntity )	{ node.targetEntity.active = false; }
					}
					else if ( destination.useType == Destination.USE_TARGET )
					{
						motionTarget.checkReached = true;	// if actually checking for reach target will need to set this to true. Not sure if it should be on by default
						motionTarget.hasNextTarget = true;
						if( node.navigation )	{ node.navigation.active = false; }
					}
					else
					{
						trace ("Error :: DestinationSystem :: Destination use type must be specified and valid, type: " + destination.useType + " is invalid.");
					}
				}
				
				// TODO :: what can interrupt a destination, should it be managed here?
				// check for interrupt, if true clear destination
				if( destination.interrupt ) 
				{
					//reset & dispatch
					resetDestination( node );	
					destination.onFinalReached.removeAll();
					destination.onInterrupted.dispatch( node.entity );	
				}
				else	// check for destination reached
				{
					// check for target reached
					if( motionTarget.targetReached )
					{
						// check for final target
						if( !motionTarget.hasNextTarget || destination.nextReachAsFinal )
						{
							// Check for further conditions
							if( !checkValidStates( node ) )	// check valid states, if defined
							{
								//destination.interrupt = true;
								//nodeUpdateFunction( node, time );
								return;
							}
							// check velocity range before proceeding?  This should be handled by the MotionTargetSystem. - bard
							
							// Destination Reached, apply on reached conditions
							if( destination.checkDirection )	{ updateDirection(node); }	// apply direciton adjustments
							// apply motion adjustments
							for (var i:int = 0; i < destination.motionToZero.length; i++) 	// apply motion adjustments
							{
								node.motion.zeroMotion(destination.motionToZero[i]);
							}
							
							// dispatch & reset
							resetDestination(node);
							if( destination.onInterrupted != null ) { destination.onInterrupted.removeAll(); }
							destination.onFinalReached.dispatch( node.entity );
						}
					}
				}
			}
		}
		
		/**
		 * Check if Entity is in a valid states.
		 * If valid states have bnnot nbeen defined, or necessary state component is not available returns true.
		 * @param node
		 * @return 
		 */
		private function checkValidStates( node:DestinationNode ):Boolean
		{
			var destination:Destination = node.destination;

			if( destination.validCharStates != null )
			{
				if( node.fsmControl )
				{
					var numState:int = destination.validCharStates.length;
					if( numState > 0 )
					{
						var currentState:String = node.fsmControl.state.type;
						for (var i:int = 0; i < numState; i++) 
						{
							if( currentState == destination.validCharStates[i] )
							{
								return true;
							}
						}
						return false
					}
				}
			}
			
			return true;
		}
		
		/**
		 * Face the specified direction either by string or point.
		 * @param	node
		 * @return
		 */
		private function updateDirection(node:DestinationNode):void
		{
			var destination:Destination = node.destination;
			var motionControl:MotionControl = node.motionControl;
			
			// determine how entity should face, 
			if ( DataUtils.validString( destination.directionFace )  )	// if directionFace has been set, implement the specified direction
			{
				if(	(node.spatial.scaleX > 0 && destination.directionFace == CharUtils.DIRECTION_RIGHT) ||
					(node.spatial.scaleX < 0 && destination.directionFace == CharUtils.DIRECTION_LEFT ) ) 
				{
					node.spatial.scaleX *= -1;
				}
				destination.resetDirection();
			}
			else if ( destination.directionTarget )						// if directionTarget is true, face direction of target 
			{
				if( destination.directionTarget.x > node.spatial.x )
				{
					if ( node.spatial.scaleX > 0 )	// target is to right, if facing left, flip scale
					{
						node.spatial.scaleX *= -1;
					}
				}
				else if( destination.directionTarget.x < node.spatial.x )
				{
					if ( node.spatial.scaleX < 0 )	// target is to left, if facing right, flip scale
					{
						node.spatial.scaleX *= -1;
					}
				}
			}
		}
		
		private function resetDestination( node:DestinationNode ):void
		{
			// reset Destination
			var destination:Destination = node.destination;
			destination.active = false;
			destination.interrupt = false;
			destination.motionToZero.length = 0;
			destination.resetDirection();
			destination.validCharStates = new Vector.<String>();
			
			// manage ignore Platform 
			// TODO :: want a cleaner way to manage this.
			if( destination.ignorePlatformTarget )
			{
				destination.ignorePlatformTarget = false;
				var platformCollider:PlatformCollider = node.entity.get(PlatformCollider);
				if( platformCollider )
				{
					platformCollider.ignoreNextHit = false;
				}
			}
			
			// reset MotionControl
			var motionControl:MotionControl = node.motionControl;
			motionControl.forceTarget = false;
			motionControl.moveToTarget = false;
			
			// clean up listeners
			//destination.onFinalReached.removeAll();
			//if( destination.onInterrupted != null ) { destination.onInterrupted.removeAll(); }
			
			// if destination called for a control lock, unlock on reset
			if( destination.lockControl )	
			{ 
				destination.lockControl = false;
				motionControl.lockInput = false; 
			}

			// reset specifically based on current means of reaching destination
			if( destination.useType == Destination.USE_PATH )
			{
				node.navigation.active = false;	// if navigation path completed, active has already been set to false
				var targetEntity:TargetEntity = node.targetEntity;
				if( targetEntity )	
				{ 
					targetEntity.active = true; // TODO :: return to active, if was active prior to destination activation? - bard
					motionControl.forceTarget = targetEntity.forceTarget;
				}
			}
			else if ( destination.useType == Destination.USE_TARGET )
			{
		
			}
			destination.useType = "";
			
			if( destination.removeOnReset )
			{
				node.entity.remove(Destination);
			}
		}

	}
}