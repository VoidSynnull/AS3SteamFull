package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.components.motion.Mass;
	import game.components.motion.PulleyConnecter;
	import game.components.motion.PulleyObject;
	
	public class PulleyObjectNode extends Node
	{
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
		public var pulleyObject:PulleyObject;
		public var pulleyConnector:PulleyConnecter;
		public var mass:Mass;
		public var entityIdList:EntityIdList;
		
		public var optional:Array = [EntityIdList];
	}
}