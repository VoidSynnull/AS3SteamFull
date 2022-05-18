package game.systems.entity.character.part
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.character.part.item.ItemMotion;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.character.part.ItemMotionNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;

	
	/**
	 * The Dress System deals with character pants parts that have a Dress component. The Dress component tells
	 * the system that the character's pants part is a dress that needs to be scaled and rotated depending on
	 * foot/leg position and character speed, respectively.
	 * 
	 * @author Drew Martin
	 */
	public class ItemMotionSystem extends GameSystem
	{
		public function ItemMotionSystem()
		{
			super(ItemMotionNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
			super.onlyApplyLastUpdateOnCatchup = true;
		}
		
		private function updateNode(node:ItemMotionNode, time:Number):void
		{
			// check state to determine which motion should be used, ROTATE_TO_SHOULDER is default state
			if( node.itemMotion.state == ItemMotion.ROTATE_TO_SHOULDER )
			{
				rotateToShouder( node );
			}
			else if( node.itemMotion.state == ItemMotion.SPIN )
			{
				spinItem( node );
			}
			else
			{
				//do nothing after halting other motion
			}
		}
		
		/**
		 * Determine angle between item & shoulder joint and applies it to item part rotation.
		 * Offsets angle by 90 degrees.
		 */
		private function rotateToShouder( node:ItemMotionNode ):void
		{
			var joint:Entity = ( node.itemMotion.isFront) ? node.rig.getJoint( CharUtils.ARM_FRONT ) : node.rig.getJoint( CharUtils.ARM_BACK )
			if( joint )
			{
				var shoulderPosition:Point = EntityUtils.getPosition(joint);
				var degrees:Number = GeomUtils.degreesBetween( node.spatial.x, node.spatial.y, shoulderPosition.x, shoulderPosition.y );
				node.spatial.rotation = degrees + 270;
			}	
		}
		
		/**
		 * Spin item 
		 */
		private function spinItem( node:ItemMotionNode ):void
		{
			var spatial:Spatial = node.spatial;
			
			// add rotation & check spinCount
			if( node.itemMotion.isSpinForward )
			{
				spatial.rotation -= node.itemMotion.spinSpeed;
				if ( node.itemMotion.spinCount > 0 )
				{
					if( spatial.rotation <= -180 )
					{
						node.itemMotion.spinCount--;
					}
				}
			}
			else
			{
				spatial.rotation += node.itemMotion.spinSpeed;
				if ( node.itemMotion.spinCount > 0 )
				{
					if( spatial.rotation >= 180 )
					{
						node.itemMotion.spinCount--;
					}
				}
			}
			
			// determine when to end spinning
			if ( node.itemMotion.spinCount == 0 )
			{
				if ( Math.abs(spatial.rotation % 360) < ( Math.abs(node.itemMotion.spinSpeed) * 1.5 ) )
				{
					node.itemMotion.state = ItemMotion.ROTATE_TO_SHOULDER;
				}
			}
		}
	}
}
