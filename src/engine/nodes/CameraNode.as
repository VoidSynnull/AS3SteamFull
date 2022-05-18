package engine.nodes
{
	import ash.core.Node;
	
	import engine.components.Camera;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	
	public class CameraNode extends Node
	{
		public var camera:Camera;
		public var spatial:Spatial;
		public var target:TargetSpatial;
	}
}