package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.WhiteBloodCell;

	public class WhiteBloodCellMotionNode extends Node
	{		
		public var whiteBloodCell:WhiteBloodCell;
		public var motion:Motion;
		public var spatial:Spatial;		
		public var sleep:Sleep;
		public var target:TargetSpatial;
		public var damageTarget:DamageTarget;
		public var timeline:Timeline;
	}
}