package game.scenes.backlot.cityDestroy.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.motion.Threshold;
	import game.scenes.backlot.cityDestroy.components.JetComponent;
	
	public class JetNode extends Node
	{
		public var jet:JetComponent;
		public var spatial:Spatial;
		public var threshold:Threshold;
		public var motion:Motion;
		public var tween:Tween;
	}
}