package game.systems.entity.character
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Spring;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.character.CharacterMovementNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.GeomUtils;
	import game.util.PlatformUtils;
	import game.util.Utils;

	public class CharacterMovementSystem extends GameSystem
	{
		private var _touchControls:Boolean = false;
		
		public function CharacterMovementSystem()
		{
			super(CharacterMovementNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			
			_touchControls = PlatformUtils.isMobileOS;
		}
		
		private function updateNode(node:CharacterMovementNode, time:Number):void
		{
			if(node.charMovement.active)
			{
				// move character based on states
				var state:String = node.charMovement.state;
				
				if(!node.motion.pause)
				{
					// update movement based on state
					switch(state)
					{
						case CharacterMovement.GROUND :
							moveGround(node);
							moveGroundFriction(node);
							break;
							
						case CharacterMovement.GROUND_FRICTION :
							moveGroundFriction(node);
							break;
							
						case CharacterMovement.AIR :
							moveAir(node);
							break;
							
						case CharacterMovement.CLIMB :
							moveClimb(node);
							break;
							
						case CharacterMovement.DIVE :
							if( _touchControls )
							{
								moveWaterTouch(node)
							}
							else
							{
								moveWater(node)
							}
							break;
					}
											
					// update direction (determined by x velocity)
					if ( node.charMotionControl.directionByVelocity && !node.charMotionControl.ignoreVelocityDirection )	
					{
						updateDirectionByVelocity(node);
					}
					// character apply head offset
					if( node.charMovement.adjustHeadWithVelocity )
					{
						applyHeadOffset(node);	
					}
				}
			}
			
			// the updates for spinning need to happen even if charMotion.active is false.  This prevents getting
			//  stuck spinning endlessly.
			if(!node.motion.pause)
			{
				// apply rotationVelocity to spin the character around for angled jumps.
				updateSpin(node, time);
			}
		}
		
		/**
		 * Manage rotation and spinning state
		 * @param	node
		 */
		private function updateSpin( node:CharacterMovementNode, time:Number ):void
		{
			var motion:Motion = node.motion;
			var charControl:CharacterMotionControl = node.charMotionControl;
			
			if(charControl.spinning)
			{ 
				var speedAdjust:Number = Math.max((Math.abs(node.motion.velocity.x) / charControl.spinSpeedAdjust), 1);
				var spinSpeed:Number = charControl.spinSpeed;
				var spinVelocity:Number = spinSpeed * speedAdjust * Utils.getCharge(node.spatial.scaleX);
				// calculate spinVelocity as a factor of x velocity and direction.
				motion.rotationVelocity = -spinVelocity;
				
				// spin count doesn't seem to be decremented anywhere so probably not necessary.  
				if (charControl.spinCount > 0)
				{
					// NOTE :: We divide by 180 because rotation ranges are 0 to 180 then -180 to 0
					if ((Math.abs(motion.rotation) / 180 ) >= charControl.spinCount)
					{
						charControl.spinEnd = true;
						charControl.spinCount = 0;
					}
				}
				
				if (charControl.spinEnd)
				{
					// If the character's rotation is close enough to 0, the spin is complete.
					if (Math.abs(motion.rotation % 360) < (Math.abs(spinVelocity) * time * 1.5 ))
					{
						motion.rotation = 0;
						motion.rotationVelocity = 0;
						charControl.spinning = false;
						charControl.spinEnd = false;
						charControl.spinCount = 0;
					}
				}
			}
		}
		
		/**
		 * Apply offset to head based on x velocity
		 * @param	node
		 */
		private function applyHeadOffset( node:CharacterMovementNode ):void
		{
			var headJoint:Entity = CharUtils.getJoint( node.entity, CharUtils.HEAD_JOINT)
			if( headJoint )
			{
				var spring:Spring = headJoint.get(Spring);
				var charControl:CharacterMotionControl = node.charMotionControl;
				if ( node.motion.velocity.x != 0 )
				{
					var offset:Number = charControl.headOffsetMax;
					// if pet
					if (node.edge.rectangle.bottom == 0)
					{
						offset = charControl.petHeadOffsetMax;
					}
					spring.offsetXOffset = -offset * Math.min( ( Math.abs( node.motion.velocity.x ) / charControl.maxVelocityX ), 1 );
				}
				else
				{
					spring.offsetXOffset = 0;
				}
			}
		}
		
		/**
		 * Update the direction of character based on velocity
		 * @param	node
		 */
		private function updateDirectionByVelocity( node:CharacterMovementNode ):void
		{
			if (node.motion.velocity.x > 0)		// face right
			{
				if ( node.spatial.scaleX > 0 )	// if facing left, flip scale
				{
					node.spatial.scaleX *= -1;
				}
			}
			else if(node.motion.velocity.x < 0)	// face left
			{
				if ( node.spatial.scaleX < 0 )	// if facing rigth, flip scale
				{
					node.spatial.scaleX *= -1;
				}
			}
		}
		
		/**
		 * Method for moving character while on a surface
		 * @param	node
		 */
		private function moveGround( node:CharacterMovementNode ):void
		{
			var motionControl:MotionControl = node.motionControl;
			var charControl:CharacterMotionControl = node.charMotionControl;
			var motion:Motion = node.motion;
			var motionTarget:MotionTarget = node.motionTarget;
			
			var directionFactor:Number = 0;
			
			// if input is active ( mouse down ) apply velocity & acceleration
			if ( motionControl.moveToTarget )	
			{
				var charMotionControlX:Number = node.charMotionControl.moveFactorX * node.charMotionControl.scalingFactor;
				
				// get direction factor and apply min & max
				if ( motionTarget.targetDeltaX > node.charMotionControl.inputDeadzoneX)			// if move right
				{
					directionFactor = Math.min( motionTarget.targetDeltaX / charMotionControlX, 1);
				}
				else if ( motionTarget.targetDeltaX < -node.charMotionControl.inputDeadzoneX)	// if move left
				{
					directionFactor = Math.max( motionTarget.targetDeltaX / charMotionControlX, -1);
				}
				
				// define max velocity
				motion.maxVelocity.x = charControl.maxVelocityX * Math.max(.5, Math.abs(directionFactor));
				
				// if velocity is changing direction ( was previously going right and is now going left & vice versa ) then apply dampening
				if((directionFactor > 0 && motion.velocity.x < 0) || (directionFactor < 0 && motion.velocity.x > 0))
				{
					motion.velocity.x *= charControl.velocityDampen;
				}
				else if( Math.abs(motion.velocity.x) < charControl.minRunVelocity )	// if direction has not changed & below minimum velocity, set to minimum
				{
					if(motion.velocity.x <= 0 && directionFactor < 0)
					{
						motion.velocity.x = -charControl.minRunVelocity;
					}
					else if(motion.velocity.x >= 0 && directionFactor > 0)
					{
						motion.velocity.x = charControl.minRunVelocity;
					}
				}
				
				// apply x acceleration, this is what takes the directionFactor into account
				motion.acceleration.x = directionFactor * charControl.baseAcceleration;
			}
			else
			{
				// define max velocity
				motion.maxVelocity.x = charControl.maxVelocityX * .5;
				
				// zero acceleration
				motion.zeroAcceleration( "x" );
			}
		}
		
		/**
		 * Determine friction along x
		 * @param	node
		 */
		private function moveGroundFriction( node:CharacterMovementNode ):void
		{
			// apply x friction if not accelerating
			//if( node.motion.acceleration.length == 0 );	// NOTE :: Not sure why it was testing total acceleration, and not just x
			if( node.motion.acceleration.x == 0 )	
			{
				if ( !node.motionControl.moveToTarget )
				{
					var friction:Point = CharUtils.getFriction( node.entity );
					if ( friction )
					{
						node.motion.friction.x = friction.x;
					}
					else
					{
						node.motion.friction.x = node.charMotionControl.frictionStop;
					}
				}
				else
				{
					node.motion.friction.x = node.charMotionControl.frictionAccel;
				}
			}
			else
			{
				node.motion.friction.x = 0;
			}
		}
		
		/**
		 * Method for moving character while in the air
		 * @param	node
		 */
		private function moveAir( node:CharacterMovementNode ):void
		{
			// apply gravity to y
			if(node.motion.velocity.y > node.charMotionControl.maxFallingVelocity)
			{
				node.motion.velocity.y = node.charMotionControl.maxFallingVelocity;
			}
			
			node.motion.acceleration.y = node.charMotionControl.gravity;
			
			// set x factors
			node.motion.acceleration.x = 0;
			node.motion.friction.x = 0;
			node.motion.maxVelocity.x = node.charMotionControl.maxAirVelocityX;
			
			if( node.motionControl.lockInput && !node.motionControl.forceTarget )
			{
				return;
			}
			else if ( node.charMotionControl.allowAutoTarget || node.motionControl.inputActive )	// if targets input by default, apply x velocity
			{
				var velocityX:Number = 0;
				if (node.motionTarget.targetDeltaX > node.charMotionControl.inputDeadzoneX)
				{
					velocityX = Math.min(node.motionTarget.targetDeltaX, node.charMotionControl.moveFactorX);
				}
				else if ( node.motionTarget.targetDeltaX < -node.charMotionControl.inputDeadzoneX)
				{
					velocityX = Math.max(node.motionTarget.targetDeltaX, -node.charMotionControl.moveFactorX);
				}
				// TODO :: Want this to be additive if possible, so velocity applied from bounce velocity can persist
				node.motion.velocity.x = velocityX * node.charMotionControl.airMultiplier;
			}
		}
		
		/**
		 * Applies movement within water
		 */
		private function moveWater( node:CharacterMovementNode ):void
		{
			if( node.motionControl.moveToTarget  && !node.motionControl.lockInput )
			{
				var inputDeadzoneY:int = ( node.motionControl.forceTarget ) ? 0 : node.charMotionControl.inputDeadzoneY;
				var directionYFactor:Number = 0;
				if ( node.motionTarget.targetDeltaY >inputDeadzoneY)
				{
					directionYFactor = Math.min( node.motionTarget.targetDeltaY / node.charMotionControl.moveFactorX, 1);
				}
				else if ( node.motionTarget.targetDeltaY < -inputDeadzoneY)
				{
					directionYFactor = Math.max( node.motionTarget.targetDeltaY / node.charMotionControl.moveFactorX, -1);
				}
				node.motion.velocity.y = directionYFactor * (node.charMotionControl.diveSpeed * .9) ;	//dampen y velocity slightly
			}
			
			if( node.charMotionControl.allowAutoTarget && !node.motionControl.lockInput)
			{
				var directionXFactor:Number = 0;
				if ( node.motionTarget.targetDeltaX > node.charMotionControl.inputDeadzoneX)
				{
					directionXFactor = Math.min( node.motionTarget.targetDeltaX / node.charMotionControl.moveFactorX, 1);
				}
				else if ( node.motionTarget.targetDeltaX < -node.charMotionControl.inputDeadzoneX)
				{
					directionXFactor = Math.min( node.motionTarget.targetDeltaX / node.charMotionControl.moveFactorX, -1);
				}
				
				if( !node.motionControl.moveToTarget )	// if input is not active, dampen velocity 
				{
					directionXFactor *= .3;
				}
				node.motion.velocity.x = directionXFactor * node.charMotionControl.diveSpeed;
			}
			
			// rotate to target
			// TODO :: this needs further work.  Gets jittery when crossing 0/180 - Bard
			if( Math.abs(directionXFactor) > 0 )
			{
				var degrees:Number = GeomUtils.degreesBetween( node.spatial.x, node.spatial.y, node.motionTarget.targetX, node.motionTarget.targetY );
				if( node.spatial.scaleX > 0 )
				{
					if ( degrees < 30 )
					{
						degrees = 30;
					}
					else if ( degrees > 75 ) 
					{
						degrees = 75;
					}
					node.spatial.rotation = degrees - (90 - ROTATION_OFFSET);
				}
				else
				{
					if ( degrees >= 90 && degrees < 105 )
					{
						degrees = 105;
					}
					else if( degrees > 150 || degrees < 0 )
					{
						degrees = 150;
					}
					node.spatial.rotation = degrees - (90 + ROTATION_OFFSET);
				}
			}
		}
		
		private function moveWaterTouch( node:CharacterMovementNode ):void
		{
			var directionXFactor:Number = 0;
			if( node.motionControl.moveToTarget )
			{
				var directionYFactor:Number = 0;
				if ( node.motionTarget.targetDeltaY > node.charMotionControl.inputDeadzoneY)
				{
					directionYFactor = Math.min( node.motionTarget.targetDeltaY / node.charMotionControl.moveFactorX, 1);
				}
				else if ( node.motionTarget.targetDeltaY < -node.charMotionControl.inputDeadzoneY)
				{
					directionYFactor = Math.max( node.motionTarget.targetDeltaY / node.charMotionControl.moveFactorX, -1);
				}
				node.motion.velocity.y = directionYFactor * (node.charMotionControl.diveSpeed * .9) ;	//dampen y velocity slightly
				
				// move torwards target x
				if ( node.motionTarget.targetDeltaX > node.charMotionControl.inputDeadzoneX)
				{
					directionXFactor = Math.min( node.motionTarget.targetDeltaX / node.charMotionControl.moveFactorX, 1);
				}
				else if ( node.motionTarget.targetDeltaX < -node.charMotionControl.inputDeadzoneX)
				{
					directionXFactor = Math.min( node.motionTarget.targetDeltaX / node.charMotionControl.moveFactorX, -1);
				}
				node.motion.velocity.x = directionXFactor * node.charMotionControl.diveSpeed;
			}
			else
			{
				// TODO :: dampen x
				//directionXFactor *= .3;	// if input is not active, dampen x 
			}
			
			// rotate to target
			if( Math.abs(directionXFactor) > 0 )
			{
				var degrees:Number = GeomUtils.degreesBetween( node.spatial.x, node.spatial.y, node.motionTarget.targetX, node.motionTarget.targetY );
				if( node.spatial.scaleX > 0 )
				{
					if ( degrees < 30 )
					{
						degrees = 30;
					}
					else if ( degrees > 75 ) 
					{
						degrees = 75;
					}
					node.spatial.rotation = degrees - (90 - ROTATION_OFFSET);
				}
				else
				{
					if ( degrees >= 90 && degrees < 105 )
					{
						degrees = 105;
					}
					else if( degrees > 150 || degrees < 0 )
					{
						degrees = 150;
					}
					node.spatial.rotation = degrees - (90 + ROTATION_OFFSET);
				}
			}
		}
		
		private function moveClimb( node:CharacterMovementNode ):void
		{
			var motion:Motion = node.motion;
			var motionControl:MotionControl = node.motionControl;
			var charMotion:CharacterMotionControl = node.charMotionControl;
			var directionFactor:Number = 0;
			
			// apply motion based on control
			if ( motionControl.moveToTarget )	
			{	
				// apply y velocity
				if( node.motionTarget.targetDeltaY > node.edge.rectangle.bottom/2)
				{
					motion.velocity.y = charMotion.climbDownVelocity;
				}
				else if( node.motionTarget.targetDeltaY < -node.charMotionControl.inputDeadzoneY)
				{
					motion.velocity.y = charMotion.climbUpVelocity;
				}
				else
				{
					if( Math.abs(motion.velocity.y) > 1)
					{
						motion.velocity.y *= .95;
					}
					else
					{
						motion.velocity.y = 0;
					}
				}
				
				// if moving from forceTarget, use navigation minXDistance, else use climb specific minXDistance
				var minXDistance:Number = ( node.motionControl.forceTarget ) ? node.charMotionControl.inputDeadzoneX : charMotion.climbMinXDistance;
				
				//determine directionFactor for x velocity
				if ( node.motionTarget.targetDeltaX > minXDistance)
				{
					directionFactor = Math.min( node.motionTarget.targetDeltaX / charMotion.moveFactorX, 1);
				}
				else if ( node.motionTarget.targetDeltaX < -minXDistance)
				{
					directionFactor = Math.max( node.motionTarget.targetDeltaX / charMotion.moveFactorX, -1);
				}
			}
			else if ( motion.velocity.y != 0 )
			{
				// adjust acceleration based on climb direction
				if( motion.velocity.y > 5)
				{
					motion.acceleration.y = -800;
				}
				else						
				{
					// halt if climbing up
					motion.zeroMotion( "y" );
				}
			}
			
			// update x velocity
			motion.maxVelocity.x = node.charMotionControl.maxVelocityX * Math.max(.5, Math.abs(directionFactor));
			motion.velocity.x *= charMotion.climbDampen;
			motion.acceleration.x = directionFactor * node.charMotionControl.baseAcceleration;
		}
		
		protected const ROTATION_OFFSET:int = 30;
	}
}