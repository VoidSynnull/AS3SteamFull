package game.nodes.entity.character
{
	import ash.core.Node;

	import game.components.entity.Dialog;
	import game.components.scene.SceneInteraction;

	public class DialogInteractionNode extends Node
	{
		public var sceneInteraction:SceneInteraction;
		public var dialog:Dialog;
	}
}
