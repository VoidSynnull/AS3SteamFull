package game.systems.motion
{
	import ash.core.NodeList;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControlBase;
	import game.nodes.motion.MoveToTargetNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	
	public class MoveToTargetSystem extends GameSystem
	{
		public function MoveToTargetSystem(viewWidth:Number, viewHeight:Number)
		{
			super(MoveToTargetNode, updateNode, nodeAdded);
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		private function updateNode(node:MoveToTargetNode, time:Number):void
		{
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			var targetDeltaX:Number = node.motionTarget.targetDeltaX;//node.motionTarget.targetX - spatial.x;	
			var targetDeltaY:Number = node.motionTarget.targetDeltaY;//node.motionTarget.targetY - spatial.y;
			
			// if target is moving
			if (node.motionControlBase.accelerate && !isNaN(targetDeltaX) && !isNaN(targetDeltaY))	
			{		
				// calculate acceleration based on angle from target
				if(node.motionControlBase.freeMovement)
				{
					var targetDistance:Number = Math.sqrt(targetDeltaX * targetDeltaX + targetDeltaY * targetDeltaY);

					if(targetDistance > node.motionControlBase.minDistance)
					{
						var factor:Number = targetDistance / node.motionControlBase.moveFactor;
						var angle:Number;
						
						factor = Math.min(factor, 1);
						
						if(node.motionControlBase.rotationDeterminesAcceleration && !isNaN(node.motion.rotation))
						{
							angle = GeomUtils.degreeToRadian(node.motion.rotation);
						}
						else
						{
							angle = Math.atan2(targetDeltaY, targetDeltaX);
						}
						
						var cosAngle:Number = Math.cos(angle);
						var sinAngle:Number = Math.sin(angle);
						
						motion.acceleration.x = cosAngle * node.motionControlBase.acceleration * factor;
						motion.acceleration.y = sinAngle * node.motionControlBase.acceleration * factor;
						
						if(node.motionControlBase.maxVelocityByTargetDistance != 0)
						{
							if( factor != 1 )
							{
								// test length 
								var maxVelocity:Number = node.motionControlBase.maxVelocityByTargetDistance * Math.abs(factor);
								
								if(node.motion.velocity.length > maxVelocity)
								{
									motion.velocity.x = cosAngle * maxVelocity;
									motion.velocity.y = sinAngle * maxVelocity;
								}
							}
						}
					}
					else
					{
						moveX(node, 0);
						moveY(node, 0);
					}
				}
				else
				{
					// calculate each axis independently
					var factorX:Number = 0;
					var factorY:Number = 0;
					var minDistanceX:Number = node.motionControlBase.minDistanceX;
					var minDistanceY:Number = node.motionControlBase.minDistanceY;
					var moveFactorX:Number = node.motionControlBase.moveFactorX;
					var moveFactorY:Number = node.motionControlBase.moveFactorY;
					
					if(node.motionControlBase.lockAxis != MotionControlBase.X)
					{
						if (targetDeltaX > minDistanceX)
						{
							factorX = Math.min(targetDeltaX / moveFactorX, 1);
						}
						else if(targetDeltaX < -minDistanceX)
						{
							factorX = Math.max(targetDeltaX / moveFactorX, -1);
						}
					}					
					
					if(node.motionControlBase.lockAxis != MotionControlBase.Y)
					{
						if (targetDeltaY > minDistanceY)
						{
							factorY = Math.min(targetDeltaY / moveFactorY, 1);
						}
						else if(targetDeltaY < -minDistanceY)
						{
							factorY = Math.max(targetDeltaY / moveFactorY, -1);
						}
					}
					
					moveX(node, factorX);
					moveY(node, factorY);
				}
			}
			else
			{
				moveX(node, 0);
				moveY(node, 0);
			}
		}	
		
		private function moveX(node:MoveToTargetNode, direction:Number):void
		{			
			node.motion.acceleration.x = direction * node.motionControlBase.acceleration;
		}
		
		private function moveY(node:MoveToTargetNode, direction:Number):void
		{
			node.motion.acceleration.y = direction * node.motionControlBase.acceleration;
		}		
		
		private function nodeAdded(node:MoveToTargetNode):void
		{
			// use the smaller dimension to allow for a perfect 'circle' 
			var viewSize:Number = super.group.shellApi.viewportHeight;
			
			if(super.group.shellApi.viewportWidth < viewSize)
			{
				viewSize = super.group.shellApi.viewportWidth;
			}
			
			var motionControlBase:MotionControlBase = node.motionControlBase;
			
			motionControlBase.minDistance = viewSize * motionControlBase.minDistanceMultiplier;
			motionControlBase.minDistanceX = viewSize * motionControlBase.minDistanceMultiplier;
			motionControlBase.minDistanceY = viewSize * motionControlBase.minDistanceMultiplier;
			
			motionControlBase.moveFactor = viewSize * motionControlBase.moveFactorMultiplier;
			motionControlBase.moveFactorX = viewSize * motionControlBase.moveFactorMultiplier;
			motionControlBase.moveFactorY = viewSize * motionControlBase.moveFactorMultiplier;
		}
		
		// not currently used...might want to switch to a viewportUpdateSystem that propogates out changes when they happen.
		public function updateViewport(width:Number, height:Number):void
		{
			var node:MoveToTargetNode;
			var nodes:NodeList = super.systemManager.getNodeList(MoveToTargetNode);
			
			for ( node = nodes.head; node; node = node.next )
			{
				nodeAdded(node);
			}
		}
	}
}