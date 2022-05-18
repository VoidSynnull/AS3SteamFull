package game.scenes.poptropolis.hurdles.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.components.entity.character.animation.RigAnimation;
	import game.scenes.poptropolis.hurdles.components.Hurdler;

	public class HurdlerNode extends Node
	{
		public var spatial:Spatial
		public var motion:Motion
		public var hurdler:Hurdler;
		public var children:Children;
		public var rigAnim:RigAnimation;
	}
}