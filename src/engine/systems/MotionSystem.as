package engine.systems
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.nodes.MotionNode;
	
	import game.data.motion.time.FixedTimestep;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;

	public class MotionSystem extends System
	{
		public function MotionSystem()
		{
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine(systemsManager:Engine):void
		{
			_nodes = systemsManager.getNodeList(MotionNode);
		}
		
		/**
		 *  Applies Velocity Vertlet integrated movement. 
		 *  @see http://www.richardlord.net/presentations/physics-for-flash-games
		 */
		override public function update(time:Number):void
		{						
			var node:MotionNode;
			var spatial:Spatial;
			var motion:Motion;
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

			for ( node = _nodes.head; node; node = node.next )
			{
				if (EntityUtils.sleeping(node.entity) || node.motion.pause)
				{
					continue;
				}
				
				spatial = node.spatial;
				motion = node.motion;
				
				// sync up the render x and y to the previous physics position.  
				motion.previousX = motion.x;
				motion.previousY = motion.y;
				motion.previousRotation = motion.rotation;
				
				motion.lastVelocity.x = motion.velocity.x;
				motion.lastVelocity.y = motion.velocity.y;
				
				if(spatial._updateX) { motion.previousX = motion._x = spatial.x; spatial._updateX = false; }
				if(spatial._updateY) { motion.previousY = motion._y = spatial.y; spatial._updateY = false; }
				if(spatial._updateRotation) { motion.previousRotation = motion._rotation = spatial.rotation; spatial._updateRotation = false; }
				
				positionRotation = NaN;
				
				accelerationX = motion.acceleration.x;
				accelerationY = motion.acceleration.y;
				
				if (motion.parentAcceleration != null)
				{
					accelerationX += motion.parentMotionFactor * motion.parentAcceleration.x;
					accelerationY += motion.parentMotionFactor * motion.parentAcceleration.y;
				}

				velocityX = motion.velocity.x + (motion.previousAcceleration.x + accelerationX) * .5 * time;
				velocityY = motion.velocity.y + (motion.previousAcceleration.y + accelerationY) * .5 * time;
				
				motion.previousAcceleration.x = accelerationX;
				motion.previousAcceleration.y = accelerationY;
				
				// only enforce a min x velocity if we're not accelerating (sliding to a stop).
				if (Math.abs(accelerationX) > 0)
				{
					minVelocityX = 0;
				}
				else
				{
					minVelocityX = motion.minVelocity.x;
				}
				
				if (Math.abs(accelerationY) > 0)
				{
					minVelocityY = 0;
				}
				else
				{
					minVelocityY = motion.minVelocity.y;
				}
				
				maxVelocityX = motion.maxVelocity.x;
				maxVelocityY = motion.maxVelocity.y;
				
				if(motion._updateRotationMotion)
				{			
					if(motion.rotationAcceleration != 0)
					{
						rotationVelocity = motion.rotationVelocity + (motion.rotationAcceleration * time);									
						rotationVelocity = checkBounds(rotationVelocity, motion.rotationMinVelocity, motion.rotationMaxVelocity);
					}
					else
					{
						rotationVelocity = motion.rotationVelocity;
					}
					
					if(motion.rotationFriction != 0)
					{
						rotationFriction = motion.rotationFriction * time;
						
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
					
					if (motion.parentRotationVelocity != 0)
					{
						positionRotation = ((motion.rotationVelocity + rotationVelocity) * .5 * time) + (motion.parentMotionFactor * motion.parentRotationVelocity * time);
					}
					else
					{
						positionRotation = (motion.rotationVelocity + rotationVelocity) * .5 * time;
					}
					
					motion.rotationVelocity = rotationVelocity;
					
					if(rotationVelocity == 0)
					{
						motion._updateRotationMotion = false;
					}
				}

				// clamp velocity to min and max values
				var totalVelocityX:Number = checkBounds(velocityX, minVelocityX, maxVelocityX);
				var totalVelocityY:Number = checkBounds(velocityY, minVelocityY, maxVelocityY);
				
				motion.velocity.x = totalVelocityX;
				motion.velocity.y = totalVelocityY;
				
				// TODO : Move parent velocity code elsewhere?
				if (motion.parentVelocity != null)
				{
					totalVelocityX += motion.parentMotionFactor * motion.parentVelocity.x;
					totalVelocityY += motion.parentMotionFactor * motion.parentVelocity.y;
				}
				/*
				// interpolate between old and new velocity
				positionX = (motion.totalVelocity.x + totalVelocityX) * .5 * time;
				positionY = (motion.totalVelocity.y + totalVelocityY) * .5 * time;
				*/
				positionX = totalVelocityX * time;
				positionY = totalVelocityY * time;
				motion.totalVelocity.x = totalVelocityX;
				motion.totalVelocity.y = totalVelocityY;
				
				// update position based on average velocity
				motion.x = motion.x + positionX;
				motion.y = motion.y + positionY;
				
				if(!isNaN(positionRotation) && positionRotation != 0) { motion.rotation = motion.rotation + positionRotation; }
								
				if(motion.velocity.x != 0 || motion.velocity.y != 0)
				{
					frictionX = 0;
					frictionY = 0;
					
					if(motion.friction.length != 0)
					{
						frictionX = motion.friction.x;
						frictionY = motion.friction.y;
					}
					
					if (motion.parentFriction != null)
					{
						frictionX += motion.parentFriction.x;
						frictionY += motion.parentFriction.y;
					}
					
					if(frictionX != 0 || frictionY != 0)
					{
						if(frictionX == frictionY)
						{
							applyUniformFriction(frictionX * time, motion.velocity);
						}
						else
						{
							if(frictionX != 0)
							{
								motion.velocity.x = applyFriction(frictionX * time, velocityX);
							}
							
							if(frictionY != 0)
							{
								motion.velocity.y = applyFriction(frictionY * time, velocityY);
							}
						}
					}
				}
				// we reset this here.  If any hit areas are still causing a parent motion they will be reapplied
				//  during the hitTest phase which happens after this (see SystemPriorities.as).
				//motion.parentMotionFactor = 1;
				motion.parentRotationVelocity = 0;
				motion.parentAcceleration = null;
				motion.parentVelocity = null;
				motion.parentFriction = null;
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
			systemsManager.releaseNodeList(MotionNode);
			_nodes = null;
		}
		
		private var _nodes : NodeList;
	}
}
