package game.components.audio
{
	import flash.events.ActivityEvent;
	import flash.media.Microphone;
	import flash.media.SoundTransform;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Mic extends Component
	{
		/**
		 * Gets invalidated by microphone ActivityEvents. Handled by MicSystem.
		 * In most cases, should be left alone.
		 */
		public var invalidate:Boolean = false;
		
		/**
		 * Gets invalidated by microphone ActivityEvents. Handled by MicSystem.
		 * In most cases, should be left alone.
		 */
		public var isActive:Boolean = false;
		
		/**
		 * Microphone instance of the default microphone being used.
		 */
		public var microphone:Microphone = Microphone.getMicrophone();
		
		/**
		 * Signal dispatched when the microphone becomes active. Dispatches Entity associsted with
		 * the Mic component.
		 */
		public var active:Signal = new Signal(Entity);
		
		/**
		 * Signal dispatched when the microphone becomes inactive. Dispatches Entity associated with
		 * the Mic component.
		 */
		public var inactive:Signal = new Signal(Entity);
		
		public function Mic()
		{
			//The microphone won't listen to or dispatch events if setLoopBack = false.
			this.microphone.setLoopBack(true);
			
			//We're only listening for audio, so we shouldn't be playing it back. Set volume = 0.
			this.microphone.soundTransform = new SoundTransform(0);
			
			this.microphone.addEventListener(ActivityEvent.ACTIVITY, this.onActivity);
		}
		
		override public function destroy():void
		{
			//Reset the microphone before getting rid of this reference.
			this.microphone.setLoopBack(false);
			this.microphone.soundTransform = new SoundTransform(1);
			
			this.active.removeAll();
			this.inactive.removeAll();
			
			super.destroy();
		}
		
		private function onActivity(event:ActivityEvent):void
		{
			this.isActive 	= event.activating;
			this.invalidate = true;	
		}
	}
}