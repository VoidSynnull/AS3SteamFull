package game.scenes.lands.shared.systems {
	
	import flash.display.DisplayObject;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.components.BarComponent;
	import game.scenes.lands.shared.nodes.BarNode;

	public class BarSystem extends System {
		
		private var barNodes:NodeList;
		
		public function BarSystem() {

			super();

		} //
		
		override public function update( time:Number ):void {

			var bar:BarComponent;
			var barClip:DisplayObject;

			var dataObj:*;

			for( var node:BarNode = this.barNodes.head as BarNode; node; node = node.next ) {

				if ( node.entity.sleeping ) {
					continue;
				}

				bar = node.bar;
				dataObj = bar.dataObj;
				barClip = bar.barClip;

				var targetPct:Number = dataObj[ bar.curProp ] / bar.maxValue;

				if ( Math.abs( targetPct - barClip.scaleX ) <= bar.scaleRate ) {

					barClip.scaleX = targetPct;

				} else if ( barClip.scaleX < targetPct ) {

					barClip.scaleX += bar.scaleRate;

				} else {

					barClip.scaleX -= bar.scaleRate;

				} //

			} // end for-loop.

		} //

		/*private function nodeRemoved( node:LifeBarNode ):void {
		} //*/

		override public function addToEngine( systemManager:Engine ):void {

			this.barNodes = systemManager.getNodeList( BarNode );

		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {

			this.barNodes = null;

		} //
		
	} // End class
	
} // End package