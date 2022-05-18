package game.systems.entity.character.states 
{
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMovement;
	import game.data.animation.entity.character.Disco;
	import game.data.animation.entity.character.LeprechanJig;
	import game.data.animation.entity.character.RobotDance;
	import game.data.animation.entity.character.Think;
	import game.data.animation.entity.character.Wave;
	import game.util.ArrayUtils;
	import game.util.CharUtils;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class IdleState extends CharacterState
	{
		public var idleAnimations:Vector.<Class> = new <Class>[ Disco, LeprechanJig, RobotDance, Wave, Think];
		public var delayBase:int = 300;
		public var delayRange:int = 200;
		
		private var _currentAnimation:Class;
		
		public function IdleState()
		{
			super.type = CharacterState.IDLE;
		}
		
		public function init( anims:Vector.<Class>, delayBase:int, delayRange:int):void
		{
			idleAnimations = anims;
			this.delayBase = delayBase;
			this.delayRange = delayRange;
		}
		
		public function getDelay():int
		{
			return ( Math.random()*delayRange + delayBase );
		}
		
		/**
		 * Start the state
		 */
		override public function start():void 
		{
			_currentAnimation = ArrayUtils.getRandomElementVector(idleAnimations);
			super.setAnim(_currentAnimation, true);
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			node.charMovement.state = CharacterMovement.GROUND;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var fsmControl:FSMControl = node.fsmControl;
			if ( fsmControl.check(CharacterState.HURT) )			// check for platform collision
			{
				fsmControl.setState( CharacterState.HURT );
				return;
			}
			else if ( fsmControl.check(CharacterState.FALL) )		// check for platform collision
			{
				fsmControl.setState( CharacterState.FALL );
				return;
			}
			else if ( node.motionControl.moveToTarget )	// check press & velocity
			{
				if ( fsmControl.check(CharacterState.JUMP) )		// check for jump
				{
					fsmControl.setState( CharacterState.JUMP ); 
					return;
				}
				else if ( fsmControl.check(CharacterState.DUCK) )	// check for jump
				{
					fsmControl.setState( CharacterState.DUCK ); 
					return;
				}
				else if ( fsmControl.check(CharacterState.WALK) )
				{
					fsmControl.setState(CharacterState.WALK);
					return;
				}
			}
			else if ( CharUtils.animAtLastFrame(node.entity, _currentAnimation) )
			{
				fsmControl.setState( CharacterState.STAND );
				return;
			}
		}
	}
}