package game.scenes.virusHunter.lungs.systems 
{
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.lungs.components.BossState;
	import game.scenes.virusHunter.lungs.nodes.BossBodyNode;
	import game.util.GeomUtils;
	import game.util.Utils;

	public class BossBodySystem extends ListIteratingSystem
	{
		public function BossBodySystem() 
		{
			super(BossBodyNode, updateNode);
		}
		
		private function updateNode(node:BossBodyNode, time:Number):void
		{
			switch(node.state.state)
			{
				case BossState.INTRO_STATE:
					intro(node, time);
				break;
				
				case BossState.ATTACK_MOVE_STATE:
				case BossState.ATTACK_STATE:
					attack(node);
				break;
				
				default:
					idle(node, time);
				break;
			}
		}
		
		private function attack(node:BossBodyNode):void
		{
			var boss:Spatial = node.body.boss.get(Spatial);
			node.motion.rotationMaxVelocity = 30;
		
			var degrees:Number = GeomUtils.degreesBetween(boss.x, boss.y, node.state.target.x, node.state.target.y);
			for(var i:uint = 0; i < node.state.currentIndex; i++)
			{
				degrees -= 90;
				if(degrees < -180) degrees = 180 + (degrees + 180);
			}
			
			if(node.spatial.rotation > degrees) node.motion.rotationAcceleration = -30;
			else if(node.spatial.rotation < degrees) node.motion.rotationAcceleration = 30;
		}
		
		private function intro(node:BossBodyNode, time):void
		{
			node.body.elapsedTime += time;
			if(node.body.elapsedTime >= node.body.waitTime)
			{
				node.body.elapsedTime = 0;
				node.body.waitTime = Utils.randNumInRange(5, 10);
				
				var motion:Motion = node.entity.get(Motion);
				motion.rotationMaxVelocity = 30;
				if(motion.rotationVelocity > 0)
					motion.rotationAcceleration = -30;
				else motion.rotationAcceleration = 30;
			}
		}
		
		private function idle(node:BossBodyNode, time):void
		{
			node.body.elapsedTime += time;
			if(node.body.elapsedTime >= node.body.waitTime)
			{
				node.body.elapsedTime = 0;
				node.body.waitTime = Utils.randNumInRange(5, 10);
				
				var motion:Motion = node.entity.get(Motion);
				motion.rotationMaxVelocity = 100;
				if(motion.rotationVelocity > 0)
					motion.rotationAcceleration = -100;
				else motion.rotationAcceleration = 100;
			}
		}
	}
}