package game.scenes.survival5.shared.whistle
{
	import ash.core.Node;
	
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.Destination;
	
	public class WhistleNode extends Node
	{
		public var fsmControl:FSMControl;
		public var id:Id;
		public var destination:Destination;
		public var listener:WhistleListener;
		public var motionControl:CharacterMotionControl;
		public var spatial:Spatial;
	}
}