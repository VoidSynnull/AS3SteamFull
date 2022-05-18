package game.scenes.backlot.soundStage1.KeepWithInDistanceSystem
{
	import flash.geom.Point;
	
	import game.systems.GameSystem;
	
	public class KeepWithInDistanceSystem extends GameSystem
	{
		public function KeepWithInDistanceSystem()
		{
			super(KeepWithInDistanceNode, updateNode);
		}
		
		public function updateNode(node:KeepWithInDistanceNode, time:Number):void
		{
			if(node.keepOnTarget.lost || !node.keepOnTarget.keepTrack)
				return;
			
			var pos:Point = new Point(node.spatial.x, node.spatial.y);
			var targetPos:Point = new Point(node.keepOnTarget.target.x, node.keepOnTarget.target.y);
			var distance:Number = Point.distance(pos, targetPos);
			
			if(distance > node.keepOnTarget.minMax.y)
			{
				loose(node.keepOnTarget);
			}
			else
			{
				if(distance > node.keepOnTarget.minMax.x)
				{
					trace("your off target");
					node.keepOnTarget.offTime += time;
				}
				else
					node.keepOnTarget.offTime = 0;
				if(node.keepOnTarget.offTime > node.keepOnTarget.looseTime)
				{
					loose(node.keepOnTarget);
				}
			}
		}
		
		private function loose(follower:KeepWithInDistance):void
		{
			follower.loose.dispatch();
			follower.looseTime = 0;
			follower.lost = true;
		}
	}
}