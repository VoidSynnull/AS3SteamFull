package game.scenes.virusHunter.heart.systems {

	import com.greensock.TweenLite;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.components.hit.Radial;
	import game.scenes.virusHunter.heart.nodes.NerveNode;
	import game.systems.GameSystem;

	public class NerveHitSystem extends GameSystem {

		private var hits:DisplayObjectContainer;

		public function NerveHitSystem( hits:DisplayObjectContainer ) {

			super( NerveNode, updateNode, null, null );

			this.hits = hits;

		} //

		private function updateNode( node:NerveNode, time:Number ):void {

			// got hit.
			if ( node.damageTarget.damage > 0 ) {

				var id:int = node.nerve.id;

				// Tween the muscles to contracted state, tween the nerve to a rotated position.
				TweenLite.to( hits["muscle"+(2*id)], 2, { scaleX:1, scaleY:1 } );
				// There are two muscles for every nerve target:
				TweenLite.to( hits["muscle"+(2*id-1)], 2, { scaleX:1, scaleY:1, onComplete:nerveDone, onCompleteParams:[id] } );

				// remove the target.
				node.entity.remove(Radial);
				super.group.removeEntity(node.entity);

			} //

		} //

		// remove the nerve wall.
		private function nerveDone( id:int ):void {

			// the wall is called virus block because the virus entity also uses these walls to
			// stop the player; but thats at a different stage in the game, and the two don't
			// (currently) conflict.
			var wall:Entity = super.group.getEntityById( "virusBlock"+id );
			wall.remove(Radial);
			super.group.removeEntity(wall);

		} //

	} // End NerveHitSystem

} // End package