package game.scenes.survival2.beaverDen.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	
	import game.components.hit.EntityIdList;
	import game.components.hit.Platform;
	import game.scenes.survival2.beaverDen.components.TreeLogComponent;
	
	public class TreeLogNode extends Node
	{
		public var entityList:EntityIdList;
		public var hit:Platform;
		public var log:TreeLogComponent;
		public var motion:Motion;
	}
}