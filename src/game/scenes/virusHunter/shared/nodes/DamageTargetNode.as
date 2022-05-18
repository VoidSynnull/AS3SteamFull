package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	
	public class DamageTargetNode extends Node
	{
		public var damageTarget:DamageTarget;
		public var hit:MovieClipHit;
		public var display:Display;
		public var spatial:Spatial;
	}
}