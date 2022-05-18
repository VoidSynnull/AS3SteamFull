package game.scenes.lands.shared.systems {

	/**
	 * makes an entity track to a given location.
	 */

	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.components.SimpleTarget;
	import game.scenes.lands.shared.nodes.SimpleTargetNode;

	public class SimpleTargetSystem extends System {

		private var targetNodes:NodeList;

		public function SimpleTargetSystem() {

			super();

		}

		override public function update( time:Number ):void {

			var sp:Spatial;
			var target:SimpleTarget;

			var dx:Number;
			var dy:Number;

			var d:Number;

			for( var node:SimpleTargetNode = this.targetNodes.head; node; node = node.next ) {

				sp = node.spatial;
				target = node.target;

				dx = target.targetX - sp.x;
				dy = target.targetY - sp.y;

				target.targetDistance = d = Math.sqrt( dx*dx + dy*dy );
				if ( d < 1 ) {

					target.vx += (-target.vx/10);
					target.vy += (-target.vy/10);

					sp.x += target.vx;
					sp.y += target.vy;

					continue;

				} //

				dx /= d;
				dy /= d;

				if ( d < target.slowRadius ) {

					var targetSpeed:Number = d/target.slowRadius;
					target.vx += ( targetSpeed*dx - target.vx ) / 10;
					target.vy += ( targetSpeed*dy - target.vy ) / 10;

				} else {

					target.vx += ( target.maxSpeed*dx - target.vx ) / 10;
					target.vy += ( target.maxSpeed*dy - target.vy ) / 10;

				} //

				sp.x += target.vx;
				sp.y += target.vy;
				if ( target.vx >= 0 ) {
					node.spatial.scaleX = 1;
				} else {
					node.spatial.scaleX = -1;
				}

			} // for()

		} // update()

		override public function addToEngine( systemManager:Engine ):void {

			this.targetNodes = systemManager.getNodeList( SimpleTargetNode );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			systemManager.releaseNodeList( SimpleTargetNode );

		} //

	} // class
	
} // package