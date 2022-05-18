package game.scenes.survival3.shared.systems
{
	import game.scenes.survival3.shared.nodes.ClimbingZoomNode;
	import game.systems.GameSystem;
	
	public class ClimbingZoomSystem extends GameSystem
	{
		public function ClimbingZoomSystem()
		{
			super(ClimbingZoomNode, updateNode);
			super.fixedTimestep = .5;
		}
		
		public function updateNode(node:ClimbingZoomNode, time:Number):void
		{
			if(node.signal.signalStrength < node.zoom.startZoomPercent)
			{
				node.zoom.camera.scaleTarget = node.zoom.defaultZoom;
				return;
			}
			node.zoom.camera.scaleTarget = node.zoom.defaultZoom - node.zoom.differernce * node.signal.signalStrength + node.zoom.startZoomPercent;
		}
	}
}