package game.scenes.virusHunter.heart.components {

	import flash.display.MovieClip;
	
	import ash.core.Component;

	public class Arrhythmia extends Component {

		static public const BROKEN:int = 1;
		static public const REPAIRING:int = 2;
		static public const FIXED:int = 3;

		public var anim:MovieClip;			// clip to be animated - separate from display.
		public var timer:Number;			// animation timer.

		public var state:int = BROKEN;

		// little twitchy bits from anim that get animated.
		public var muscle:MovieClip;
		public var nerve1:MovieClip;
		public var nerve2:MovieClip;

		// base angles for the little twitching nerve things.
		public var nerve1Base:Number;
		public var nerve2Base:Number;

		public function Arrhythmia( clip:MovieClip ) {

			super();

			this.anim = clip;

		} //

	} // End Arrhythmia

} // End package