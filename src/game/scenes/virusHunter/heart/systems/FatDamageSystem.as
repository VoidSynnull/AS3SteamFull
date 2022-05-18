package game.scenes.virusHunter.heart.systems {

	import flash.display.MovieClip;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.heart.components.AngleHit;
	import game.scenes.virusHunter.heart.components.HeartFat;
	import game.scenes.virusHunter.heart.nodes.FatDamageNode;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.systems.GameSystem;
	import game.util.TimelineUtils;

	public class FatDamageSystem extends GameSystem {

		public function FatDamageSystem():void {

			super( FatDamageNode, updateNode, null, null );

		} //

		private function updateNode( node:FatDamageNode, time:Number ):void {

			if ( node.damage.damage > 0 ) {
				killFat( node );
			}

		} // updateNode()

		private function killFat( node:FatDamageNode ):void {

			var anim:MovieClip = node.swapDisplay.saveClip as MovieClip;
			node.swapDisplay.swap();

			// this should active the fat death system.
			TimelineUtils.convertClip( anim, this.group, node.entity );

			// if we remove the display or entity, the entire display will be taken out
			// automatically by the rendering system.
			node.entity.remove( DamageTarget );
			//node.entity.remove( HeartFat );
			node.entity.remove( MovieClipHit );

		} //

	} // End class

} // End package