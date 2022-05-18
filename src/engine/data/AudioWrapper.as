package engine.data
{
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.Dictionary;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;

	public class AudioWrapper
	{
		//public var next:Vector.<String>;
		public var sound:Sound;
		public var url:String;
		public var event:String;
		public var loop:Boolean;
		public var channel:SoundChannel;
		public var transform:SoundTransform;
		public var fadeTarget:Number;
		public var fadeStep:Number;
		public var volumeModifiers:Dictionary;
		public var overrideVolume:Number;
		
		public var playbackComplete:Boolean = false;
		public var playbackCompleted:NativeSignal;
		public var complete:Signal;
		
		public function AudioWrapper()
		{
			complete = new Signal();
		}
		
		public function handlePlaybackComplete(event:Event):void
		{ 
			this.playbackComplete = true;
			complete.dispatch();
		}
	}
}