package game.components.motion
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.util.CharUtils;
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;
	
	public class Destination extends Component
	{
		public function Destination()
		{
		}

		private var _active:Boolean = false;		// if attempt to reach destination should be interrupted
		public function get active():Boolean	{ return _active; }
		public function set active(value:Boolean):void
		{
			if( value )	{ _activated = true; }
			_active = value;
		}
		public var _activated:Boolean = false;	
		public var lockControl:Boolean = false;
		public var nextReachAsFinal:Boolean = false;	// if first reach can be treated as the final reach (generally used in conjunction with follow target)
		public var removeOnReset:Boolean = false;		// if true Destination component will be removed on final reached or interrupted.
		private var _interrupt:Boolean = false;			// if attempt to reach destination should be interrupted
		public function get interrupt():Boolean	{ return _interrupt; }
		public function set interrupt(value:Boolean):void { _interrupt = value; }
		public var ignorePlatformTarget:Boolean = false	// if platforms should be ignored while trying to reach destination

		public var onFinalReached:Signal = new Signal( Entity );	// dispatched when final destination is reached
		public var onInterrupted:Signal = new Signal( Entity );		// dispatched when interrupted

		public static const USE_PATH:String = "path";
		public static const USE_TARGET:String = "target";
		private var _useType:String = "";		// if attempt to reach destination should be interrupted
		public function get useType():String	{ return _useType; }
		public function set useType(value:String):void
		{
			if ( value == USE_PATH || value == USE_TARGET )
			{
				if( _useType != value && active )	{ _activated = true; } 	// re-activate if use type has changed and currently active
				_useType = value;
			}
			else
			{
				_useType = "";
			}
		}

		//////////////// CONDITIONS TO REACH ////////////////
		
		// requirements for successfully reaching destination
		//public var minTargetDelta:Point;	// TODO :: may want better controls than just a point
		public var validCharStates:Vector.<String> = new Vector.<String>();	// list of valid char states
		
		//////////////// CONDITIONS ON REACHED ////////////////
		
		public var motionToZero:Vector.<String> = new Vector.<String>();

		//////////////// DIRECTION ON REACHED ////////////////
		
		// manage direction of owning entiy while moving towards destination and/or upon reach it.
		// can only be one or the other, not both
		public var checkDirection:Boolean = false;	// if direction should be checked upon reaching destination
		private var _directionFace:String = "";		// direction to face when target is reached
		public function get directionFace():String 	{ return _directionFace; }
		private var _directionTarget:Point;			// point to face when target is reached
		public function get directionTarget():Point { return _directionTarget; }

		public function setDirectionOnReached( faceDirection:String = "", faceX:Number = NaN, faceY:Number = NaN ):void
		{
			this.checkDirection = true;
			if ( !isNaN(faceX) || !isNaN(faceY) )
			{
				_directionFace = ""; 			// turn of string driven direction
				_directionTarget = new Point();
				if ( !isNaN(faceX) ) 	{ _directionTarget.x = faceX; }
				if ( !isNaN(faceY) ) 	{ _directionTarget.y = faceY; }
			} 
			else if ( DataUtils.validString( faceDirection ) )
			{
				if ( faceDirection == CharUtils.DIRECTION_LEFT || faceDirection == CharUtils.DIRECTION_RIGHT )
				{
					_directionTarget = null;	// turn off point driven direction
					_directionFace = faceDirection;
				}
				else
				{
					_directionFace = "";
				}
			}
		}
		
		public function resetDirection():void
		{
			checkDirection = false;
			_directionFace = "";
			_directionTarget = null;
		}
	}
}