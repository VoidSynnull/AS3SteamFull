package game.scenes.mocktropica.cheeseInterior.components {

	import ash.core.Component;
	import engine.components.Spatial;

	public class ScreenShake extends Component {

		/**
		 * This is the target the Camera will actually follow. It will match the location of a target player
		 * and then have the current shake offset applied to it.
		 * The Shake System will create this target. There is no reason to set it directly.
		 */
		public var _shakeTarget:Spatial;

		/**
		 * Angular frequency of the shake ( radians per second = 2pi*shakes per second )
		 */
		public var frequency:Number = 2*Math.PI*4;

		/**
		 * Having the max shake time separate from timer allows resetting, and shake smoothing when a shake is nearly finished.
		 */
		public var shakeTime:Number;
		public var _timer:Number;

		public var maxShakeX:Number;
		public var maxShakeY:Number;

		/**
		 * By keeping a reference to the current shake offset, can add random amounts and keep
		 * the shaking from looking too periodic and orderly.
		 */
		//public var _offsetX:Number;
		//public var _offsetY:Number;

		/**
		 * If true, the shaking will stop after 'shakeTime' has expired. If false the shake is continuous.
		 */
		public var timedShake:Boolean = true;


		public var _enabled:Boolean = true;

		/**
		 * Private. Need to have a marker to indicate when the component is enabled/disabled
		 * so the camera target can be changed.
		 */
		public var _switchEnabled:Boolean = false;

		public function ScreenShake( shakeTime:Number=4, maxShakeX:Number=20, maxShakeY:Number=20 ) {

			this.shakeTime = shakeTime;
			this.maxShakeX = maxShakeX;
			this.maxShakeY = maxShakeY;

		} //

		/**
		 * Reset the shake time.
		 */
		public function reset():void {

			this._timer = this.shakeTime;

		} //

		public function get enabled():Boolean {
			return this._enabled;
		}

		public function set enabled( b:Boolean ):void {

			this._enabled = b;
			this._switchEnabled = true;

		} //

	} // class

} //