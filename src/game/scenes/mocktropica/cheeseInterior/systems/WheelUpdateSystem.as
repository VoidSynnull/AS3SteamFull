package game.scenes.mocktropica.cheeseInterior.systems {

	import ash.core.Engine;
	
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.cheeseInterior.components.Wheel;
	import game.scenes.mocktropica.cheeseInterior.nodes.WheelUpdateNode;
	import game.systems.GameSystem;

	/**
	 * Because the exact time displayed isn't very important, not bothering to work
	 * through the date object. 
	 */
	public class WheelUpdateSystem extends GameSystem {

		public function WheelUpdateSystem() {

			super( WheelUpdateNode, this.updateNode, this.nodeAdded, this.nodeRemoved );

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );

		} //

		private function updateNode( node:WheelUpdateNode, time:Number ):void {

			var wheel:Wheel = node.wheel;

			if ( wheel.omega == 0 ) {

			} else {

				wheel.omega *= wheel.drag;
				if ( Math.abs( wheel.omega ) < wheel.minOmega ) {

					wheel.omega = 0;
					wheel.onWheelStop.dispatch( node.entity, wheel );

				} else {
					wheel.angle += wheel.omega*time;
				}

			} // end-if.

			node.spatial.rotation = wheel.angle * wheel.DEG_PER_RAD;

		} //

		private function nodeAdded( node:WheelUpdateNode ):void {
		} //

		private function nodeRemoved( node:WheelUpdateNode ):void {

			node.wheel.onWheelStop.removeAll();

		} //

		/*override public function removeFromEngine( engine:Engine ):void {

			super.removeFromEngine( engine );

		} //*/

	} // End class

} // End package