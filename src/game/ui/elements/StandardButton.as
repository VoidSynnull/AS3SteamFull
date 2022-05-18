package game.ui.elements 
{
	import flash.display.MovieClip;
	import flash.events.Event;

	public class StandardButton extends BasicButton 
	{
		public function StandardButton()
		{
		}
		
		public var label:String;
		
		
		public function setPosition( x:int, y:int ):void
		{
			super.displayObject.x = x;
			super.displayObject.y = y;
		}
		
		protected var _state:String;
		public function get state():String 	{ return _state; }
		public function set state( state:String ):void
		{
			_state = state;
			MovieClip(super.displayObject).gotoAndStop(_state);
			
		}
		
		public function overHandler(e:Event):void
		{
			if ( _state != DOWN )	// prevents Over from overriding Down
			{
				state = OVER;
			}
		}
		
		public function downHandler(e:Event):void
		{
			state = DOWN;
		}
		
		public function upHandler(e:Event):void
		{
			state = UP;
		}
		
		public function outHandler(e:Event):void
		{
			state = UP;
		}

		public function clickHandler(e:Event):void 
		{
			
		}
		
		public static const UP:String 	= "up";
		public static const OVER:String = "over";
		public static const DOWN:String = "down";
	}
}