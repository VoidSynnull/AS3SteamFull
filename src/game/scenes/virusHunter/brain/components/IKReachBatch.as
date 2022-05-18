package game.scenes.virusHunter.brain.components
{
	import ash.core.Entity;
	
	import ash.core.Component;

	/**
	 * Batch of IKReach's (multiple reach armatures in a system) processed by the IKReachSystem
	 * IKReach - is an end-point "reaching" armature.
	 */
	
	public class IKReachBatch extends Component
	{
		public function IKReachBatch($ikReachBatch:Vector.<Entity>)
		{
			ikReachBatch = $ikReachBatch;
		}
		
		public var ikReachBatch:Vector.<Entity>;
		public var tentacleBatch:Vector.<Entity> = new Vector.<Entity>;
	}
}