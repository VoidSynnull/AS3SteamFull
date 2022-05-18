package game.scenes.shrink.bedroomShrunk02.TelescopeSystem
{
	import game.systems.GameSystem;
	
	public class TelescopeSystem extends GameSystem
	{
		public function TelescopeSystem()
		{
			super(TelescopeNode, updateNode);
		}
		
		public function updateNode(node:TelescopeNode, time:Number):void
		{
			for(var dial:int = 0; dial < node.telescope.dials.length; dial++)
			{
				if(node.telescope.dials[dial].value > node.telescope.maxAngle)
					node.telescope.dials[dial].value = node.telescope.maxAngle;
				
				if(node.telescope.dials[dial].value < 0)
					node.telescope.dials[dial].value = 0;
				
				node.telescope.displays[dial].text = "" + Math.ceil(node.telescope.dials[dial].value);
				
				node.telescope.totalDisplayedAngle += node.telescope.dials[dial].value;
			}
			
			node.spatial.rotation = node.telescope.defaultAngle + node.telescope.totalDisplayedAngle * node.telescope.rotationScale;
			
			node.telescope.totalDisplayedAngle = 0;
		}
	}
}