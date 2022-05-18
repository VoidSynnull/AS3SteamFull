package game.scenes.virusHunter.lungs.nodes
{
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	import game.scenes.virusHunter.lungs.components.BossArm;
	import game.scenes.virusHunter.lungs.components.BossState;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	
	public class BossArmNode extends Node
	{
		public var arm:BossArm;
		public var state:BossState;
		public var followTarget:FollowTarget;
		public var spatial:Spatial;
		public var damageTarget:DamageTarget;
	}
}