package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Platform;
	import game.data.scene.hit.MovingHitData;
	
	public class MovingHitNode extends Node
	{
		//public var spatial : Spatial;
		public var display : Display;
		public var data : MovingHitData;
		public var motion : Motion;
	}
}
