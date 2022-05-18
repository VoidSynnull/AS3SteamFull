package game.scenes.shrink.shared.Systems.Nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	
	public class HitNode extends Node
	{
		public var idList:EntityIdList;
		public var spatial:Spatial;
	}
}