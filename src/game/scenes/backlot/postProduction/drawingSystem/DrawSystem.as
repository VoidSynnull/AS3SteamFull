package game.scenes.backlot.postProduction.drawingSystem
{
	import flash.geom.Point;
	
	import game.systems.GameSystem;
	
	public class DrawSystem extends GameSystem
	{
		public function DrawSystem()
		{
			super(DrawNode, updateNode);
		}
		
		public function updateNode(node:DrawNode, time:Number):void
		{
			if(node.draw.penDown)
			{
				node.draw.drawingPoint = new Point(node.spatial.x * node.draw.scale.x + -node.draw.offset.x, node.spatial.y * node.draw.scale.y + -node.draw.offset.y);
				if(!node.draw.drawing)
				{
					node.draw.canvas.graphics.moveTo(node.draw.drawingPoint.x, node.draw.drawingPoint.y);
					node.draw.canvas.graphics.lineStyle(node.draw.thickness, node.draw.color);
					node.draw.drawing = true;
				}
				node.draw.canvas.graphics.lineTo(node.draw.drawingPoint.x, node.draw.drawingPoint.y);
				if(node.draw.limits != null)
				{
					if(!node.draw.limits.contains(node.draw.drawingPoint.x, node.draw.drawingPoint.y))
					{
						node.draw.outSideLimits.dispatch(node.draw.limits, node.draw.drawingPoint);
					}
				}
			}
			else
			{
				if(node.draw.drawing)
				{
					node.draw.drawing = false;
				}
			}	
		}
	}
}