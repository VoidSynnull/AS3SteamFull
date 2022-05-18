package game.scenes.survival5.chase.states
{
	import flash.geom.Point;
	
	import engine.components.Motion;
	
	import game.components.input.Input;
	import game.data.animation.entity.character.Jump;
	import game.data.animation.entity.character.poptropolis.HurdleJump;
	import game.managers.ScreenManager;
	import game.scenes.poptropolis.hurdles.Hurdles;
	import game.scenes.reality2.cheetahRun.CheetahRun;
	import game.scenes.survival5.chase.nodes.RunningCharacterStateNode;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SkinUtils;

	public class RunningCharacterJump extends RunningCharacterState
	{
		private var jumpHeight:Number = -.7;
		private const TRIGGER_LABEL:String = "stop";
		private const SPIN_LABEL:String = "spin";
		
		public function RunningCharacterJump()
		{
			super.type = RunningCharacterState.JUMP;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{			
			node.motion.velocity.y = Hurdles.JUMP_VEL_Y;
			node.motion.acceleration.y = Hurdles.JUMP_ACCEL_Y;
			
			setAnim( HurdleJump );
			super.updateStage = this.updateCheckTrigger;
			if( _uiHead && node.motionMaster.active )
			{
				SkinUtils.setEyeStates( _uiHead, "casual_still", "forward" );
			}
		}

		override public function check():Boolean
		{
			switch( node.looperCollider.collisionType )
			{
				case "puddle":
					node.looperCollider.isHit = false;
					return false;

				case "bush":
					node.looperCollider.isHit = false;
					return false;

				default:
					node.fsmControl.setState( RunningCharacterState.HURT );
					return true;
			}
		}

		/**
		 * Manage the state
		 */
		override public function update( time:Number ):void
		{
			super.update( time );
			super.updateStage();
		}
		
		private function updateCheckTrigger():void
		{	
			if( node.primary.current is HurdleJump )
			{
				if ( !(node.timeline.currentIndex < node.primary.getLabelIndex( TRIGGER_LABEL )))				
				{
					super.updateStage = this.updateCheckFall;
					applyJumpVelocity( node, node.charMotionControl.jumpDampener );
					var motion:Motion = node.motion;
					
					motion.acceleration = new Point( 0, MotionUtils.GRAVITY );
				}
			}
		}
		
		protected function applyJumpVelocity( node:RunningCharacterStateNode, dampener:Number = 1 ):void
		{
			node.motion.velocity.y = node.charMotionControl.jumpVelocity * -jumpHeight * dampener;
		}
		
		private function updateCheckFall():void
		{
			if ( node.motion.velocity.y >= 0 )
			{
				super.updateStage = this.updateCheckLand;
				return;
			}
		}
		
		protected function updateCheckLand():void
		{
			if ( node.platformCollider.isHit )
			{
				node.fsmControl.setState( RunningCharacterState.RUN );
				if(_isReality)
					CheetahRun(node.owningGroup.group.shellApi.currentScene).numJumps = 0;
				return;
			}
		}
		
		public override function onActiveInput( input:Input ):void
		{
			if(_isReality )
			{
				if(CheetahRun(node.owningGroup.group.shellApi.currentScene).numJumps < 5)
				{
					var state:String = node.fsmControl.state.type;
				
					if(  state != RunningCharacterState.HURT && state != RunningCharacterState.STUMBLE && state != RunningCharacterState.ROLL )
					{ 
						applyJumpVelocity(node);
					}
					CheetahRun(node.owningGroup.group.shellApi.currentScene).numJumps++;
				}
			}
		}
	}
}