package game.scenes.mocktropica.shared.systems
{
	import game.scenes.mocktropica.shared.components.CreateRandomAdComponent;
	import game.scenes.mocktropica.shared.nodes.CreateRandomAdNode;
	import game.systems.GameSystem;
	
	public class CreateRandomAdSystem extends GameSystem
	{
		public function CreateRandomAdSystem()
		{
			super( CreateRandomAdNode, updateNode );
		}
		
		private function updateNode( node:CreateRandomAdNode, time:Number ):void
		{
			var random:CreateRandomAdComponent = node.randomAd;
			
			if(( Math.abs( node.spatial.x - random.lastX ) < MOTION_RANGE ) && ( Math.abs( node.spatial.y - random.lastY ) < MOTION_RANGE ))
			{
				random.timeSinceMovement ++;
				if( random.timeSinceMovement > COUNT_DOWN && random.count < random.max )
				{
					random.timeSinceMovement = 0;
					random.adSystem.createRandomAds();
				}
			}
			
			else
			{
				random.timeSinceMovement = 0;
				random.lastX = node.spatial.x;
				random.lastY = node.spatial.y;
			}
		}
		
		private var MOTION_RANGE:Number = 200;
		private var COUNT_DOWN:Number = 1000;
	}
}