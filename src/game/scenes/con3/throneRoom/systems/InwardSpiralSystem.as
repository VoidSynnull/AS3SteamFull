package game.scenes.con3.throneRoom.systems
{
	import game.data.motion.time.FixedTimestep;
	import game.scenes.con3.throneRoom.nodes.InwardSpiralNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class InwardSpiralSystem extends GameSystem
	{
		public function InwardSpiralSystem()
		{
			super( InwardSpiralNode, updateNode, nodeAdded );
			this._defaultPriority = SystemPriorities.moveControl;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		private function nodeAdded( node:InwardSpiralNode ):void
		{
			var distanceX:Number = node.spatial.x - node.spiral.centerPoint.x;
			var distanceY:Number = node.spatial.y - node.spiral.centerPoint.y;
			
			node.spiral.radius = Math.sqrt( distanceX * distanceX + distanceY * distanceY );
			node.spiral.angle = Math.atan2( distanceY, distanceX );
		}
		
		private function updateNode( node:InwardSpiralNode, time:Number ):void
		{
			node.spatial.x = node.spiral.radius * Math.cos( node.spiral.angle ) + node.spiral.centerPoint.x;
			node.spatial.y = node.spiral.radius * Math.sin( node.spiral.angle ) + node.spiral.centerPoint.y;
			node.spatial.rotation += node.spiral.rotation;
			
			if( node.spiral.radius > 0 )
			{
				node.spiral.radius -= node.spiral.radiusStep;
				node.spiral.angle += node.spiral.angleStep;
			}
			else if( node.spiral.reachedCenter )
			{
				node.spiral.reachedCenter.dispatch( node.entity );
			}
		}
	}
}