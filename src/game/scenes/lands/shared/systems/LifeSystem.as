package game.scenes.lands.shared.systems {
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.nodes.LifeNode;
	
	import org.osflash.signals.Signal;

	public class LifeSystem extends System {
		
		private var lifeNodes:NodeList;

		/**
		 * onEntityDied entity
		 */
		public var onEntityDied:Signal;

		public function LifeSystem() {
			
			super();

			this.onEntityDied = new Signal( Entity );

		} //
		
		override public function update( time:Number ):void {
			
			var life:Life;
			
			for( var node:LifeNode = this.lifeNodes.head as LifeNode; node; node = node.next ) {

				if ( node.entity.sleeping ) {
					continue;
				}

				life = node.life;
				if ( !life.alive ) {
	
					continue;

				}

				if ( life._resetting ) {

					life._resetTimer -= time;
					if ( life._resetTimer <= 0 ) {
						life._hittable = true;
						life._resetting = false;
					}

				} //

				if ( life.curLife != life.targetLife ) {
					life.curLife += ( life.targetLife - life.curLife )*0.1;
					if ( life.curLife <= 0 ) {
						life.curLife = 0;
					}
				}

				if ( life.curLife <= 0 ) {

					life._hittable = false;
					life.alive = false;
					life._resetting = false;
					
					this.onEntityDied.dispatch( node.entity );

				} else if ( life.regenRate > 0 ) {

					life.targetLife += life.regenRate*time;
					if ( life.targetLife > life.maxLife ) {
						life.targetLife = life.maxLife;
					}

				}

			} // end for-loop.
			
		} //

		private function nodeRemoved( node:LifeNode ):void {

			// maybe a bad idea in case it gets re-added.
			//node.life.onDie.removeAll();

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.lifeNodes = systemManager.getNodeList( LifeNode );
			//this.lifeNodes.nodeRemoved.add( this.nodeRemoved );

		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {

			this.onEntityDied.removeAll();

			//this.lifeNodes.nodeRemoved.remove( this.nodeRemoved );
			this.lifeNodes = null;

		} //
		
	} // End LifeSystem
	
} // End package