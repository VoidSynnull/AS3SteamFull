package game.scenes.virusHunter.heart.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	/**
	 * Expand or contract the rigid arm to the number of segments indicated.
	 */
	public class RigidArmExtend extends Component {

		/**
		 * Number of segments the arm should end up with.
		 */
		public var targetSegments:uint;

		/**
		 * radius of newly added segments.
		 */
		public var segmentRadius:Number;

		/**
		 * Filename of the segments to add.
		 */
		public var segmentFile:String;

		/**
		 * Time it takes for an entire segment to extend or contract.
		 */
		public var extendTime:Number = 1;

		public var onSegmentAdded:Signal;
		public var onSegmentRemoved:Signal;

		/**
		 * If true, segment entities are automatically removed/added to group
		 * when a new segment is added/removed.
		 */
		public var autoHandleEntities:Boolean = true;

		/**
		 * onExtendComplete is actually triggered for both extending and contracting completion events.
		 * Checking the current mode, changing the signal, etc. should be enough to distinguish these.
		 */
		public var onExtendComplete:Signal;

		public function RigidArmExtend() {

			super();

			onExtendComplete = new Signal( Entity );
			onSegmentAdded = new Signal( Entity, ArmSegment );
			onSegmentRemoved = new Signal( Entity, ArmSegment );

		} //

	} // End RigidArmExtend

} // End package