package game.scenes.deepDive1.shared.data
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.components.motion.RotateToVelocity;
	import game.scenes.deepDive1.shared.components.FishPath;
	import game.scenes.deepDive1.shared.nodes.FishPathNode;
	import game.util.GeomUtils;
	import game.util.TweenUtils;

	public class DirectPathLooping extends SwimStyle
	{
		/**
		 * perfroms basic move-to between each target point, loops back to start at the end
		 */
		public function DirectPathLooping()
		{
			super();
		}
		
		public override function update(node:FishPathNode, time:Number):Boolean
		{
			var fishEnt:Entity = node.entity;
			var path:FishPath = node.path;
			var data:FishPathData = path.data[path.currentIndex];
			var target:Point = data.targetPosition;
			var speed:Number = data.speed;
			var dist:Number = GeomUtils.distSquared(node.spatial.x,node.spatial.y, target.x,target.y);
			if(dist > minRange){
				var angle:Number = Math.atan2(target.y-node.spatial.y,target.x-node.spatial.x);
				var dx:Number = Math.cos(angle) * speed;
				var dy:Number = Math.sin(angle) * speed;
				node.motion.velocity.x = dx;
				node.motion.velocity.y = dy;
				node.entity.get(RotateToVelocity).pause = false;
				return false;
			}else{
				node.motion.velocity= new Point(0,0);
				node.entity.get(RotateToVelocity).pause = true;
				TweenUtils.globalTo(node.entity.group, node.spatial, 0.7, {rotation:data.rotation},"fishR");
				data.delayCounter += time;
				if(data.delayCounter > data.delay){
					// head back to starting point
					data.delayCounter = 0;
					path.currentIndex++;

					if(path.currentIndex > path.data.length -1){
						path.currentIndex = 0;
					}
				}
				return	true;
			}
		}
	}
}