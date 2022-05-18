package game.scenes.examples.customCharacter.states
{
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.Viewport;
	import game.components.timeline.Timeline;
	import game.scenes.examples.customCharacter.CustomCharacterNode;
	import game.systems.animation.FSMState;
	import game.systems.entity.character.states.CharacterState;
	import game.util.TimelineUtils;
	
	public class CustomCharacterState extends FSMState
	{
		public function CustomCharacterState() 
		{
		
		}
		/**
		 * Use getter to cast node to CharacterStateNode.
		 */
		public function get node():CustomCharacterNode
		{
			return CustomCharacterNode(super._node);
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
			node.motion.maxVelocity.x = node.characterMotionControl.maxVelocityX;
			node.motion.maxVelocity.y = node.characterMotionControl.maxVelocityY;
			node.motion.friction.x = 0;
		}
		
		/**
		 * Set the animation
		 * @param	node
		 * @param	animClass
		 */
		protected function setAnim(label:String, play:Boolean = true, callback:Function = null, args:Array = null):void
		{
			if(node.timeline != null)
			{
				if(play)
				{
					node.timeline.gotoAndPlay(label);
					
					if(callback)
					{
						if(args == null)
						{
							args = new Array();
						}
						
						args.unshift(label);
						
						node.timeline.labelReached.addOnce(Command.create(callback, args));
					}
				}
				else
				{
					node.timeline.gotoAndStop(label);
				}	
			}
		}
		
		protected function setChildLabel(child:String, label:String, play:Boolean = true):void
		{
			var childEntity:Entity = TimelineUtils.getChildClip(node.entity, child);
			
			try
			{
				var timeline:Timeline = childEntity.get(Timeline);
				if(play) timeline.gotoAndPlay(label);
				else timeline.gotoAndStop(label);
			} 
			catch(error:Error) 
			{
				trace("MovieclipState at: "+child+" ... Couldn't find a timeline on the child entity.");
			}			
		}
		
		// TODO :: Would like listening to not be signal based, so it can clean up on removal.
		
		/**
		 * Handler for when animation ends, sets flag within CharacterStateControl
		 * @param	anim
		 * @param	animClass
		 * @param	stateControl
		 */
		/*
		private function onEnd( anim:Animation, animClass:Class ):void
		{		
			if(node)
			{
				if ( Utils.getClass( anim ) == animClass )
				{
					node.primary.ended.remove( Command.create( onEnd, animClass ) );
					node.charMotionControl.animEnded = true;
				}
			}
		}
		*/
		
		/*
		protected function getCurrentAnim():Class
		{
			return Utils.getClass(node.primary.current);
		}
		*/
		////////////////////////////////////////////////////////////////////////
		///////////////////////////// STATE TYPES //////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		public var animationId:String;   // the animation frame to play when state is reached.
		
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