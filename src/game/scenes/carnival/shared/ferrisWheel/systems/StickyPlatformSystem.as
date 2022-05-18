package game.scenes.carnival.shared.ferrisWheel.systems {
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.nodes.entity.collider.PlatformCollisionNode;
	import game.scenes.carnival.shared.ferrisWheel.components.StickyPlatform;
	import game.scenes.carnival.shared.ferrisWheel.nodes.StickyPlatformNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;

	public class StickyPlatformSystem extends System {

		private var nodeList:NodeList;

		private var colliders:NodeList;

		public function StickyPlatformSystem() {

			super();
			super._defaultPriority = SystemPriorities.moveComplete;

		}

		override public function update( time:Number ):void {

			var spatial:Spatial;
			var sticky:StickyPlatform;

			for( var node:StickyPlatformNode = this.nodeList.head; node; node = node.next ) {

				if ( EntityUtils.sleeping( node.entity  ) ) {
					continue;
				}

				sticky = node.sticky;
				spatial = node.spatial;

				for( var collider:PlatformCollisionNode = this.colliders.head; collider; collider = collider.next ) {

					if ( collider.currentHit.hit != node.entity ) {
						continue;
					}

					sticky._velocity.setTo( sticky.motionFactorX*( spatial.x - sticky.prevX )/time, sticky.motionFactorY*( spatial.y - sticky.prevY )/time );
					collider.motion.parentVelocity = sticky._velocity;

				} //

				sticky.prevX = spatial.x;
				sticky.prevY = spatial.y;

			} // for-loop.

		} // update()

		override public function addToEngine( systemManager:Engine ):void {

			this.nodeList = systemManager.getNodeList( StickyPlatformNode );

			for( var node:StickyPlatformNode = this.nodeList.head; node; node = node.next ) {
				this.nodeAdded( node );
			} //
			this.nodeList.nodeAdded.add( this.nodeAdded );

			this.colliders = systemManager.getNodeList( PlatformCollisionNode );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {
			
			systemManager.releaseNodeList( StickyPlatformNode );
			this.nodeList = null;

		} //

		private function nodeAdded( node:StickyPlatformNode ):void {

			node.sticky.prevX = node.spatial.x;
			node.sticky.prevY = node.spatial.y;

			/*
			dx = swing.platformSpatial.x - spatial.x;
			dy = swing.platformSpatial.y - spatial.y;
			
			var cos:Number = Math.cos( spatial.rotation * this.RAD_PER_DEG );
			var sin:Number = Math.sin( spatial.rotation * this.RAD_PER_DEG );
			
			swing.platformOffset = new Point( dx*cos + dy*sin, dy*cos - dx*sin );
			*/

		} //

	} // End StickToEntitySystem

} // End package