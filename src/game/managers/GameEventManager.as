package game.managers
{
	/**
	 * A class to track game events a user has completed.  This class should not be used directly but accessed through ShellApi.
	 */
	
	import flash.utils.Dictionary;
	
	import engine.Manager;
	import engine.managers.GroupManager;
	import engine.util.Command;
	
	import game.data.game.GameEvent;
	import game.data.scene.ConditionData;
	import game.data.scene.EventGroupData;
	import game.data.scene.EventGroupParser;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	public class GameEventManager extends Manager
	{
		public function GameEventManager()
		{
			
		}
		
		/**
		 * Adds event to events list, returning true if event had not yet been added.
		 * @param	event
		 * @param	island
		 * @param	restore
		 * @return
		 */
		public function complete(event:String, island:String, restore:Boolean = false):Boolean
		{
			if(_events[island] == null)
			{
				_events[island] = new Vector.<String>;
			}
			
			var events:Vector.<String> = _events[island];
			
			if (events.indexOf(event) == -1)
			{
				events.push(event);
				checkEventGroups(island);
				
				if(!restore)
				{
					saveEventsToProfile(island);
				}
				return(true);
			}
			else
			{
				return(false);
			}
		}
		
		/**
		 * 
		 * @param	allEvents
		 * @param	island
		 */
		public function restore(allEvents:Dictionary, island:String = null):void
		{
			var total:Number;
			var events:Array;
			var index:uint = 0;
			var nextIsland:String;
			
			if(island != null)
			{
				events = allEvents[island];
				total = events.length;
				
				for(index = 0 ; index < total; index++)
				{
					complete(events[index], island, true);
				}
				saveEventsToProfile(island);
			}
			else
			{
				for(nextIsland in allEvents)
				{
					events = allEvents[nextIsland];
					total = events.length;
					
					for(index = 0 ; index < total; index++)
					{
						complete(events[index], nextIsland, true);
					}
					
					saveEventsToProfile(nextIsland);
				}
			}
			
			//checkEventGroups(island);
		}
		
		public function remove(event:String, island:String, refreshEvents:Boolean = true):Boolean
		{
			if(_events[island] != null)
			{
				var events:Vector.<String> = _events[island];
				var index:Number = events.indexOf(event);
				
				if (index > -1)
				{
					events.splice(index, 1);
					saveEventsToProfile(island);
					
					if(refreshEvents)
					{
						refreshEventGroups(event, island);
					}
					
					return(true);
				}
			}
			
			return(false);
		}
		
		public function trigger(event:String, island:String, save:Boolean = false, makeCurrent:Boolean = true):Boolean
		{
			var isNew:Boolean = false;
			
			if(save)
			{
				// If we're saving the triggered event, do a complete as well.
				isNew = complete(event, island);
			}
			else
			{
				var events:Vector.<String> = _events[island];
				
				if(events)
				{
					if (events.indexOf(event) == -1)
					{
						events.push(event);
						// Check to see if any event groups are triggered with 'complete'.  We add it to the event list for the group check, than remove it.
						checkEventGroups(island);
						events.pop();
						isNew = true;
					}
				}
				else
				{
					trace("Triggered Event was not part of an eligible island");
				}
			}
			
			dispatchEventTrigger(event, makeCurrent);
			
			return(isNew);
		}
		
		public function check(event:String, island:String):Boolean
		{
			if(_events[island] != null)
			{
				var events:Vector.<String> = _events[island];
				
				return(events.indexOf(event) > -1);
			}
			else
			{
				return(false);
			}
		}
		
		public function getEvents(island:String):Vector.<String>
		{
			if(_events[island] == null)
			{
				_events[island] = new Vector.<String>();
			}

			return(_events[island]);
		}
		
		public function reset(island:String = null, save:Boolean = true):void
		{
			if(island != null)
			{
				_events[island] = new Vector.<String>();
			}
			else
			{
				_events = new Dictionary();
			}
			
			if(save)
			{
				if(island != null)
				{
					shellApi.profileManager.active.events[island] = new Array();
				}
				else
				{
					shellApi.profileManager.active.events = new Dictionary();
				}
				
				shellApi.profileManager.save();
			}
		}
		
		public function createEventGroups(xml:XML, island:String):void
		{
			var eventGroupParser:EventGroupParser = new EventGroupParser();
			
			_eventGroups[island] = eventGroupParser.parse(xml);
		}
				
		public function checkEventGroups(island:String):void
		{
			if (_eventGroups[island] != null)
			{
				var groups:Dictionary = _eventGroups[island];
				
				if (groups != null)
				{
					for each(var group:EventGroupData in groups)
					{
						// If event conditions are met, complete this event.
						if(checkEventConditions(group.conditions, island))
						{
							if(!check(group.event, island))
							{
								if(group.onlyTrigger)
								{
									trigger(group.event, island, false);
								}
								else if(group.triggerAndSave)
								{
									trigger(group.event, island, true);
								}
								else
								{
									complete(group.event, island);
								}
							}
						}
						else
						{
							// If event conditions are not currently met and this group event has been completed, remove it.
							if(check(group.event, island))
							{
								remove(group.event, island);
							}
						}
					}	
				}
			}
		}
		
		// Only dispatch this when the game loop completes to avoid interrupting the system update loop.
		private function dispatchEventTrigger(event:String, makeCurrent:Boolean = true, removeEvent:String = null):void
		{
			var groupManager:GroupManager = GroupManager(this.shellApi.getManager(GroupManager));
			if(!groupManager.systemManager.updating)
			{
				eventTriggered.dispatch(event, makeCurrent, false, removeEvent);
			}
			else
			{
				groupManager.systemManager.updateComplete.addOnce(Command.create(eventTriggered.dispatch, event, makeCurrent, false, removeEvent));
			}
		}
		
		private function saveEventsToProfile(island:String):void
		{
			if(shellApi.profileManager.active.events[island] == null)
			{
				shellApi.profileManager.active.events[island] = new Array();
			}
			// if events had island data
			if (_events[island])
			{
				shellApi.profileManager.active.events[island] = Utils.convertVectorToArray(_events[island]);
			}
			shellApi.saveGame();
		}
		
		private function checkEventConditions(conditions:ConditionData, island:String):Boolean
		{
			var type:String = conditions.type;
			var total:Number = 0;
			var condition:ConditionData;
			
			if (type == EventGroupParser.EVENT)
			{
				return(check(conditions.event, island));
			}
			else
			{
				for (var n:Number = 0; n < conditions.conditions.length; n++)
				{
					condition = conditions.conditions[n];
					
					if (checkEventConditions(condition, island))
					{
						if (!condition.not)
						{
							total++;
						}
					}
					else if (condition.not)
					{
						total++;
					}
				}
				
				if ((type == EventGroupParser.AND && total == conditions.conditions.length) ||
					(type == EventGroupParser.OR && total > 0))
				{
					return(true);
				}
				else
				{
					return(false);
				}
			}
		}
		
		private function refreshEventGroups(event:String, island:String):void
		{
			checkEventGroups(island);
			
			var events:Vector.<String> = _events[island];
			var allEvents:Vector.<String> = events.slice();
			allEvents.unshift(GameEvent.DEFAULT);
			var index:int;
			var total:int = allEvents.length;
			
			for(index = 0; index < total; index++)
			{
				dispatchEventTrigger(allEvents[index], true, event);
			}
		}
		
		public var eventTriggered:Signal = new Signal(String);
		/** Dictionary of Vector.<String> storing events, using island id as key */
		private var _events:Dictionary = new Dictionary();
		/** Dictionary, using island id as key, of Dictionaries of EventGroupData using EventGroupData's event as key */
		private var _eventGroups:Dictionary = new Dictionary(true);
	}
}