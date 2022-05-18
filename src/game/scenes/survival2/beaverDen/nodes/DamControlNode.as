package game.scenes.survival2.beaverDen.nodes
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	import game.components.hit.Platform;
	import game.scenes.survival2.beaverDen.components.DamControlComponent;
	import game.scenes.survival2.beaverDen.components.DamTriggerPlatformComponent;
	
	public class DamControlNode extends Node
	{
		public var entityList:EntityIdList;
		public var hit:Platform;
		public var trigger:DamTriggerPlatformComponent;
		public var damControl:DamControlComponent;
	}
}