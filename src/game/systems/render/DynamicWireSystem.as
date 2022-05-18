package game.systems.render
{
	import flash.geom.Point;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.render.DynamicWireNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	import game.util.PointUtils;

	public class DynamicWireSystem extends GameSystem
	{
		public function DynamicWireSystem()
		{
			super(DynamicWireNode, updateNode, addedNode, removeNode);
			//super.fixedTimestep = FixedTimestep.MOTION_TIME;
			//super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.checkCollisions;
		}
		
		private function addedNode(node:DynamicWireNode):void
		{
			node.display.container.addChild(node.wire.wireSprite);
			DisplayUtils.moveToOverUnder(node.wire.wireSprite, node.display.displayObject, false);
		}
		
		private function removeNode(node:DynamicWireNode):void
		{
			node.display.container.removeChild(node.wire.wireSprite);
		}
		
		private function updateNode(node:DynamicWireNode, time:Number):void
		{
			if(node.wire.active)
			{
				node.wire.startPoint.x = node.spatial.x;
				node.wire.startPoint.y = node.spatial.y;
				
				node.wire.endPoint.x = node.target.target.x;
				node.wire.endPoint.y = node.target.target.y;
				
				if(node.target.addition)
				{
					node.wire.endPoint.x += node.target.addition.x;
					node.wire.endPoint.y += node.target.addition.y;
				}
				
				if(node.wire.startPoint.x == node.wire.previousStart.x && node.wire.startPoint.y == node.wire.previousStart.y
					&& node.wire.endPoint.x == node.wire.previousEnd.x && node.wire.endPoint.y == node.wire.previousEnd.y)
				{
					return;
				}
				
				node.wire.previousEnd = new Point(node.wire.endPoint.x, node.wire.endPoint.y);
				node.wire.previousStart = new Point(node.wire.startPoint.x, node.wire.startPoint.y);
				
				var sag:Number = Math.max(0, (node.wire.wireLength - Point.distance(node.wire.startPoint, node.wire.endPoint))) + node.wire.droop;
				
				var midPoint:Point = node.wire.startPoint.add(node.wire.endPoint);
				midPoint = PointUtils.times(midPoint, .5);
				midPoint.y += sag;
				
				//node.wire.startPoint = DisplayUtils.localToLocalPoint(node.wire.startPoint, node.display.displayObject.parent, node.display.displayObject);
				//node.wire.endPoint = DisplayUtils.localToLocalPoint(node.wire.endPoint, node.display.displayObject.parent, node.display.displayObject);
				//midPoint = DisplayUtils.localToLocalPoint(midPoint, node.display.displayObject.parent, node.display.displayObject);
								
				node.wire.wireSprite.graphics.clear();
				if(node.wire.outlineColor != node.wire.wireColor && node.wire.outlineThickness > 0)
				{
					node.wire.wireSprite.graphics.lineStyle(node.wire.outlineThickness, node.wire.outlineColor);
					node.wire.wireSprite.graphics.moveTo(node.wire.startPoint.x, node.wire.startPoint.y);
					node.wire.wireSprite.graphics.curveTo(midPoint.x, midPoint.y, node.wire.endPoint.x, node.wire.endPoint.y);
				}
				node.wire.wireSprite.graphics.lineStyle(node.wire.wireThickness, node.wire.wireColor);
				node.wire.wireSprite.graphics.moveTo(node.wire.startPoint.x, node.wire.startPoint.y);
				node.wire.wireSprite.graphics.curveTo(midPoint.x, midPoint.y, node.wire.endPoint.x, node.wire.endPoint.y);
			}
		}
	}
}