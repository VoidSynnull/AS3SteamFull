package game.systems.timeline
{
	import flash.display.MovieClip;
	
	import ash.tools.ListIteratingSystem;
	
	import game.components.timeline.Timeline;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.timeline.TimelineClipNode;
	import game.systems.SystemPriorities;
	
	/**
	 * Links a MovieClip's frame progression to a Timeline component
	 */
	public class TimelineClipSystem extends ListIteratingSystem
	{
		public function TimelineClipSystem()
		{
			super( TimelineClipNode, updateNode ); 
			super._defaultPriority = SystemPriorities.timelineEvent;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
		}
		
		private function nodeRemoved( node:TimelineClipNode ) : void
		{	
			node.timelineClip.mc.stop();
			node.timelineClip.mc = null;
		}
			
		private function updateNode(node:TimelineClipNode, time:Number):void
		{
			var timeline:Timeline = node.timeline;

			// NOTE :: mc timelines start at 1, Timeline component starts at 0
			if ( !timeline.lock )
			{
				if( timeline.currentIndex != -1 )	// When Timeline is reset it's index is set to -1, do not update mc in this state
				{
					var mc:MovieClip = node.timelineClip.mc;
					if ( timeline.currentIndex != (mc.currentFrame - 1) )
					{
						mc.gotoAndStop( timeline.currentIndex + 1 );
						//trace("TimelineClipSystem :: " + mc.name + " current frame : " + mc.currentFrame + " timeline index: " + timeline.currentIndex );
					}
				}
			}
		}
	}
}
