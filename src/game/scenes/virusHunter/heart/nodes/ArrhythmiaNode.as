package game.scenes.virusHunter.heart.nodes {

	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.scenes.virusHunter.heart.components.Arrhythmia;
	import game.scenes.virusHunter.shared.components.DamageTarget;

	public class ArrhythmiaNode extends Node {

		public var arrhythmia:Arrhythmia;
		public var display:Display;
		public var spatial:Spatial;

		public var sleep:Sleep;

		public var damageTarget:DamageTarget;

	} // End ArrhythmiaNode
	
} // End package