package game.scenes.carnival.shared.game3d.systems {
	
	import flash.geom.Vector3D;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.carnival.shared.game3d.components.ConstantForce3D;
	import game.scenes.carnival.shared.game3d.components.Motion3D;
	import game.scenes.carnival.shared.game3d.nodes.ConstantForceNode;

	public class ConstantForceSystem extends System {

		private var forceNodes:NodeList;

		public function ConstantForceSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			var force:ConstantForce3D;
			var accel:Vector3D;
	
			for( var node:ConstantForceNode = this.forceNodes.head as ConstantForceNode; node; node = node.next ) {

				accel = node.motion.acceleration;
				force = node.force;
	
				accel.x += force.x;
				accel.y += force.y;
				accel.z += force.z;
				
			} //

		} //

		/*private function nodeAdded( node:Motion3DNode ):void {

			//node.display.displayObject.z = node.zdepth.z;

		} //*/

		override public function addToEngine( systemManager:Engine):void {

			this.forceNodes = systemManager.getNodeList( ConstantForceNode );
			//this.motionNodes.nodeAdded.add( this.nodeAdded );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			systemManager.releaseNodeList( ConstantForceNode );
			this.forceNodes = null;

		} //

	} // End ConstantForceSystem

} // End package