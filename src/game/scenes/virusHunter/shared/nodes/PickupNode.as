package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.EntityType;
	
	import game.components.entity.Sleep;
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.Pickup;
	
	public class PickupNode extends Node
	{
		public var pickup:Pickup;
		public var sleep:Sleep;
		public var hit:MovieClipHit;
		public var type:EntityType;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}