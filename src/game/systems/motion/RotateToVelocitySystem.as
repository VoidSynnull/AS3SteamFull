package game.systems.motion
{
	import game.nodes.motion.RotateToVelocityNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	import game.util.TweenUtils;
	
	public class RotateToVelocitySystem extends GameSystem
	{
		public function RotateToVelocitySystem()
		{
			super(RotateToVelocityNode, updateNode, addNode);
			
			this._defaultPriority = SystemPriorities.lowest;
		}
		
		private function addNode(node:RotateToVelocityNode):void
		{
			if(node.rotate.mirrorHorizontal){
				if(node.spatial.rotation > 90 ||node.spatial.rotation < -90){
					if(node.rotate.originY){
						node.spatial.scaleY = -node.rotate.originY;
					}
				}
				else{
					if(node.rotate.originY){
						node.spatial.scaleY = node.rotate.originY;
					}
				}
			}
		}
		
		public function updateNode(node:RotateToVelocityNode, time:Number):void
		{
			if(node.rotate.mirrorHorizontal){
				if(node.spatial.rotation > 90 ||node.spatial.rotation < -90){
					if(node.rotate.originY){
						node.spatial.scaleY = -node.rotate.originY;
					}
				}
				else{
					if(node.rotate.originY){
						node.spatial.scaleY = node.rotate.originY;
					}
				}
			}
			if(!node.rotate.pause){
				var degrees:Number = Math.atan2(node.motion.velocity.y, node.motion.velocity.x);
				degrees = GeomUtils.radianToDegree(degrees) + node.rotate.offset;
				degrees = this.toRotation(degrees);
				
				if(node.rotate.rotateEase > 0){
					TweenUtils.globalTo(node.entity.group,	node.spatial, node.rotate.rotateEase, {rotation:degrees});
				}
				else{
					node.spatial.rotation = degrees;
				}
								
				if(node.rotate.limitRotation)
				{
					var delta:Number = -this.toRotation(node.spatial.rotation - node.rotate.angle);
					if(Math.abs(delta) > node.rotate.range)
					{
						if(delta > node.rotate.range) node.spatial.rotation = node.rotate.angle - node.rotate.range;
						else if(delta < -node.rotate.range) node.spatial.rotation = node.rotate.angle + node.rotate.range;
					}
				}
			}
		}
		
		private function toRotation(degrees:Number):Number
		{
			if(Math.abs(degrees) > 180)
			{
				if(degrees > 180)
				{
					while(degrees > 180)
						degrees -= 360;
				}
				else if(degrees < -180)
				{
					while(degrees < -180)
						degrees += 360;
				}
			}
			
			return degrees;
		}
	}
}