package game.scenes.lands.shared.systems {

	/**
	 * 
	 * There are over 89 buttons in the land system -  to give each of them their own entity
	 * and input component is a big waste of resources. this collects groups of input
	 * while still binding their pause/play to the ash system - hopefully.
	 * 
	 * The only real purpose of this system is to automatically pause the events when
	 * the manager's entity goes to sleep, and to remove all events when the entity is destroyed.
	 * this ties things in with the ash system, though there could be a one frame delay between
	 * removing an event, and its dispatcher getting removed. this can be fixed if it becomes a problem.
	 * 
	 */

	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.nodes.InputManagerNode;

	public class InputManagerSystem extends System {

		private var nodeList:NodeList;

		public function InputManagerSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			// all we're doing here is syncing the event dispatchers with the entity sleep state.
			for( var node:InputManagerNode = this.nodeList.head; node; node = node.next ) {

				if ( node.entity.sleeping ) {

					if ( node.input.paused == false ) {
						node.input.paused = true;
					}

				} else {

					if ( node.input.paused == true ) {
						node.input.paused = false;
					}

				} //

			} //

		} //


		private function onNodeAdded( node:InputManagerNode ):void {

			if ( node.entity.sleeping ) {
				node.input.paused = true;
			}

		} //

		private function onNodeRemoved( node:InputManagerNode ):void {

			node.input.paused = true;

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.nodeList = systemManager.getNodeList( InputManagerNode );
			this.nodeList.nodeAdded.add( this.onNodeAdded );
			this.nodeList.nodeRemoved.add( this.onNodeRemoved );

			for( var node:InputManagerNode = this.nodeList.head; node; node = node.next ) {
				this.onNodeAdded( node );
			} //

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			for( var node:InputManagerNode = this.nodeList.head; node; node = node.next ) {

				node.input.destroy();

			} //

			systemManager.releaseNodeList( InputManagerNode );

		} //

	} // End class

} // End package