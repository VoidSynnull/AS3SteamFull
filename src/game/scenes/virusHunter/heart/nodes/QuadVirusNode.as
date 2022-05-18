package game.scenes.virusHunter.heart.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.scenes.virusHunter.heart.components.QuadVirus;
	import game.scenes.virusHunter.shared.components.DamageTarget;

	public class QuadVirusNode extends Node {

		public var virusInfo:QuadVirus;
		public var motion:Motion;
		public var children:Children;

		public var spatial:Spatial;

		public var display:Display;

	} //

} // End package