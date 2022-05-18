package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Ship;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	
	public class ShipDamageNode extends Node
	{
		public var damageTarget:DamageTarget;
		public var ship:Ship;
		public var motion:Motion;
		public var spatial:Spatial;
		public var display:Display;
		public var hit:MovieClipHit;
		public var weaponSlots:WeaponSlots;
	}
}