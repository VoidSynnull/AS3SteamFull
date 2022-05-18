package game.systems.entity
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.components.entity.MotionMaster;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.MotionMasterNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	
	public class MotionMasterSystem extends GameSystem//System
	{
		public function MotionMasterSystem()
		{
			super( MotionMasterNode, updateNode, nodeAdded );
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_nodes = systemsManager.getNodeList( MotionMasterNode );
			super.addToEngine( systemManager );
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}

		private function nodeAdded( node:MotionMasterNode ):void
		{
		}
		
		public function updateNode( node:MotionMasterNode, time:Number ):void
		{						
//			var spatial:Spatial;
			var motionMaster:MotionMaster;
			var velocityX:Number = 0;
			var velocityY:Number = 0;
			var rotationVelocity:Number;
			var frictionX:Number;
			var frictionY:Number;
			var rotationFriction:Number;
			var positionX:Number;
			var positionY:Number;
			var positionRotation:Number;
			var minVelocityX:Number;
			var minVelocityY:Number;
			var maxVelocityX:Number;
			var maxVelocityY:Number;
			var accelerationX:Number;
			var accelerationY:Number;
			
		//	for ( node = _nodes.head; node; node = node.next )
		//	{
			if( !node.motionMaster.pause && node.motionMaster.active )
			{
					
				
		//		spatial = node.spatial;
				motionMaster = node.motionMaster;
				
				// sync up the render x and y to the previous physics position.  
//				motionMaster.previousX = motionMaster.x;
//				motionMaster.previousY = motionMaster.y;
				motionMaster.previousRotation = motionMaster.rotation;
				
//				if(spatial._updateX) { motionMaster.previousX = motionMaster._x = spatial.x; spatial._updateX = false; }
//				if(spatial._updateY) { motionMaster.previousY = motionMaster._y = spatial.y; spatial._updateY = false; }
//				if(spatial._updateRotation) { motionMaster.previousRotation = motionMaster._rotation = spatial.rotation; spatial._updateRotation = false; }
				
				positionRotation = NaN;
				
				accelerationX = motionMaster.acceleration.x;
				accelerationY = motionMaster.acceleration.y;
				
				if (motionMaster.parentAcceleration != null)
				{
					accelerationX += motionMaster.parentMotionFactor * motionMaster.parentAcceleration.x;
					accelerationY += motionMaster.parentMotionFactor * motionMaster.parentAcceleration.y;
				}
				
				velocityX = motionMaster.velocity.x + (motionMaster.previousAcceleration.x + accelerationX) * .5 * time;
				velocityY = motionMaster.velocity.y + (motionMaster.previousAcceleration.y + accelerationY) * .5 * time;
				
				motionMaster.previousAcceleration.x = accelerationX;
				motionMaster.previousAcceleration.y = accelerationY;
				
				// only enforce a min x velocity if we're not accelerating (sliding to a stop).
				if (Math.abs(accelerationX) > 0)
				{
					minVelocityX = 0;
				}
				else
				{
					minVelocityX = motionMaster.minVelocity.x;
				}
				
				if (Math.abs(accelerationY) > 0)
				{
					minVelocityY = 0;
				}
				else
				{
					minVelocityY = motionMaster.minVelocity.y;
				}
				
				maxVelocityX = motionMaster.maxVelocity.x;
				maxVelocityY = motionMaster.maxVelocity.y;
				
				if(motionMaster._updateRotationMotion)
				{			
					if(motionMaster.rotationAcceleration != 0)
					{
						rotationVelocity = motionMaster.rotationVelocity + (motionMaster.rotationAcceleration * time);									
						rotationVelocity = checkBounds(rotationVelocity, motionMaster.rotationMinVelocity, motionMaster.rotationMaxVelocity);
					}
					else
					{
						rotationVelocity = motionMaster.rotationVelocity;
					}
					
					if(motionMaster.rotationFriction != 0)
					{
						rotationFriction = motionMaster.rotationFriction * time;
						
						if(rotationVelocity > rotationFriction)
						{
							rotationVelocity -= rotationFriction;
						}
						else if(rotationVelocity < -rotationFriction)
						{
							rotationVelocity += rotationFriction;
						}
						else
						{
							rotationVelocity = 0;
						}
					}
					
					if (motionMaster.parentRotationVelocity != 0)
					{
						positionRotation = ((motionMaster.rotationVelocity + rotationVelocity) * .5 * time) + (motionMaster.parentMotionFactor * motionMaster.parentRotationVelocity * time);
					}
					else
					{
						positionRotation = (motionMaster.rotationVelocity + rotationVelocity) * .5 * time;
					}
					
					motionMaster.rotationVelocity = rotationVelocity;
					
					if(rotationVelocity == 0)
					{
						motionMaster._updateRotationMotion = false;
					}
				}
				
				// clamp velocity to min and max values
				var totalVelocityX:Number = checkBounds(velocityX, minVelocityX, maxVelocityX);
				var totalVelocityY:Number = checkBounds(velocityY, minVelocityY, maxVelocityY);
				
				motionMaster.velocity.x = totalVelocityX;
				motionMaster.velocity.y = totalVelocityY;
				
				// TODO : Move parent velocity code elsewhere?
				if (motionMaster.parentVelocity != null)
				{
					totalVelocityX += motionMaster.parentMotionFactor * motionMaster.parentVelocity.x;
					totalVelocityY += motionMaster.parentMotionFactor * motionMaster.parentVelocity.y;
				}
				/*
				// interpolate between old and new velocity
				positionX = (motionMaster.totalVelocity.x + totalVelocityX) * .5 * time;
				positionY = (motionMaster.totalVelocity.y + totalVelocityY) * .5 * time;
				*/
				positionX = totalVelocityX * time;
				positionY = totalVelocityY * time;
				
				motionMaster.totalVelocity.x = totalVelocityX;
				motionMaster.totalVelocity.y = totalVelocityY;
				
				// update position based on average velocity
				motionMaster.distanceX = motionMaster._distanceX + positionX;
				motionMaster.distanceY = motionMaster._distanceY + positionY;
				
				// update progress display
				if (motionMaster.progressDisplay)
				{
					var axis:String = motionMaster.axis.toUpperCase();
					motionMaster.progressDisplay["scale"+axis] = Math.abs(motionMaster["distance"+axis]) / motionMaster.goalDistance;
				}
				if (motionMaster.progressDisplayText)
				{
					var axis2:String = motionMaster.axis.toUpperCase();
					var distance:Number = Math.abs(motionMaster["distance"+axis2]);
					var percent:String = Math.round((distance/motionMaster.goalDistance)*100).toString();
					motionMaster.progressDisplayText.text = percent;
				}
				
				if(!isNaN(positionRotation) && positionRotation != 0) { motionMaster.rotation = motionMaster.rotation + positionRotation; }
				
				if(motionMaster.velocity.x != 0 || motionMaster.velocity.y != 0)
				{
					frictionX = 0;
					frictionY = 0;
					
					if(motionMaster.friction != null)
					{
						frictionX = motionMaster.friction.x;
						frictionY = motionMaster.friction.y;
					}
					
					if (motionMaster.parentFriction != null)
					{
						frictionX += motionMaster.parentFriction.x;
						frictionY += motionMaster.parentFriction.y;
					}
					
					if(frictionX != 0 || frictionY != 0)
					{
						if(frictionX == frictionY)
						{
							applyUniformFriction(frictionX * time, motionMaster.velocity);
						}
						else
						{
							if(frictionX != 0)
							{
								motionMaster.velocity.x = applyFriction(frictionX * time, velocityX);
							}
							
							if(frictionY != 0)
							{
								motionMaster.velocity.y = applyFriction(frictionY * time, velocityY);
							}
						}
					}
				}
				// we reset this here.  If any hit areas are still causing a parent motionMaster they will be reapplied
				//  during the hitTest phase which happens after this (see SystemPriorities.as).
				motionMaster.parentMotionFactor = 1;
				motionMaster.parentRotationVelocity = 0;
				motionMaster.parentAcceleration = null;
				motionMaster.parentVelocity = null;
				motionMaster.parentFriction = null;
				
			}
		}
		
		// used for side-view platforming where different friction values are applied along each axis.
		private function applyFriction(friction:Number, velocity:Number):Number
		{
			if (velocity > friction)
			{
				velocity -= friction;
			}
			else if (velocity < -friction)
			{
				velocity += friction;
			}
			else
			{
				velocity = 0;
			}
			
			return(velocity);
		}
		
		// used for 'top-down' movement where friction in applied evenly to x and y axis.
		private function applyUniformFriction(friction:Number, velocity:Point):Point
		{
			var speed:Number = Math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
			var angle:Number = Math.atan2(velocity.y, velocity.x);
			
			if(speed > friction)
			{
				speed -= friction;
				
				velocity.x = Math.cos(angle) * speed;
				velocity.y = Math.sin(angle) * speed;
			}
			else
			{
				velocity.x = 0;
				velocity.y = 0;
			}
			
			return(velocity);
		}
		
		private function checkBounds(value:Number, min:Number, max:Number):Number
		{
			if (Math.abs(value) > max)
			{
				if (value > max)
				{
					value = max;
				}
				else if (value < -max)
				{
					value = -max;
				}
			}
			else if (Math.abs(value) < min)
			{
				value = 0;
			}
			
			return(value);
		}
		
		override public function removeFromEngine(systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList(MotionMasterNode);
			_nodes = null;
		}
		
		private var _nodes : NodeList;
	}
}