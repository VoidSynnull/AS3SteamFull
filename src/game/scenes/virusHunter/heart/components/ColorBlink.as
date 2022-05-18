package game.scenes.virusHunter.heart.components {

	import flash.geom.ColorTransform;
	
	import ash.core.Component;

	public class ColorBlink extends Component {

		static public var LINEAR:int = 1;
		static public var SINE:int = 2;

		public var redOffset:uint = 0;
		public var greenOffset:uint = 0;
		public var blueOffset:uint = 0;

		public var maxMult:Number;

		public var repeat:Boolean;

		public var blinkTime:Number;
		public var timer:Number;

		public var colorTrans:ColorTransform;

		// listener returns entity that completed the blink.
		public var onComplete:Function;

		public var type:int = LINEAR;

		public function ColorBlink( color:uint, mult:Number, blinkTime:Number ) {

			super();

			this.redOffset = color >> 16;
			this.greenOffset = 0xFF & ( color >> 8 );
			this.blueOffset = 0xFF & color;

			this.maxMult = mult;

			this.blinkTime = blinkTime;

			this.colorTrans = new ColorTransform();

		} //

		public function continuous():void {

			if ( this.timer <= 0 ) {
				this.timer = this.blinkTime;
			}
			this.repeat = true;

		} //

		public function start():void {
			this.timer = this.blinkTime;
		}

	} // End ColorBlink
	
} // End package