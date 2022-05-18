package game.components.timeline
{	
	import ash.core.Component;
	
	import game.data.animation.FrameData;
	import game.data.animation.FrameEvent;
	import game.data.animation.LabelHandler;
	import game.data.animation.TimelineData;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class Timeline extends Component
	{
		public function Timeline()
		{
			data 		= new TimelineData();
			events 		= new Vector.<FrameEvent>;
			labels 		= new Array();
			
			this.labelReached = new Signal();
			this.labelHandlers = new Vector.<LabelHandler>()
		}
		
		public var labelReached:Signal;
		public var labelHandlers:Vector.<LabelHandler>;
		public function handleLabel( label:String, handler:Function, listenOnce:Boolean = true ):LabelHandler
		{
			var labelHandler:LabelHandler = new LabelHandler( label, handler, listenOnce );
			labelHandlers.push( labelHandler );
			return labelHandler;
		}
		public function removeLabelHandler( handler:Function ):void
		{
			var labelHandler:LabelHandler;
			for (var i:int = 0; i < labelHandlers.length; i++) 
			{
				labelHandler = labelHandlers[i];
				if( labelHandler.handler == handler )
				{
					labelHandlers.splice( i, 1 );
					i--;
				}
			}
		}
		
		public var data:TimelineData;  					// contains FrameData for the entire timeline
		
		public var currentFrameData:FrameData;    		// FrameData for the current frame
		public var events:Vector.<FrameEvent>;			// FrameEvents for current frame (or multiply frames if goToAnd)
		public var labels:Array;						// Array of labels for current frame (or multiply frames if goToAnd), could be Numbers or Strings
		public var currentIndex:int;					// index of timeline in reference to current animation
		public var nextIndex:int;						// next index of timeline should move to
		public function get totalFrames():int	{ return data.duration; }	// total frames in timeline, remember that index starts at 0.
		
		public var frameAdvance:Boolean = false;
		public var timeAccumulator:Number = 0; 
		public var looped:Boolean = false;			// is true if the timeline looped this frame ( gotoAndPlay or animation repeat )
		public var reverse:Boolean = false;	
		public var lock:Boolean = false;			// locks the timeline, no changes can be made until lock is false

		private var _playing:Boolean;
		public function get playing():Boolean	{ return _playing; }
		public function set playing(bool:Boolean):void
		{
			if( _playing != bool )
			{
				_playing = bool;
				if ( _playing )
				{
					_paused = false;
				}
			}
		}
		
		// Added to make it more like a movieclip - Gabriel
		public function play ():void 
		{
			playing = true;
		}
		
		private var _paused:Boolean;    // pause prevents the play head from progressing, but continues checking events & labels
		public function get paused():Boolean	{ return _paused; }
		public function set paused(bool:Boolean):void
		{
			_paused = bool;
			_playing = !_paused;
		}
		
		/**
		 * Resets timeline so that it restarts
		 */
		public function reset( startPlaying:Boolean = true ):void
		{
			currentIndex = ( startPlaying ) ? -1 : 0;
			nextIndex = 0;
			lock = false;
			this.playing = startPlaying;
		}
		
		/**
		 * Increments nextIndex by 1
		 */
		public function nextFrame():void
		{
			if( !reverse )
			{
				nextIndex++;
				if( nextIndex >= totalFrames )
				{
					nextIndex = 0;
				}
			}
			else
			{
				nextIndex--;
				if( nextIndex < 0 )
				{
					nextIndex = totalFrames - 1;
				}
			}
			this.playing = true;
		}
		
		public function gotoAndPlay( obj:* ):void
		{
			events.push( new FrameEvent( TimelineUtils.FRAME_EVENT_GOTOANDPLAY, obj ) );
		}
		
		public function gotoAndStop( obj:* ):void
		{
			events.push( new FrameEvent( TimelineUtils.FRAME_EVENT_GOTOANDSTOP, obj ) );
		}
		
		public function stop( ...args ):void
		{
			events.push( new FrameEvent( TimelineUtils.FRAME_EVENT_STOP ) );
		}
		
		public function getLabelIndex( label:String ):int
		{
			return data.getLabelIndex( label );
		}
		
		public function duplicate():Timeline
		{
			var copy:Timeline = new Timeline();
			copy.data = this.data
			return copy;
		}
	}
}
