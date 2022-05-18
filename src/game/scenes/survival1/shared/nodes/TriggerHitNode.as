package game.scenes.survival1.shared.nodes
{
	import ash.core.Node;
	
	import game.components.hit.Bounce;
	import game.components.hit.EntityIdList;
	import game.components.hit.Platform;
	import game.scenes.survival1.shared.components.TriggerHit;
	
	public class TriggerHitNode extends Node
	{
		public var animatedHit:TriggerHit;
		public var bounce:Bounce;
		public var platform:Platform;
		public var entityList:EntityIdList;
		
		public var optional:Array = [ Bounce, Platform ];
	}
}