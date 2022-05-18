package game.scenes.deepDive1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.scene.SceneInteraction;
	import game.scenes.deepDive1.shared.components.Filmable;
	
	public class FilmableNode extends Node
	{
		public var display:Display;
		public var spatial:Spatial;
		public var filmable:Filmable;	
		public var sceneInteraction:SceneInteraction;
	}
}