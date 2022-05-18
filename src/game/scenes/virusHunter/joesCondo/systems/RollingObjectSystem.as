package game.scenes.virusHunter.joesCondo.systems {

	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import game.components.hit.Zone;
	import game.scenes.virusHunter.joesCondo.components.RollingObject;
	import game.scenes.virusHunter.joesCondo.nodes.RollingObjectNode;
	import game.systems.GameSystem;

	public class RollingObjectSystem extends GameSystem {

		public var DEG_PER_RAD:Number = 180 / Math.PI;

		public var pusher:Entity;			// default pusher. no support for multiple pushers for now.

		public function RollingObjectSystem() {

			super( RollingObjectNode, updateNode, nodeAdded, nodeRemoved );

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );

			pusher = group.getEntityById( "player" );

		} //

		override public function removeFromEngine( engine:Engine ):void {

			pusher = null;

			super.removeFromEngine( engine );

		} //

		// Don't need to actually update the node, just check for hits.
		private function updateNode( node:RollingObjectNode, time:Number ):void {

			var roller:RollingObject = node.roller;
			var motion:Motion = node.motion;

			// friction is always applied by the system opposite to motion.
			motion.friction.x = Math.abs( motion.velocity.x )*roller.friction;

			if ( node.collider.isHit ) {

				motion.rotationVelocity = DEG_PER_RAD*motion.velocity.x/roller.radius;

			} else {

				motion.rotationFriction = motion.rotationVelocity*roller.friction;

			} //

		} //

		private function nodeAdded( node:RollingObjectNode ):void {

			if ( node.roller.pusher == null ) {
				node.roller.pusher = pusher;
			}

		} //

		private function nodeRemoved( node:RollingObjectNode ):void {

			var zone:Zone = node.zoneHit;
			if ( zone != null ) {
				zone.inside.remove( updateNode );
			}
			node.roller.pusher = null;

		} //

	} // End class

} // End package