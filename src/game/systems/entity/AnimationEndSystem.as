package game.systems.entity
{
	import game.components.entity.character.animation.RigAnimation;
	import game.data.animation.entity.RigAnimationData;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.AnimationEndNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	/** 
	 * Checks for the 'end' of animations, flagging the RigAnimation end to true
	 * Animations end when:
		 * they have reached their last frame and they have not been specified to not end within their xml
		 * When the duration, if it was set, reaches zero. 
	 * 
	 * 
	 **/

	public class AnimationEndSystem extends GameSystem
	{
		public function AnimationEndSystem()
		{
			super( AnimationEndNode, updateNode )
			super._defaultPriority = SystemPriorities.updateAnim;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
		}

		private function updateNode( node:AnimationEndNode, time:Number ):void
		{
			var rigAnim:RigAnimation = node.rigAnim;
			
			if ( rigAnim.current)				// if current has been set
			{
				if ( rigAnim.next == null )	// if not waiting on next
				{
					if( !rigAnim.manualEnd )
					{
						checkLastFrame( node );			// check for last frame
						updateDuration( node );			// update & check duration	//TODO :: we may want to be able to disable of override
					}
					else
					{
						rigAnim.end = true;
						rigAnim.duration = 0;
						rigAnim.manualEnd = false;
					}
				}
			}
		}
	
		/**
		 * Checks if animation reached its last frame.
		 * @param	node
		 */
		private function checkLastFrame( node:AnimationEndNode ):void
		{
			var rigAnim:RigAnimation = node.rigAnim;
			var data:RigAnimationData = rigAnim.current.data;
			
			if ( !data.noEnd && !rigAnim.loop)	// if animation is meant to end ( this is the default )
			{
				// if timeline is at last frame & stopped, animation has ended
				if ( node.timeline.currentIndex == data.duration - 1 && !node.timeline.playing )	
				{
					rigAnim.end = true;
					rigAnim.duration = 0;	// when animation ends we clear the duration as well
				}
			}
		}
		
		/**
		 * Checks if duration (set by frames), if it was set, has reached zero.
		 * Decrements duration on each frame played.
		 * @param	node
		 */
		private function updateDuration( node:AnimationEndNode ):void
		{
			var rigAnim:RigAnimation = node.rigAnim;
			
			if ( rigAnim.duration > 0 )			// if duration was set
			{
				if ( node.timeline.frameAdvance )		// when frame increments
				{
					rigAnim.duration--;			// decrement duration
					if ( rigAnim.duration <= 0 )
					{
						rigAnim.duration = 0;
						rigAnim.end = true;		// when duration reaches zero, animation has ended		
					}
				}
			}
		}
	}
}
