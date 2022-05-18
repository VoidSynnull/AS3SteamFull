package game.scenes.virusHunter.condoInterior.components {

	import ash.core.Component;

	public class ScaleBounce extends Component {

		public var minDeltaScale:Number = 0.02;

		public var targetScale:Number;
		public var curScale:Number;

		public var lastScale:Number;			// this is basically private - for the bounceSystem verlet.

		public var spring:Number = 100;			// equivalent to spring constant
		public var damping:Number = 0.05;

		public var onScaleDone:Function;

		public var enabled:Boolean = true;

		// changed to use a System.
		public function ScaleBounce( targetScale:Number=2, onScaleDone:Function=null ) {

			super();

			this.targetScale = targetScale;
			this.onScaleDone = onScaleDone;

		} //

	} // End ClickTarget

} // End package