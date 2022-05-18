package game.scenes.virusHunter.heart.systems {
	
	import flash.geom.ColorTransform;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.virusHunter.heart.components.ColorBlink;
	import game.scenes.virusHunter.heart.nodes.ColorBlinkNode;

	import game.util.EntityUtils;

	public class ColorBlinkSystem extends System {

		private var blinkList:NodeList;

		public function ColorBlinkSystem() {

			super();

		} //

		override public function addToEngine( systemManager:Engine ):void {
			
			this.blinkList = systemManager.getNodeList( ColorBlinkNode );
			this.blinkList.nodeAdded.add( this.nodeAdded );
			
			for( var node:ColorBlinkNode = this.blinkList.head; node; node = node.next ) {
				this.nodeAdded( node );
			}

		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			this.blinkList.nodeAdded.remove( this.nodeAdded );
			
			systemManager.releaseNodeList( ColorBlinkNode );
			
			this.blinkList = null;
			
		} //
		
		override public function update(time:Number):void {

			for( var node:ColorBlinkNode = this.blinkList.head; node; node = node.next ) {

				if ( EntityUtils.sleeping(node.entity) ) {
					continue;
				}

				this.updateNode( node, time );

			} //

		} //

		private function updateNode( node:ColorBlinkNode, time:Number ):void {

			if ( node.blink.timer <= 0 ) {
				return;
			}

			var blink:ColorBlink = node.blink;
			var colorTrans:ColorTransform = blink.colorTrans;

			blink.timer -= time;

			if ( blink.timer > 0 ) {

				var pct:Number = ( blink.timer / blink.blinkTime );
				if ( blink.type == ColorBlink.SINE ) {
					pct = Math.sin( pct*Math.PI );
				}

				colorTrans.redOffset = pct * blink.redOffset * blink.maxMult;
				colorTrans.greenOffset = pct * blink.greenOffset* blink.maxMult;
				colorTrans.blueOffset = pct * blink.blueOffset* blink.maxMult;

				// Not quite correct but close enough. these should actually be set to some percent of (1-maxMult)
				colorTrans.redMultiplier = colorTrans.greenMultiplier = colorTrans.blueMultiplier = 1 - pct*( 1 - blink.maxMult );
				node.display.displayObject.transform.colorTransform = colorTrans;

			} else {

				// depending on which system runs first, the cooldown will be over this frame or next frame.
				// better just end it now.
				colorTrans.redMultiplier = colorTrans.blueMultiplier = colorTrans.greenMultiplier = 1;
				colorTrans.redOffset = colorTrans.blueOffset = colorTrans.greenOffset = 0;
				node.display.displayObject.transform.colorTransform = colorTrans;

				if ( blink.repeat ) {
					blink.timer = blink.blinkTime;
				} else {

					blink.timer = 0;
					if ( blink.onComplete ) {
						blink.onComplete( node.entity );
					}

				} //

			} //

		} //

		private function nodeAdded( node:ColorBlinkNode ):void {

			node.blink.timer = 0;

		} //

	} // End ColorBlinkSystem
	
} // End package