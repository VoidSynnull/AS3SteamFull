package game.systems.timeline
{
	import game.components.entity.character.Character;
	import game.components.timeline.Timeline;
	import game.data.animation.FrameEvent;
	import game.data.character.CharacterData;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.timeline.TimelineRigNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.SkinUtils;
	
	/* TimelineEventSystem
	 * 
	 * Handles the non-standard timeline events
	 * 
	 **/

	public class TimelineRigSystem extends GameSystem
	{
		public function TimelineRigSystem()
		{
			super( TimelineRigNode, updateNode );
			super._defaultPriority = SystemPriorities.timelineEvent;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
			super.onlyApplyLastUpdateOnCatchup = true;
		}
				
		private function updateNode(node:TimelineRigNode, time:Number):void
		{
			if ( !node.timeline.lock )
			{
				if ( node.timeline.currentFrameData != null )	
				{
					if ( node.timeline.labels.length > 0 )
					{
						handleLabels( node );	// process events
					}
					
					if ( node.timeline.events.length > 0 )
					{
						handleFrameEvents( node );	// process events
					}
				}
			}
		}
		
		/**
		 * Processes all labels within a frame (or accumulated from multiple frames)
		 * @param	node
		 */
		private function handleLabels( node:TimelineRigNode ):void
		{	
			var timeline:Timeline = node.timeline;
			var label:String;
			
			var n:uint = 0;
			for (n; n < timeline.labels.length; n++)
			{	
				label = String( timeline.labels[n] );
				node.rigAnim.current.reachedFrameLabel( node.parent.parent, label );
			}
		}
		
		// Processes all FrameEvents within a frame
		private function handleFrameEvents( node:TimelineRigNode ):void
		{	
			var timeline:Timeline = node.timeline;
			
			var n:uint = 0;
			for (n; n < timeline.events.length; n++)
			{	
				if ( handleFrameEvent( timeline.events[n], node) )
				{
					timeline.events.splice(n, 1);
					n--;
				}
			}
		}

		private function handleFrameEvent(event:FrameEvent, node:TimelineRigNode ):Boolean
		{
			switch(event.type)
			{
				case FRAME_EVENT_SET_PART:
					// rlh: we want to suppress this for pets because some animations change the parts
					// if no pet animation.xml is found then the human animations are used
					if (node.parent.parent.get(Character).variant == CharacterData.VARIANT_PET_BABYQUAD)
					{
						return false;
					}
					// NOTE: set skinPart ( arg[0] ) to non-permanent value ( arg[1] )
					return SkinUtils.setSkinPart( node.parent.parent, event.args[0], event.args[1], false );				
				
				case FRAME_EVENT_SET_EYES:
					// args[0] == eye state, string
					// args[1] == pupil andle/state, can be an angle (Number) or a string
					// TODO :: Will want to change xml approach to use setEyes( eyeState, pupilState )
					if( event.args.length == 2 )
					{
						return SkinUtils.setEyeStates( node.parent.parent, event.args[0], event.args[1], false );
					}
					else
					{
						return SkinUtils.setEyeStates( node.parent.parent, event.args[0], null, false );
					}
					
			}
			return false;
		}
		
		public static const FRAME_EVENT_SET_EYES:String = "setEyes";
		public static const FRAME_EVENT_SET_PART:String = "setPart";
	}
}
