package game.scenes.carnival.shared.ferrisWheel.systems {

	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.Node;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;

	import game.scenes.carnival.shared.ferrisWheel.components.FerrisArm;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisAxle;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisSwing;
	import game.scenes.carnival.shared.ferrisWheel.nodes.FerrisArmNode;
	import game.scenes.carnival.shared.ferrisWheel.nodes.FerrisSwingNode;
	import game.scenes.carnival.shared.ferrisWheel.nodes.FerrisWheelNode;

	public class FerrisWheelSystem extends System {

		private const DEG_PER_RAD:Number = 180 / Math.PI;
		private const RAD_PER_DEG:Number = Math.PI/180;

		private var armList:NodeList;
		private var swingList:NodeList;

		private var axleList:NodeList;

		public function FerrisWheelSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			for( var node:FerrisWheelNode = this.axleList.head; node; node = node.next ) {

				this.updateWheel( node, time );

			} //

			for( var armNode:FerrisArmNode = this.armList.head; armNode; armNode = armNode.next ) {

				this.updateArm( armNode );

			} //

			for( var swingNode:FerrisSwingNode = this.swingList.head; swingNode; swingNode = swingNode.next ) {

				this.updateSwing( swingNode, time );

			} //

		} //

		private function updateWheel( node:FerrisWheelNode, time:Number ):void {

			node.axle.theta = node.spatial.rotation*this.RAD_PER_DEG;
			node.axle._angularVelocity = node.motion.rotationVelocity*this.RAD_PER_DEG;

			//node.axle.x = node.spatial.x;
			//node.axle.y = node.spatial.y;

		} //

		private function updateArm( node:FerrisArmNode ):void {

			var axle:FerrisAxle = node.axle;
			var arm:FerrisArm = node.arm;

			var angle:Number = axle.theta + arm.axisAngle;
			var cos:Number = Math.cos( angle );
			var sin:Number = Math.sin( angle );

			var dx:Number = arm.radius*cos;
			var dy:Number = arm.radius*sin;

			var spatial:Spatial = node.spatial;

			spatial.x = axle.x + dx;
			spatial.y = axle.y + dy;
			spatial.rotation = this.DEG_PER_RAD*angle;

		} // updateArm()

		private function updateSwing( node:FerrisSwingNode, time:Number ):void {

			var axle:FerrisAxle = node.axle;
			var swing:FerrisSwing = node.swing;

			var armAngle:Number = axle.theta + swing.axisAngle;

			var dx:Number = swing.radius*Math.cos( armAngle );
			var dy:Number = swing.radius*Math.sin( armAngle );

			var spatial:Spatial = node.spatial;
			//var oldX:Number = spatial.x;
			//var oldY:Number = spatial.y;
			spatial.x = axle.x + dx;
			spatial.y = axle.y + dy;

			// TEMPORARY rotation values.
			spatial.rotation = -axle._angularVelocity*8*Math.sin( armAngle );

			/*var cos:Number = Math.cos( spatial.rotation*this.RAD_PER_DEG );
			var sin:Number = Math.sin( spatial.rotation*this.RAD_PER_DEG );

			var comX:Number = swing.centerOfMass.x*cos - swing.centerOfMass.y*sin;
			var comY:Number = swing.centerOfMass.x*sin + swing.centerOfMass.y*cos;

			dx += comX;
			dy += comY;*/

			//node.motion.rotationFriction = 0.1;
			//node.motion.rotationVelocity += time*( ( dy )*comX - ( dx*comY) )/( Math.sqrt(dx*dx+dy*dy)*100 );

		} // updateSwing()

		override public function addToEngine( systemManager:Engine ):void {

			this.axleList = systemManager.getNodeList( FerrisWheelNode );

			for( var ferrisNode:FerrisWheelNode = this.axleList.head; ferrisNode; ferrisNode = ferrisNode.next ) {
				this.axleAdded( ferrisNode );
			} //

			this.axleList.nodeAdded.add( this.axleAdded );
			this.axleList.nodeRemoved.add( this.axleRemoved );
			
			this.armList = systemManager.getNodeList( FerrisArmNode );
			this.armList.nodeAdded.add( this.armAdded );
			//this.armList.nodeRemoved.add( this.armRemoved );

			for( var armNode:FerrisArmNode = this.armList.head; armNode; armNode = armNode.next ) {
				this.armAdded( armNode );
			} //

			this.swingList = systemManager.getNodeList( FerrisSwingNode );
			this.swingList.nodeAdded.add( this.swingAdded );
			//this.swingList.nodeRemoved.add( this.swingRemoved );

			for( var node:FerrisSwingNode = this.swingList.head; node; node = node.next ) {
				this.swingAdded( node );
			} //

		} //

		override public function removeFromEngine( systemManager:Engine ):void {
			
			systemManager.releaseNodeList( FerrisWheelNode );
			systemManager.releaseNodeList( FerrisArmNode );
			systemManager.releaseNodeList( FerrisSwingNode );

			this.swingList = null;
			this.armList = null;
			this.axleList = null;

		} //

		private function axleAdded( node:FerrisWheelNode ):void {

			node.axle._angularVelocity = node.motion.rotationVelocity;

		} //

		/**
		 * Now might be a good time to do a search and remove any arms/swings that depend on this axle.
		 */
		private function axleRemoved( node:FerrisWheelNode ):void {
		} //

		private function armAdded( node:FerrisArmNode ):void {

			var arm:FerrisArm = node.arm;
			var spatial:Spatial = node.spatial;

			var dx:Number = spatial.x - node.axle.x;
			var dy:Number = spatial.y - node.axle.y;

			arm.radius = Math.sqrt( dx*dx + dy*dy );

			var dtheta:Number = Math.atan2( dy, dx ) - node.axle.theta;
			if ( dtheta > Math.PI ) {
				dtheta -= 2*Math.PI;
			} else if ( dtheta < -Math.PI ) {
				dtheta += 2*Math.PI;
			}

			arm.axisAngle = dtheta;

		} // armAdded()

		private function swingAdded( node:FerrisSwingNode ):void {

			var swing:FerrisSwing = node.swing;
			var spatial:Spatial = node.spatial;
			
			var dx:Number = spatial.x - node.axle.x;
			var dy:Number = spatial.y - node.axle.y;

			swing.radius = Math.sqrt( dx*dx + dy*dy );

			var dtheta:Number = Math.atan2( dy, dx ) - node.axle.theta;
			if ( dtheta > Math.PI ) {
				dtheta -= 2*Math.PI;
			} else if ( dtheta < -Math.PI ) {
				dtheta += 2*Math.PI;
			}

			swing.axisAngle = dtheta;

			if ( swing.centerOfMass == null ) {

				var d:DisplayObjectContainer = node.display.displayObject;
				var bounds:Rectangle = d.getBounds( d );

				swing.centerOfMass = new Point( bounds.left + node.spatial.width/2, bounds.top + node.spatial.height/2 );
			}

		} //

		/*private function armRemoved( node:FerrisArmNode ):void {
		} //

		private function swingRemoved( node:FerrisSwingNode ):void {
		} //*/

		/*private function updateSwing( node:FerrisSwingNode, time:Number ):void {
			
			var axle:FerrisAxle = node.axle;
			var swing:FerrisSwing = node.swing;
			
			var armAngle:Number = axle.theta + swing.axisAngle;
			
			var dx:Number = swing.radius*Math.cos( armAngle );
			var dy:Number = swing.radius*Math.sin( armAngle );
			
			var spatial:Spatial = node.spatial;
			spatial.x = axle.x + dx;
			spatial.y = axle.y + dy;
			
			var cos:Number = Math.cos( spatial.rotation*this.RAD_PER_DEG );
			var sin:Number = Math.sin( spatial.rotation*this.RAD_PER_DEG );
			
			var comX:Number = swing.centerOfMass.x*cos - swing.centerOfMass.y*sin;
			var comY:Number = swing.centerOfMass.x*sin + swing.centerOfMass.y*cos;
			
			//trace( comX + "," + comY );
			// acceleration = gravity component + rotational pull.
			//node.motion.rotationFriction = 0.1;
			node.motion.rotationVelocity = 10*( ( dy )*comX - ( dx*comY) )/( Math.sqrt(dx*dx+dy*dy) );
			
			if ( swing.platformSpatial ) {
				
				// UPDATE STUPID PLATFORM WITH STUPID MATH.
				
				swing.platformSpatial.x = spatial.x + swing.platformOffset.x * cos - swing.platformOffset.y * sin;
				swing.platformSpatial.y = spatial.y + swing.platformOffset.x * sin + swing.platformOffset.y * cos;
				swing.platformSpatial._rotation = spatial.rotation;
				
			} //
			
		} // updateSwing()*/

	} // End FerrisWheelSystem

} // End package