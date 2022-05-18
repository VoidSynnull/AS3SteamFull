package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Interaction;
	import engine.components.Motion;
	
	import game.scenes.virusHunter.shared.components.WeaponControlInput;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	
	public class WeaponInputControlNode extends Node
	{
		public var weaponSlots:WeaponSlots;
		public var motion:Motion;
		public var weaponControlInput:WeaponControlInput;
		public var interaction:Interaction;
	}
}