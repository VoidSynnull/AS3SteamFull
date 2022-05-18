package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Virus;
	
	public class VirusMotionNode extends Node
	{
		public var virus:Virus;
		public var motion:Motion;
		public var spatial:Spatial;
		public var target:TargetSpatial;
		public var damageTarget:DamageTarget;
		public var timeline:Timeline;
	}
}