package game.systems.entity.character.states.movieClip 
{
	import engine.components.Motion;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.DuckSpin;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.Utils;
	
	public class MCDuckState extends MCState
	{
		public var duckUpLabel:String = "duckUp";
		public var duckDownLabel:String = "duckDown";
		public var duckSpinLabel:String = "duckSpin";
		public var duckUpSpinLabel:String = "duckUpSpin";
		
		private var _minXDistanceSpin:Number = 960 * 0.05; // minimum delta distance needed to trigger a duck spin
		private var _maxXDistanceSpin:Number = 960 * 0.1; // maximum distance accounted for when determining jump spin values
		
		public function MCDuckState()
		{
			super.type = CharacterState.DUCK;
		}
		
		override public function check():Boolean
		{
			if ( !node.motionControl.forceTarget )
			{
				if( node.motionControl.moveToTarget )	// if input active
				{
					if ( node.motionTarget.targetDeltaY > (node.edge.rectangle.bottom + node.charMotionControl.duckBufferY) )
					{
						if( Math.abs(node.motionTarget.targetDeltaX) < node.charMotionControl.duckDeltaX )
						{
							return true;
						}
					}
				}
			}
			return false;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			var charMotionCtrl:CharacterMotionControl = node.charMotionControl;
			
			charMotionCtrl.ignoreVelocityDirection = false;
			node.charMovement.state = CharacterMovement.NONE;

			if ( charMotionCtrl.spinning )
			{
				this.setLabel(this.duckSpinLabel);
				charMotionCtrl.spinSpeed = charMotionCtrl.spinLandRotation * Utils.getCharge( charMotionCtrl.spinSpeed ) ;
				charMotionCtrl.spinEnd = true;
				
				// wait for end of spin
				super.updateStage = updateSpin;
			}
			else
			{
				// check delta to see if qualifies for spin
				var targetDeltaXAbs:Number = Math.min( Math.abs(node.motionTarget.targetDeltaX ), _maxXDistanceSpin );
				if ( targetDeltaXAbs > _minXDistanceSpin )
				{
					this.setLabel(this.duckSpinLabel);
					charMotionCtrl.spinning = true;
					charMotionCtrl.spinCount = 1;							// rotate once
					charMotionCtrl.spinSpeed = charMotionCtrl.duckRotation;	// set spin speed
					super.updateStage = updateSpin;							// wait for end of spin

					// if ducking while running/walking allow velocity to carry over
					// otherwise clear motion settings and apply velocity using duck values
					var motion:Motion = node.motion;
					if ( Math.abs( motion.velocity.x) < charMotionCtrl.walkSpeed )
					{
						// reset motion
						super.resetMotion();
						
						// apply friction
						motion.friction.x = charMotionCtrl.duckFriction;
						
						// apply velocity
						var rollFactor:Number = targetDeltaXAbs / _minXDistanceSpin;
						motion.velocity.x = charMotionCtrl.duckSpeed * rollFactor * Utils.getCharge( node.motionTarget.targetDeltaX );
					}
				}
				else
				{
					this.setLabel(this.duckDownLabel);
					super.updateStage = updateDown;
				}
			}
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
	
			if ( node.hazardCollider.isHit )			// check for hazard collision				
			{
				node.fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( !node.platformCollider.isHit )	// check for platform collision				
			{
				node.fsmControl.setState( CharacterState.FALL );
				return;
			}
			else
			{
				super.updateStage();
			}
		}
		
		/////////////////////////////////////////////////////////////////
		////////////////////////// UPDATE STAGES ////////////////////////
		/////////////////////////////////////////////////////////////////
		
		private function updateDown():void
		{
			// check if animation has reached last frame
			if ( CharUtils.animAtLastFrame( node.entity, DuckDown ) )
			{
				node.motion.velocity.x = 0;
				node.motion.acceleration.x = 0;
				node.motion.friction.x = 0;
				
				super.updateStage = updateWait;
				super.updateStage();
			}
		}
		
		private function updateSpin():void
		{
			// TODO :: apply friction to slow down x velocity 
			
			if ( node.charMotionControl.spinStopped )
			{
				// force animation to last frame
				// node.timeline.gotoAndStop( node.timeline.data.duration - 1 );
				
				// is input is down and out of duck range continue to run/walk
				if ( node.motionControl.moveToTarget && check() )
				{
					node.motion.velocity.x = 0;
					node.motion.acceleration.x = 0;
					node.motion.friction.x = 0;
					
					super.updateStage = updateWait;
					return;
				}
				else
				{
					beginUp();
					super.updateStage = updateUp;
					return;
				}
			}
		}
		
		private function beginUp():void
		{
			var currentClass:Class = DuckDown;//TO-DO This is hardcoded. Utils.getClass(node.primary.current);
			if ( currentClass == DuckDown )
			{
				this.setLabel(duckUpLabel);
			}
			else if ( currentClass == DuckSpin )
			{
				this.setLabel(this.duckUpSpinLabel);
			}
			else
			{
				trace( "Error :: DuckState :: beginUp :: Not coming from a valid animation." );
			}
		}
		
		private function updateWait():void
		{
			node.motion.velocity.x = 0;
			node.motion.acceleration.x = 0;
			node.motion.friction.x = 0;
			if ( !check() )	// once no longer ducking
			{
				beginUp();
				super.updateStage = updateUp;
			}
		}

		private function updateUp():void
		{
			if ( node.charMotionControl.animEnded )			// if animation has ended
			{
				node.charMotionControl.animEnded = false;

				if ( node.fsmControl.check( CharacterState.RUN ) )		// check for walk
				{
					node.fsmControl.setState( CharacterState.RUN );
					return;
				}
				else if( node.fsmControl.check( CharacterState.WALK ) )	// check for stand
				{
					node.fsmControl.setState( CharacterState.WALK ); 
					return;
				}
				else
				{
					node.motion.velocity.x = 0;
					node.motion.acceleration.x = 0;
					node.fsmControl.setState( CharacterState.STAND );
					return;
				}
			}
		}
	}
}