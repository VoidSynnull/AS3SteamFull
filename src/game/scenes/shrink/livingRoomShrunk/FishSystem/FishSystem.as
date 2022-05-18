package game.scenes.shrink.livingRoomShrunk.FishSystem
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.systems.GameSystem;
	import game.util.TweenUtils;
	
	public class FishSystem extends GameSystem
	{
		public function FishSystem()
		{
			super(FishNode, updateNode);
		}
		
		public function updateNode(node:FishNode, time:Number):void
		{
			if(node.fish.isEating)
				return;
			
			if(node.fish.state == node.fish.IDLE)
			{
				if(node.fish.inTerritory)
					switchState(node.fish.ANGRY, node);
			}
				
			if(node.fish.state == node.fish.ANGRY)
			{
				checkIfFishShouldAttack(node, time);
				
				checkIfFishHitWall(node, time);
				
				if(!node.fish.inTerritory)
					switchState(node.fish.IDLE, node);
			}
			
			if(node.fish.food != null)
			{
				if(node.fish.state != node.fish.FEEDING)
					eatFood(node);
			}
		}
		
		private function checkIfFishShouldAttack(node:FishNode, time:Number):void
		{
			var intruder:Entity = group.getEntityById(node.fish.intruder);
			var intruderSpatial:Spatial = intruder.get(Spatial);
			if(intruderSpatial.y < node.spatial.y - node.spatial.height)
				return;
			if(intruderSpatial.x < node.spatial.x - node.spatial.width / 2)
			{
				if(node.fish.direction == 1)
					turn(node, -1, time);
			}
			if(intruderSpatial.x > node.spatial.x + node.spatial.width / 2)
			{
				if(node.fish.direction == -1)
					turn(node, 1,time);
			}
		}
		
		private function checkIfFishHitWall(node:FishNode, time:Number):void
		{
			if(node.motion.velocity.x == 0)
				node.motion.velocity = new Point(node.fish.speed * node.fish.direction, 0 );
			
			if(node.spatial.x > node.fish.tank.right - node.spatial.width / 2 || node.spatial.x < node.fish.tank.left + node.spatial.width / 2)
			{
				turn(node, node.fish.direction * -1, time);
			}
		}
		
		private function turn(node:FishNode, direction:int, time:Number):void
		{
			node.fish.direction = direction;
			node.spatial.scaleX = node.fish.direction;
			node.spatial.x += node.fish.speed * node.fish.direction * time * 2;
			node.motion.velocity = new Point(node.fish.speed * node.fish.direction, 0 );
		}
		
		private function switchState(state:String, node:FishNode):void
		{
			node.motion.velocity = new Point();
			node.fish.state = state;
			node.timeline.gotoAndPlay(state);
		}
		
		private function eatFood(node:FishNode):void
		{
			var space:Number = 25;
			
			switchState(node.fish.FEEDING,node);
			node.fish.isEating = true;
			
			var pos:Point = new Point(node.spatial.x, node.spatial.y);
			var target:Point = new Point(node.fish.food.x, node.fish.food.y);
			var rotation:Number = Math.atan2(target.y - pos.y, target.x - pos.x);
			var offsetDistance:Number = node.spatial.width / 2 + space;
			
			if(pos.x > target.x)
				node.spatial.scaleY = -1;
			
			node.spatial.scaleX = 1;
			
			var moveTo:Point = new Point(target.x - offsetDistance * Math.cos(rotation), target.y - offsetDistance * Math.sin(rotation));
			
			TweenUtils.entityTo(node.entity, Spatial, 2, {x:moveTo.x, y:moveTo.y, rotation:rotation * 180 / Math.PI});
		}
	}
}