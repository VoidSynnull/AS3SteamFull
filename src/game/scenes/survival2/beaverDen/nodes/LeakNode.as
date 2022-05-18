package game.scenes.survival2.beaverDen.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.scenes.survival2.beaverDen.components.LeakComponent;
	
	public class LeakNode extends Node
	{
		public var audio:Audio;
		public var id:Id;
		public var leak:LeakComponent;
		public var spatial:Spatial;
		public var display:Display;
	}
}