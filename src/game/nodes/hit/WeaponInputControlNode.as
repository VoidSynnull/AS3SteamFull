package game.nodes.hit
{
	import ash.core.Node;
	
	import engine.components.Interaction;
	
	import game.components.hit.WeaponControl;
	import game.components.hit.WeaponControlInput;
	
	public class WeaponInputControlNode extends Node
	{
		public var weaponControl:WeaponControl;
		public var weaponControlInput:WeaponControlInput;
		public var interaction:Interaction;
		public var optional:Array = [WeaponControlInput];
	}
}