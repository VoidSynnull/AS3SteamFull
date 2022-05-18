package game.nodes.entity
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.entity.NPCDetector;
	
	public class NPCDetectorNode extends Node
	{
		public var npcDetector:NPCDetector;
		public var spatial:Spatial;
	}
}