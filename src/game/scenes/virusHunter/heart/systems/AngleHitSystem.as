package  game.scenes.virusHunter.heart.systems {
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Node;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.SceneCollisionNode;
	import game.scenes.virusHunter.heart.components.AngleHit;
	import game.scenes.virusHunter.heart.nodes.AngleHitNode;
	import game.util.EntityUtils;
	
	import org.flintparticles.common.displayObjects.Rect;

	public class AngleHitSystem extends System {

		private var hitPoint:Point;			// Used for some display hittests.
		private var _hits:NodeList;
		private var _colliders:NodeList;

		public function AngleHitSystem() {

			hitPoint = new Point( 0, 0 );

			super();
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;

		} //

		override public function addToEngine( systemManager:Engine ):void {

			super.addToEngine( systemManager );

			_colliders = systemManager.getNodeList( SceneCollisionNode );

			_hits = systemManager.getNodeList( AngleHitNode );
			_hits.nodeAdded.add( this.hitAdded );


		} //

		override public function update( time:Number ) : void {

			var node:SceneCollisionNode;

			for ( node = _colliders.head; node; node = node.next ) {

				if ( EntityUtils.sleeping( node.entity ) ) {
					continue;
				}
				updateNode( node, time );

			} // for

		} //

		// Repositions the angleHits when their spatials have changed.
		// No reason for such an expensive operation when it won't be used.
		/*private function updateHits( node:AngleHitNode, time:Number ):void {

			var angleHit:AngleHit = node.angleHit;
			var spatial:Spatial = node.spatial;

			for ( var hitNode:AngleHitNode = _hits.head; hitNode; hitNode = hitNode.next ) {

				if ( EntityUtils.sleeping( hitNode.entity ) ) {
					continue;
				}

				// Update cos,sin of angle hits. Checking the sleep might actually be slower than just
				// doing it for all nodes.
				angleHit.cos = Math.cos( spatial.rotation*Math.PI/180 );
				angleHit.sin = Math.sin( spatial.rotation*Math.PI/180 );

			} // end for-loop.

		} //*/

		private function updateNode( node:SceneCollisionNode, time:Number ):void {

			var motion:Motion = node.motion;
			//var spatial:Spatial = node.spatial;

			var hitNode:AngleHitNode;
			var angleHit:AngleHit;

			var dx:Number, dy:Number;
			var dot:Number, cross:Number;

			var hitDisplay:Display;

			for ( hitNode = _hits.head; hitNode; hitNode = hitNode.next ) {

				if ( hitNode.sleep.sleeping ) {
					continue;
				}

				angleHit = hitNode.angleHit;
				if ( angleHit.enabled == false ) {
					continue;
				}

				/**
				 * Optional display test for different parent containers.
				 * Note that we should actually loop on hitNodes, THEN on collision nodes for efficiency,
				 * but it was made this way first. Then we could keep the display result.
				 */
				hitDisplay = hitNode.entity.get( Display );
				if ( hitDisplay != null ) {

					if ( hitDisplay.displayObject.parent != node.display.displayObject.parent ) {

						hitPoint.setTo( 0, 0 );
						hitPoint = hitDisplay.displayObject.localToGlobal( hitPoint );
						hitPoint = node.display.displayObject.parent.globalToLocal( hitPoint );

						// NOTE: we still assume no rotations have been applied in the display chain.
						dx = motion.x - hitPoint.x;
						dy = motion.y - hitPoint.y;

					} else {

						dx = motion.x - hitNode.spatial.x;
						dy = motion.y - hitNode.spatial.y;

					} //

				} else {

					dx = motion.x - hitNode.spatial.x;
					dy = motion.y - hitNode.spatial.y;

				} //

				dot = dx*angleHit.cos + dy*angleHit.sin;
				if ( Math.abs(dot) > angleHit.height ) {
					continue;
				}

				cross = dx*angleHit.sin - dy*angleHit.cos;
				if ( Math.abs( cross ) > angleHit.thickness ) {
					continue;
				}

				// dot becomes vcross, why not?
				dot = motion.velocity.x*angleHit.sin - motion.velocity.y*angleHit.cos;
				if ( (cross > 0 && dot > 0) || ( cross < 0 && dot < 0 ) ) {
					// moving away from hit.
					continue;
				}

				// probably don't need to reposition, as long as the new velocity gets set.
				if ( cross > 0 ) {
					motion.x += angleHit.sin*( angleHit.thickness - cross );
					motion.y -= angleHit.cos*( angleHit.thickness - cross );
				} else {
					motion.x += angleHit.sin*( -angleHit.thickness - cross );
					motion.y -= angleHit.cos*( -angleHit.thickness - cross );
				} //

				// remember, dot is vcross now. harhar.
				dot *= ( 1 + angleHit.rebound );
				motion.velocity.x -= dot*angleHit.sin;
				motion.velocity.y += dot*angleHit.cos;

			} // end for-loop.

		} // updateNode()

		public function hitAdded( node:AngleHitNode ):void {

			var angleHit:AngleHit = node.angleHit;

			if ( angleHit.useSpatialAngle ) {
				var spatial:Spatial = node.spatial;

				angleHit.cos = Math.cos( spatial.rotation*Math.PI/180 );
				angleHit.sin = Math.sin( spatial.rotation*Math.PI/180 );
			} //

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			_hits.nodeAdded.remove( hitAdded );

			systemManager.releaseNodeList( SceneCollisionNode );
			systemManager.releaseNodeList( AngleHitNode );

			_hits = null;
			super.removeFromEngine( systemManager );

		} //

	} // class

} // package