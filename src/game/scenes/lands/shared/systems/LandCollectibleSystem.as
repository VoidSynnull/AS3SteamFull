package game.scenes.lands.shared.systems {

	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.data.motion.time.FixedTimestep;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.nodes.LandCollectibleNode;
	
	import org.osflash.signals.Signal;

	public class LandCollectibleSystem extends System {

		private var _collectibles:NodeList;

		/**
		 * gives entity collected.  onCollected( e:Entity, LandCollectible )
		 */
		public var onCollected:Signal;

		public function LandCollectibleSystem( landGroup:LandGroup ) {

			super();

			landGroup.onLeaveScene.add( this.destroyCollectibles );

			// need these or the system won't sync with MovieClipHitSystem
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;

			this.onCollected = new Signal( Entity );

		} //

		override public function addToEngine( systemManager:Engine ):void {
			
			super.addToEngine( systemManager );
			
			this._collectibles = systemManager.getNodeList( LandCollectibleNode );
		//	this._collectibles.nodeAdded.add( this.nodeAdded );

		} //

		override public function update( time:Number ) : void {

			for( var node:LandCollectibleNode = this._collectibles.head; node; node = node.next ) {

				if ( node.entity.sleeping ) {

					continue;

				} else if ( node.hit.isHit ) {

					// necessary to put the entity to sleep or else it can multiple-trigger while waiting to be removed,
					// due to fixed time-step triggering this update() function multiple times.
					node.entity.sleeping = true;
					this.onCollected.dispatch( node.entity, node.collectible );
					this.group.removeEntity( node.entity, true );

				} //

			} // end-for

		} //

		public function destroyCollectibles():void {

			for( var node:LandCollectibleNode = this._collectibles.head; node; node = node.next ) {

				this.group.removeEntity( node.entity, true );

			} //

		} //

		/*private function updateNode( node:LandCollectibleNode, time:Number ):void {

			// collect the node.
			if ( node.hit.isHit ) {
			} // end-if.

		} // updateNode()*/

		/*public function nodeAdded( node:LandCollectibleNode ):void {

			node.si.reached.add( this.collectEntity );

		} //*/

		/*private function collectEntity( interactor:Entity, interactedWith:Entity ):void {

			this.onCollected.dispatch( interactedWith );

		} //*/

		override public function removeFromEngine( systemManager:Engine ):void {

			systemManager.releaseNodeList( LandCollectibleNode );
			
		} //

	} // class

} // package