package game.scenes.virusHunter.heart.components {
	
	import ash.core.Component;

	public class RigidArm extends Component {

		static public const DEG_PER_RAD:Number = 180/Math.PI;
		static public const RAD_PER_DEG:Number = Math.PI/180;

		public var maxSegmentOmega:Number = Math.PI/6;
		public var maxSegmentVelocity:Number = 10;

		public var segments:Vector.<ArmSegment>;

		/**
		 * Location of the final point of the last segment.
		 */
		public var endX:Number;
		public var endY:Number;

		/**
		 * Base location of arm.
		 */
		public var startX:Number;
		public var startY:Number;

		/**
		 * Maximum number of child segments, in case arms
		 * extend with extra segments.
		 */
		public var maxSegments:int = 8;

		/**
		 * If followParents is true, segments will try to match their parent nodes.
		 * This will either be omega matching, or theta matching, haven't decided yet- probably omega.
		 * see the RigidArmUpdate system to find out which.
		 */
		public var followParents:Boolean = false;

		public function RigidArm() {
		} //

		/**
		 * Need to make sure the angle of the old-first segment does not change abruptly.
		 * This occurs because the first segment's theta matches its absTheta.
		 */
		public function unshiftSegment( seg:ArmSegment ):void {

			if ( segments.length == 0 ) {
				segments.unshift( seg );
				return;
			} //

			var first:ArmSegment = segments[0];

			seg.x = first.x;
			seg.y = first.y;
			seg.baseTheta = seg.theta = seg.absTheta = first.theta;

			seg.omega = first.omega;

			/**
			 * relative theta becomes zero so the effective angle won't change.
			 */
			first.baseTheta = first.theta = 0;

			segments.unshift( seg );

		} //

		public function stop():void {

			var seg:ArmSegment;
			for( var i:int = segments.length-1; i >= 0; i-- ) {

				seg = segments[ i ];
				seg.omega = 0;
				seg.theta = seg.baseTheta;

			} //

		} //

		/**
		 * save all the current segment angles so they can be restored later.
		 */
		public function saveAngles():void {

			for( var i:int = segments.length-1; i >= 0; i-- ) {

				segments[ i ].baseTheta = segments[ i ].theta;

			} //

		} //

		/**
		 * Shift the first segment off the arm and make sure the next segment
		 * keeps the rotation and position of the old first segment.
		 */
		public function shiftSegment():void {

			var last:ArmSegment = segments.shift();

			if ( segments.length == 0 ) {
				return;
			}

			var first:ArmSegment = segments[0];
			first.x = last.x;
			first.y = last.y;
			first.theta = first.absTheta = last.theta;

		} //

		/**
		 * Cut out all segments up to, but not including, the given index.
		 * The segments are returned so their entities can be disposed of.
		 */
		public function cutTo( segmentIndex:int ):Vector.<ArmSegment> {

			var segs:Vector.<ArmSegment> = segments.splice( 0, segmentIndex );

			return segs;

		} //

	} // End VirusArm

} // End package