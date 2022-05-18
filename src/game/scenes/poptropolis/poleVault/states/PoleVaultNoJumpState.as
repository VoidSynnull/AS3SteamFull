package game.scenes.poptropolis.poleVault.states
{
	import flash.geom.Point;
	
	import game.data.animation.entity.character.Skid;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;

	public class PoleVaultNoJumpState extends CharacterState
	{
		public function PoleVaultNoJumpState()
		{
			super.type = "noJump";
		}
		
		override public function start():void
		{
			node.motion.acceleration = new Point(0, 0);
			
			CharUtils.setAnim(node.entity, Skid);
			CharUtils.getTimeline(node.entity).handleLabel("ending", skidDone);
		}
		
		private function skidDone():void
		{
			node.fsmControl.setState(CharacterState.STAND);
		}
	}
}