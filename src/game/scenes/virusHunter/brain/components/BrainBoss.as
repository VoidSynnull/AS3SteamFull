package game.scenes.virusHunter.brain.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.scenes.virusHunter.brain.neuron.Neuron;
	
	public class BrainBoss extends Component
	{
		public function BrainBoss($startNeuron:Neuron, $landingNeurons:Vector.<Neuron>, $spawnPoint:Entity):void{
			onNeuron = $startNeuron;
			landingNeurons = $landingNeurons;
			spawnPoint = $spawnPoint;
		}
		
		public var active:Boolean = false;
		
		public var onNeuron:Neuron;
		public var landIndex:int = 0;
		public var landingNeurons:Vector.<Neuron>;
		public var shocked:Boolean = false;
		public var spawnPoint:Entity;
		
		public var tentacleReachBatch:Vector.<Entity> = new Vector.<Entity>;
		
		public var rightTentacle:Entity;
		public var leftTentacle:Entity;
	}
}