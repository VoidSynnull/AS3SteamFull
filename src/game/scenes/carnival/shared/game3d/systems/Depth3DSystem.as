package game.scenes.carnival.shared.game3d.systems {

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.carnival.shared.game3d.components.Camera3D;
	import game.scenes.carnival.shared.game3d.components.Frustum;
	import game.scenes.carnival.shared.game3d.components.Spatial3D;
	import game.scenes.carnival.shared.game3d.nodes.Camera3DNode;
	import game.scenes.carnival.shared.game3d.nodes.Spatial3DNode;
	import game.systems.SystemPriorities;

	/**
	 * For now this only allows for one 3d camera at a time. If you need another... you'll have to change
	 * it yourself.
	 */
	public class Depth3DSystem extends System {

		private var cameraList:NodeList;

		private var cameraNode:Camera3DNode;
		private var camera:Camera3D;
		private var view:DisplayObjectContainer;

		private var frustum:Frustum;


		private var depthNodes:NodeList;

		/**
		 * When looking at a DisplayObjectContainer, the Entity system cannot get from the container to the ZDepth component.
		 * This provides the mapping displayObjects -> ZDepth components.
		 */
		private var hash:Dictionary;

		public function Depth3DSystem() {

			super._defaultPriority = SystemPriorities.render;

		}

		override public function addToEngine( systemManager:Engine ):void {

			super.addToEngine( systemManager );

			// Note: useWeakKeys is important here to prevent memory leaks.
			this.hash = new Dictionary( true );

			this.cameraList = systemManager.getNodeList( Camera3DNode );

			for( var camNode:Camera3DNode = this.cameraList.head; camNode; camNode = camNode.next ) {
				this.cameraNodeAdded( camNode );
			} //			
			this.cameraList.nodeAdded.add( this.cameraNodeAdded );

			this.depthNodes = systemManager.getNodeList( Spatial3DNode );
			this.depthNodes.nodeAdded.add( this.zNodeAdded );

			for( var node:Spatial3DNode = this.depthNodes.head; node; node = node.next ) {
				this.zNodeAdded( node as Spatial3DNode );
			}

		} //

		override public function update( time:Number ):void {

			if ( this.view ) {
				this.updateDepths();
			}

		} //

		/**
		 * I was forced to introduce a lot of special code in here, to check that the clip wasn't taken off its parent,
		 * and that the Display.displayObject wasn't reassigned to a new displayObject.
		 * 
		 * Disallowing these situations could improve the code slightly; but at the cost of usability.
		 */
		public function updateDepths():void {

			var zNode:Spatial3DNode;

			var loc:Spatial3D;
			var clip:DisplayObjectContainer;

			for ( zNode = depthNodes.head; zNode; zNode = zNode.next ) {

				loc = zNode.spatial3D;
				clip = zNode.display.displayObject;

				if ( !clip ) {

					// we lost the display or its parent somewhere along the way.
					// need to stop updating depths.
					loc._displayObject = null;
					loc._updateDepth = false;

				} else if ( loc._displayObject != clip ) {

					// the displayObject has changed, which means the hash is now out of date.
					loc._displayObject = clip;
					loc._updateDepth = true;			// try to update.
					this.view.removeChild( clip );
					this.hash[ clip ] = loc;			// store a hash from displayObject->ZDepth

				} else if ( loc._updateDepth ) {

					// need to remove this from the display list because it will mess up the search algorithm.
					// can't do a binary search if elements in the list are in the wrong places.
					this.view.removeChild( clip );

				}

			} //

			//trace( "-----" );
			for ( zNode = depthNodes.head; zNode; zNode = zNode.next ) {

				if ( zNode.spatial3D._updateDepth ) {

					this.binaryInsert( zNode.display.displayObject, this.view, zNode.spatial3D._cz );
					zNode.spatial3D._updateDepth = false;

				}

			} // end for-loop.

			/*trace( "----" );
			for ( zNode = depthNodes.head; zNode; zNode = zNode.next ) {
				trace( "Z: " + zNode.spatial3D._cz + "  INDEX: " + ( this.view ).getChildIndex( zNode.display.displayObject ) );
			} //*/

		} // end update()

		private function binaryInsert( display:DisplayObject, parent:DisplayObjectContainer, z:Number ):void {

			var min:int = 0;
			var max:int = parent.numChildren-1;

			var mid:int;

			while ( min <= max ) {

				mid = ( min + max ) / 2;

				if ( this.hash[ parent.getChildAt(mid) ]._cz < z ) {

					// display belongs below the midpoint.
					max = mid - 1;

				} else {

					// display belongs above the mid-point.
					min = mid + 1;

				} //

			} // end-while.

			//trace( "ZVALUe: " + z + "   aDDED AT: " + min );
			parent.addChildAt( display, min );

		} // binaryInsert()

		private function zNodeAdded( node:Spatial3DNode ):void {

			var display:DisplayObjectContainer = node.display.displayObject;

			if ( !display || !display.parent ) {

				node.spatial3D._updateDepth = false;
				node.spatial3D._displayObject = null;

			} else {

				this.hash[ display ] = node.spatial3D;
				node.spatial3D._updateDepth = false;
				node.spatial3D._displayObject = display;

				if ( this.view ) {
					this.binaryInsert( display, this.view, node.spatial3D._cz );
				}

			} //

		} //

		/**
		 * Remember, only one camera3D can be active at a time. (for now)
		 */
		public function cameraNodeAdded( node:Camera3DNode ):void {
			
			this.cameraNode = node;
			this.camera = node.camera;
			this.frustum = node.frustum;
			this.view = node.display.displayObject;
			
		} //

		override public function removeFromEngine( systemManager:Engine ) : void {
	
			//this._zNodes.nodeAdded.remove( this.zNodeAdded );

			systemManager.releaseNodeList( Spatial3DNode );

			systemManager.releaseNodeList( Camera3DNode );
			this.cameraList = null;

			//this._controlNodes = null;
			this.depthNodes = null;

			super.removeFromEngine(systemManager);

		} //

	} // class

} // package