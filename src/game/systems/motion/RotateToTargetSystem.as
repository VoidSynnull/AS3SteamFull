package game.systems.motion
{
	import engine.components.Spatial;
	
	import game.components.entity.Parent;
	import game.components.motion.RotateControl;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.motion.RotateToControlNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;

	/**
	 * Rotate entity torwards control.
	 * Rotation limits can be set, so entity does not rotate beyond the specified threshold.
	 */
	public class RotateToTargetSystem extends GameSystem
	{
		public function RotateToTargetSystem()
		{
			super(RotateToControlNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
			     
	    private function updateNode(node:RotateToControlNode, time:Number):void
	    {
			var target:Spatial = node.target.target;
			var rotateControl:RotateControl = node.rotateControl;
			var origin:Spatial = ( rotateControl.origin ) ? rotateControl.origin : node.spatial;

			if(rotateControl.lock)
			{
				return;
			}
			
			var initialRotation:Number = node.spatial.rotation;
			var degrees:int;
			
			if(isNaN(rotateControl.manualTargetRotation))
			{
				var originX:Number = origin.x;
				var originY:Number = origin.y;
				var targetX:Number = target.x;
				var targetY:Number = target.y;
				
				if( rotateControl.targetInLocal )
				{
					// adjust origin to be in local coordinates
					originX = super.group.shellApi.sceneToGlobal(originX, "x");
					originY = super.group.shellApi.sceneToGlobal(originY, "y");
				}
				else if ( rotateControl.originInLocal )
				{
					// adjust target to be in local coordinates
					targetX = super.group.shellApi.sceneToGlobal(targetX, "x");
					targetY = super.group.shellApi.sceneToGlobal(targetY, "y");
				}
				
				// determine degrees
				if( rotateControl.fromTargetToOrigin )
				{
					degrees = GeomUtils.degreesBetween( targetX, targetY, originX, originY );
				}
				else
				{
					degrees = GeomUtils.degreesBetween( originX, originY, targetX, targetY );
				}
				degrees = checkLimits(rotateControl, degrees);
			}
			else
			{
				degrees = rotateControl.manualTargetRotation;
			}
			
			// TODO :: This is temporary, want a standalone system that manages parent scale and rotation
			if( origin.scaleX < 0 )
			{
				degrees = 180 - degrees;
			}
			node.spatial.rotation = degrees;
			
			if( rotateControl.velocity || rotateControl.ease )
			{
				var angleDelta:Number = initialRotation - degrees;

				if(Math.abs(angleDelta) > 0)
				{
					if (angleDelta < -180)
					{
						node.spatial.rotation = initialRotation + 360;
						angleDelta += 360;
					}
					else if (angleDelta >= 180)
					{
						node.spatial.rotation = initialRotation - 360;
						angleDelta -= 360;
					}
				
					if(rotateControl.velocity)
					{				
						if (angleDelta > rotateControl.velocity * time)
						{
							node.spatial.rotation = initialRotation - rotateControl.velocity * time;
						}
						else if(angleDelta < -rotateControl.velocity * time)
						{
							node.spatial.rotation = initialRotation + rotateControl.velocity * time;
						}
						else
						{
							node.spatial.rotation = degrees;
						}
					}
					else if(rotateControl.ease)
					{
						if(Math.abs(angleDelta) > rotateControl.ease)
						{
							node.spatial.rotation = initialRotation - angleDelta * rotateControl.ease;
						}
						else
						{
							node.spatial.rotation = degrees;
						}
					}
				}
			}
			
			// TODO :: This is temporary, want a standalone system that manages paretn scale and rotation
			if(node.rotateControl.syncHorizontalFlipping)
			{
				var parentSpatial:Spatial = node.entity.get(Parent).parent.get(Spatial);
				if(parentSpatial.rotation < -90 || parentSpatial.rotation > 90){
					node.spatial.scaleX = -1;
					node.spatial.rotation = -degrees;
				}else{
					node.spatial.scaleX = 1;
				}
			}
		}
		
		private function checkLimits( rotateControl:RotateControl, degree:Number ):Number
		{
			if ( rotateControl.rotationRange )
			{
				if ( degree < rotateControl.rotationRange.x )
				{
					return rotateControl.rotationRange.x;
				}
				else if ( degree > rotateControl.rotationRange.y )
				{
					return rotateControl.rotationRange.y;
				}
			}
			return degree;
		}
	}	
}
