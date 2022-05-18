package game.scenes.cavern1.shared.nodes
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.PlatformCollider;
	import game.components.motion.MotionControl;
	import game.scenes.cavern1.shared.components.Magnet;
	import game.scenes.cavern1.shared.components.MagneticData;
	
	public class MagnetNode extends Node
	{
		public var magnet:Magnet;
		public var magneticData:MagneticData;
		
		public var charMotionControl:CharacterMotionControl;
		public var platformCollider:PlatformCollider;
		public var motionControl:MotionControl;
		
		public var display:Display;
		public var spatial:Spatial;
		public var motion:Motion;
	}
}