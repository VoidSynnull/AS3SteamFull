package game.scenes.poptropolis.promoDive.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.poptropolis.promoDive.components.Fish;
	
	public class FishNode extends Node
	{
		public var fish:Fish;
		public var display:Display;
		public var spatial:Spatial;
		public var hit:MovieClipHit;
	}
}