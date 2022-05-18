package game.scenes.deepDive1.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.Emitter;
	import game.components.hit.Mover;
	import game.scenes.deepDive1.shared.creators.GeyserCreator;
	
	import org.flintparticles.common.counters.Steady;
	
	public class Geyser extends Component
	{
		public function Geyser(on:Boolean, onEmitter:Emitter, offEmitter:Emitter)
		{
			this.on = on;
			this.onEmitter = onEmitter;
			this.offEmitter = offEmitter;
			super();
		}
		
		public function turnOn():void{
			onEmitter.stop = false;
			onEmitter.start = true;
			offEmitter.stop = true;
			on = true;
		}
		public function turnOff():void{
			onEmitter.stop = true;
			offEmitter.stop = false;
			offEmitter.start = true;
			on = false;
		}
		public function shutOn():void{
			// restors the flow of bubbles
			onEmitter.emitter.counter = new Steady(GeyserCreator.BUBBLE_NUM_ON);
		}
		public function shutOff():void{
			// keeps emitter running (so particles don't dissappear) - but shuts off the bubbles
			onEmitter.emitter.counter = new Steady(0);
		}
		
		public var on:Boolean = true;
		public var onEmitter:Emitter;
		public var offEmitter:Emitter;
		
		public var geyserHit:Entity; // entity that holds hit component(s) and data
		public var mover:Mover; // stored mover component
	}
}