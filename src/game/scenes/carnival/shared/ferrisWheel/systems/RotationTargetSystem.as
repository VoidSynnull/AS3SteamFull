package game.scenes.carnival.shared.ferrisWheel.systems {
	
	import ash.core.Engine;
	import ash.core.Node;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Motion;
	
	import game.scenes.carnival.shared.ferrisWheel.components.RotationTarget;
	import game.scenes.carnival.shared.ferrisWheel.nodes.RotationTargetNode;
	import game.util.EntityUtils;

	public class RotationTargetSystem extends System {

		private const DEG_PER_RAD:Number = 180 / Math.PI;
		private const RAD_PER_DEG:Number = Math.PI/180;

		private var nodeList:NodeList;

		public function RotationTargetSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			for( var node:RotationTargetNode = this.nodeList.head; node; node = node.next ) {

				if ( EntityUtils.sleeping(node.entity) || node.target.enabled == false ) {
					continue;
				}

				if ( node.target.useVelocityTarget ) {

					this.doVelocityTarget( node, time );

				} else {

					this.doAngleTarget( node, time );

				} // end-if.

				

			} // for-loop

		} // update()

		private function doVelocityTarget( node:RotationTargetNode, time:Number ):void {

			var delta:Number = ( node.target.rotationVelocity - node.motion.rotationVelocity );
			var maxChange:Number =  node.target.maxAngularAcceleration*time

			if ( Math.abs( delta ) <= maxChange ) {

				node.motion.rotationVelocity = node.target.rotationVelocity;
				if ( node.target.autoRemove ) {
					node.entity.remove( RotationTarget );
				} else if ( node.target.autoDisable ) {
					node.target.enabled = false;
				} //

			} else {

				if ( delta > 0 ) {
					node.motion.rotationVelocity += maxChange;
				} else {
					node.motion.rotationVelocity -= maxChange;
				} //

			} //

		} //

		private function doAngleTarget( node:RotationTargetNode, time:Number ):void {

			var motion:Motion = node.motion;
			var target:RotationTarget = node.target;

			var delta:Number = target.rotation - node.spatial.rotation;

			if ( Math.abs(delta) < target.stopRadius && Math.abs( motion.rotationVelocity ) < 10 ) {

				motion.rotationAcceleration = 0;
				motion.rotationVelocity = 0;
				target.enabled = false;
				target.onReachedTarget.dispatch( node.entity );

				return;

			} //

			/**
			 * Don't change current direction of rotation to get to the goal.
			 */
			if ( delta < 0 && motion.rotationVelocity > 0 ) {
				delta += 360;
			} else if ( delta > 0 && motion.rotationVelocity < 0 ) {
				delta -= 360;
			}

			/**
			 * Rotation speed is low and won't reach the target within 3 seconds.
			 * Speed up instead.
			 */
			if ( Math.abs( motion.rotationVelocity ) < 20 && ( Math.abs( motion.rotationVelocity ) * 3.0 < Math.abs(delta) ) ) {

				if ( delta > 0 ) {
					motion.rotationAcceleration = target.maxAngularAcceleration;
				} else {
					motion.rotationAcceleration = -target.maxAngularAcceleration;
				}

				return;

			} //

			var stopDist:Number = ( 0.5*motion.rotationVelocity*motion.rotationVelocity / target.maxAngularAcceleration );

			// if sufficient velocity... this should actually work in both cases.
			// not sure about extreme velocities though.
			if ( delta > 0 ) {
				motion.rotationAcceleration = -0.5*motion.rotationVelocity*motion.rotationVelocity/delta;
			} else {
				motion.rotationAcceleration = 0.5*motion.rotationVelocity*motion.rotationVelocity/delta;
			} //

			/*if ( Math.abs(delta) >= stopDist ) {

				// if sufficient velocity...
				if ( delta > 0 ) {
					motion.rotationAcceleration = -0.5*motion.rotationVelocity*motion.rotationVelocity/delta;
				} else {
					motion.rotationAcceleration = 0.5*motion.rotationVelocity*motion.rotationVelocity/delta;
				} //

			} else {

			} // end-if.*/

		} //

		override public function addToEngine( systemManager:Engine ):void {
			
			this.nodeList = systemManager.getNodeList( RotationTargetNode );
			
			for( var node:RotationTargetNode = this.nodeList.head; node; node = node.next ) {
				this.nodeAdded( node );
			} //
			
			this.nodeList.nodeAdded.add( this.nodeAdded );
			this.nodeList.nodeRemoved.add( this.nodeRemoved );
	
		} //

		override public function removeFromEngine( systemManager:Engine ):void {
			
			systemManager.releaseNodeList( RotationTargetNode );

			this.nodeList = null;

		} //

		private function nodeAdded( node:RotationTargetNode ):void {
		} //

		private function nodeRemoved( node:RotationTargetNode ):void {
		} //

	} // End FerrisWheelSystem

} // End package