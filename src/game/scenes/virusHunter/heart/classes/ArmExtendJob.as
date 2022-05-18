package game.scenes.virusHunter.heart.classes {
	
	import game.scenes.virusHunter.heart.components.ArmSegment;

	/**
	 * Contains information about the process of extending a new segment from an arm
	 * or contracting an arm segment inwards.
	 * 
	 * You need information on the current segment being moved, whethere the segment
	 * clip is being loaded from a file, and the timing step of the animation.
	 */
	public class ArmExtendJob {

		public var loading:Boolean = false;

		public var curSegment:ArmSegment;
		public var timer:Number;

		public function ArmExtendJob() {
		} //

	} // End ArmExtendJob

} // End package