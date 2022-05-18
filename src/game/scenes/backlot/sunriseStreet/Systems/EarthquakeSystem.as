package game.scenes.backlot.sunriseStreet.Systems
{
	import game.scenes.backlot.sunriseStreet.nodes.EarthquakeNode;
	import game.systems.GameSystem;
	public class EarthquakeSystem extends GameSystem
	{
		override public function EarthquakeSystem():void
		{
			super( EarthquakeNode, updateNode );
		}
		
		private function updateNode(node:EarthquakeNode, time:Number):void
		{
			node.earthquake.shakeTime += node.earthquake.shakeSpeed * time;
			node.spatial.x = node.earthquake.origin.x + node.earthquake.range.x * Math.sin(node.earthquake.shakeTime) * Math.random() * node.earthquake.severity;
			node.spatial.y = node.earthquake.origin.y + node.earthquake.range.y * Math.sin(node.earthquake.shakeTime) * Math.random() * node.earthquake.severity;
			 
			if(node.earthquake.offset != null)
			{
				node.spatial.x += node.earthquake.offset.x;
				node.spatial.y += node.earthquake.offset.y;
			}
		}
	}
}