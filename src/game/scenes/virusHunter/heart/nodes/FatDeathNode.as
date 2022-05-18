package game.scenes.virusHunter.heart.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.heart.components.HeartFat;
	import game.scenes.virusHunter.heart.components.SwapDisplay;

	public class FatDeathNode extends Node {

		public var fat:HeartFat;

		public var swapDisplay:SwapDisplay;

		public var timeline:Timeline;

		public var spatial:Spatial;
		public var display:Display;

	} //

} // End package