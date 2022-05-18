package game.scenes.carrot.computer.nodes
{
	import ash.core.Node;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Display;
	import game.components.motion.TargetSpatial;
	import game.scenes.carrot.computer.components.Rabbot;

	public class RabbotNode extends Node
	{
		public var spatial:Spatial;
		public var motion:Motion;
		public var target:TargetSpatial
		public var rabbot:Rabbot;
	}
}