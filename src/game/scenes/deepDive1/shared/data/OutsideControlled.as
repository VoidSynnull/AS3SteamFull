package game.scenes.deepDive1.shared.data
{
	import flash.geom.Point;
	
	import game.scenes.deepDive1.shared.components.FishPath;
	import game.scenes.deepDive1.shared.data.FishPathData;
	import game.scenes.deepDive1.shared.data.SwimStyle;
	import game.scenes.deepDive1.shared.nodes.FishPathNode;
	import game.util.GeomUtils;
	import game.util.TweenUtils;
	
	public class OutsideControlled extends SwimStyle
	{
		private var idling:Boolean = true;
		/** 
		 * move-to then waits to be handed a new target before moving
		**/
		public function OutsideControlled()
		{
			super();
		}
		
		/**
		 * Called by FishPathSystem's update. 
		 * @param node
		 * @param time
		 * @return 
		 * 
		 */
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
					node.timeline.gotoAndPlay(node.path.movingLabel);
				}
				return false;
			}else{
				// reached target
				// zero motion & finish rotating
				node.motion.zeroMotion();
				if(node.spatial.rotation != data.rotation){
					if(node.rotateToVelocity){
						node.rotateToVelocity.pause = true;
						TweenUtils.globalTo(node.entity.group, node.spatial, 0.7, {rotation:data.rotation},"fishR");
					}
				}
				if(!idling){
					idling = true;
				}
				return	true;
			}
		}
	}
}