package game.nodes.entity.character
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Player;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	
	public class PlayerNode extends Node
	{
		public var player:Player;
		public var edge:Edge;
		public var spatial:Spatial;
		
		public var motion:Motion;
		public var characterMotionControl:CharacterMotionControl;
		public var motionControl:MotionControl;
		public var optional:Array = [Motion,CharacterMotionControl,MotionControl];
	}
}