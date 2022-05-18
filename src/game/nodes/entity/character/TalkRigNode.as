package game.nodes.entity.character
{
	import ash.core.Node;
	
	import game.components.entity.character.Skin;
	import game.components.entity.character.Talk;
	import game.components.entity.character.animation.RigAnimation;

	public class TalkRigNode extends Node
	{
		public var talk:Talk;
		public var rigAnim:RigAnimation;
		public var skin:Skin;
	}
}