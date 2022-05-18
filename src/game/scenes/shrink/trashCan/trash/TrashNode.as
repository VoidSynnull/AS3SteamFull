package game.scenes.shrink.trashCan.trash
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.entity.collider.PlatformCollider;
	import game.components.motion.WaveMotion;
	
	public class TrashNode extends Node
	{
		public var trash:Trash;
		public var motion:Motion;
		public var hit:PlatformCollider;
		public var shake:WaveMotion;
		public var display:Display;
		//public var optional:Array = [WaveMotion, SpatialAddition];
	}
}