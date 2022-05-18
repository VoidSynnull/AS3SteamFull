package game.scenes.myth.sphinx.systems
{	
	import game.scenes.myth.sphinx.components.BridgeComponent;
	import game.scenes.myth.sphinx.components.WaterWayComponent;
	import game.scenes.myth.sphinx.nodes.BridgeNode;
	import game.systems.GameSystem;
	
	public class BridgeSystem extends GameSystem
	{
		public function BridgeSystem()
		{
			super( BridgeNode, updateNode );
		}
		
		private function updateNode( node:BridgeNode, time:Number ):void
		{
			var bridge:BridgeComponent = node.bridge;
			var waterWay:WaterWayComponent = bridge.pathIn;
			
			if( bridge.isDown ) 
			{
				if( waterWay.isOn )
				{
					bridge.feedsInto.isOn = true;
				}
				
				else
				{
					bridge.feedsInto.isOn = false;
				}
			}
		}
	}
}