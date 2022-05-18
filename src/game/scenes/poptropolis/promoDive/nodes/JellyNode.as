package game.scenes.poptropolis.promoDive.nodes 
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.poptropolis.promoDive.components.Jelly;
	
	public class JellyNode extends Node
	{
		public var jelly:Jelly;
		public var display:Display;
		public var spatial:Spatial;
		public var hit:MovieClipHit;
	}
}