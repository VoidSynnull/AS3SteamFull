package game.nodes.specialAbility
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.specialAbility.WhoopeeComponent;
	
	public class WhoopeeNode extends Node
	{
		public var whoopeeCushion:WhoopeeComponent;
		public var spatial:Spatial;
		public var display:Display;
		public var audio:Audio;
		public var optional:Array = [Audio];
	}
}

