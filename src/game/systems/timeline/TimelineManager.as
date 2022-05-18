package game.systems.timeline
{
	import ash.core.Entity;
	
	import game.components.entity.Parent;
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.data.animation.FrameEvent;
	import game.data.animation.LabelHandler;
	import game.util.EntityUtils;

	public class TimelineManager
	{
		public function TimelineManager()
		{
		}
		
		/**
		 * Set the next frame index, updating labels and events for that frame.
		 * Handles both playing and pause states
		 * If playing updates based on the next frame
		 * If paused updates the current frame
		 * @param	node
		 */
		public function updateTimeline( timeline:Timeline, entity:Entity ):void
		{
			timeline.looped = false;			// reset looped to false, checked for true within process()
			
			if ( !timeline.lock )
			{
				if ( timeline.events.length > 0 )	// if commands were set directly (from scene) process first (shoud override framedata) 
				{
					process(timeline, entity);
				}
				else if ( timeline.playing )		// set to next index (if not yet set) 
				{
					if ( timeline.currentIndex != timeline.nextIndex )	
					{
						setTimelineIndex( timeline, timeline.nextIndex );
					}
					
					process(timeline, entity);
				}
				else if ( timeline.paused )
				{
					setTimelineIndex( timeline, timeline.currentIndex );
					process(timeline, entity);
				}
			}
		}
		
		/**
		 * Handles timeline commands for current frame, increments index if playing is true.
		 * If the timeline command is a goToAnd... then setTimelineIndex and process are called again.
		 * Repeating setTimelineIndex concats labels and events for the multiple frames.
		 * @param	node
		 */
		private function process( timeline:Timeline, entity:Entity  ):void 
		{
			if( timeline.events.length > 0 )
			{
				handleFrameEvents( timeline, entity );	// process basic timeline events ( gotoAndPlay, gotoAndStop, play, stop )
			}
			
			// once timeline events have been handled...
			if ( timeline.currentIndex != timeline.nextIndex )	// gotoAnd was handled or nextFrame was called, update current index and process again
			{
				if ( timeline.nextIndex < timeline.currentIndex )
				{
					timeline.looped = true;	// TODO :: not a fool proof way checking for loop
				}
				setTimelineIndex( timeline, timeline.nextIndex );
				process(timeline, entity);
			}
			else if ( timeline.playing )
			{
				if ( !timeline.reverse )
				{
					timeline.nextIndex++;
					if ( timeline.nextIndex >= timeline.data.duration )
					{ 
						timeline.nextIndex = 0;	//loop by default
						timeline.looped = true;
					}
				}
				else
				{
					timeline.nextIndex--;
					if ( timeline.nextIndex < 0 )
					{ 
						timeline.nextIndex = timeline.data.duration - 1;	//loop by default
						timeline.looped = true;
					}
				}
			}
		}
		
		/**
		 * Set the index of the timeline and updates labels and events for the corresponding frame
		 * @param	timeline
		 * @param	index
		 */
		private function setTimelineIndex( timeline:Timeline, index:Number ):void 
		{
			if ( index > -1 && index < timeline.data.duration )
			{
				timeline.currentFrameData = timeline.data.getFrame(index);	// assign reference to FrameData from RigAnimationData of current Animation
				timeline.currentIndex = timeline.nextIndex = index;
				timeline.events = timeline.events.concat( timeline.currentFrameData.events );	// TODO :: Might be a more efficient way to copy/merge arrays?
				timeline.labels = ( timeline.currentFrameData.label ) ? timeline.labels.concat( timeline.currentFrameData.label ) : timeline.labels;
				
				// add labels for beginning and ending of animations
				if ( index == 0 )
				{
					timeline.labels.push( Animation.LABEL_BEGINNING );
				}
				if ( index == (timeline.data.duration - 1) )
				{
					timeline.labels.push( Animation.LABEL_ENDING );
				}
			}
		}
		
		/**
		 * Processes all FrameEvents within a frame
		 * @param	node
		 */
		private function handleFrameEvents( timeline:Timeline, entity:Entity ):void
		{	
			var n:uint = 0;
			for (n; n < timeline.events.length; n++)
			{		
				if ( handleFrameEvent( timeline.events[n], timeline, entity) )
				{
					timeline.events.splice(n, 1);
					n--;
				}
			}
		}
		
		/**
		 * Checks for timeline specific events, and processes them accordingly
		 * @param	event
		 * @param	node
		 * @return
		 */
		private function handleFrameEvent( event:FrameEvent, timeline:Timeline, entity:Entity ):Boolean
		{
			if ( event.type == FRAME_EVENT_GOTOANDPLAY )
			{
				gotoAndPlay( event.args[0], timeline );
				return true;
			}
			else if ( event.type == FRAME_EVENT_GOTOANDSTOP )
			{
				gotoAndStop( event.args[0], timeline );
				return true;
			}
			else if ( event.type == FRAME_EVENT_STOP )
			{
				stop( timeline );
				return true;
			}
			else if ( event.type == FRAME_EVENT_PLAY )
			{
				play( timeline );
				return true;
			}
			else if(event.type == FRAME_EVENT_CHILD)
			{
				var children:Vector.<String> = event.args[0];
				var childEntity:Entity = entity;
				var nextEntity:Entity;
				if(children != null)
				{
					for(var i:int = 0; i < children.length; i++)
					{
						if(children[i] == FRAME_EVENT_PARENT)//can access parentage now parent.parent.parent.parent
							nextEntity = Parent(childEntity.get(Parent)).parent;
						else
							nextEntity = EntityUtils.getChildById( childEntity, children[i]);
						
						if(nextEntity != null)
							childEntity = nextEntity;
					}
					if(childEntity != null)
					{
						var time:Timeline = childEntity.get(Timeline);
						if(time != null)
						{
							time.events.push(event.args[1]);
							return true;
						}
					}
				}
			}
			
			return false;
		}
		
		// TODO : convert labels to a frame index
		private function gotoAndPlay(frameName:*, timeline:Timeline):void
		{
			var frame:int = -1;
			if (typeof(frameName) == "number")	// TODO :: I don't think these are being cast to number when parsed
			{
				frame = frameName;
			}
			else 
			{
				frame = timeline.data.getLabelIndex(String(frameName));
			}
			
			if ( frame > -1)
			{
				timeline.nextIndex = frame;
				timeline.playing = true;
			}
			else
			{
				//trace("TimelineControlSystem :: gotoAndPlay :: invalid frame : " + frame + " from frameName : " + frameName);
			}
		}
		
		private function gotoAndStop(frameName:*, timeline:Timeline):void
		{
			var frame:int = -1;
			if (!isNaN(Number(frameName)))	// fixed this check...if the num conversion fails we know it is something else...wrb
			{
				frame = frameName;
			}
			else 
			{
				frame = timeline.data.getLabelIndex(String(frameName));
			}
			
			if (frame > -1)
			{
				timeline.nextIndex = frame;
				timeline.playing = false;
			}
			else
			{
				//trace("TimelineControlSystem :: gotoAndStop :: invalid frame : " + frame);
			}
		}
		
		private function play(timeline:Timeline):void
		{
			timeline.playing = true;
		}
		
		private function stop(timeline:Timeline):void
		{
			timeline.playing = false;
		}
		
		////////////////////////////////////////////////////////////////////
		////////////////////////// LABEL HANDLING //////////////////////////
		////////////////////////////////////////////////////////////////////
		
		public function handleLabels( timeline:Timeline ):void
		{
			if( !timeline.lock )
			{
				if ( timeline.currentFrameData != null)	
				{
					if ( timeline.labels != null )
					{
						var label:String;
						var labelHandler:LabelHandler;
						
						var i:uint;
						var j:uint;
						for ( i=0; i < timeline.labels.length; i++)
						{	
							label = String( timeline.labels[i] );
							timeline.labelReached.dispatch( label ); 
							
							// check for LabelEvents on Timeline
							if( timeline.labelHandlers )
							{
								for ( j=0; j < timeline.labelHandlers.length; j++ )
								{
									labelHandler = timeline.labelHandlers[j];
									if ( label == labelHandler.label )
									{
										labelHandler.handler.call();
										if ( labelHandler.listenOnce )
										{
											timeline.labelHandlers.splice( j, 1 );
											j--;
										}
									}
								}
							}
						}
					}
				}
			}
		}
		
		private const FRAME_EVENT_PARENT : String = "parent";
		private const FRAME_EVENT_CHILD : String = "child";
		private const FRAME_EVENT_GOTOANDPLAY : String = "gotoAndPlay";
		private const FRAME_EVENT_GOTOANDSTOP : String = "gotoAndStop";
		private const FRAME_EVENT_PLAY : String = "play";
		private const FRAME_EVENT_STOP : String = "stop";
	}
}