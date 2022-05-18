package engine.nodes
{
	import ash.core.Node;
	
	import engine.components.CameraLayer;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import game.components.motion.MotionWrap;
	
	public class CameraLayerNode extends Node
	{
		public var spatial:Spatial;
		public var cameraLayer:CameraLayer;
		public var spatialOffset:SpatialOffset;
		
		public var motion:Motion;
		public var motionWrap:MotionWrap;

		public var optional:Array = [ Motion, MotionWrap ]
	}
}
