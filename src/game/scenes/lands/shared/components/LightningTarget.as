package game.scenes.lands.shared.components {

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Component;

	public class LightningTarget extends Component {

		/**
		 * the hit target is in the component instead of the Display because
		 * the target might be a subclip or overlay clip
		 */
		public var targetClip:DisplayObjectContainer;

		/**
		 * time it takes to trigger a strike - the user has to hold
		 * down the mouse before the strike occurs.
		 */
		public var strikeTime:Number;

		/**
		 * counts upwards towards strikeTime. need a new one for each target
		 * because you need to be able to reset the strike without
		 * accessing the lightning target system.
		 */
		public var _timer:Number;

		/**
		 * whether this particular target is enabled or should be ignored.
		 */
		public var enabled:Boolean = true;

		/**
		 * function called when a lightning strike occurs on the target.
		 * strikeFunc( entityHit:Entity, lightningStrike:LightningStrike )
		 */
		public var strikeFunc:Function;

		/**
		 * the hitTarget is the display object that can be struck by lightning.
		 */
		public function LightningTarget( hitTarget:DisplayObjectContainer, strikeTime:Number=0.5 ) {

			super();

			this.strikeTime = strikeTime;
			this.targetClip = hitTarget;

		}

		final public function resetStrikeTimer():void {
			this._timer = 0;
		} //

	} // class
	
} // package