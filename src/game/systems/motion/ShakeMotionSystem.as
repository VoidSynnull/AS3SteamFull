package game.systems.motion
{
	import ash.core.Entity;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import flash.geom.Point;
	import game.components.motion.ShakeMotion;
	import game.nodes.motion.ShakeMotionNode;
	import game.systems.SystemPriorities;
	
	import game.util.EntityUtils;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	import ash.tools.ListIteratingSystem;

	public class ShakeMotionSystem extends ListIteratingSystem
	{
		public function ShakeMotionSystem()
		{
			super( ShakeMotionNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:ShakeMotionNode, time:Number):void
	    {
			var shake:ShakeMotion = node.shakeMotion;
			
			if ( shake.active )
			{
				if ( shake.counter > 0 )
				{
					shake.counter -= time;
				}
				else
				{
					var targetPosition:Point = shake.shakeZone.getLocation();
					node.spatialAddition.x = targetPosition.x;
					node.spatialAddition.y = targetPosition.y;
					
					shake.counter = ( isNaN(shake.speed) ) ? ANIMATION_SPEED : shake.speed;
				}
			}
		}
		
		/**
		 * Adds components necessary to get processed by ShakeMotionSystem.
		 * Returns the ShakeMotion component, which maybe require furtehr param settings.
		 * @param	entity
		 * @param	group
		 * @param	shakeMotion
		 * @return
		 */
		public function configEntity( entity:Entity ):void
		{
			if ( !entity.get( ShakeMotion ) )
			{
				entity.add( new ShakeMotion() );
			}
			if ( !entity.get( SpatialAddition ) )
			{
				entity.add( new SpatialAddition() );
			}
			if ( !entity.get( Spatial ) )
			{
				entity.add( new Spatial() );
			}
		}
		
		private const ANIMATION_SPEED:Number = .032		// .032;  // This is the speed of animation per second.  We wait this length of time before advancing the timeline.
	}
}
