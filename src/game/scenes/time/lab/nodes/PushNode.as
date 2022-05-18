package game.scenes.time.lab.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.time.lab.components.PushComponent;
	
	public class PushNode extends Node
	{
		public var push:PushComponent;
		public var motion:Motion;
		public var spatial:Spatial;
	}
}