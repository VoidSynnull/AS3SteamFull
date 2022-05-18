package game.scenes.virusHunter.day2Heart.systems 
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.virusHunter.day2Heart.components.WormBoss;
	import game.scenes.virusHunter.day2Heart.nodes.WormBodyNode;
	import game.util.Utils;

	public class WormBodySystem extends ListIteratingSystem
	{
		public function WormBodySystem() 
		{
			super(WormBodyNode, updateNode);
		}
		
		private function updateNode(node:WormBodyNode, time:Number):void
		{
			if(node.sleep.sleeping) return;
			
			switch(node.body.wormBoss.state)
			{
				case WormBoss.MOVE_STATE:
				case WormBoss.ANGRY_STATE:
				case WormBoss.DEATH_STATE:
					node.body.elapsedTime += time;
					if(node.body.elapsedTime >= node.body.waitTime)
					{
						node.body.elapsedTime = 0;
						node.body.waitTime = Utils.randNumInRange(5, 10);
						
						if(node.motion.rotationVelocity > 0)
							node.motion.rotationAcceleration = -50;
						else node.motion.rotationAcceleration = 50;
					}
				break;
			}
			
		}
	}
}