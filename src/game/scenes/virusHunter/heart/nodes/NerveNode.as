package game.scenes.virusHunter.heart.nodes {
	
	import ash.core.Node;
	
	import engine.components.Id;
	
	import game.scenes.virusHunter.heart.components.Nerve;
	import game.scenes.virusHunter.shared.components.DamageTarget;

	public class NerveNode extends Node {

		public var nerve:Nerve;
		public var damageTarget:DamageTarget;
		public var id:Id;

	} // End NerveNode
	
} // End package