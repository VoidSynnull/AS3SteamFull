package game.nodes.specialAbility
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.specialAbility.WhoopeeCushionComponent;
	
	public class WhoopeeCushionNode extends Node
	{
		public var whoopeeCushion:WhoopeeCushionComponent;
		public var spatial:Spatial;
		public var display:Display;
		public var audio:Audio;
	}
}