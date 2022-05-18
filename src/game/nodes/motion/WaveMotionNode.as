package game.nodes.motion
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.motion.WaveMotion;

	public class WaveMotionNode extends Node
	{
		public var waveMotion : WaveMotion;
		public var spatial : Spatial;
		public var spatialAddition:SpatialAddition;
		
		public var optional:Array = [SpatialAddition];
	}
}
