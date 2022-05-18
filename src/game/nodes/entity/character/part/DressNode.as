package game.nodes.entity.character.part
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.Part;
	import game.components.entity.character.part.pants.Dress;

	public class DressNode extends Node
	{
		public var spatial:Spatial;
		public var addition:SpatialAddition;
		public var display:Display;
		public var part:Part;
		public var dress:Dress;	
		public var rig:Rig;
	}
}
