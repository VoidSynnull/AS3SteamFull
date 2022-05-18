package game.scenes.shrink.shared.Systems.PopupCamera
{
	import engine.components.Spatial;
	
	import game.systems.GameSystem;
	
	public class PopupCameraSystem extends GameSystem
	{
		public function PopupCameraSystem()
		{
			super(PopupCameraNode, updateNode);
		}
		
		public function updateNode(node:PopupCameraNode, time:Number):void
		{
			node.spatial.x = -node.camera.focus.x * node.camera.zoom + node.camera.center.x;
			node.spatial.y = -node.camera.focus.y * node.camera.zoom + node.camera.center.y;
			
			// camera is negative of what you want to see on screen
			
			if(node.spatial.x < -node.camera.bounds.right)
				node.spatial.x = -node.camera.bounds.right;
			
			if(node.spatial.x > -node.camera.bounds.left)
				node.spatial.x = -node.camera.bounds.left;
			
			if(node.spatial.y < -node.camera.bounds.bottom)
				node.spatial.y = -node.camera.bounds.bottom;
			
			if(node.spatial.y > -node.camera.bounds.top)
				node.spatial.y = -node.camera.bounds.top;
			
			for(var i:int = 0; i < node.camera.layers.length; i ++)
			{
				var layer:Spatial = node.camera.layers[i];
				layer.x = node.spatial.x * node.spatial.scaleX;
				layer.y = node.spatial.y * node.spatial.scaleY;
			}
		}
	}
}