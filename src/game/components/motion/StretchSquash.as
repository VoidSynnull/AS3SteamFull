package game.components.motion
{
	import ash.core.Component;
	
	import fl.motion.easing.Quadratic;
	
	import org.osflash.signals.Signal;

	public class StretchSquash extends Component
	{
		public function StretchSquash( scalePercent:Number = .5, duration:Number = 1, axis:String = "y", anchorEdge:String = "bottom" )
		{
			this.scalePercent = scalePercent;
			this.axis = axis;
			this.duration = duration;
			this.anchorEdge = anchorEdge;
			this.complete = new Signal();
		}
		
		public var scalePercent:Number 	= .5;	// max change in value, what percentage of the total value will be reached 
		public var duration:Number 		= 1;	// duration of start tansition in seconds;
		public var inverseRate:Number 	= 1;	// inverse between morph dimensions, default is 1:1
		public var transition:Function 	= Quadratic.easeIn;
		public var complete:Signal;
		
		public var _morphing:Boolean 	= false;
		private var _active:Boolean = false;
		public function get active():Boolean	{ return _active; }
		
		private var _axis:String;
		public function get axis():String	{ return _axis; }
		public function set axis( x_or_y:String ):void
		{
			x_or_y = x_or_y.toLocaleLowerCase();
			if ( x_or_y == "x" || x_or_y == "y" )
			{
				_axis = x_or_y	
			}
			else
			{
				trace( "Error :: StretchSquash :: valid axis values are x or y : " + x_or_y +  " is invalid." );
			}	
		}

		public function squash( axis:String = "y" ):void
		{
			_active = true;
			_state = SQUASH;
			this.axis = axis;
		}
		
		public function stretch( axis:String = "y" ):void
		{
			_active = true;
			_state = STRETCH;
			this.axis = axis;
		}
		
		public function original( axis:String = "y" ):void
		{
			_active = true;
			_state = ORIGINAL;
			this.axis = axis;
		}
		
		private var _state:String;
		public function get state():String	{ return _state; }
		
		public const SQUASH:String 		= "squash";
		public const STRETCH:String 	= "stretch";
		public const ORIGINAL:String 	= "original";
		
		public function stateComplete():void
		{
			_morphing = false;
			_active = false;
			complete.dispatch();
		}
		
		public var anchorEdge:String = "";	// anchor point for morph, registration by default unless set
		
		public const ANCHOR_LEFT:String 	= "left";
		public const ANCHOR_RIGHT:String 	= "left";
		public const ANCHOR_TOP:String 		= "top";
		public const ANCHOR_BOTTOM:String 	= "bottom";
		public const ANCHOR_CENTER:String 	= "center";
		
	}
}