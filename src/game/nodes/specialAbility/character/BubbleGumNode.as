package game.nodes.specialAbility.character
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.specialAbility.character.BubbleGum;
	
	public class BubbleGumNode extends Node
	{
		public var gum:BubbleGum;
		public var motion:Motion;
		public var spatial:Spatial;
		public var display:Display;
	}
}