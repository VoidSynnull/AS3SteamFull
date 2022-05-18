package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Parent;
	import game.components.motion.RotateControl;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	
	public class WeaponControlNode extends Node
	{
		public var weaponControl:WeaponControl;
		public var spatial:Spatial;
		public var weapon:Weapon;
		public var parent:Parent;
		public var display:Display;
		public var rotateControl:RotateControl;
	}
}