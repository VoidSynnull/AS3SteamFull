package game.scenes.poptropolis.poleVault.states
{
	import game.components.entity.character.CharacterMotionControl;
	import game.data.animation.entity.character.poptropolis.PoleVaultAnim;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	
	public class PoleVaultRunState extends CharacterState
	{
		public function PoleVaultRunState()
		{
			super.type = CharacterState.RUN;
		}
		
		override public function start():void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			charControl.ignoreVelocityDirection = true;
			
			setAnim(PoleVaultAnim, true);
			CharUtils.getTimeline(node.entity).gotoAndPlay("poleVault");
		}
		
		override public function update( time:Number ):void
		{
			if(node.spatial.x > endX)
			{
				node.fsmControl.setState("noJump");
			}
			
			if(node.motionControl.inputActive)
			{
				node.fsmControl.setState("vault");
			}
			
			applyMotion();
		}
		
		/**
		 * Method for making the character run
		 */
		public function applyMotion():void
		{
			node.motion.maxVelocity.x = 800;
			
			if(node.spatial.x < threshold)
			{
				node.motion.acceleration.x = 150;
			}
			else
			{
				node.motion.acceleration.x = -300;
			}
		}
		
		public var threshold:Number = 100000000;
		public var endX:Number = 1000000;
	}
}