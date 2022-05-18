package game.systems.hit
{
	import flash.geom.Point;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.hit.DirectionalMoverNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class DirectionalMoverSystem extends GameSystem
	{
		public function DirectionalMoverSystem()
		{
			super(DirectionalMoverNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.moveControl;
		}
		
		public function updateNode (node:DirectionalMoverNode, time:Number):void
		{
			var directionX:Number = Math.cos(node.spatial.rotation * Math.PI / 180);
			var directionY:Number = -Math.sin(node.spatial.rotation * Math.PI / 180);
			
			node.mover.velocity = new Point(directionX * node.directionalMover.veloctiy, directionY * node.directionalMover.veloctiy);
			node.mover.acceleration = new Point(directionX * node.directionalMover.acceleration, directionY * node.directionalMover.acceleration);
		}
	}
}