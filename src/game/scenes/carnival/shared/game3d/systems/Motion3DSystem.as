package game.scenes.carnival.shared.game3d.systems {

	import flash.geom.Vector3D;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.carnival.shared.game3d.components.Motion3D;
	import game.scenes.carnival.shared.game3d.components.Spatial3D;
	import game.scenes.carnival.shared.game3d.nodes.Motion3DNode;

	public class Motion3DSystem extends System {

		private var motionNodes:NodeList;

		public function Motion3DSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			for( var node:Motion3DNode = this.motionNodes.head as Motion3DNode; node; node = node.next ) {

				this.updateNode( node, time );

			} //

		} //

		/**
		 * Going to skip verlet for the first version. can alter it later if it looks bad.
		 */
		public function updateNode( node:Motion3DNode, time:Number ):void {

			var motion:Motion3D = node.motion;
			var spatial:Spatial3D = node.spatial;

			var velocity:Vector3D = motion.velocity;

			/**
			 * Technically should add some checks here so the momentum from drag doesnt go beyond abs(vel).
			 * Providing time < 1, this shouldn't happen.. but we'll see.
			 * Yawn.
			 */
			velocity.x += ( motion.acceleration.x - motion.drag*velocity.x )*time;
			velocity.y += ( motion.acceleration.y - motion.drag*velocity.y )*time;
			velocity.z += ( motion.acceleration.z - motion.drag*velocity.z )*time;

			//velocity.x -= motion.friction*velocity.x*time;
			//velocity.y -= motion.friction*velocity.y*time;
			//velocity.z -= motion.friction*velocity.z*time;

			// zero the acceleration.
			motion.acceleration.setTo( 0, 0, 0 );

			spatial.x += velocity.x*time;
			spatial.y += velocity.y*time;
			spatial.z += velocity.z*time;

		} //

		/*private function nodeAdded( node:Motion3DNode ):void {

			//node.display.displayObject.z = node.zdepth.z;

		} //*/

		override public function addToEngine( systemManager:Engine):void {

			this.motionNodes = systemManager.getNodeList( Motion3DNode );
			//this.motionNodes.nodeAdded.add( this.nodeAdded );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			this.motionNodes.nodeAdded.removeAll();
			this.motionNodes = null;

		} //

	} // End Motion3DSystem

} // End package