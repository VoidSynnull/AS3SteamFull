package game.systems.timeline
{

	import ash.core.Engine;
	
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMasterVariable;
	import game.nodes.timeline.TimelineVariableNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	/**
	 * Handles the standard playhead events from Flash and keeps track of the frame index.
	 * Updates each frame through use of time accumulator.
	 * Updates frame labels and events, adding them to an array, each frame.
	 * Labels and events are processed by other systems ( TimelineLabelSystem, RigTimelineSystem )
	 * 
	 */
	
	public class TimelineVariableSystem extends GameSystem
	{
		public function TimelineVariableSystem()
		{
			super( TimelineVariableNode, updateNode, null, nodeRemoved );
			super._defaultPriority = SystemPriorities.timelineControl;
		}

		override public function addToEngine( game : Engine ) : void
		{
			_timelineManager = new TimelineManager();
			super.addToEngine( game );
		}
		
		private function nodeRemoved( node:TimelineVariableNode ) : void
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
		private function updateNode(node:TimelineVariableNode, time:Number):void
		{
			// determine is timeline shoudl advance
			var timeline:Timeline = node.timeline;
			var variable:TimelineMasterVariable = node.masterVariable;
			
			variable.timeAccumulator += time;
			
			if(variable.timeAccumulator >= variable.timePerFrame)
			{
				// update timeline
				var numUpdates:int = Math.floor( variable.timeAccumulator / variable.timePerFrame )
				variable.timeAccumulator = ( variable.precise ) ? variable.timeAccumulator % variable.timePerFrame : 0;
				timeline.labels.length = 0;	// clear labels each update (so they are not handled multiple times)
				timeline.frameAdvance = true;
				var i:uint;
				for (i = 0; i < numUpdates; i++) 
				{
					_timelineManager.updateTimeline( timeline, node.entity );
				}
				
				// process labels
				_timelineManager.handleLabels( timeline );
			}
			else
			{
				timeline.frameAdvance = false;
			}
		}
		
		private var _timelineManager:TimelineManager;
	}
}
