package game.nodes.specialAbility
{
	import ash.core.Node;
	
	import engine.components.OwningGroup;
	
	import game.components.entity.character.Player;
	import game.components.specialAbility.SpecialAbilityControl;

	public class SpecialAbilityNode extends Node
	{
		public var specialControl:SpecialAbilityControl;
		public var owning:OwningGroup;
		
		public var player:Player;
		public var optional:Array = [Player]
	}
}
