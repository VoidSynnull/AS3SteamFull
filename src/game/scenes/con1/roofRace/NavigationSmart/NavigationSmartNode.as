package game.scenes.con1.roofRace.NavigationSmart
{
	import ash.core.Node;
	
	import engine.components.Motion;
	//import engine.components.MotionBounds;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.Destination;
	//import game.components.motion.Edge;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	
	public class NavigationSmartNode extends Node
	{
		public var smart:NavigationSmart;
		public var navigation:Navigation;
		public var control:CharacterMotionControl;
		public var fsm:FSMControl;
		public var target:MotionTarget;
		public var motion:Motion;
		public var destination:Destination;
	}
}