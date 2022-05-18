package game.scenes.virusHunter.heart.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.heart.components.HeartFat;
	import game.scenes.virusHunter.heart.components.SwapDisplay;
	import game.scenes.virusHunter.shared.components.DamageTarget;

	public class FatDamageNode extends Node {

		public var fat:HeartFat;
		public var damage:DamageTarget;

		public var swapDisplay:SwapDisplay;

		public var hit:MovieClipHit;
		public var spatial:Spatial;
		public var display:Display;

	} //

} // End package