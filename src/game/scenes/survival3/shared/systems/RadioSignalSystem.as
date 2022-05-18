package game.scenes.survival3.shared.systems
{
	import game.scenes.survival3.shared.nodes.RadioSignalNode;
	import game.systems.GameSystem;
	
	public class RadioSignalSystem extends GameSystem
	{
		public function RadioSignalSystem()
		{
			super(RadioSignalNode, updateNode);
		}
		
		public function updateNode(node:RadioSignalNode, time:Number):void
		{
			node.radioSignal.height = node.radioSignal.groundLevel - node.spatial.y;
			
			node.radioSignal.signalStrength = node.radioSignal.height / node.radioSignal.maxSignalHeight;
			
			node.radioSignal.hasGoodSignal = node.radioSignal.signalStrength > node.radioSignal.minSignalStrength;
		}
	}
}