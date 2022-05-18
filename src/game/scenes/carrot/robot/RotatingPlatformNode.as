package game.scenes.carrot.robot
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Platform;
	
	public class RotatingPlatformNode extends Node
	{
		public var rotatingPlatform:RotatingPlatform;
		public var platform:Platform;
		public var motion:Motion;
		public var id:Id;
		public var spatial:Spatial;
	}
}