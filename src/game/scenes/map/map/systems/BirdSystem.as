package game.scenes.map.map.systems
{
	import flash.geom.Point;
	
	import game.scenes.map.map.nodes.BirdNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	import game.util.Utils;
	
	public class BirdSystem extends GameSystem
	{
		private var point:Point = new Point;
		
		public function BirdSystem()
		{
			super(BirdNode, updateNode);
			
			this._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:BirdNode, time:Number):void
		{
			//Flapping
			node.bird.flapTime += node.bird.flapRate * time;
			while(node.bird.flapTime > Math.PI)
				node.bird.flapTime -= Math.PI * 2;
			
			node.bird.wing1.rotation = 45 * Math.sin(node.bird.flapTime);
			node.bird.wing2.rotation = -node.bird.wing1.rotation;
			
			//Flocking
			node.bird.flockTime += node.bird.flockRate * time;
			while(node.bird.flockTime > Math.PI)
				node.bird.flockTime -= Math.PI * 2;
			
			point = DisplayUtils.localToLocal(node.bird.display.displayObject, node.display.displayObject.parent);
			
			//Depending on what behavior we want for birds, uncomment this and pull out "node.bird.offsetX/Y" from delta calcs.
			//point.x += node.bird.offsetX;
			//point.y += node.bird.offsetY;
			
			var deltaX:Number = (point.x + node.bird.offsetX) - node.spatial.x;
			var deltaY:Number = (point.y + node.bird.offsetY) - node.spatial.y;
			
			if(Math.abs(deltaX) > 500)
			{
				if(deltaX > 500) deltaX = 500;
				else if(deltaX < -500) deltaX = -500;
			}
			
			if(Math.abs(deltaY) > 500)
			{
				if(deltaY > 500) deltaY = 500;
				else if(deltaY < -500) deltaY = -500;
			}
			
			node.spatial.x += deltaX * 0.5 * time;
			node.spatial.y += deltaY * 0.5 * time;
			
			if(Utils.distance(node.spatial.x, node.spatial.y, point.x, point.y) <= node.bird.radius)
				node.bird.tempTime = node.bird.flockTime;
			
			node.bird.offsetX = node.bird.radius * Math.cos(node.bird.tempTime);
			node.bird.offsetY = node.bird.radius * Math.sin(node.bird.tempTime) * 0.5;
		}
	}
}