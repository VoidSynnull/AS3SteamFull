package game.util
{
	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.group.Group;
	
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.timeline.TimelineMaster;
	import game.components.timeline.TimelineMasterVariable;
	import game.data.animation.FrameData;
	import game.data.animation.FrameEvent;
	import game.data.animation.LabelHandler;
	import game.systems.timeline.TimelineVariableSystem;
	
	public class TimelineUtils
	{	
		
		/**
		 * Add a handler to a timeline at a speific label. 
		 * @param entity
		 * @param label
		 * @param handler
		 * @param listenOnce
		 * 
		 */
		public static function onLabel( entity:Entity, label:String, handler:Function, listenOnce:Boolean = true ):void
		{
			var timeline:Timeline = entity.get( Timeline );
			if ( timeline )
			{
				timeline.labelHandlers.push( new LabelHandler( label, handler, listenOnce ));
			}
		}
		
		/**
		 * Resets entity's Timeline and all of its children's Timelines.
		 * @param	entity
		 */
		public static function resetAll( entity:Entity, startPlaying:Boolean = true ):void
		{
			// check for timeline
			var timeline:Timeline = entity.get( Timeline );
			if ( timeline )
			{
				timeline.reset( startPlaying );
			}
			
			//check children for timeline
			var children:Children = entity.get( Children );
			if ( children )
			{
				var i:int = 0;
				for ( i; i < children.children.length; i++ )
				{
					resetAll( children.children[i] as Entity, startPlaying );
				}
			}
		}
		
		/**
		 * Sets all Timelines to play 
		 * @param entity
		 */
		public static function playAll(entity:Entity):void
		{
			var timeline:Timeline = entity.get(Timeline);
			if(timeline != null)
				timeline.playing = true;
			
			var children:Children = entity.get(Children);
			if(children != null)
			{
				for (var i:int = 0; i < children.children.length; i ++)
				{
					playAll(children.children[i]);
				}
			}
		}
		
		/**
		 * Sets all Timelines to play 
		 * @param entity
		 */
		public static function stopAll(entity:Entity):void
		{
			var timeline:Timeline = entity.get(Timeline);
			if(timeline != null)
				timeline.playing = false;
			
			var children:Children = entity.get(Children);
			if(children != null)
			{
				for (var i:int = 0; i < children.children.length; i ++)
				{
					playAll(children.children[i]);
				}
			}
		}
		
		/**
		 * 
		 * @param parentEntity
		 * @param instanceName
		 * @return 
		 * 
		 */
		public static function getChildClip( parentEntity:Entity, instanceName:String ):Entity 
		{ 
			var children:Vector.<Entity> = parentEntity.get(Children).children;
			for(var i:Number = 0; i < children.length; i++)
			{
				var currentChild:Entity = children[i];
				if(currentChild.has(TimelineClip))
				{
					var name:String = currentChild.get(TimelineClip).mc.name;
					if(name == instanceName)
					{
						return(currentChild);
					}
				}
			}
			
			return null;
		}
		
		/////////////////////////////////////////////////////////////////////////////////
		///////////////////////// PARSE MOVECLIP LABELS TO DATA /////////////////////////
		/////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Searches through displayObject for MovieClips with timelines, creates a new Entity for each found.
		 * Maintains a parent heirarchy through recursion.
		 * @param	displayObject - DisplayObject being parsed for timelines.
		 * @param	parentEntity - Entity that timeline Entities will be parented under.
		 * @param	group - if group is not specified, will look for parentEntity's owning group.
		 * @return	returns the top most Entity found, containing Timeline, TimelineMaster, Sleep, &amp; Parent components 
		 */
		public static function convertAllClips( displayObject:DisplayObject, parentEntity:Entity = null, group:Group = null, startPlaying:Boolean = true, frameRate:int = 32, entity:Entity = null ):Entity
		{
			if ( displayObject is MovieClip )
			{
				// if group was not specified, get from parentEntity
				if ( group == null )
				{
					group = EntityUtils.getOwningGroup( parentEntity )
					if ( group == null )
					{
						trace( "Error :: TimelineUtils :: convertAllClips :: If group is not specified parentEntity must have OwningGroup");
						return null;
					}
				}
				
				// check if displayObject has a timeline
				var newEntity:Entity;
				if ( MovieClip(displayObject).totalFrames > 1 )
				{
					newEntity = TimelineUtils.convertClip( MovieClip(displayObject), group, entity, parentEntity, startPlaying, frameRate );
				}
				
				// check displayObject children
				var childEntity:Entity;
				var numChildren:int = MovieClip(displayObject).numChildren;
				if ( numChildren > 0 )
				{
					var childDisplayObject:DisplayObject;
					for ( numChildren; numChildren > 0; numChildren-- )
					{
						childDisplayObject = DisplayObject(MovieClip(displayObject).getChildAt(numChildren - 1));
						if ( newEntity )
						{
							childEntity = TimelineUtils.convertAllClips( childDisplayObject, newEntity, group, startPlaying, frameRate  );
						}
						else
						{
							childEntity = TimelineUtils.convertAllClips( childDisplayObject, parentEntity, group, startPlaying, frameRate  );
						}
					}
				} 
				
				return ( ( newEntity != null ) ? newEntity : childEntity );
			}
			return null;
		}
		
		/**
		 * Converts the first MovieClip within the display heirarchy that has a timeline.
		 * 
		 * @param displayObject
		 * @param entity - Entity that components will be added to.
		 * @param startPlaying
		 * @return 
		 */
		public static function convertFirstTimeline( displayObject:DisplayObject, entity:Entity, parent:Entity = null, startPlaying:Boolean = true, frameRate:int = 32 ):Entity
		{
			if ( displayObject is MovieClip )
			{				
				// check if displayObject has a timeline, otherwise check children
				if ( MovieClip(displayObject).totalFrames > 1 )
				{
					return TimelineUtils.convertClip( MovieClip(displayObject), null, entity, parent, startPlaying, frameRate  );
				}
				else
				{
					// check displayObject children
					var numChildren:int = MovieClip(displayObject).numChildren;
					if ( numChildren > 0 )
					{
						var childDisplayObject:DisplayObject;
						var childEntity:Entity;
						//for ( numChildren; numChildren > 0; numChildren-- )
						var i:uint = 0;
						for ( i = 0; i < numChildren; i++ )
						{
							childDisplayObject = DisplayObject(MovieClip(displayObject).getChildAt(i));
							childEntity = TimelineUtils.convertFirstTimeline( childDisplayObject, entity, parent, startPlaying, frameRate  );
							if( childEntity )	
							{ 
								return childEntity; 
							}
						}
					} 
				}
			}
			return null;
		}
		
		/**
		 * Converts MovieClip into components for use in timeline ystems.
		 * Assumes will be used in conjunction timelineClipSystem
		 * If no Entity is specified a new one is created and adds to the group.
		 * Adds a Sleep component it doesnt have one and if parent is not passed.
		 * @param mc
		 * @param group
		 * @param entity
		 * @param parent
		 * @param startPlaying
		 * @param frameRate
		 * @return 
		 * 
		 */
		public static function convertClip( mc:MovieClip, group:Group = null, entity:Entity = null, parent:Entity = null, startPlaying:Boolean = true, frameRate:int = 32 ):Entity
		{
			if ( entity == null )
			{
				entity = new Entity();
				if(group != null)	{ group.addEntity( entity ); }
			}
			
			/// create/convert Timeline
			var timeline:Timeline = entity.get( Timeline );
			if ( !timeline )
			{
				timeline = new Timeline();
				entity.add( timeline );
			}
			TimelineUtils.parseMovieClip( timeline, mc);
			mc.gotoAndStop(1);
			timeline.reset(startPlaying);
			
			// create TimelineMaster or TimelineMasterVariable
			if( frameRate != 32 )
			{
				if(group.getSystem(TimelineVariableSystem) == null)
					group.addSystem(new TimelineVariableSystem());
				entity.remove( TimelineMaster );
				entity.add( new TimelineMasterVariable( frameRate ) );
			}
			else
			{
				entity.remove( TimelineMasterVariable );
				if ( !entity.has( TimelineMaster ) )	{ entity.add( new TimelineMaster() ); }
			}
			
			// creates/sets TimelineClip
			var timelineClip:TimelineClip = entity.get( TimelineClip );
			if ( !timelineClip )
			{
				timelineClip = new TimelineClip( mc );
				entity.add( timelineClip );
			}
			else
			{
				timelineClip.mc = mc;
			}
			
			// add Sleep if parent isn't passed
			if ( !entity.has( Sleep ) && !parent)	
			{ 
				entity.add( new Sleep() );
				/*
				if(group != null)
				{
				if( group is Scene )
				{
				entity.add( new Sleep() ); 
				}
				}
				*/
			} 
			// add Id
			if( !entity.has(Id) ) { entity.add( new Id(mc.name) );}
			// create parent/children relationship if parent is passed
			if ( parent )	{ EntityUtils.addParentChild( entity, parent ); }
			
			return entity;
		}
		
		/**
		 * Converts moveiclip labels into FrameData for use in TimelineSystem
		 * @param	timeline
		 * @param	mc
		 */
		public static function parseMovieClip( timeline:Timeline, mc:MovieClip ):void
		{
			// Parse frame events
			var frames:Vector.<FrameData> = new Vector.<FrameData>();
			var frameData:FrameData;
			var label:FrameLabel;
			
			var i:uint = 0;
			for (i; i < mc.totalFrames; i++)
			{
				frameData = new FrameData();
				frameData.index = i;
				frames.push( frameData );
			}
			
			i = 0;
			for (i; i < mc.currentLabels.length; i++)
			{
				label = mc.currentLabels[i];
				TimelineUtils.parseLabel( frames[label.frame - 1], StringUtil.removeWhiteSpace(label.name) );
			}
			
			timeline.data.frames = frames;
			timeline.data.duration =  mc.totalFrames;
		}
		
		/**
		 * Parses single movieclip label into FrameData
		 * @param	frameData
		 * @param	label
		 * @param	startIndex
		 */
		public static function parseLabel( frameData:FrameData, label:String, startIndex:int = 0 ):void
		{
			var subLabel:String;
			var endIndex:int = label.indexOf( TimelineUtils.DIVDER, startIndex );
			var frameEvent:FrameEvent;
			
			if ( endIndex > 0 )
			{
				subLabel = label.substring( startIndex, endIndex );
				TimelineUtils.addType( frameData, subLabel ); 
				TimelineUtils.parseLabel( frameData, label, endIndex + 1 ); 
			}
			else
			{
				subLabel = label.substring( startIndex );
				TimelineUtils.addType( frameData, subLabel ); 
			}
		}
		
		
		
		public static function moveTimelineToRandomFrame(timeline:Timeline, play:Boolean = true):void
		{
			var frame:int = int(Math.random() * timeline.data.duration);
			if(play)
				timeline.gotoAndPlay(frame);
			else
				timeline.gotoAndStop(frame);
		}
		
		
		/////////////////////////////////////////////// PRIVATE ///////////////////////////////////////////////
		
		/**
		 * Determines is label String is a FrameEvent or just a label, adding to FrameData appropriately.
		 * @param	frameData
		 * @param	label
		 */
		private static function addType( frameData:FrameData, label:String ):void
		{
			var frameEvent:FrameEvent = TimelineUtils.convertLabelToFrameEvent( label );
			if ( frameEvent )				// check for timeline method
			{
				frameData.addEvent( frameEvent );	
			}
			else							// if not timeline method set as label
			{
				frameData.label = label;
			}
		}
		
		/**
		 * Checks label String for method match, if found converts to FrameEvent
		 * @param	label
		 * @return
		 */
		private static function convertLabelToFrameEvent( label:String ):FrameEvent
		{
			var frameEvent:FrameEvent;
			var firstIndex:int;
			var lastIndex:int;
			var arg:String;
			var argNumber:Number;
			
			
			if (label.indexOf(TimelineUtils.PROPERTY) != -1)
			{
				var subString:String = label;
				frameEvent = new FrameEvent();
				frameEvent.type = TimelineUtils.FRAME_EVENT_CHILD;//child should do something
				var children:Vector.<String> = new Vector.<String>();
				while(subString.indexOf(TimelineUtils.PROPERTY) != -1)
				{
					firstIndex = subString.indexOf(TimelineUtils.PROPERTY);
					
					arg = subString.substring(0, firstIndex);
					children.push(arg);
					
					subString = subString.substring(firstIndex + 1);
				}
				
				frameEvent.addArg(children);
				frameEvent.addArg(convertLabelToFrameEvent(subString));//what the child should do
				
				return frameEvent;
			}
			else if ( label == TimelineUtils.FRAME_EVENT_STOP || label == (TimelineUtils.FRAME_EVENT_STOP + "()") )
			{
				frameEvent = new FrameEvent();
				frameEvent.type = TimelineUtils.FRAME_EVENT_STOP;
				return frameEvent;
			}
			else if ( label == TimelineUtils.FRAME_EVENT_PLAY || label == (TimelineUtils.FRAME_EVENT_PLAY + "()") )
			{
				frameEvent = new FrameEvent();
				frameEvent.type = TimelineUtils.FRAME_EVENT_PLAY;
				return frameEvent;
			}
			else if ( label.indexOf( TimelineUtils.FRAME_EVENT_GOTOAND ) != -1 )
			{
				// parse argument
				frameEvent = new FrameEvent();
				firstIndex = label.indexOf("(") + 1;
				lastIndex = label.indexOf(")");
				arg = label.slice( firstIndex, lastIndex );
				argNumber = Number(arg)
				if ( !isNaN(argNumber) )
				{
					frameEvent.addArg(argNumber);
				}
				else
				{
					frameEvent.addArg(String(arg));
				}
				
				//check for type
				if ( label.indexOf( TimelineUtils.FRAME_EVENT_GOTOANDPLAY ) != -1 )
				{
					frameEvent.type = TimelineUtils.FRAME_EVENT_GOTOANDPLAY;
				}
				else if ( label.indexOf( TimelineUtils.FRAME_EVENT_GOTOANDSTOP ) != -1 )
				{
					frameEvent.type = TimelineUtils.FRAME_EVENT_GOTOANDSTOP;
				}
				else
				{
					trace( "Error :: TimelineUtils :: checkForFrameEvent :: " + label + " is an invalid method.");
					return null;
				}
				
				return frameEvent;
			}
			return null;
		}
		
		public static const DIVDER : String = ",";
		public static const PROPERTY : String = ".";
		public static const FRAME_EVENT_CHILD : String = "child";
		public static const FRAME_EVENT_GOTOAND : String = "gotoAnd";
		public static const FRAME_EVENT_GOTOANDPLAY : String = "gotoAndPlay";
		public static const FRAME_EVENT_GOTOANDSTOP : String = "gotoAndStop";
		public static const FRAME_EVENT_PLAY : String = "play";
		public static const FRAME_EVENT_STOP : String = "stop";
	}
}