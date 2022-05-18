package game.scenes.shrink.schoolCafetorium.HitTheDeckSystem
{
	import flash.geom.Point;
	
	import game.systems.GameSystem;
	
	public class HitTheDeckSystem extends GameSystem
	{
		public function HitTheDeckSystem()
		{
			super(HitTheDeckNode, updateNode);
		}
		
		public function updateNode(node:HitTheDeckNode, time:Number):void
		{
			if(node.hitTheDeck.projectile == null || node.hitTheDeck.ignoreProjectile)
				return;
			
			var pos:Point = new Point(node.spatial.x, node.spatial.y);
			
			if(node.hitTheDeck.offset)
			{
				pos.x += node.hitTheDeck.offset.x;
				pos.y += node.hitTheDeck.offset.y;
			}
			
			var projectilPos:Point = new Point(node.hitTheDeck.projectile.x, node.hitTheDeck.projectile.y);
			
			//var projectileDistance:Number = Point.distance(pos, projectilPos);
			//if(projectileDistance < node.hitTheDeck.duckDistance)// based off distance but is more expensive than just checking if with in a rect
			if(Math.abs(pos.x - projectilPos.x) < node.hitTheDeck.duckDistance && Math.abs(pos.y - projectilPos.y) < node.hitTheDeck.duckDistance)
			{
				if(!node.hitTheDeck.ducking)
				{
					node.hitTheDeck.ducking = true;
					node.hitTheDeck.duck.dispatch(node.entity);
				}
			}
			else
			{
				if(node.hitTheDeck.ducking)
				{
					node.hitTheDeck.ducking = false;
					node.hitTheDeck.coastClear.dispatch(node.entity);
				}
			}
		}
	}
}