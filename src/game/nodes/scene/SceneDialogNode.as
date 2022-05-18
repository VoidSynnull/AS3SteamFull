package game.nodes.scene
{
	import ash.core.Node;
	import game.components.entity.Dialog;
	import game.components.motion.MotionControl;
	import game.components.entity.character.Player;
	import engine.components.Motion;
	
	public class SceneDialogNode extends Node
	{
		public var dialog:Dialog;
		public var player:Player;
		public var motion:Motion;
	}
}