package game.scenes.arab1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.arab1.shared.components.QuickSand;
	
	public class QuickSandNode extends Node
	{
		public var quickSand:QuickSand;
		public var id:Id;
		public var motion:Motion;
		public var spatial:Spatial;
	}
}