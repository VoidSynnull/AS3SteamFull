package game.scenes.poptropolis.longJump.states 
{
	import game.components.entity.character.CharacterMotionControl;
	import game.data.animation.entity.character.poptropolis.LongJumpAnim;
	import game.nodes.entity.character.CharacterStateNode;
	import game.systems.entity.character.states.CharacterState;
	import game.util.ClassUtils;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class LongJumpState extends CharacterState
	{
		private var TRIGGER_LABEL:String = "trigger";
		public var jumpCount:int = 0;	// TODO :: remember to clear this on each set
		
		public function LongJumpState()
		{
			super.type = CharacterState.JUMP;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void 
		{

			// TODO :: Might want to zero velocity, so char is standing still when they jump?
			// could save initial velocity to reapply when applying jump velocity
			setAnim( LongJumpAnim );
			super.updateStage = this.updateCheckTrigger;
		}
		
		/**
		 * Manage the state
		 */
		override public function update(time:Number):void
		{
			super.updateStage();
		}
		
		/////////////////////////////////////////////////////////////////
		////////////////////////// UPDATE STAGES ////////////////////////
		/////////////////////////////////////////////////////////////////
		
		private function updateCheckTrigger():void
		{	
			var charState:CharacterMotionControl = node.charMotionControl;
			
			var currentClass:Class = ClassUtils.getClassByObject( node.primary.current );
			if( currentClass == LongJumpAnim )
			{
				// once trigger frame has been reached, apply velocity
				if ( !(node.timeline.currentIndex < node.primary.getLabelIndex(TRIGGER_LABEL)) )				
				{
					applyJumpVelocity( node, charState.jumpDampener );
					super.updateStage = this.updateCheckFall;
				}
			}
		}
		
		private function applyJumpVelocity( node:CharacterStateNode, dampener:Number = 1 ):void
		{
			// jump velocity should be effected by the number of jumps (3rd jump is higher)
			// apply jump velocity
			node.motion.velocity.x = 300;	// TODO :: get appropriate velocities
			node.motion.velocity.y = -400;
			node.motion.maxVelocity.y = node.charMotionControl.maxFallingVelocity;
		}
		
		private function updateCheckFall():void
		{
			// once moving down, check for collision with surfaces
			if ( node.motion.velocity.y >= 0 )	
			{
				node.timeline.gotoAndPlay( "apex" );	// TODO :: Not sure how this should works, know the animation changes
				super.updateStage = this.updateCheckLand;	
				super.updateStage();
				return;
			}
			
			applyMotion();
		}
		
		private function updateCheckLand():void
		{
			// check for platform collision
			if ( node.platformCollider.isHit )		
			{
				// TODO :: Not sure what happens with landing on triple jump, do you start running until you release mouse?
				node.fsmControl.setState( CharacterState.LAND );
				return;
			}
			
			applyMotion();
		}
		
		private function applyMotion():void
		{
			// apply gravity to y
			node.motion.acceleration.y = node.charMotionControl.gravity;
		}
	}
}