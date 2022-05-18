package game.scenes.poptropolis.poleVault.states
{
	import flash.geom.Point;
	
	import game.data.animation.entity.character.poptropolis.PoleVaultAnim;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	
	public class PoleVaultLandState extends CharacterState
	{
		public function PoleVaultLandState()
		{
			super.type = CharacterState.LAND;
		}
		
		override public function start():void
		{
			node.motion.friction = new Point(0, 0);
			node.motion.velocity = new Point(0, 0);
			node.motion.acceleration = new Point(0, 0);
			
			setAnim(PoleVaultAnim);
			CharUtils.getTimeline(node.entity).gotoAndPlay("landing");
			CharUtils.getTimeline(node.entity).handleLabel("ending", landEnded, true);
		}
		
		override public function update( time:Number ):void
		{
			node.motion.friction = new Point(0, 0);
			node.motion.velocity = new Point(0, 0);
			node.motion.acceleration = new Point(0, 0);
		}
		
		private function landEnded():void
		{
			node.fsmControl.setState(CharacterState.STAND);
		}
	}
}