package game.scenes.carnival.shared.game3d.systems {

	import flash.geom.Vector3D;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Camera;
	import engine.components.Spatial;
	
	import game.scenes.carnival.shared.game3d.components.Camera3D;
	import game.scenes.carnival.shared.game3d.components.Frustum;
	import game.scenes.carnival.shared.game3d.components.Spatial3D;
	import game.scenes.carnival.shared.game3d.nodes.Camera3DNode;
	import game.scenes.carnival.shared.game3d.nodes.Spatial3DNode;

	/**
	 * WARNING: currently only supports one 3d camera at a time.
	 * All 3d objects must have their displays as children of this
	 * camera's display.
	 */
	public class Render3DSystem extends System {

		private var cameraList:NodeList;
		private var objList:NodeList;

		private var cameraNode:Camera3DNode;
		private var camera:Camera3D;
		private var frustum:Frustum;

		public function Render3DSystem() {

			super();

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.cameraList = systemManager.getNodeList( Camera3DNode );

			for( var node:Camera3DNode = this.cameraList.head; node; node = node.next ) {
				this.cameraNodeAdded( node );
			} //

			this.cameraList.nodeAdded.add( this.cameraNodeAdded );
			this.cameraList.nodeRemoved.add( this.cameraNodeRemoved );

			this.objList = systemManager.getNodeList( Spatial3DNode );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			systemManager.releaseNodeList( Camera3DNode );
			this.cameraList = null;

			systemManager.releaseNodeList( Spatial3DNode );

		} //

		override public function update( time:Number ):void {

			if ( !this.camera ) {
				// No camera defined.
				return;
			}

			if ( this.camera.axisAlignedCamera ) {

				for( var node:Spatial3DNode = this.objList.head; node; node = node.next ) {
					this.alignedUpdate( node );
				} //

			} else {

				for( node = this.objList.head; node; node = node.next ) {
					this.rotateUpdate( node );
				} //

			} //

		} //

		/**
		 * Update function for camera whose axes do not rotate.
		 */
		public function alignedUpdate( renderNode:Spatial3DNode ):void {

			var loc:Spatial3D = renderNode.spatial3D;

			loc._cx = loc.x - this.camera.location.x;
			loc._cy = loc.y - this.camera.location.y;
			loc.cz = loc.z - this.camera.location.z;
			loc.focusScale = this.frustum.focus_dist / ( this.frustum.focus_dist - loc._cz );

			if ( loc.enableScaling ) {
				renderNode.spatial.scale = loc.focusScale;
			} //

			if ( loc.enablePerspective ) {

				// LOL WE DON'T NEED THIS TODAY.
				renderNode.spatial.x = loc._cx * loc.focusScale;
				renderNode.spatial.y = loc._cy * loc.focusScale;

			} else {

				renderNode.spatial.x = loc._cx;
				renderNode.spatial.y = loc._cy;

			} //

		} //

		/**
		 * Update function for a camera that uses rotated axes.
		 */
		public function rotateUpdate( renderNode:Spatial3DNode ):void {

			var loc:Spatial3D = renderNode.spatial3D;

			this.setRotatedCoords( loc );

			if ( loc.enableScaling ) {

				renderNode.spatial.scale = loc.focusScale;

			} //

			if ( loc.enablePerspective ) {

				renderNode.spatial.x = loc._cx * loc.focusScale;
				renderNode.spatial.y = loc._cy * loc.focusScale;

			} else {

			} //

		} //

		/**
		 * Set camera coordinates for an axis-aligned camera. This is more efficient
		 * than the rotated version.
		 */
		/*public function setAlignedCoords( loc:Spatial3D ):void {

			loc._cx = loc.x - this.camera.location.x;
			loc._cy = loc.y - this.camera.location.y;
			loc._cz = loc.z - this.camera.location.z;

			loc.focusScale = this.frustum.focus_dist / ( this.frustum.focus_dist - loc._cz );

		} //*/

		/**
		 * Set camera coordinates for a rotated camera.
		 */
		public function setRotatedCoords( loc:Spatial3D ):void {

			var dx:Number = loc.x - this.camera.location.x;
			var dy:Number = loc.y - this.camera.location.y;
			var dz:Number = loc.z - this.camera.location.z;
			
			// Project onto the camera axes.
			var axis:Vector3D = this.camera.axisX;
			loc._cx = dx*axis.x + dy*axis.y + dz*axis.z;

			axis = this.camera.axisY;
			loc._cy = dx*axis.x + dy*axis.y + dz*axis.z;
			
			axis = this.camera.axisZ;
			loc.cz = dx*axis.x + dy*axis.y + dz*axis.z;

			loc.focusScale = this.frustum.focus_dist / ( this.frustum.focus_dist - loc._cz );

		} //

		public function cameraNodeRemoved( node:Camera3DNode ):void {

			if ( this.cameraNode == node ) {
				this.cameraNode = null;
				this.camera =  null;
				this.frustum = null;
			}

			node.camera._frustum = null;

		} //

		public function cameraNodeAdded( node:Camera3DNode ):void {

			this.cameraNode = node;
			this.camera = node.camera;

			this.camera._frustum = this.frustum = node.frustum;

		} //

	} // End Render3DSystem

} // End package