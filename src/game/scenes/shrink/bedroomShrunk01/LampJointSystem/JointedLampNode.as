package game.scenes.shrink.bedroomShrunk01.LampJointSystem
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	
	import game.components.hit.Platform;
	
	public class JointedLampNode extends Node
	{
		public var lamp:JointedLamp;
		public var platform:Platform;
		public var entityIdList:EntityIdList;
	}
}