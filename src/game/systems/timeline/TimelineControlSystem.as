package game.systems.timeline
{

	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.timeline.Timeline;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.timeline.TimelineNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;

	/**
	 * Handles the standard playhead events from Flash and keeps track of the frame index.
	 * Updates each frame through use of time accumulator.
	 * Updates frame labels and events, adding them to an array, each frame.
	 * Labels and events are processed by other systems ( TimelineLabelSystem, RigTimelineSystem )
	 * 
	 */
	
	public class TimelineControlSystem extends System
	{
		public function TimelineControlSystem()
		{
			super._defaultPriority = SystemPriorities.timelineControl;
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
			super.linkedUpdate = FixedTimestep.ANIMATION_LINK;
		}

		override public function addToEngine( game : Engine ) : void
		{
			_nodes = game.getNodeList( TimelineNode );
			_game = game;
			_timelineManager = new TimelineManager();
			_nodes.nodeRemoved.add( nodeRemoved );
		}
		
		private function nodeRemoved( node:TimelineNode ) : void
		{	
			/*
			node.timeline.events = null;
			node.timeline.frame = null;
			node.timeline.labels = null;
			*/
			node.timeline.labelHandlers = null;
			node.timeline.labelReached.removeAll();
		}
		
		/**
		 * Updates enties each frame instead of each update.
		 * @param	time
		 */
		override public function update( time : Number ) : void
		{	
			var node : TimelineNode;
			for ( node = _nodes.head; node; node = node.next )
			{
				if (EntityUtils.sleeping(node.entity))
				{
					continue;
				}
				
				// update timeline
				var timeline:Timeline = node.timeline;
				timeline.labels.length = 0;	// clear labels each update (so they are not handled multiple times)
				timeline.frameAdvance = true;
				_timelineManager.updateTimeline( timeline, node.entity );
				
				// process labels
				_timelineManager.handleLabels( timeline );
			}
		}

		protected var _nodes:NodeList;
		protected var _game:Engine;
		protected var _timelineManager:TimelineManager;
	}
}
