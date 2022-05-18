package game.scenes.arab2.entrance.enforcer
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	
	public class EnforcerNode extends Node
	{
		public var enforcer:Enforcer;
		public var fsm:FSMControl;
		public var spatial:Spatial;
		public var target:MotionTarget;
		public var navigation:Navigation;
	}
}