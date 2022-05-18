package game.nodes.specialAbility
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.specialAbility.ObjectSwarmComponent;
	
	public class ObjectSwarmNode extends Node
	{
		public var swarmComponent:ObjectSwarmComponent;
		public var spatial:Spatial;
		public var display:Display;
	}
}


