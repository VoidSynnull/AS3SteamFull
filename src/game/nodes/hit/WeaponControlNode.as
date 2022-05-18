package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Parent;
	import game.components.motion.RotateControl;
	import game.components.hit.Gun;
	import game.components.hit.WeaponControl;
	
	public class WeaponControlNode extends Node
	{
		public var weaponControl:WeaponControl;
		public var spatial:Spatial;
		public var gun:Gun;
		public var parent:Parent;
		public var display:Display;
		public var rotateControl:RotateControl;
		public var optional:Array = [Parent,RotateControl];
	}
}