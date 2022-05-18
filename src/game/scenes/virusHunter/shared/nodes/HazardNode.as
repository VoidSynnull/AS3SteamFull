package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import engine.components.EntityType;
	
	public class HazardNode extends Node
	{
		public var hazard:Hazard;
		public var hit:MovieClipHit;
		//public var type:Type;
		public var spatial:Spatial;
	}
}