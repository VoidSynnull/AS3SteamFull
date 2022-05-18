package game.scenes.survival2.trees.TweenPath
{
	import com.greensock.easing.Linear;
	
	import flash.geom.Point;
	
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.systems.GameSystem;
	import game.util.PointUtils;
	import game.util.TweenUtils;
	
	public class TweenPathSystem extends GameSystem
	{
		public function TweenPathSystem()
		{
			super(TweenPathNode, updateNode);
		}
		
		public function updateNode(node:TweenPathNode, time:Number):void
		{
			if(node.path.path == null || !node.path.play || node.path.tweening || node.path.end)
				return;
			
			var point:Point = node.path.path[node.path.pointInPath];
			
			var rotation:Number = PointUtils.getRadiansBetweenPoints(new Point(node.spatial.x, node.spatial.y), point) * 180 / Math.PI;
			
			if(node.path.turnBehaviour == TweenPath.FACE)
				node.spatial.rotation = rotation;
			
			if(node.path.newPath)
				node.entity.remove(Tween);
			node.path.newPath = false;
			
			if(node.path.turnBehaviour == TweenPath.TURN)
				TweenUtils.entityTo(node.entity, Spatial, node.path.speed, {x:point.x, y:point.y, rotation:rotation, ease:Linear.easeNone, onComplete:Command.create(gotoNextPoint, node)});
			else
				TweenUtils.entityTo(node.entity, Spatial, node.path.speed, {x:point.x, y:point.y, ease:Linear.easeNone, onComplete:Command.create(gotoNextPoint, node)});
			
			node.path.tweening = true;
		}
		
		private function gotoNextPoint(node:TweenPathNode):void
		{
			node.path.tweening = false;
			
			if(node.path.reverse)
				node.path.pointInPath--;
			else
				node.path.pointInPath++;
			
			var end:Boolean = false;
			
			if(node.path.pointInPath >= node.path.path.length && !node.path.reverse || node.path.pointInPath <= -1 && node.path.reverse)
				end = true;
			
			if(end && node.path.loopBehaviour == TweenPath.LOOP)
			{
				if(node.path.reverse)
					node.path.pointInPath = node.path.path.length - 1;
				else
					node.path.pointInPath = 0;
				end = false;
			}
			
			if(end && node.path.loopBehaviour == TweenPath.REVERSE)
			{
				if(node.path.reverse)
					node.path.pointInPath = 1;
				else
					node.path.pointInPath = node.path.path.length - 2;
				
				end = false;
				node.path.reverse = !node.path.reverse;
			}
			
			node.path.reachedPoint.dispatch(node.entity, end);
			
			node.path.end = end;
		}
	}
}