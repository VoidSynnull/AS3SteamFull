package game.scenes.virusHunter.lungs.systems 
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.virusHunter.lungs.nodes.AirFlowNode;
	import game.util.GeomUtils;
	import game.util.Utils;

	public class AirFlowSystem extends ListIteratingSystem
	{
		public function AirFlowSystem() 
		{
			super(AirFlowNode, updateNode);
		}
		
		private function updateNode(node:AirFlowNode, time:Number):void
		{
			node.motion.velocity.x += node.airflow.x * time;
			node.motion.velocity.y += node.airflow.y * time;
			
			node.airflow.elapsedTime += time;
			if(node.airflow.elapsedTime >= node.airflow.waitTime)
			{
				node.motion.velocity.x -= node.airflow.x * time;
				node.motion.velocity.y -= node.airflow.y * time;
				
				node.airflow.elapsedTime = 0;
				node.airflow.waitTime = Utils.randNumInRange(node.airflow.minTime, node.airflow.maxTime);
				
				var radians:Number = GeomUtils.degreeToRadian(Utils.randInRange(-180, 180));
				node.airflow.x = node.airflow.acceleration * Math.cos(radians);
				node.airflow.y = node.airflow.acceleration * Math.sin(radians);
			}
		}
	}
}