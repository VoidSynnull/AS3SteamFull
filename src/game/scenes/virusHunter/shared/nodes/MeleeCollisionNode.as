package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	import engine.components.EntityType;
	
	import game.components.entity.Parent;
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.Melee;
	import game.scenes.virusHunter.shared.components.Weapon;
	
	public class MeleeCollisionNode extends Node
	{
		public var melee:Melee;
		public var hit:MovieClipHit
		public var weapon:Weapon;
		public var type:EntityType;
		public var parent:Parent;
		public var spatial:Spatial;
	}
}