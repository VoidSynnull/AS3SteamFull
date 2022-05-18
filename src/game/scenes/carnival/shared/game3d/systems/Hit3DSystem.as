package game.scenes.carnival.shared.game3d.systems {
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.carnival.shared.game3d.components.Hit3D;
	import game.scenes.carnival.shared.game3d.geom.Shape3D;
	import game.scenes.carnival.shared.game3d.nodes.Hit3DNode;
	
	import org.osflash.signals.Signal;
	
	
	public class Hit3DSystem extends System {

		private var hitList:NodeList;

		/**
		 * onHit( Entity, Entity )
		 */
		//public var onHit:Signal;

		public function Hit3DSystem() {

			super();

			//this.onHit = new Signal( Entity, Entity );

		}

		override public function addToEngine( systemManager:Engine ):void {
			
			this.hitList = systemManager.getNodeList( Hit3DNode );
			
			for( var node:Hit3DNode = this.hitList.head; node; node = node.next ) {
				this.hitNodeAdded( node );
			} //

			this.hitList.nodeAdded.add( this.hitNodeAdded );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			systemManager.releaseNodeList( Hit3DNode );
			this.hitList = null;

			//this.onHit.removeAll();
			//this.onHit = null;

		} //

		override public function update( time:Number ):void {

			/*for( var node:Hit3DNode = this.hitList.head; node; node = node.next ) {
				shape = node.hit.shape;
				shape.x = node.spatial.x;
				shape.y = node.spatial.y;
				shape.z = node.spatial.z;
			} */

			var hit:Hit3D;
			var hitShape:Shape3D;
			var shape:Shape3D;

			var result:int;			// hit result
			/**
			 * Combine updating shape coordinates with hitTesting. Note the loop order ensures
			 * every shape has its coordinates updated before it is hittested.
			 */
			for( var hitNode:Hit3DNode = this.hitList.head; hitNode; hitNode = hitNode.next ) {

				hit = hitNode.hit;
				shape = hit.shape;

				shape.x = hitNode.spatial.x;
				shape.y = hitNode.spatial.y;
				shape.z = hitNode.spatial.z;

				for( var node:Hit3DNode = this.hitList.head; node != hitNode; node = node.next ) {

					if ( ( hit.hitCheck & node.hit.hitType ) == 0 && ( hit.hitType & node.hit.hitCheck ) == 0 ) {
						continue;
					}

					hitShape = node.hit.shape;

					result = shape.testHit( hitShape );
					if ( result == Shape3D.UNDEFINED ) {
						result = hitShape.testHit( shape );
					}

					if ( result == Shape3D.HIT ) {
						// Flash-Bang-Pow

						hit.onHit.dispatch( hitNode.entity, node.entity );
						node.hit.onHit.dispatch( node.entity, hitNode.entity );

					} //

				} //

			} //

		} // update()

		/*public function updateHit( hitNode:Hit3DNode ):void {
		} //*/

		public function hitNodeAdded( node:Hit3DNode ):void {

			node.hit.shape.x = node.spatial.x;
			node.hit.shape.y = node.spatial.y;
			node.hit.shape.z = node.spatial.z;

		} //

	} // End Hit3DSystem
	
} // End package