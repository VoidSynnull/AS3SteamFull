package game.scenes.virusHunter.shipDemo.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControlBase;
	import game.components.motion.TargetEntity;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shipDemo.components.PointValue;
	import game.scenes.virusHunter.shipDemo.components.SpinnerEnemy;
	
	public class SpinnerEnemyNode extends Node
	{
		public var spinner:SpinnerEnemy;
		public var motion:Motion;
		public var spatial:Spatial;
		public var damageTarget:DamageTarget;
		public var pointValue:PointValue;
		public var target:TargetEntity;
		public var motionControlBase:MotionControlBase;
	}
}