package game.scenes.poptropolis.poleVault.states
{
	import flash.geom.Point;
	
	import game.data.animation.entity.character.Stand;
	import game.systems.entity.character.states.CharacterState;
	
	public class PoleVaultStandState extends CharacterState
	{
		public function PoleVaultStandState()
		{
			super.type = CharacterState.STAND;
		}
		
		override public function start():void
		{
			node.motion.friction = new Point(0, 0);
			node.motion.velocity = new Point(0, 0);
			node.motion.acceleration = new Point(0, 0);
			
			setAnim(Stand, true);
		}
		
		override public function update( time:Number ):void
		{
			node.motion.friction = new Point(0, 0);
			node.motion.velocity = new Point(0, 0);
			node.motion.acceleration = new Point(0, 0);
		}
	}
}