package game.systems.motion
{
	import flash.display.DisplayObjectContainer;
	
	import engine.components.Spatial;
	
	import game.components.motion.MaintainRotation;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.MaintainRotationNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	/**
	 * system to maintain an object's current rotation in relation to its parent rotation
	 * handles x and y axis fliped objects and rotation ranges
	 */
	public class MaintainRotationSystem extends GameSystem
	{
		public function MaintainRotationSystem()
		{
			super( MaintainRotationNode, updateNode, addNode);
			super._defaultPriority = SystemPriorities.preRender;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
		}
		
		public function updateNode(node:MaintainRotationNode,time:Number):void
		{
			var maint:MaintainRotation = node.maintainRotation;
			var spatial:Spatial = node.spatial;
			var rotationOffset:Number = 0;
			var flipXOffset:Number = 1;
			var flipYOffset:Number = 1;
			if(maint.parentSpatial)
			{
				// use parent property if available
				rotationOffset = -maint.parentSpatial.rotation;
				flipXOffset = maint.parentSpatial.scaleX;
				flipYOffset = maint.parentSpatial.scaleY;
			}
			else if(node.display.container)
			{
				// collect all rotations affecting container
				var container:DisplayObjectContainer = node.display.container;
				flipXOffset = container.scaleX;
				flipYOffset = container.scaleY;
				while(container.parent){
					rotationOffset -= container.rotation;
					container = container.parent;
					if(container.scaleX > 0){
						flipXOffset *= -1;
					}
					else if(container.scaleX < 0){
						flipXOffset *= -1;
					}
					if(container.scaleY > 0){
						flipYOffset *= -1;
					}
					else if(container.scaleY < 0){
						flipYOffset *= -1;
					}
				}
			}
			rotationOffset += node.maintainRotation.startingRotation;
			
			updateLockedRotation(node, rotationOffset);
			
			updateFlipX(node, rotationOffset,flipXOffset);
			updateFlipY(node, rotationOffset,flipYOffset);

		}
		
		private function updateFlipX(node:MaintainRotationNode, rotationOffset:Number, flipXOffset:Number):void
		{
			if(node.maintainRotation.flipX){
				var container:DisplayObjectContainer = node.display.container;
				var nextScale:Number = flipXOffset;
				if(nextScale > 0){
					node.spatial.scaleX = -node.maintainRotation.startingScaleX;
					if(node.maintainRotation.lockRotation){
						node.spatial.rotation = -rotationOffset;
					}
					node.maintainRotation.flippedX  = true;
					node.maintainRotation.flippedX  = true;
				}
				else if(nextScale < 0){
					node.spatial.scaleX = node.maintainRotation.startingScaleX;
					if(node.maintainRotation.lockRotation){
						node.spatial.rotation = rotationOffset;
					}
					node.maintainRotation.flippedX  = false;
					node.maintainRotation.flippedX  = false;
				}
			}
		}
		
		private function updateFlipY(node:MaintainRotationNode, rotationOffset:Number, flipYOffset:Number):void
		{
			if(node.maintainRotation.flipY){
				var container:DisplayObjectContainer = node.display.container;
				var nextScale:Number = flipYOffset;
				if(nextScale > 0){
					node.spatial.scaleY = -node.maintainRotation.startingScaleY;
					if(node.maintainRotation.flippedX && node.maintainRotation.lockRotation){
						node.spatial.rotation = rotationOffset;
					}else if(node.maintainRotation.lockRotation){
						node.spatial.rotation = -rotationOffset;
					}
				}
				else if(nextScale < 0){
					node.spatial.scaleY = node.maintainRotation.startingScaleY;
					if(node.maintainRotation.flippedX  && node.maintainRotation.lockRotation){
						node.spatial.rotation = -rotationOffset;
					}else if(node.maintainRotation.lockRotation){
						node.spatial.rotation = rotationOffset;
					}
				}
			}
		}
		
		private function updateLockedRotation(node:MaintainRotationNode, rotationOffset:Number):void
		{
			if(node.maintainRotation.lockRotation){
				node.spatial.rotation = rotationOffset;
				if(node.maintainRotation.limitRotation){
					if(node.spatial.rotation > node.maintainRotation.maxAngle)
					{
						node.spatial.rotation = node.maintainRotation.maxAngle;
					}
					else if(node.spatial.rotation < node.maintainRotation.minAngle)
					{
						node.spatial.rotation = node.maintainRotation.minAngle;
					}	
				}
			}
		}
		
		
		
		public function addNode(node:MaintainRotationNode):void
		{
			//node.maintainRotation.startingRotation = node.spatial.rotation;
		}
	}
}