package game.components.entity.character.part.eye
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Component;
	
	import game.data.character.part.eye.EyeBallData;
	import game.systems.entity.EyeSystem;
	import game.util.DataUtils;

	/**
	 * ...
	 * @author ... Bard McKinley
	 */
	public class Eyes extends Component
	{
		public function Eyes()
		{
		}

		public var _state : String = "";
		public function get state():String		{ return _state; }
		public function set state( value:String ):void	
		{
			if( !locked )
			{
				if( _state != value || _pupilsManual )
				{
					_state = value;
					_stateInvalidate = true;
				}
			}
		}
		public var locked:Boolean = false;
		public var previousState:String;	// used with blink, so previous state can be returned to
		public var permanentState:String;	// "open" & "squint" are only valid values
		public var _stateInvalidate : Boolean;
		public var requiresUpdate:Boolean;		
		public var blinkIndex:int;
		public var isBlinking:Boolean = false;
		public var targetDisplay:DisplayObject;
		
		// pupils
		public var _pupilInvalidate:Boolean;
		public var pupilAngle : Number;
		public var previousPupilState:*;
		public var pupilRadiusPercent : Number = 1;
		
		public function previousStore():void
		{
			// if previous state is not already being store, store current as previous
			if( !DataUtils.validString(previousState) )
			{
				// if _state is invalid, use permananetState
				if( !DataUtils.validString( _state )  )	
				{ 
					_state = permanentState; 
				}
				previousState = _state;
			}
			
			// if previous pupil state is not already being store, store current pupil state as previous
			if( !DataUtils.validString(previousPupilState) )
			{
				previousPupilState = ( _pupilsManual ) ? _pupilState : "";
			}
		}
		
		public function previousApply():void
		{
			this.state = previousState;
			previousState = null;
			if( DataUtils.validString( previousPupilState ) )
			{
				this.pupilState = previousPupilState;
				previousPupilState = null;
			}
		}
		
		private var _pupilState:*;
		public function get pupilState():*		{ return _pupilState; }
		/**
		 * Can pass a descriptive string or an angle
		 * @param stateOrAngle - a descriptive string (accessible vie EyeSystem) or an angle
		 */
		public function set pupilState( stateOrAngle:* ):void
		{
			if( !locked )
			{
				_pupilState = stateOrAngle;
				_pupilInvalidate = true;
				
//				if( _pupilState != stateOrAngle )
//				{
//					_pupilState = stateOrAngle;
//					_pupilInvalidate = true;
//				}
//				else if ( _pupilsFollow || !_pupilsManual )
//				{
//					_pupilInvalidate = true;
//				}
			}
		}
		
		private var _pupilsFollow : Boolean;		// if pupils are following 
		public function get pupilsFollow():Boolean		{ return _pupilsFollow; }
		public function set pupilsFollow( bool:Boolean ):void		
		{ 
			_pupilsFollow = bool;
			if( _pupilsFollow )	{ _pupilsManual = false; }
		}
		
		private var _pupilsManual : Boolean;	// flag to track is pupil has been set
		public function get pupilsManual():Boolean		{ return _pupilsManual; }
		public function set pupilsManual( bool:Boolean ):void		
		{ 
			_pupilsManual = bool;
			if( _pupilsManual )	{ _pupilsFollow = false; }
		}

		// lashes
		public var _lashInvalidate : Boolean;	// for use with system only
		public var _lashState : String;
		public function get lashState():String		{ return _lashState; }
		public function set lashState( value:String ):void		
		{ 
			if( hasLashes )
			{
				if( value != _lashState )
				{
					_lashState = value;
					if( value == EyeSystem.OFF )
					{
						_lashes.visible = false;
						_lashes.stop();
						_lashInvalidate = false;
					}
					else
					{
						_lashInvalidate = true;
					}
				}
			}
		}
		public var _hasLashes:Boolean;
		public function get hasLashes():Boolean		{ return _hasLashes; }
		public function set hasLashes( bool:Boolean ):void	
		{
			_hasLashes = bool;
			if( _lashes )
			{
				_lashes.visible = bool;
			}
		}
		public var isLashFollow : Boolean;
		
		// lids
		public var isLidFollow : Boolean;
		public var lidPercent : Number;
		public var _lidLineInvalidate : Boolean;	// for use with system only
		public var _lidLineState : String;
		public function get lidLineState():String		{ return _lidLineState; }
		public function set lidLineState( value:String ):void		
		{
			if( value != _lidLineState )
			{
				_lidLineState = value;
				if( value == EyeSystem.OFF )
				{
					if (_lidLine != null)
					{
						_lidLine.visible = false;
						_lidLine.stop();
					}
					_lidLineInvalidate = false;
				}
				else
				{
					_lidLineInvalidate = true;
				}
			}
			else
			{
				if( value != EyeSystem.OFF )
				{
					if ((_lidLine != null) && ( !_lidLine.visible ))
					{
						_lidLine.visible = true;
					}
				}
			}
		}
		
		public var _lidFillInvalidate : Boolean;	// for use with system only
		public var _lidFillState : String;
		public function get lidFillState():String		{ return _lidFillState; }
		public function set lidFillState( value:String ):void		
		{ 
			if( value != _lidFillState )
			{
				_lidFillState = value;
				if( value == EyeSystem.OFF )
				{
					_lids.visible = false;
					_lidFillInvalidate = false;
				}
				else
				{
					_lidFillInvalidate = true;
				}
			}
		}
	
		
		// blinking
		public var canBlink : Boolean;
		public var blinkSequence : Vector.<Number> = new <Number>[ 75, 100, 100, 100, 80 ];
		public var blinkChance:int = 500;

		//parts
		private var _outline:MovieClip;
		public function get outline():MovieClip			{ return _outline; }
		
		private var _lids:MovieClip;
		public function get lids():MovieClip			{ return _lids; }
		
		private var _lidLine:MovieClip;
		public function get lidLine():MovieClip			{ return _lidLine; }

		private var _lidFill:MovieClip;
		public function get lidFill():MovieClip			{ return _lidFill; }
		
		private var _lidFillLine:MovieClip;
		public function get lidFillLine():MovieClip		{ return _lidFillLine; }
		
		private var _lashes:MovieClip;
		public function get lashes():MovieClip			{ return _lashes; }

		private var _eye1:EyeBallData;
		public function get eye1():EyeBallData			{ return _eye1; }
		
		private var _eye2:EyeBallData;
		public function get eye2():EyeBallData			{ return _eye2; }

		private var _isPet:Boolean = false;
		public function get isPet():Boolean				{ return _isPet; }

		public function applyDisplay( displayObject:DisplayObjectContainer ):void
		{
			if( displayObject )
			{
				var content:MovieClip = MovieClip(displayObject).getChildAt(0) as MovieClip;
				if( content )
				{
					_outline 		= MovieClip(content.outline);
					_lids 			= MovieClip(content.lids);
					_lidFill 		= MovieClip(_lids.lidFill);
					_lidFillLine 	= MovieClip(_lids.lidLine);
					_lidLine 		= MovieClip(content.lidLineStatic);
					_lashes 		= MovieClip(content.lashes);
					//set these as precaution
					_lidFill.gotoAndStop(EyeSystem.STANDARD);
					_lidFillLine.gotoAndStop(EyeSystem.STANDARD);
					
					// pets have no lid line
					if (_lidLine != null)
					{
						_lidLine.stop();
						_lidLine.visible = false;
					}
					else
					{
						_isPet = true;
					}
					
					if (_lashes != null)
					{
						_lashes.gotoAndStop(EyeSystem.STANDARD);
					}
					
					_eye1 		= new EyeBallData(MovieClip(content.eye1));
					_eye2 		= new EyeBallData(MovieClip(content.eye2));
					
					requiresUpdate = true;
				}
			}
		}
	}
}