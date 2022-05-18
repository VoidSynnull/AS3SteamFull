package game.scenes.shrink.kitchenShrunk01.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.CurrentHit;
	import game.components.scene.SceneInteraction;
	import game.scenes.shrink.kitchenShrunk01.components.Plug;
	
	public class PlugNode extends Node
	{
		public var plug:Plug;
		public var spatial:Spatial;
		public var display:Display;
		public var motion:Motion;
		public var sceneInteraction:SceneInteraction;
		public var interaction:Interaction;
		public var currentHit:CurrentHit;
	}
}