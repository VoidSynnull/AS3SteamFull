package game.scenes.hub.skydive
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	
	public class SkydiveNode extends Node
	{
		public var playerState:PlayerState;
		public var motionBounds:MotionBounds;
		public var motion:Motion;
		public var id:Id;
		public var parachute:Parachute;
		public var audio:Audio;
	}
}