package game.nodes.entity
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	import game.components.entity.AlertSound;
	
	public class AlertSoundNode extends Node
	{
		public var alert:AlertSound;
		public var entityList:EntityIdList;
	}
}