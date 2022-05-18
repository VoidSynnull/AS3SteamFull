package game.scenes.virusHunter.condoInterior.systems {

	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.condoInterior.nodes.SimpleUpdateNode;
	import game.util.EntityUtils;

	// For simple frame-update events that don't require complex systems/components
	// but still need to respond to game pausing, GameSystem functionality etc.
	// Just like an old AS2 onEnterFrame for the main scene.

	public class SimpleUpdateSystem extends System {

		private var updateList:NodeList;

		public function SimpleUpdateSystem():void {

			super();

		} //

		override public function addToEngine( systemManager:Engine ):void {
			
			this.updateList = systemManager.getNodeList( SimpleUpdateNode );
			this.updateList.nodeAdded.add( this.nodeAdded );

			for( var node:SimpleUpdateNode = this.updateList.head; node; node = node.next ) {
				this.nodeAdded( node );
			}

		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {

			this.updateList.nodeAdded.remove( this.nodeAdded );

			systemManager.releaseNodeList( SimpleUpdateNode );

			this.updateList = null;

		} //

		override public function update(time:Number):void {

			for( var node:SimpleUpdateNode = this.updateList.head; node; node = node.next ) {

				if ( EntityUtils.sleeping(node.entity) || node.updater.paused ) {
					continue;
				}

				node.updater.update( time );

			} //

		} //

		private function nodeAdded( node:SimpleUpdateNode ):void {

			var sleep:Sleep = node.entity.get( Sleep );
			if ( sleep == null ) {
				// Since this is a general updater, ignore offscreen sleep events.
				// We add the Sleep directly because if we don't, the sleep check
				// will just go to the parent, which is wasted recursion.
				node.entity.add( new Sleep( false, true ) );
			} //

		} //

	} // End class

} // End package