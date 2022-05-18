package game.nodes.hit
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	
	public class HitTestNode extends Node
	{
		public var hit:HitTest;
		public var entityIdList:EntityIdList;
	}
}