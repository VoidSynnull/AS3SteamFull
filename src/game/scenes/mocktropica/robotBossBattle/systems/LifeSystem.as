package game.scenes.mocktropica.robotBossBattle.systems {
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;

	import game.scenes.mocktropica.robotBossBattle.components.Life;
	import game.scenes.mocktropica.robotBossBattle.nodes.LifeNode;
	
	public class LifeSystem extends System {

		private var lifeNodes:NodeList;

		public function LifeSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			var life:Life;

			for( var node:LifeNode = this.lifeNodes.head as LifeNode; node; node = node.next ) {

				life = node.life;
				if ( !life.alive ) {

					continue;

				} else if ( life.resetting ) {

					life.hitResetTimer -= time;
					if ( life.hitResetTimer <= 0 ) {
						life._hittable = true;
						life.resetting = false;
					}
					
				} else if ( life._hittable && life.life <= 0 ) {

					life._hittable = false;
					life.alive = false;
					life.resetting = false;

					life.onDie.dispatch( node.entity );

				} // end-if.

			} // end for-loop.

		} //

		override public function addToEngine( systemManager:Engine ):void {
			
			this.lifeNodes = systemManager.getNodeList( LifeNode );

		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			this.lifeNodes = null;
			
		} //

	} // End LifeSystem
	
} // End package