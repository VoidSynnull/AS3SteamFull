package game.systems.motion
{
	

	import ash.tools.ListIteratingSystem;
	import flash.geom.Point;
	import game.systems.SystemPriorities;
	
	import engine.components.Spatial;
	
	import game.components.motion.RadiusControl;
	import game.nodes.motion.RadiusToControlNode;
	import game.util.GeomUtils;

	/**
	 * Positions entity torwards control while maintaining a distance(radius) from a center point.
	 * Rotation limits can be set, so entity does not pass the specified threshold.
	 */
	public class RadiusToTargetSystem extends ListIteratingSystem
	{
		public function RadiusToTargetSystem()
		{
			super(RadiusToControlNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
		}
			     
	    private function updateNode(node:RadiusToControlNode, time:Number):void
	    {
			var target:Spatial = node.target.target;
			var radiusControl:RadiusControl = node.radiusControl;
			
			var originX:Number = radiusControl.center.x;
			var originY:Number = radiusControl.center.y;
			
			if(radiusControl.cameraOffset)
			{
				originX = super.group.shellApi.sceneToGlobal(originX, "x");
				originY = super.group.shellApi.sceneToGlobal(originY, "y");
			}

			var angle:Number = GeomUtils.degreesBetween( target.x, target.y, originX, originY );
			angle = GeomUtils.degreeToRadian( checkLimits( radiusControl, angle ));
			
			node.spatial.x = radiusControl.center.x + Math.cos(angle) * radiusControl.radius;
			node.spatial.y = radiusControl.center.y + Math.sin(angle) * radiusControl.radius;
		}
		
		private function checkLimits( radiusControl:RadiusControl, degree:Number ):Number
		{
			if ( radiusControl.rotationRange )
			{
				if ( degree < radiusControl.rotationRange.x )
				{
					return radiusControl.rotationRange.x;
				}
				else if ( degree > radiusControl.rotationRange.y )
				{
					return radiusControl.rotationRange.y;
				}
			}
			return degree;
		}
	}	
}
