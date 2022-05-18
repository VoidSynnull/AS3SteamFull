package game.scenes.shrink.shared.Systems.CarrySystem
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.scene.SceneInteraction;
	
	public class CarryNode extends Node
	{
		public var carry:Carry;
		public var interaction:Interaction;
		public var sceneInteraction:SceneInteraction;
		public var motion:Motion;
		public var spatial:Spatial;
		public var display:Display;
	}
}