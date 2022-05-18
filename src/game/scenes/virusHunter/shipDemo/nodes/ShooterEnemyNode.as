package game.scenes.virusHunter.shipDemo.nodes
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControlBase;
	import game.components.motion.TargetSpatial;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	import game.scenes.virusHunter.shipDemo.components.PointValue;
	import game.scenes.virusHunter.shipDemo.components.ShooterEnemy;
	
	public class ShooterEnemyNode extends Node
	{
		public var shooter:ShooterEnemy;
		public var motion:Motion;
		public var spatial:Spatial;
		public var damageTarget:DamageTarget;
		public var pointValue:PointValue;
		public var weaponSlots:WeaponSlots;
		public var target:TargetSpatial;
		public var motionControlBase:MotionControlBase;
	}
}