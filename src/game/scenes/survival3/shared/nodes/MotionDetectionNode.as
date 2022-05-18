package game.scenes.survival3.shared.nodes
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	import game.scenes.survival3.shared.components.MotionDetection;
	
	public class MotionDetectionNode extends Node
	{
		public var motionDetection:MotionDetection;
		public var hitIds:EntityIdList;
	}
}