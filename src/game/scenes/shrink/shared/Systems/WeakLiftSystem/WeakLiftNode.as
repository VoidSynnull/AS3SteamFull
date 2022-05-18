package game.scenes.shrink.shared.Systems.WeakLiftSystem
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	
	import game.components.hit.Platform;
	import game.data.scene.hit.MovingHitData;
	
	public class WeakLiftNode extends Node
	{
		public var weakLift:WeakLift;
		public var platform:Platform;
		public var moveData:MovingHitData;
		public var entityIdList:EntityIdList;
	}
}