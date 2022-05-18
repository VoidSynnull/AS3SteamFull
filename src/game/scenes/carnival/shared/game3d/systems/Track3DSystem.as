package game.scenes.carnival.shared.game3d.systems {

	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	import game.scenes.carnival.shared.game3d.nodes.Track3DNode;

	public class Track3DSystem extends System {

		private var trackNodes:NodeList;

		public function Track3DSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			for( var node:Track3DNode = this.trackNodes.head as Track3DNode; node; node = node.next ) {

				if ( node.tracking.active == false ) {
					continue;
				}

				node.moveTarget.setTarget( node.tracking._trackSpatial.x, node.tracking._trackSpatial.y, node.tracking._trackSpatial.z );

			} // end for-loop.

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.trackNodes = systemManager.getNodeList( Track3DNode );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			this.trackNodes = null;

		} //

	} // End Track3DSystem

} // End package