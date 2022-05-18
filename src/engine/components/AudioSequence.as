package engine.components
{
	import engine.data.AudioWrapper;
	
	import org.osflash.signals.Signal;
	import ash.core.Component;

	public class AudioSequence extends Component
	{
		public function AudioSequence(sequence:Array = null)
		{
			if(sequence != null)
			{
				this.sequence = sequence;
			}
			else
			{
				this.sequence = new Array();
			}
			
			this.playbackComplete = new Signal();
		}
		
		public var sequence:Array;
		public var playing:AudioWrapper;
		public var play:Boolean = false;
		public var loop:Boolean = false;
		public var playbackComplete:Signal;
		
		// used by the AudioSequenceSystem to track playback of sequence.
		public var _index:int = 0;
		public var _stopped:Boolean = false;
	}
}