package game.systems.entity.character.states.touch 
{
	import game.nodes.entity.character.CharacterStateNode;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.JumpState;
	import game.util.MotionUtils;


	/**
	 * Jump state for touch devices 
	 * @author Bard McKinley
	 * 
	 */
	public class JumpState extends game.systems.entity.character.states.JumpState
	{	
		private var _targetOn:Boolean = false;
		private var _forceDirection:Boolean = true;
		
		/////////////////////////////////////////////////////////////////
		////////////////////////// UPDATE STAGES ////////////////////////
		/////////////////////////////////////////////////////////////////
		
		override public function start():void
		{
			_targetOn = false;
			_forceDirection = true;
			super.start();
		}
		
		override public function exit():void
		{
			node.charMotionControl.allowAutoTarget = true;
			_targetOn = false;
			super.exit();
		}
		
		/**
		 * Uses trajectory formula to determine initial velocities.
		 * For more on the trajectory formula:
		 * <link>http://en.wikipedia.org/wiki/Trajectory_of_a_projectile#Angle_required_to_hit_coordinate_.28x.2Cy.29</link>
		 * @param node
		 * @param dampener
		 */
		override protected function applyJumpVelocity( node:CharacterStateNode, dampener:Number = 1 ):void
		{
			var gravity:Number = MotionUtils.GRAVITY;
			var dx:Number = Math.abs(node.motionTarget.targetDeltaX) + node.edge.rectangle.right ; 	// make absolute for equation
			var dy:Number = -node.motionTarget.targetDeltaY;				// account for flash coordinates, adjust for velocity testing
				
			// determine velocity, adjust based on delta
			var vel:Number = createVelocity(dx, dy) * dampener;
			var vel2:Number = vel * vel;	// store velocity squared
			
			// calculate angle
			var root:Number = Math.sqrt( Math.abs(vel2 * vel2 - ( gravity * (gravity * dx * dx + 2 * dy * vel2) ) ) );
			var radians:Number = Math.atan( (vel2 + root)/(gravity * dx) );
			//var radians:Number = Math.atan( (vel2 - root)/(gravity * dx) ); // this will give you the lesser more direct angle, but we want the greater for an upward arc.

			// set x & y velocity from angle
			node.motion.velocity.x = Math.cos( radians ) * vel;
			node.motion.velocity.y = -Math.sin( radians ) * vel;
			if( node.motionTarget.targetDeltaX < 0 )	// flip x velocity depending on x delta
			{
				node.motion.velocity.x *= -1;
			}

			// make character faces jump direction
			super.directionByVelocity();
			
			_targetOn = true;
		}
		

		override protected function move():void
		{
			if( node.motionControl.inputActive )
			{
				_targetOn = false;
			}
		}
		
		override protected function updateCheckLand():void
		{
			if ( node.platformCollider.isHit )		// check for platform collision
			{
				if ( Math.abs(node.motion.velocity.x) > node.charMotionControl.runSpeed )
				{
					super.directionByVelocity();
				}
				if( _targetOn )	
				{ 
					node.motion.velocity.x = 0; 
				}
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			else if ( node.fsmControl.check(CharacterState.SWIM)  )
			{
				// check for water collision
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			else if ( node.motion.velocity.y < 0 && node.fsmControl.check(CharacterState.FALL) )
			{
				// if velocity has reversed change state to fall
				node.fsmControl.setState( CharacterState.FALL );
				return;
			}

			// apply motion
			super.move();
		}

		/**
		 * Heuristic to estimate necessary velocity for trajectory 
		 * @param dx
		 * @param dy
		 * @return 
		 */
		private function createVelocity( dx:Number, dy:Number ):int
		{
			dy += node.edge.rectangle.bottom;	// adjust so we calculate from feet
			var slope:Number = dy/dx;
			var distPercent:Number = Math.sqrt( dx * dx + dy * dy )/300;
			var dampener:Number;
			
			if( slope < 0 )
			{
				if( slope < -1 )
				{ 
					dampener = .65;
				}
				else
				{
					dampener = .3 + (1 + slope) * .3 + distPercent * .2;
				}
			}
			else
			{
				dampener = .6 + Math.min(1, slope) * .2 + distPercent * .2;
			}

			return node.charMotionControl.jumpTargetVelocity * Math.min( 1, dampener )
		}
		
		
	}
}