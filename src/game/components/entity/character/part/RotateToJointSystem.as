package game.components.entity.character.part
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.character.part.RotateToJointNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	
	public class RotateToJointSystem extends GameSystem
	{
		public function RotateToJointSystem()
		{
			super( RotateToJointNode, updateNode );
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
			super.onlyApplyLastUpdateOnCatchup = true;
		}
		
		private function updateNode( node:RotateToJointNode, time:Number ):void
		{
				// TO:DO - extend to not just be for the legs
			var joint:Entity = ( node.rotateToJoint.isFront) ? node.rig.getJoint( CharUtils.FOOT_FRONT ) : node.rig.getJoint( CharUtils.FOOT_BACK )
			var clip:MovieClip = node.rotateToJoint.instanceData.getInstanceFrom( node.display.displayObject ) as MovieClip;
			
			if( joint && clip )
			{
				var jointPosition:Point = EntityUtils.getPosition( joint );
				var degrees:Number = GeomUtils.degreesBetween( node.spatial.x, node.spatial.y, jointPosition.x, jointPosition.y );
				clip.rotation = degrees + 105;
			}	
		}
	}
}