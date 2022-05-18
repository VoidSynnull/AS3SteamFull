package game.scenes.survival2.trees.SplatBug
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.systems.GameSystem;
	import game.util.PointUtils;
	
	public class SplatBugSystem extends GameSystem
	{
		public function SplatBugSystem()
		{
			super(SplatBugNode, updateNode);
			super.fixedTimestep = .033;
		}
		
		public function updateNode(node:SplatBugNode, time:Number):void
		{
			for(var i:int = 0; i < node.bug.asset.numChildren; i++)
			{
				var dis:* = node.bug.asset["l"+i];
				if(dis is MovieClip)
				{
					var clip:MovieClip = dis as MovieClip
					clip.getChildAt(0).y = -3 + Math.random() * 4;
				}
			}
			
			node.spatial.rotation += Math.random() * 30 - 15;
			var direction:Point = PointUtils.getUnitDirectionOfAngle(node.spatial.rotation /180 * Math.PI);
			
			var pos:Point = new Point(node.spatial.x, node.spatial.y);
			if(Point.distance(pos, node.bug.origin) > node.bug.wanderRadius)
			{
				direction = PointUtils.getUnitDirectionOfAngle(PointUtils.getRadiansBetweenPoints(pos, node.bug.origin));
				node.spatial.rotation = PointUtils.getRadiansOfTrajectory(direction) * 180 / Math.PI;
			}
			
			direction = PointUtils.times(direction, Math.random() * node.bug.wanderSpeed);
			
			node.spatial.x += direction.x;
			node.spatial.y += direction.y;
		}
	}
}