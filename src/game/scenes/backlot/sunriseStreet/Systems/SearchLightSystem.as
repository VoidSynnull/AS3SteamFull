package game.scenes.backlot.sunriseStreet.Systems
{
	import game.scenes.backlot.sunriseStreet.components.SearchLight;
	import game.scenes.backlot.sunriseStreet.nodes.SearchLightNode;
	import game.systems.GameSystem;
	
	public class SearchLightSystem extends GameSystem
	{
		override public function SearchLightSystem():void
		{
			super(SearchLightNode, updateNode);
		}
		
		private function updateNode(node:SearchLightNode, time:Number):void
		{
			if(node.light.rotation > node.light.limits.y && !node.light.rotateClockWise)
			{
				node.light.rotateClockWise = true;
				rotate(node.light);
			}
			
			if(node.light.rotation < node.light.limits.x && node.light.rotateClockWise)
			{
				node.light.rotateClockWise = false;
				rotate(node.light);
			}
			
			rotate(node.light);
			
			node.spatial.rotation = node.light.rotation * 180 / Math.PI + 180;
		}
		
		private function rotate(light:SearchLight):void
		{
			if(light.rotateClockWise)
				light.rotation -= light.speed;
			else
				light.rotation += light.speed;
		}
	}
}