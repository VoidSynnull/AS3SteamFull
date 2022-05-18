package game.systems.entity.character.states 
{
	import game.components.Viewport;
	import game.data.animation.Animation;
	import game.nodes.entity.character.CharacterStateNode;
	import game.systems.animation.FSMState;
	import game.util.ClassUtils;
	
	import org.osflash.signals.ISlot;

	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class CharacterState extends FSMState
	{
		public function CharacterState() {}
		
		/**
		 * Use getter to cast node to CharacterStateNode.
		 */
		public function get node():CharacterStateNode
		{
			return CharacterStateNode(super._node);
		}

		/**
		 * Use viewport dimension to determine state level constants.
		 * TODO :: Want to move viewport info to a component, so this will go away
		 * @param	viewWidth
		 * @param	viewHeight
		 */
		//public function setViewport( viewWidth:Number, viewHeight:Number ):void { }
		public function setViewport( viewPort:Viewport ):void { }
		
		////////////////////////////////////////////////////////////////////////
		///////////////////////////// HELPER METHODS ///////////////////////////
		////////////////////////////////////////////////////////////////////////

		/**
		 * Pass the state of local variables, this can be extended via override
		 */
		public function mirror( charState:CharacterState ):CharacterState
		{
			return charState;
		}

		/**
		 * Update facing direction by velocity
		 * @param	node
		 * @return
		 */
		public function directionByVelocity():void
		{
			if ( node.motion.velocity.x > 0 )
			{
				node.spatial.scaleX = -node.spatial.scale;
			}
			else if( node.motion.velocity.x < 0 )
			{
				node.spatial.scaleX = node.spatial.scale;
			}
		}
		
		/**
		 * Resets max velocity and sets friction to 0.
		 * @param	node
		 * @param	animClass
		 */
		protected function resetMotion():void
		{		
			node.motion.maxVelocity.x = node.charMotionControl.maxVelocityX;
			node.motion.maxVelocity.y = node.charMotionControl.maxVelocityY;
			node.motion.friction.x = 0;
		}
		
		/**
		 * Set the animation
		 * @param	node
		 * @param	animClass
		 */
		protected function setAnim(animClass:Class, listendForEnd:Boolean = false ):void
		{		
			if( node.primary != null )
			{
				//trace("CharacterState :: next animation class:", animClass);
				node.primary.next = animClass;
				if ( listendForEnd )
				{
					var slot:ISlot = node.primary.ended.add( onEnd );
					slot.params = [animClass];
				}
			}
		}
		
		// TODO :: Would like listening to not be signal based, so it can clean up on removal.
		
		/**
		 * Handler for when animation ends, sets flag within CharacterStateControl
		 * @param	anim
		 * @param	animClass
		 * @param	stateControl
		 */
		private function onEnd( anim:Animation, animClass:Class ):void
		{		
			if(node)
			{
				if ( ClassUtils.getClassByObject( anim ) == animClass )
				{
					node.primary.ended.remove( onEnd );
					node.charMotionControl.animEnded = true;
				}
			}
		}
		
		protected function getCurrentAnim():Class
		{
			return ClassUtils.getClassByObject(node.primary.current);
		}
		
		override public function exit():void
		{
			if(node)
			{
				if(node.primary)
				{
					node.primary.ended.remove(onEnd);
				}
			}
			super.exit();
		}
		
		////////////////////////////////////////////////////////////////////////
		///////////////////////////// STATE TYPES //////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		public static const CLICK_DELAY:Number	= .15;	
		
		public static const JUMP:String 	= "jump";
		public static const CLIMB:String 	= "climb";
		public static const SWIM:String 	= "swim";
		public static const DIVE:String 	= "dive";
		public static const LAND:String 	= "land";
		public static const STAND:String 	= "stand";
		public static const WALK:String 	= "walk";
		public static const RUN:String 		= "run";
		public static const SKID:String 	= "skid";
		public static const DUCK:String 	= "duck";
		public static const FALL:String 	= "fall";
		public static const HURT:String 	= "hurt";
		public static const IDLE:String 	= "idle";
		public static const PUSH:String 	= "push";
	}

}