package game.scenes.poptropolis.poleVault.states
{
	import game.data.animation.entity.character.poptropolis.PoleVaultAnim;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;

	public class PoleVaultVaultState extends CharacterState
	{
		public function PoleVaultVaultState()
		{
			super.type = "vault";
		}
		
		override public function start():void
		{
			node.charMotionControl.ignoreVelocityDirection = true;
			PoleVaultLaunchState(node.fsmControl.getState("launch")).runVelocity = node.motion.velocity.x;
			
			setAnim(PoleVaultAnim);
			CharUtils.getTimeline(node.entity).gotoAndPlay("launch");
		}
		
		override public function update( time:Number ):void
		{
			if(!node.motionControl.inputActive)
			{
				node.fsmControl.setState("launch");
			}
			
			applyMotion();
		}
		
		public function applyMotion():void
		{
			node.motion.acceleration.x = 0;
			node.motion.velocity.x = 0;
		}
	}
}