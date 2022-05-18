package game.data.animation
{	
	// A standard timeline event like stop, play, gotoAndStop, or gotoAndPlay
	public class FrameEvent
	{
		public var type:String;
		public var args:Array;
		
		public function FrameEvent( type:String = null, ...args )
		{
			if ( type != null )
			{
				this.type = type;
				if ( args.length > 0 )
				{
					this.args = args;
				}
			}
		}
		
		public function addArg( arg:* ):void
		{
			if ( !args )
			{
				args = new Array();
			}
			args.push( arg );
		}
	}
}
