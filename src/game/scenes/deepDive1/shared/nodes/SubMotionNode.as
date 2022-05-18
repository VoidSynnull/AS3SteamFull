package game.scenes.deepDive1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.entity.collider.HazardCollider;
	import game.scenes.deepDive1.shared.components.Sub;
	
	public class SubMotionNode extends Node
	{
		public var sub:Sub;
		public var motion:Motion;
		public var motionControlBase:MotionControlBase;
		public var display:Display;
		public var audio:Audio;
		public var spatial:Spatial;
		public var spatialAddition:SpatialAddition;
		public var hazardCollider:HazardCollider;
		public var motionControl:MotionControl;
	}
}