package game.scenes.virusHunter.heart.nodes {
	
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.heart.components.QuadVirusBody;
	import game.scenes.virusHunter.shared.components.DamageTarget;

	public class BodyNode extends Node {

		public var body:QuadVirusBody;
		public var display:Display;

		public var spatial:Spatial;
		public var id:Id;
		public var damageTarget:DamageTarget;

		public var hit:MovieClipHit;

	} // End BodyNode

} // End package