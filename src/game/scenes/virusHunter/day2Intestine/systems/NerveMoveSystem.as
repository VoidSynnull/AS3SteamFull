package game.scenes.virusHunter.day2Intestine.systems 
{
	import ash.tools.ListIteratingSystem;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.day2Intestine.components.NerveMove;
	import game.scenes.virusHunter.day2Intestine.nodes.NerveMoveNode;
	import game.util.Utils;

	public class NerveMoveSystem extends ListIteratingSystem
	{
		public function NerveMoveSystem() 
		{
			super(NerveMoveNode, updateNode);
		}
		
		private function updateNode(node:NerveMoveNode, time:Number ):void
		{
			if(node.entity.get(Sleep).sleeping) return;
			
			switch(node.nerveMove.state)
			{
				case NerveMove.IDLE_STATE:
					updateState(node, time, NerveMove.MOVE_STATE, 1, 2);
				break;
				
				case NerveMove.MOVE_STATE:
					moveNerve(node, time, 80);
					updateState(node, time, NerveMove.IDLE_STATE, 3, 6);
				break;
				
				case NerveMove.SHOCK_STATE:
					moveNerve(node, time, 140);
					updateState(node, time, NerveMove.IDLE_STATE, 3, 6);
				break;
			}
		}
		
		private function updateState(node:NerveMoveNode, time:Number, nextState:String, min:Number, max:Number):void
		{
			node.nerveMove.elapsedTime += time;
			if(node.nerveMove.elapsedTime >= node.nerveMove.waitTime)
			{
				node.nerveMove.elapsedTime = 0;
				node.nerveMove.waitTime = Utils.randNumInRange(min, max);
				node.nerveMove.state = nextState;
			}
		}
		
		private function moveNerve(node:NerveMoveNode, time:Number, speed:Number):void
		{
			if(node.nerveMove.direction == true)
			{
				node.spatial.rotation += speed * time;
				if(node.spatial.rotation > NerveMove.MAX_ANGLE)
				{
					node.spatial.rotation = NerveMove.MAX_ANGLE;
					node.nerveMove.direction = false;
				}
			}
			else
			{
				node.spatial.rotation -= speed * time;
				if(node.spatial.rotation < -NerveMove.MAX_ANGLE)
				{
					node.spatial.rotation = -NerveMove.MAX_ANGLE;
					node.nerveMove.direction = true;
				}
			}
		}
	}
}