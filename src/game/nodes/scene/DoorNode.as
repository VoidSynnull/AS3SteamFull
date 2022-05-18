package game.nodes.scene
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	
	import game.components.scene.SceneInteraction;
	import game.components.hit.Door;
	
	public class DoorNode extends Node
	{
		public var interaction:Interaction;
		public var hit:Door;
		public var sceneInteraction:SceneInteraction;
		public var id:Id;
		public var display:Display;
	}
}
