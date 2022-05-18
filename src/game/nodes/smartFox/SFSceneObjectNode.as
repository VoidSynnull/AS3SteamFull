package game.nodes.smartFox
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.smartFox.SFSceneObject;
	
	public class SFSceneObjectNode extends Node
	{
		public var sfSceneObject:SFSceneObject;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}