package game.systems.motion
{
	import game.nodes.motion.SpatialToMouseNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	/**
	 * The Spatial To Mouse System finds the (x, y) position of the mouse in a given Display Object and
	 * positions its Spatial there. If Spatial To Mouse is locked, then other systems and updates are free
	 * to move the Entity's Spatial.
	 */
	public class SpatialToMouseSystem extends GameSystem
	{
		public function SpatialToMouseSystem()
		{
			super(SpatialToMouseNode, updateNode);
			
			this._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:SpatialToMouseNode, time:Number):void
		{
			if(node.mouse.locked) return;
			
			if(node.mouse.axis == null || node.mouse.axis == "x")
				node.spatial.x = node.mouse.container.mouseX;
			
			if(node.mouse.axis == null || node.mouse.axis == "y")
				node.spatial.y = node.mouse.container.mouseY;
		}
	}
}