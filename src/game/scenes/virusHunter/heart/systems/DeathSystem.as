package game.scenes.virusHunter.heart.systems {

	import flash.display.BlendMode;
	
	import ash.core.Entity;
	import ash.core.Node;
	
	import engine.components.Display;
	
	import game.scenes.virusHunter.heart.components.DeathTimer;
	import game.scenes.virusHunter.heart.nodes.DeathNode;
	import game.systems.GameSystem;

	public class DeathSystem extends GameSystem {

		public function DeathSystem():void {

			super( DeathNode, updateNode, nodeAdded, nodeRemoved );

		} //

		private function updateNode( node:DeathNode, time:Number ):void {

			var death:DeathTimer = node.death;

			death.timer -= time;

			if ( death.timer <= 0 ) {

				group.removeEntity( node.entity );
				return;

			}

			if ( death.blinkRate > 0 ) {

				var lifePct:Number = ( death.timer / death.dieTime );

				var display:Display = node.entity.get( Display );
				if ( display ) {

					death.blinkTimer += ( 0.5/ Math.exp( death.timer ) );
					if ( death.blinkTimer > death.blinkRate ) {

						death.blinkOn = !death.blinkOn;
						if ( death.blinkOn ) {
							display.alpha = death.highAlpha*lifePct;
						} else {
							display.alpha = death.lowAlpha*lifePct;
						}
						death.blinkTimer = 0;

					} //

				} //

			} // End-blink.

		} // updateNode()

		private function nodeAdded( node:DeathNode ):void {

			var display:Display = node.entity.get( Display );
			if ( display ) {
				display.displayObject.blendMode = BlendMode.LAYER;
			}

			node.death.timer = node.death.dieTime;
			node.death.blinkTimer = 0;

		} //

		private function nodeRemoved( node:DeathNode ):void {
		} //

	} // End class

} // End package