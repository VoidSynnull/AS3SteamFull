package game.components.input
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.creators.InteractionCreator;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	public class Input extends Component
	{
		public var inputActive:Boolean = false;    // whether control input is active (Mouse or touch)
		public var target:Point = new Point(0, 0); // current position of target.
		public var lockPosition:Boolean = false;
		public var lockInput:Boolean = false;
		public var offscreen:Boolean = false;
		
		public var inputDown:Signal;
		public var inputUp:Signal;
		
		public var inputStateChange:Boolean = false;
		public var inputStateDown:Boolean = false;
		
		private var _inputDown:NativeSignal;
		private var _inputUp:NativeSignal;
		private var _inputOut:NativeSignal;
		private var _container:DisplayObjectContainer;
		
		public function get container():DisplayObjectContainer { return(_container); }
		public function set container(container:DisplayObjectContainer):void { _container = container; }
		
		public function addInput(container:DisplayObjectContainer):void
		{
			_container = container;
			
			_inputDown = InteractionCreator.create(container, InteractionCreator.DOWN);
			_inputDown.add(handleInputDown);
			_inputUp = InteractionCreator.create(container, InteractionCreator.UP);
			_inputUp.add(handleInputUp);
			_inputOut = InteractionCreator.create(container, InteractionCreator.RELEASE_OUT);
			_inputOut.add(handleInputUp);
			
			inputDown = new Signal();
			inputUp = new Signal();
		}
		
		public function removeAllSignals():void
		{
			_inputDown.removeAll();
			_inputUp.removeAll();
			_inputOut.removeAll();
			inputDown.removeAll();
			inputUp.removeAll();
		}
		
		public function handleInputDown(event:Event):void
		{
			updateInputState(true);
		}
		
		public function handleInputUp(event:Event):void
		{
			updateInputState(false);
		}	
		
		private function updateInputState(isDown:Boolean):void
		{
			this.inputStateDown = isDown;
			this.inputStateChange = true;
		}
	}
}
