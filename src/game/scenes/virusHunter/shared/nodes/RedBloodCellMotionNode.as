package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.RedBloodCell;
	
	public class RedBloodCellMotionNode extends Node
	{
		public var redBloodCell:RedBloodCell;
		public var motion:Motion;
		public var spatial:Spatial;
		public var collider:MovieClipHit;
		public var display:Display;
		public var damageTarget:DamageTarget;
	}
}