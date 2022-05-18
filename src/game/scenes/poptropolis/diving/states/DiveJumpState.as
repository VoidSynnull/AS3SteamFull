package game.scenes.poptropolis.diving.states 
{
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.poptropolis.DiveAnim;
	import game.systems.entity.character.states.CharacterState;
	import game.util.ClassUtils;
	import game.util.MotionUtils;
	
	import org.osflash.signals.Signal;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class DiveJumpState extends CharacterState
	{
		private var TRIGGER_LABEL:String = "trigger";
		private var MAX_VEL_Y:int = 400;
		private var GRAVITY:int = 600;
		private var SPIN_MAX:int = 250;
		private var DIVE_POSE_DURATION:int = 300;
		
		public var spinChanged:Signal;	// signal fired when spin direction changes, passes 1 or -1 base on spin direction
		
		private var _spinDirection:int;
		public function get spinDirection():int { return _spinDirection; }
		public var spinsComplete:Boolean;
		public var isDivePose:Boolean;
		private var _poseDuration:int;
		private var _isFalling:Boolean;
		
		public function DiveJumpState()
		{
			super.type = CharacterState.JUMP;
			spinChanged = new Signal(int);
		}
		
		/**
		 * Start the state
		 */
		override public function start():void 
		{
			node.charMotionControl.ignoreVelocityDirection = false;
			
			spinsComplete = false;
			isDivePose = false;
			_isFalling = false;
			super.updateStage = this.updateCheckTrigger;
			setAnim( DiveAnim );
			
			node.charMovement.state = CharacterMovement.NONE;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			// check for water collision
			if ( node.fsmControl.check(CharacterState.SWIM)  )	// check for water collision
			{
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			
			super.updateStage();
			
			if( _isFalling )
			{
				// apply gravity to y
				if(node.motion.velocity.y > MAX_VEL_Y)
				{
					node.motion.velocity.y = MAX_VEL_Y;
				}
				else
				{
					node.motion.acceleration.y = MotionUtils.GRAVITY;
				}
			}
		}
		
		/////////////////////////////////////////////////////////////////
		////////////////////////// UPDATE STAGES ////////////////////////
		/////////////////////////////////////////////////////////////////
		
		private function updateCheckTrigger():void
		{	
			var charState:CharacterMotionControl = node.charMotionControl;
			var currentClass:Class = ClassUtils.getClassByObject( node.primary.current );
			if( currentClass == DiveAnim )
			{
				if ( !(node.timeline.currentIndex < node.primary.getLabelIndex(TRIGGER_LABEL)) )				
				{
					// apply jump velocity
					node.motion.velocity.x = 600;	// TODO :: get appropriate velocities
					node.motion.velocity.y = -600;
					node.charMotionControl.spinning = true;
					node.charMotionControl.spinSpeed = 80;
					super.updateStage = this.updateCheckStraight;
					_isFalling = true;
				}
			}
		}
		
		private function updateCheckStraight():void
		{
			// check is player is pointing down
			if( node.motion.velocity.y > 0 )
			{
				node.charMotionControl.spinSpeed = 150;
				if( node.spatial.rotation > 180 )
				{
					node.charMotionControl.spinSpeed = 0;
					node.timeline.gotoAndPlay( "enterCurl" );
					super.updateStage = this.updateSpinning;
					super.updateStage();
					return;
				}
			}
		}
		
		private function updateSpinning():void
		{
			if( spinsComplete )
			{
				if ( node.motionControl.inputActive )	//listen for click
				{
					//node.charMotionControl.spinSpeed *= 1.5	//adjust spin speed
					node.timeline.gotoAndPlay( "exitCurl" );
					super.updateStage = this.updateDivePose;
					super.updateStage();
					return;
				}
			}

			//determine what direction spin should go based on target position
			var previousSpinDirection:int = _spinDirection;
			if( node.motionTarget.targetX > node.spatial.x )		//spin to right
			{
				_spinDirection = 1;
				node.charMotionControl.spinSpeed = SPIN_MAX;
				
			}
			else if( node.motionTarget.targetX < node.spatial.x )	//spin to left
			{
				_spinDirection = -1;
				node.charMotionControl.spinSpeed = -SPIN_MAX;
			}
			
			if( previousSpinDirection != _spinDirection )
			{
				spinChanged.dispatch( _spinDirection );
			}
		}
		
		private function updateDivePose():void
		{
			var rotationAbs:int = Math.abs( node.spatial.rotation % 360 );
			if( rotationAbs > 170 && rotationAbs < 190 )
			{
				isDivePose = true;
				node.charMotionControl.spinSpeed = 0;
				_poseDuration = 0;
				super.updateStage = this.updateIncrementDivePose;
			}
		}
		
		private function updateIncrementDivePose():void
		{
			_poseDuration++;
			if( _poseDuration >= DIVE_POSE_DURATION )
			{
				//return to spinning
				isDivePose = false;
				node.timeline.gotoAndPlay( "enterCurl" );
				super.updateStage = this.updateSpinning;
				super.updateStage();
			}
		}
	}
}