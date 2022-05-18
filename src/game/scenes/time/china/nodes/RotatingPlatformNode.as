package game.scenes.time.china.nodes
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Platform;
	import game.scenes.time.china.components.RotatingPlatform;
	
	public class RotatingPlatformNode extends Node
	{
		public var rotatingPlatform:RotatingPlatform;
		public var platform:Platform;
		public var motion:Motion;
		public var id:Id;
		public var spatial:Spatial;
		public var entityIdList:EntityIdList;
	}
}