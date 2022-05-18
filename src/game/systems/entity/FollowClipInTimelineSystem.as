package game.systems.entity
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.nodes.entity.FollowClipInTimelineNode;
	import game.systems.GameSystem;
	
	public class FollowClipInTimelineSystem extends GameSystem
	{
		public function FollowClipInTimelineSystem()
		{
			super(FollowClipInTimelineNode, updateNode);
		}
		
		private function updateNode(node:FollowClipInTimelineNode, time:Number):void
		{
			if(node.followClip.clip == null)
				return;
			
			var parent:Spatial = node.followClip.parent;
			var origin:Point = new Point();
			var scale:Point = new Point(1,1);
			
			if(parent != null)
			{
				origin.x = parent.x;
				origin.y = parent.y;
				scale.x = parent.scaleX;
				scale.y = parent.scaleY;
			}
			
			if(node.followClip.followRotation)
			{
				var rotation:Number = node.followClip.clip.rotation + node.followClip.rotationOffset;
				var parentRotation:Number = 0;
				if(parent != null)
					parentRotation = parent.rotation;
				node.spatial.rotation = rotation + parentRotation;
				
				var clipOffset:Point = rotatePoint(new Point(node.followClip.clip.x, node.followClip.clip.y), parentRotation);
				var offset:Point = rotatePoint(node.followClip.offSet, rotation+parentRotation);
				
				node.spatial.x = origin.x + clipOffset.x + offset.x;
				node.spatial.y = origin.y + clipOffset.y + offset.y;
			}
			else
			{
				node.spatial.x = origin.x + (node.followClip.clip.x + node.followClip.offSet.x) * scale.x;
				node.spatial.y = origin.y + (node.followClip.clip.y + node.followClip.offSet.y) * scale.y;
			}
		}
		
		private function rotatePoint(point:Point, rotation:Number):Point
		{
			var rotPoint:Point = new Point();
			var radians:Number = rotation * Math.PI / 180;
			rotPoint.x = Math.cos(radians) * point.x - Math.sin(radians) * point.y;
			rotPoint.y = Math.cos(radians) * point.y + Math.sin(radians) * point.x;
			return rotPoint;
		}
	}
}