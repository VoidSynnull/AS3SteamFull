package game.scenes.time.aztec.states
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionTarget;
	import game.data.animation.entity.character.Run;
	import game.systems.entity.character.states.CharacterState;
	
	public class AztecRetreatState extends CharacterState
	{
		public function AztecRetreatState()
		{
			super.type = "retreat";
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim(Run);
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
			var targetSpatial:Spatial = node.entity.get(MotionTarget).targetSpatial;
			
			target.useSpatial = false;
			
			// back at the original location
			if(Math.abs(target.targetX - node.spatial.x) < 10)
			{
				node.fsmControl.setState("stand");
				return;
			}
			
			// attack
			if(Math.abs(targetSpatial.x - node.spatial.x) < 200 && Math.abs(targetSpatial.x - originalLocation.x) < 500 && targetSpatial.y >= 1440 && !maskOn)
			{
				node.fsmControl.setState("attack");
				return;
			}
		}
		
		public var maskOn:Boolean = false;
		public var originalLocation:Point;
	}
}