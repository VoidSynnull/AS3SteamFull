package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.motion.RotateControl;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	
	public class WeaponSelectionNode extends Node
	{
		public var weaponControl:WeaponControl;
		public var spatial:Spatial;
		public var weapon:Weapon;
		public var display:Display;
		public var rotateControl:RotateControl;
		public var interaction:Interaction;
		public var sleep:Sleep;
	}
}