package game.nodes.render
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.components.render.Shadow;
	import game.components.timeline.Timeline;
	
	public class ShadowNode extends Node
	{
		public var shadow:Shadow;
		public var display:Display;
		public var spatial:Spatial;
		
		public var lightSource:TargetSpatial;//light
		public var timeline:Timeline;
		
		public var optional:Array = [TargetSpatial, Timeline];
	}
}