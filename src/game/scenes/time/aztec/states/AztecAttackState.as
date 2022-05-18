package game.scenes.time.aztec.states
{
	import flash.geom.Point;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionTarget;
	import game.data.animation.entity.character.Run;
	import game.systems.entity.character.states.CharacterState;
	import game.util.SkinUtils;
	
	public class AztecAttackState extends CharacterState 
	{

		public function AztecAttackState()
		{
			super.type = "attack";
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim(Run);
			SkinUtils.setSkinPart(node.entity, SkinUtils.MOUTH, "angry");
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMovement.state = CharacterMovement.GROUND;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var target:MotionTarget = node.entity.get(MotionTarget);
			
			target.useSpatial = true;
			
			// too far away, retreat
			if(Math.abs(node.spatial.x - originalLocation.x) >= 500 || Math.abs(target.targetSpatial.x - node.spatial.x) > 200 || target.targetSpatial.y < 1440 || maskOn)
			{
				node.motion.velocity.x = 0;
				node.fsmControl.setState("retreat");
				return;
			}
			
			// hit
			if(Math.abs(target.targetSpatial.x - node.spatial.x) < 40 && Math.abs(target.targetSpatial.y - node.spatial.y) < 49)
			{
				node.motion.velocity.x = 0;
				node.fsmControl.setState("hit_retreat");
				
				return;
			}
		}
		
		public var originalLocation:Point;
		public var maskOn:Boolean = false;
	}
}