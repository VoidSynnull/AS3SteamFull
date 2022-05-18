package game.scenes.lands.shared.components {

	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	
	import ash.core.Component;
	
	import engine.components.Display;

	public class LightningStrike extends Component {

		public var sectionLength:int = 20;

		/**
		 * need this to easily get the transformation from source to parent coordinates.
		 * DO NOT alter this unless you change the effectClip as well.
		 */
		public var effectParent:DisplayObjectContainer;

		/**
		 * effectClip is stored here and not in a Display component for several reasons.
		 * First the graphics can be cleared outside the system, we can ensure the clip
		 * is a shape, and it's more efficient anyway.
		 */
		public var effectClip:Shape;

		/**
		 * this is the offset to the ORIGIN of the lightning strike.
		 */
		public var sourceOffsetX:Number = 0;
		public var sourceOffsetY:Number = 0;
		
		public var outerLineWidth:Number = 8;
		public var outerLineAlpha:Number = 0.2;
		
		public var innerLineWidth:Number = 2;
		public var innerLineAlpha:Number = 1;
		
		public var lineColor:uint = 0xBFE6FF;
		
		public var maxOffset:Number = this.sectionLength/2;

		/**
		 * Location the lightning strike should aim for, in the effect parent's coordinate system.
		 */
		public var targetX:Number;
		public var targetY:Number;

		/**
		 * strike_dx, strike_dy give the DIRECTION of the lightning strike, relative to the
		 * effect's parent coordinate system. ( usually the scene )
		 */
		public var strike_dx:Number = 0;
		public var strike_dy:Number = 0;

		/**
		 * indicates that the lighting is not currently active (firing)
		 */
		public var active:Boolean = false;

		/**
		 * if true, no lightning should fire at all until the component is unpaused.
		 * this was added in addition to the 'active' parameter because the light saber
		 * needed to disable the visible lightning effect animation - but the lightning targets
		 * still had to work.
		 * 
		 * this is a bit messy. there wasn't a good way around it.
		 */
		public var paused:Boolean;

		/**
		 * Source that the lightning strike comes from.
		 * the effectClip will be positioned to match the sourceDisplay.
		 */
		public var sourceDisplay:Display;

		public function LightningStrike( source:Display, parent:DisplayObjectContainer ) {
			
			this.sourceDisplay = source;
			this.effectClip = new Shape();
			this.effectClip.visible = false;

			this.effectParent = parent;
			parent.addChild( this.effectClip );

		} //

		public function pause():void {
			this.paused = true;
			this.effectClip.visible = false;
		} //
		
		public function unpause():void {
			this.paused = false;
		}
		
		public function start():void {
			
			if ( !this.paused ) {
				this.effectClip.visible = true;
				this.active = true;
			}

		} //
		
		public function stop():void {

			this.effectClip.visible = false;
			this.effectClip.graphics.clear();
			this.active = false;

		} //

		public function setTarget( tx:Number, ty:Number ):void {

			this.targetX = tx;
			this.targetY = ty;

		}

		public function removeClip():void {
			
			if ( this.effectClip.parent ) {
				this.effectClip.parent.removeChild( this.effectClip );
			}
			
		} //

	} // class

} // package