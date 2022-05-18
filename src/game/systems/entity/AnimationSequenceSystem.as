package game.systems.entity
{
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.data.animation.AnimationData;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.AnimationSequenceNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.ClassUtils;

	/* AnimationSequenceSystem
	 * 
	 * Manages animation sequence for animation slot entities.
	 * An animation sequence is an array of AnimationData data objects.
	 * AnimationData can contain a Animation Class and a duration.  
	 * The AnimationData are stored within a AnimationSequence data class.
	 * AnimationSequence can provides access to the AnimationData. 
	 * The AnimationSequenceas also specifies how the sequcne should be handled.
	 * random - if true then AnimationData is selected randomly from the sequence, otherwise it is slected sequencially  (should the 
	 * loop - if the sequence should loop, if random is true it loops automatically
	 **/

	public class AnimationSequenceSystem extends GameSystem
	{
		public function AnimationSequenceSystem()
		{
			super( AnimationSequenceNode, updateNode );
			super._defaultPriority = SystemPriorities.sequenceAnim;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
		}
		
		/**
		 * If AnimationSequencer contains sequences update the sequence.
		 * Sequence is update if is set to tstart, or when current Riganimation is has ended
		 * @param	node
		 */
		private function updateNode( node:AnimationSequenceNode, time:Number ):void
		{
			var animSequencer:AnimationSequencer = node.animSequencer;

			// if AnimationSequencer conatins a sequence, determine if and what it should play next
			if ( animSequencer.active )
			{
				if ( animSequencer.start )			// if sequence is starting
				{
					animSequencer.index = -1;		// reset index
					setNextAnim( node );			// set RigAnimation from new sequence
					animSequencer.start = false;
				}
				else if ( node.rigAnim.end && node.rigAnim.next == null )		// current animation has reached end & next animation not pending
				{
					// if primary and fsm is active, only duration can reset sequence
					// this is because essentially we want to treat auto like a looping animation
					if ( node.animSlot.priority == 0 )
					{
						if( node.fsmControl )
						{
							if( node.fsmControl.active )
							{
								if ( node.rigAnim.duration == 0)
								{
									setNextAnim( node );
								}
								return;
							}
						}
					}
					
					setNextAnim( node );
				}
			}
		}
		
		/**
		 * Sets the next animation in the sequence
		 * @param	node
		 */
		private function setNextAnim( node:AnimationSequenceNode ):void
		{
			if( node.animSequencer.interrupt )
			{
				node.animSequencer.interrupt = false;
				return;
			}
			
			var animSequencer:AnimationSequencer = node.animSequencer;
			var animControl:AnimationControl = node.animControl;
			
			// Get next AnimationData from Sequence
			var nextAnimData:AnimationData = getNextAnimData( node );
			
			// If AnimationData exists and has next Animation, if not RigAnimation next remains null.
			// AnimationControlSystem follows and determines if slot becomes inactive.
			if( nextAnimData )
			{
				if ( nextAnimData.animClass )
				{
					if ( node.animSlot.priority == 0 )		// if  primary, turn off fsm control
					{
						if( node.fsmControl )
						{
							node.fsmControl.active  = false;
						}
						if( node.charMovement )
						{
							node.charMovement.active  = false;
						}
					}
					
					if ( nextAnimData.animClass == ClassUtils.getClassByObject( node.rigAnim.current ) )	// if same then restart current Animation
					{	
						node.timeline.nextIndex = 0;		// restart timeline
						node.timeline.playing = true;
						node.rigAnim.end = false;
					}
					else									// set next Animation to new Animation class
					{
						node.rigAnim.next = nextAnimData.animClass;
					}
				}
			}
			
			// set or reset duration from AnimationData, 
			// if nextAnimData is null duration defaults to zero.
			node.rigAnim.duration = getDuration( nextAnimData );
		}
		
		/**
		 * Get the next AnimationData in the currentSequence.
		 * If current sequence is null then default is set as current
		 * @param	node
		 * @return
		 */
		private function getNextAnimData( node:AnimationSequenceNode ):AnimationData
		{
			var animSequencer:AnimationSequencer = node.animSequencer;
			
			if ( !animSequencer.currentSequence )	// if current if null, set current to default
			{
				node.animSequencer.currentSequence = node.animSequencer.defaultSequence;
			}
			
			// check that sequence has AnimationData
			if ( animSequencer.currentSequence.sequence.length == 0 )
			{
				return null;
			}
			
			// update index 
			if ( animSequencer.currentSequence.random )			// if sequence is random, get next sequence & return ( random loops automatically )
			{
				if ( animSequencer.currentSequence.sequence.length > 1 )
				{
					animSequencer.index = Math.floor( Math.random() * animSequencer.currentSequence.sequence.length );
				}
				else
				{
					animSequencer.index = 0;
				}
			}
			else													// sequence is not random
			{
				animSequencer.index++;
				
				// check index
				if ( animSequencer.index >= animSequencer.currentSequence.sequence.length )
				{
					if ( animSequencer.currentSequence.loop )	// if current sequence is set to loop, set index back to start
					{
						animSequencer.index = 0;
					}
					else										// if current sequence is not set to loop, sequence has ended
					{
						// if currentSequence is not the default, and a defaultSequence exist, set current to default and reiterate
						if ( animSequencer.currentSequence != animSequencer.defaultSequence && animSequencer.defaultSequence )
						{
							animSequencer.currentSequence = animSequencer.defaultSequence;
							animSequencer.index = -1;	
							return getNextAnimData(node);
						}
						else	// sequence has ended
						{
							return null;
						}
					}
				}
			}
			
			// return AnimationData at index
			return animSequencer.currentSequence.getAnimDataAt( animSequencer.index );
		}
		
		/**
		 * Returns the duration of the AnimationData, if AnimationData is false returns 0.
		 * @param	animData
		 * @return
		 */
		private function getDuration( animData:AnimationData ):int
		{
			// check duration
			if ( animData )
			{
				if ( animData.duration > 0 )
				{
					return animData.duration;
				}
			}
			return 0;
		}
	}
}
