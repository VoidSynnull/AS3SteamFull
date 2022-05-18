package game.scenes.deepDive1.shared.data
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.motion.RotateToVelocity;
	import game.scenes.deepDive1.shared.components.FishPath;
	import game.scenes.deepDive1.shared.nodes.FishPathNode;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.TweenUtils;

	public class DirectOneWay extends SwimStyle
	{
		private var idling:Boolean;
		/**
		 * perfroms basic move-to between each target point once
		 */
		public function DirectOneWay()
		{
			super();
		}
		
		override public function update(node:FishPathNode, time:Number):Boolean
		{
			super.update(node,time);
			var path:FishPath = node.path;
			var data:FishPathData = path.getCurrentData();
			var target:Point = data.targetPosition;
			var speed:Number = data.speed;
			var dist:Number = GeomUtils.distSquared(node.spatial.x,node.spatial.y, target.x,target.y);
			if( dist > speed){
				var angle:Number = Math.atan2(target.y-node.spatial.y,target.x-node.spatial.x);
				var dx:Number = Math.cos(angle) * speed;
				var dy:Number = Math.sin(angle) * speed;
				node.motion.velocity.x = dx;
				node.motion.velocity.y = dy;
				if(node.rotateToVelocity){
					node.rotateToVelocity.pause = false;
				}
				if(idling){
					// not idle
					idling = false;
					node.timeline.gotoAndPlay("swim");
				}
				return false;
			}else{
				// reached target
				// zero motion & finish rotating
				node.motion.zeroMotion();
				if(node.spatial.rotation != data.rotation){
					if(node.rotateToVelocity){
						node.rotateToVelocity.pause = true;
						TweenUtils.globalTo(node.entity.group, node.spatial, 0.7, {rotation:data.rotation, onComplete:Command.create(nextTarget,node)},"fishR");
					}
				}
				if(!idling){
					idling = true;
				}
				return	false;
			}
		}
		
		private function nextTarget(node:FishPathNode):void
		{
			node.path.currentIndex++;
			if(node.path.currentIndex > node.path.data.length){
				node.path.currentIndex = node.path.data.length;
			}
		}
		
		
		
		
	};
};