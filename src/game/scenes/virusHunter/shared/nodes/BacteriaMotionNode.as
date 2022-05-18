package game.scenes.virusHunter.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.shared.components.Bacteria;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	
	public class BacteriaMotionNode extends Node
	{
		public var bacteria:Bacteria;
		public var motion:Motion;
		public var spatial:Spatial;
		public var display:Display;
		public var damageTarget:DamageTarget;
		public var timeline:Timeline;
	}
}
