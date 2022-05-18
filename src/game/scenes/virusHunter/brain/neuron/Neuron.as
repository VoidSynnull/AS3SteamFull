package game.scenes.virusHunter.brain.neuron
{
	import com.greensock.TweenMax;
	
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.scenes.virusHunter.brain.Brain;

	public class Neuron
	{
		public function Neuron($mc:MovieClip, $brain:Brain)
		{
			display = $mc;
			//_pulseSeq.push(display["head"]);
			for(var c:int = 1; c <= 16; c++){
				_pulseSeq.push(display["ikNode_"+c]);
			}
			//_pulseSeq.push(display["foot"]);
			// create pulse sequence

		}
		
		public function pulse():void{
			pulsing = true;
			var ps:Number = 0.1 / 15; // pulse speed in seconds
			
			var pc:int = 15;
			
			var tween:TweenMax;
			
			next();
			
			function next():void{
				if(pc >= 0){
					tween = new TweenMax(_pulseSeq[pc], ps, {glowFilter:{color:0xCCFF33, alpha:1, blurX:15, blurY:15, quality:2}, colorMatrixFilter:{contrast:1.7, brightness:2}, onComplete:next});
					TweenMax.to(_pulseSeq[pc], ps*4, {glowFilter:{color:0x91e600, alpha:0, blurX:10, blurY:10, quality:2, remove:true}, colorMatrixFilter:{}, delay:ps*15});

					pc--;
				} else {
					pulseConnected();
				}
			}
		}
		
		private function pulseConnected():void{
			// test
			if(pulsing){
				pulse();
				if(connectedNeuron){
					if(!connectedNeuron.pulsing){
						connectedNeuron.pulse();
					}
				}
			}
			
			// find where "foot" is within reach of other "heads" from other neurons
		}
		
		private var _displayBMC:Object;
		
		private var _brain:Brain;
		private var _pulseSeq:Vector.<MovieClip> = new Vector.<MovieClip>; // sequence of movieClips for electrical pulse effect
		
		public var neuronReach:Entity;
		public var display:MovieClip; // container
		public var pulseSource:Boolean = false;
		public var pulsing:Boolean = false;
		public var connectedNeuron:Neuron;
	}
}