package game.components.entity.character
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import game.components.Viewport;
	import game.util.CharUtils;
	import game.util.MotionUtils;

	public class CharacterMotionControl extends Component
	{
		public function CharacterMotionControl()
		{
		}

		//public var ignorePlatformTarget:Boolean = false;	// if entity should ignore platforms when trying to above target 
		public var allowAutoTarget:Boolean = false;			// determined by platform, allows for autotargeting when in air
		
		// direction
		public var directionByVelocity:Boolean = false;		// specifies if direction is controlled by motion & hit

		// use for jump target UI
		public var jumpTargetTrigger:Boolean = false;
		public var targetJumping:Boolean = false;
		public var waitingForRelease:Boolean = false;

		private var _directionFace:String = "";
		public function get directionFace():String 	{ return _directionFace; }
		public function set directionFace( direction:String ):void
		{
			if ( direction == CharUtils.DIRECTION_LEFT || direction == CharUtils.DIRECTION_RIGHT )
			{
				_directionFace = direction;
				directionTarget = null;
			}
			else
			{
				_directionFace = "";
			}
		}
		
		private var _directionTarget:Point;
		public function get directionTarget():Point 	{ return _directionTarget; }
		public function set directionTarget( target:Point ):void
		{
			if ( target )
			{
				_directionFace = "";
				_directionTarget = target;
			}
		}
		
		// input ranges
		private var _inputXPercent:Number = .02;
		private var _inputYPercent:Number = .14; 
		public function set inputXPercent( value:Number):void	{ _inputXPercent = value }
		public function set inputYPercent( value:Number):void	{ _inputYPercent = value }
				
		private var _inputDeadzoneX:Number; 
		private var _inputDeadzoneY:Number; 		
		public function get inputDeadzoneX():Number				{ return _inputDeadzoneX; }
		public function get inputDeadzoneY():Number				{ return _inputDeadzoneY; }
		public function set inputDeadzoneX(inputDeadzoneX:Number):void { _inputDeadzoneX = inputDeadzoneX; }
		public function set inputDeadzoneY(inputDeadzoneY:Number):void { _inputDeadzoneY = inputDeadzoneY; }
		
		// movement factors
		private var _moveXPercent:Number = .25;
		public function set moveXPercent( value:Number):void	{ _moveXPercent = value }
		
		private var _moveFactorX:Number;
		public function get moveFactorX():Number				{ return _moveFactorX; }

		/**
		 * Handler for Viewport dispatch, updates viewport dependent variables
		 * @param	viewport
		 */
		public function viewportChanged( viewport:Viewport ):void 
		{
			_inputDeadzoneX = viewport.width * _inputXPercent;
			_inputDeadzoneY = viewport.height * _inputYPercent;
			
			_moveFactorX = viewport.width * _moveXPercent;
			
			_climbMinXDistance = viewport.width * .15;
		}
		
		////////////////////////////////////////////////////////////////////////
		//////////////////////////////// FLAGS /////////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		public var ignoreVelocityDirection:Boolean = false;		// if direction is changed based on velocity
		
		public var animEnded:Boolean 	= false;
		
		public var climbingUp:Boolean 	= false;	// climbing flag // TODO :: Want to phase this out

		// spinning
		private var _spinning:Boolean = false;
		public function set spinning( bool:Boolean ):void
		{
			_spinning = bool;
			spinStopped = !_spinning;
		}
		public function get spinning():Boolean { return _spinning; }
		public var spinEnd:Boolean 		= false;
		public var spinStopped:Boolean 	= false;
		public var spinCount:int 		= 0;
		public var spinSpeed:Number 	= 0;
		
		////////////////////////////////////////////////////////////////////////
		/////////////////////////// MOVEMENT VARIABLES /////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		public var headOffsetMax:Number 	= 40;
		public var petHeadOffsetMax:Number 	= 10; 		// offset for pet head
		
		// movement speeds 
		public var walkSpeed:Number 		= 10;
		public var runSpeed:Number 			= 440; 		//384;
		public var petRunSpeed:Number 		= 145;
		public var skidSpeed:Number 		= 320;
		public var swimSpeed:Number 		= 256;
		public var petSwimSpeed:Number 		= 85;
		public var diveSpeed:Number 		= 225;
		
		// defaults
		public var gravity:Number 			= MotionUtils.GRAVITY;
		public var maxVelocityX:Number 		= 800;
		public var maxVelocityY:Number 		= Number.MAX_VALUE;
		public var velocityDampen:Number 	= .6;
		public var baseAcceleration:Number 	= 850;
		public var frictionAccel:Number 	= 1000;		//20;//2.72;
		public var frictionStop:Number 		= 5000;		//30;//6;
		public var minRunVelocity:Number    = 200;   	// minimum velocity to move while running
		public var maxFallingVelocity:Number = 1000;   	// was 1200...turning this down to help with passing through movieclips
		
		// duck spin movement
		public var duckBufferY:Number 		= 50;		// distance below character feet to exceed in order to trigger ducking
		public var duckDeltaX:Number 		= 100;		// max x distance from player that will trigger duck
		public var duckRotation:Number 		= 900;		//1080;
		public var duckSpeed:Number 	 	= 140;		//120;
		public var duckFriction:Number 		= 400;
		
		// spin movement
		public var spinJumpRotation:Number 	= 6.4 * 60;
		public var spinLandRotation:Number 	= 25.6 * 60;
		public var spinSpeedAdjust : int 	= 500;
		
		// jump movement
		public var jumpVelocity:Number 			= -900;//-1000;//-900;//-850;//-845;
		public var petJumpVelocity:Number 		= -1000;
		public var jumpTargetVelocity:Number 	= 950;
		public var jumpDampener: Number 		= 1;
		public var jumpDampenerWater:Number 	= .96;		// multiplied by jump velocities
		
		// air movement
		public var maxAirVelocityX:Number 	= 500;
		public var airMultiplier:Number		= 2;
		
		// climb movement
		public var climbUpVelocity:int = -200;
		public var climbDownVelocity:int = 300;
		public var climbDampen:Number = .9;
		private var _climbMinXDistance:Number;
		public function get climbMinXDistance():Number	{ return _climbMinXDistance; }

		// water movement
		public const invincibleInterval:Number 	= 400;	// period (in milliseconds) of time character is 'invicible' after entering hurt state
		
		// water movement
		
		// target constants
		public static const MIN_DIST_POINT:int = 25;	// default minimum distance for reaching a target
		public static const MIN_DIST_ENTITY:int = 200;	// default minimum distance for reaching a entity
		
		public var scalingFactor:Number = 1;
	}
}