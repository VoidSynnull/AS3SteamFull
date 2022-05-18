package game.scenes.time.aztec.states
{
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionTarget;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Walk;
	import game.systems.entity.character.states.CharacterState;
	import game.util.SkinUtils;

	public class AztecStandState extends CharacterState 
	{
		public function AztecStandState()
		{
			super.type = "stand";
		}

		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim(Walk);
			SkinUtils.setSkinPart(node.entity, SkinUtils.MOUTH, "14");
			SkinUtils.setEyeStates(node.entity, "squint");
			node.charMotionControl.ignoreVelocityDirection = false;
			node.charMotionControl.directionByVelocity = true;
			node.charMovement.state = CharacterMovement.GROUND;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var targetSpatial:Spatial = node.entity.get(MotionTarget).targetSpatial;
			
			if(node.entity.get(Motion).velocity.x == 0)
				super.setAnim(Stand);
			
			if(waitCounter <= 0 && !maskOn)
			{
				// check for stomp
				if(Math.abs(targetSpatial.x - node.spatial.x) < 280 && targetSpatial.y >= 1440)
				{
					node.fsmControl.setState("stomp");
					return;
				}
			}
			else
			{
				waitCounter -= .1;
			}
		}
		
		public var maskOn:Boolean = false;
		public var waitCounter:Number = 0;
	}
}