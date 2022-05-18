package game.nodes.entity.character.part
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;

	import game.components.entity.character.part.CreepyEyes;

	public class CreepyEyesNode extends Node
	{
		public var creepyEyes:CreepyEyes;
		public var spatial:Spatial;
		public var display:Display;
	}
}