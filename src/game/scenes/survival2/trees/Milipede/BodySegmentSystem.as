package game.scenes.survival2.trees.Milipede
{
	import flash.geom.Point;
	
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.PointUtils;
	
	public class BodySegmentSystem extends GameSystem
	{
		public function BodySegmentSystem()
		{
			super(BodySegmentNode, updateNode);
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		public function updateNode(node:BodySegmentNode, time:Number):void
		{
			node.body.lastPosition = node.body.currentPosition;
			node.body.rotation = node.spatial.rotation / 180 * Math.PI;
			
			if(node.body.leader == null || node.body.currentPosition == null)
			{
				node.body.currentPosition = new Point(node.spatial.x, node.spatial.y);
				if(node.body.lastPosition != null)
					segmentMoved(node.body.lastPosition, node)
				return;
			}
			
			var target:Point = node.body.leader.currentPosition;
			var pos:Point = new Point(node.spatial.x, node.spatial.y);
			var direction:Number;
			
			if(node.body.leader.kinematicType == BodySegment.FOLLOW)
				direction = PointUtils.getRadiansBetweenPoints(pos, target);
			else
				direction = PointUtils.getRadiansBetweenPoints(target, pos);
			
			///* all of this is to get the segments to obey their joint max min bend limits
			var difference:Number = node.body.leader.rotation - direction;
			
			if(difference > Math.PI)
				difference -= Math.PI * 2;
			if(difference < -Math.PI)
				difference += Math.PI * 2;
			
			var maxRight:Number = node.body.leader.maxBendRight / 180 * Math.PI;
			var maxLeft:Number = node.body.leader.maxBendLeft / 180 * Math.PI;
			
			var distanceRight:Number = Math.abs(maxRight - difference);
			var distanceLeft:Number = Math.abs(maxLeft - difference);
			
			if(difference > maxRight && distanceRight < distanceLeft)
				direction -= maxRight - difference;
			if(difference < maxLeft && distanceLeft < distanceRight)
				direction -= maxLeft - difference;
			//*/
			var unitDirection:Point = PointUtils.getUnitDirectionOfAngle(direction);
			if(node.body.leader.kinematicType == BodySegment.FOLLOW)
				pos = target.subtract(PointUtils.times(unitDirection, node.body.space + node.body.leader.length));
			else
				pos = target.add(PointUtils.times(unitDirection, node.body.space + node.body.leader.length));
			
			if(!segmentMoved(pos, node))
				return;
			
			node.spatial.x = pos.x;
			node.spatial.y = pos.y;
			node.spatial.rotation = direction * 180 / Math.PI;
			node.body.currentPosition = new Point(node.spatial.x, node.spatial.y);
		}
		
		private function segmentMoved(target:Point, node:BodySegmentNode):Boolean
		{
			if(target.x == node.spatial.x && target.y == node.spatial.y)
			{
				if(node.body.moving)
				{
					node.body.moving = false;
					node.body.move.dispatch(node.entity, false);
				}
				return false;
			}
			if(!node.body.moving)
			{
				node.body.moving = true;
				node.body.move.dispatch(node.entity, true);
			}
			return true;
		}
	}
}