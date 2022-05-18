package game.scenes.poptropolis.poleVault.states
{
	import flash.geom.Point;
	
	import game.components.entity.character.CharacterMovement;
	import game.systems.entity.character.states.CharacterState;
	import game.util.MotionUtils;

	public class PoleVaultLaunchState extends CharacterState
	{
		public function PoleVaultLaunchState()
		{
			super.type = "launch";
		}
		
		override public function start():void
		{
			// reset these values so we can apply correct launch
			node.motion.velocity = new Point(0, 0);
			node.motion.acceleration = new Point(0,0);
			node.motion.friction = new Point(0, 0);
			maxHeight = 1108;
			applyLaunch();
			node.charMovement.state = CharacterMovement.NONE;
		}
		
		override public function update( time:Number ):void
		{
			node.motion.acceleration.y = MotionUtils.GRAVITY - 800;
			
			if(node.spatial.y < maxHeight)
			{
				maxHeight = node.spatial.y;
			}
			
			// once moving down, look for collision
			if(node.motion.velocity.y >= 0)
			{
				if(node.platformCollider.isHit)
				{
					node.fsmControl.setState(CharacterState.LAND);
				}
			}
		}
		
		private function applyLaunch():void
		{
			var angle:Number = (90 / meterMax) * meter;
			angle = (angle * Math.PI) / 180;
			node.motion.velocity.x = Math.cos(angle) * runVelocity;
			node.motion.velocity.y = -(Math.sin(angle) * (runVelocity * 1.85));
		}
		
		public var runVelocity:Number;
		public var meter:Number;
		public var meterMax:Number;
		public var maxHeight:Number = 1108;
	}
}