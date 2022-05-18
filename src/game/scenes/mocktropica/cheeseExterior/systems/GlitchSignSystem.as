package game.scenes.mocktropica.cheeseExterior.systems {

	import ash.core.Engine;
	
	import game.scenes.mocktropica.cheeseExterior.nodes.GlitchSignNode;
	import game.systems.GameSystem;

	public class GlitchSignSystem extends GameSystem {

		public function GlitchSignSystem() {

			super( GlitchSignNode, this.updateNode, null, null );

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );

		} //

		private function updateNode( node:GlitchSignNode, time:Number ):void {

			if ( node.timeline.playing == true ) {

				// don't do anything.

			} else {

				node.sign.timer += time;

				if ( node.sign.timer > 5 && Math.random() < 0.001 ) {

					// switch the sign.
					node.timeline.play();
					node.sign.timer = 0;

				} // end-if.

			} // end-if.

		} //

		/*private function nodeAdded( node:GlitchSignNode ):void {
		} //

		private function nodeRemoved( node:GlitchSignNode ):void {
		} //*/

		/*override public function removeFromEngine( engine:Engine ):void {

			super.removeFromEngine( engine );

		} //*/

	} // End class

} // End package