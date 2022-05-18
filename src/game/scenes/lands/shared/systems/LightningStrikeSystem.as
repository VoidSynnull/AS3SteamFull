package game.scenes.lands.shared.systems {

	/**
	 * 
	 * this system handles the visual of a lightning strike.
	 * In land it's used for the hammer lightning effect. Sort of a waste to make it a system
	 * since its only active on mouseDown. Have to think about that.
	 * 
	 */

	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import ash.core.Engine;

	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.components.LightningStrike;
	import game.scenes.lands.shared.nodes.LightningStrikeNode;


	public class LightningStrikeSystem extends System {

		private var lightningNodes:NodeList;

		public function LightningStrikeSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			var lightning:LightningStrike;
			var effectClip:Shape;

			for( var node:LightningStrikeNode = lightningNodes.head; node; node = node.next ) {

				if ( node.entity.sleeping ) {
					continue;
				}

				lightning = node.lightning;
				if ( (!lightning.active) || lightning.paused ) {
					continue;
				}

				effectClip = lightning.effectClip;

				// perform coord transformation.
				var p:Point = new Point( lightning.sourceOffsetX, lightning.sourceOffsetY );
				p = lightning.sourceDisplay.displayObject.localToGlobal( p );
				p = lightning.effectParent.globalToLocal( p );

				effectClip.x = p.x;
				effectClip.y = p.y;

				var dx:Number = lightning.targetX - p.x;
				var dy:Number = lightning.targetY - p.y;
				
				var d:Number = Math.sqrt( dx*dx + dy*dy );
				if ( d < 1 ) {
					d = 1;
				}
				dx /= d;
				dy /= d;

				lightning.strike_dx = dx;
				lightning.strike_dy = dy;

				effectClip.graphics.clear();
				effectClip.graphics.lineStyle( lightning.outerLineWidth, lightning.lineColor, lightning.outerLineAlpha );

				this.drawLightning( effectClip.graphics, lightning, dx, dy, d );

				effectClip.graphics.lineStyle( lightning.innerLineWidth, lightning.lineColor, lightning.innerLineAlpha );

				this.drawLightning( effectClip.graphics, lightning, dx, dy, d );

			} //

		} // update()

		private function drawLightning( g:Graphics, lightning:LightningStrike, dx:Number, dy:Number, dist:Number):void {

			var len:Number = lightning.sectionLength;
			g.moveTo(0, 0);

			do {

				g.lineTo( dx*len - dy*lightning.maxOffset*( 2*Math.random() - 1), dy*len + dx*lightning.maxOffset*(Math.random()*2 - 1 ) );
				len += lightning.sectionLength;

			} while ( len < dist );

			dx = dx*dist;
			dy = dy*dist;

			g.lineTo( dx, dy );
			g.drawCircle( dx, dy, Math.random()*10);

		} // drawLightning

		private function nodeRemoved( node:LightningStrikeNode ):void {

			node.lightning.removeClip();

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.lightningNodes = systemManager.getNodeList( LightningStrikeNode );
			this.lightningNodes.nodeRemoved.add( this.nodeRemoved );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			/**
			 * note: this ACTUALLY should be done. because its not currently implemented in the system.
			 */
			this.lightningNodes.nodeRemoved.remove( this.nodeRemoved );

			systemManager.releaseNodeList( LightningStrikeNode );

		} //

	} // class

} // package