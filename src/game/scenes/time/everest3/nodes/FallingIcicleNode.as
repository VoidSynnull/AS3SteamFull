package game.scenes.time.everest3.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.time.everest3.components.FallingIcicle;
	
	public class FallingIcicleNode extends Node
	{
		public var fallingIcicle:FallingIcicle;
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}