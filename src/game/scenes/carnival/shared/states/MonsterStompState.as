package game.scenes.carnival.shared.states
{
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionTarget;
	import game.data.animation.entity.character.Stomp;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	public class MonsterStompState extends CharacterState
	{
		public function MonsterStompState()
		{
			super.type = "stomp";
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			super.setAnim(Stomp);
			node.charMotionControl.ignoreVelocityDirection = false;
			SkinUtils.setSkinPart(node.entity, SkinUtils.MOUTH, "angry");
			node.charMovement.state = CharacterMovement.GROUND;
		}
		
		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			var charControl:CharacterMotionControl = node.charMotionControl;
			var targetSpatial:Spatial = node.entity.get(MotionTarget).targetSpatial;
			
			// too far away, stand normal again, or mask is on
			if(Math.abs(targetSpatial.x - node.spatial.x) > 280 || targetSpatial.y < 1440 || maskOn)
			{
				node.fsmControl.setState("stand");
				return;
			}
			
			// check for attack
			if(Math.abs(targetSpatial.x - node.spatial.x) < 200 && targetSpatial.y >= 1440)
			{
				node.fsmControl.setState("attack");
				return;
			}
			
			if ( CharUtils.animAtLastFrame( node.entity, Stomp ) )
			{
				node.timeline.reset();
			}
		}
		
		public var maskOn:Boolean = false;
	}
}