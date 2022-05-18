package game.components.entity.character
{
	import ash.core.Component;

	public class Talk extends Component
	{
		public function Talk()
		{
		}
		
		public var _active:Boolean;
		
		private var _isStart:Boolean;
		public function get isStart():Boolean	{ return _isStart; }
		public function set isStart(value:Boolean):void
		{ 
			_isStart = value;
			if( _isStart )
			{
				_active = true;
				_isEnd = false;
			}
		}
		private var _isEnd:Boolean;
		public function get isEnd():Boolean	{ return _isEnd; }
		public function set isEnd(value:Boolean):void
		{ 
			_isEnd = value;
			if( _isEnd )
			{
				_active = true;
				_isStart = false;
			}
		}
		
		public var adjustEyes:Boolean = true;
		public var instances:Vector.<String> = new Vector.<String>();
		
		// RIG DRIVEN
		/** For use with rig character : Id of mouth part that corresponds to talking, default is "talk", but this can be overwritten */
		public var talkPart:String = "talk";
		
		// MOVIECLIP DRIVEN
		/** For use with movieclip character : Label in movieclip that corresponds to talking, default is "talk", but this can be overwritten */
		public var talkLabel:String = "talk";
		/** For use with movieclip character : Label in movieclip to return to when talking has ceased */
		public var mouthDefaultLabel:String = "idle";

	}
}