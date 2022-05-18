package game.nodes.hit
{
	import ash.core.Node;
	
	import game.components.hit.EntityIdList;
	import engine.components.Id;
	
	public class HitEntityListNode extends Node
	{
		public var hits:EntityIdList;
		public var id:Id;
		public var optional:Array = [Id];
		/*
		public var bounce:Bounce;
		public var platform:Platform;
		public var ceiling:Ceiling;
		public var wall:Wall;
		public var water:Water;
		public var id:Id;
		public var optional:Array = [Bounce,Platform,Ceiling,Wall,Water,Id];
		*/
	}
}