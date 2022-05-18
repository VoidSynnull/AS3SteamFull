package game.scenes.mocktropica.robotBossBattle.systems {

	import flash.geom.Vector3D;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.robotBossBattle.components.Motion3D;
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthNumber;
	import game.scenes.mocktropica.robotBossBattle.nodes.Motion3DNode;

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
			var spatial:Spatial = node.spatial;
			var zdepth:ZDepthNumber = node.zdepth;

			var velocity:Vector3D = motion.velocity;

			velocity.x -= motion.friction*velocity.x*time;
			velocity.y -= motion.friction*velocity.y*time;
			velocity.z -= motion.friction*velocity.z*time;

			if ( motion.acceleration.length > motion.maxAcceleration ) {
				motion.acceleration.scaleBy( motion.maxAcceleration / motion.acceleration.length );
			}

			velocity.x += motion.acceleration.x*time;
			velocity.y += motion.acceleration.y*time;
			velocity.z += motion.acceleration.z*time;

			// zero the acceleration.
			motion.acceleration.setTo( 0, 0, 0 );

			spatial.x += velocity.x*time;
			spatial.y += velocity.y*time;

			zdepth.z += velocity.z*time;
			// z,z,z,z,z
			//node.display.displayObject.z = zdepth.z += velocity.z*time;

			if ( motion.omega != 0 ) {
				spatial.rotation += (180/Math.PI)*motion.omega*time;
			}

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