package game.managers.ads
{
	import com.poptropica.AppConfig;
	
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import engine.ShellApi;
	
	import game.data.ads.ActivityTimerData;
	import game.data.ads.ActivityTimerDataEvent;
	import game.data.ads.AdTrackingConstants;
	import game.util.ArrayUtils;
	import game.util.DataUtils;

	/**
	 * A class for managing active-time between events in an activity
	 * Used for ads
	 * @author Tony Sawyer
	 */
	public class ActivityTimer
	{
		private const UPDATE_TIME:Number = 1000;
		
		private var _validScenes:Array;
		private var _events :Vector.<ActivityTimerData>;
		private var _lso:SharedObject;
		private var _updateTimer:Timer;
		private var _timerStarted:Boolean = false;
		private var _initialTime:Number = 0;
		private var _baseStartTime:int;
		
		[Inject]
		public var _shellApi:ShellApi;
		
		// PUBLIC FUNCTIONS //////////////////////////////////////////////////////////////
		
		/**
		 * Constructor
		 */
		public function ActivityTimer()
		{		
			// get ActivityTimer LSO
			_lso = SharedObject.getLocal("ActivityTimer", "/");
			_lso.objectEncoding = ObjectEncoding.AMF0;
			
			// setup timer to trigger and update every second
			_updateTimer = new Timer(UPDATE_TIME);
			_updateTimer.addEventListener(TimerEvent.TIMER, update);
		
			// if lso event data is not null
			if (!DataUtils.isNull(_lso.data.eventData))
			{
				trace("ActivityTimer: create: lso event data: " + _lso.data.eventData + " total time: " +  _lso.data.totalTime);
				// get last total time as seconds
				_initialTime = Math.floor(_lso.data.totalTime / 1000);

				// create events array from lso data
				_events = getLSODataAsEvents(_lso.data.eventData);
			}
			else
			{
				// if event data is null
				trace("ActivityTimer: create: no events in lso");
				// create event events array
				_events = new Vector.<ActivityTimerData>();
			}
			
			// setup valid scenes array
			_validScenes = new Array();
			// save current time to use as base time
			_baseStartTime = flash.utils.getTimer();
		}
		
		/**
		 * Starts or stops timer based on Campaign Name passed in.
		 * @param campaignName String
		 */
		public function initialize(campaignName:String):void
		{
			// if campaign is found in events
			if(checkCampaign(campaignName))
			{
				trace("ActivityTimer: initialize: found exiting campaign: " + campaignName);
				
				// if timer hasn't started then start it with total time
				if (!_timerStarted)
					startTimer();
			}
			// if no camapign passed, then assume any active campaigns should be ended
			else if (campaignName == "") 
			{
				trace("ActivityTimer: initialize: clear all events");
				
				// if there was any campaign, then kill all events
				if (_events.length != 0)
					killAllEvents();

				// if timer running, then end it
				if (_timerStarted)
					endTimer();
				
				// clear all data
				clearLSOData();
			}
			// if new campaign
			else
			{
				trace("ActivityTimer: initialize: new campaign: " + campaignName);

				// if any events still linger, then kill them
				if(_events.length != 0)
				{
					trace("ActivityTimer: initialize: clear all existing events");
					killAllEvents();
				}
				
				// create new event for campaign
				createEvent(campaignName);

				// save new data to lso
				saveTimerDataToLSO();
			}
		}
		
		/**
		 * Adds scene to _validScenes array
		 * @param scene String
		 */
		public function addScene(scene:String):void
		{
			// if scene is not in valid scenes
			if (_validScenes.indexOf(scene) == -1)
			{
				// add to valid scenes array and save to LSO
				_validScenes.push(scene);
				saveTimerDataToLSO();
			}
		}
		
		// PRIVATE FUNCTIONS //////////////////////////////////////////////////////////////
		
		/**
		 * Create new event, add to events list and start it
		 * @param campaign
		 */
		private function createEvent(campaign:String):void
		{
			// start timer
			startTimer();
			
			// set start time (if mobile, then always set start time at 0)
			var startTime:int = 0
			// if not mobile then set start time to total time
			if (!AppConfig.mobile)
				startTime = getTotalTime();

			// create event object
			var eventData:ActivityTimerData = createEventObject(campaign);
			
			// if event doesn't exist in event list, then add it
			if (!checkForEvent(eventData))
			{
				trace("ActivityTimer: createEvent: Adding new event: " + campaign + " startTime: " + startTime);
				_events.push(eventData);
			}
			else
			{
				// if found in event list, then get existing event
				trace("ActivityTimer: createEvent: Event already exists: " + campaign + " startTime: " + startTime);
				eventData = getEvent(campaign);
			}
			
			// set started flag
			eventData.started = true;
			// now set start time
			eventData.start = startTime;
		}
		
		/**
		 * Kill single event 
		 * @param eventData
		 * @param time
		 */
		private function killEvent(eventData:ActivityTimerData):void
		{
			trace("ActivityTimer: killEvent: " + eventData.campaign);
			
			// set started flag to false
			eventData.started = false;
			
			// if only tracking on complete, then remove event
			if (eventData.onlyTrackOnComplete)
			{
				removeEvent(eventData.campaign);
			}
			else
			{
				// else trigger event complete
				eventComplete(eventData);
			}
		}
		
		/**
		 * Trigger event complete 
		 * @param eventData
		 * @param time
		 */
		private function eventComplete(eventData:ActivityTimerData):void
		{
			// set started event to false
			eventData.started = false;
			
			// if not mobile then don't adjust end times
			if (!AppConfig.mobile)
				eventData.end = getTotalTime();
			
			trace("ActivityTimer: eventComplete: " + eventData.campaign + " start: " + eventData.start + " end: " + eventData.end);
			
			// if persisting, then save data
			if (eventData.persist)
			{
				saveTimerDataToLSO();
			}
			else
			{
				// if not persisting, then remove event
				removeEvent(eventData.campaign);
			}
			
			// track event
			trackEvent(eventData);
			
			// if no events left
			if (_events.length == 0)
			{
				// end timer and clear data
				endTimer();
				clearLSOData();
			}
		}

		/**
		 * Track event 
		 * @param eventData
		 */
		private function trackEvent(eventData:ActivityTimerData):void
		{
			// get end time minus start time
			var elapsedTime:int = eventData.end - eventData.start;
			
			trace("ActivityTimer: trackEvent: campaign: " + eventData.campaign + " elapsedTime: " + elapsedTime);
			
			// check for negative numbers (still seeing these)
			if (elapsedTime < 0)
			{
				trace("ActivityTimer: trackEvent: NEGATIVE NUMBER RECORDED FOR AD: " + eventData.campaign);
				// get elapsed time since initial time
				var elapsedSinceTotal:int = _initialTime - eventData.start;
				// if positive, then set elapsed time to that
				if (elapsedSinceTotal > 0)
					elapsedTime = elapsedSinceTotal;
			}

			if (ExternalInterface.available) 
				ExternalInterface.call('dbug', "AdTimer ended for " + eventData.campaign + ": " + elapsedTime);		

			// send tracking call
			AdManager(_shellApi.adManager).track(eventData.campaign, AdTrackingConstants.TRACKING_TOTAL_TIME, null, null, AdTrackingConstants.TRACKING_TIME_SPENT, elapsedTime);
		}
		
		// TIMER FUNCTIONS //////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Start up the timer w/ an initial time.
		 * @param initialTime
		 */
		private function startTimer():void
		{
			// it timer hasn't started already
			if (!_timerStarted)
			{
				trace("ActivityTimer: startTimer: initialTime: " + _initialTime);
				// set started flag to true
				_timerStarted = true;
				// start timer
				_updateTimer.start();
			}
		}
		
		/**
		 * End timer 
		 */
		private function endTimer():void
		{
			trace("ActivityTimer: endTimer");
			// clear initial time
			_initialTime = 0;
			// turn off started flag
			_timerStarted = false;
			// stop timer
			_updateTimer.stop();
		}
		
		/**
		 * When the timer reaches every second 
		 * @param event TimerEvent
		 */
		private function update(event:TimerEvent):void
		{
			// if timer running
			if (_timerStarted)
			{
				// update events for mobile
				if (AppConfig.mobile)
					updateEvents();
				
				// save data to lso
				saveTimerDataToLSO();
			}
			else
			{
				// if timer not running, then end timer
				endTimer();
			}
		}
		
		/**
		 * Updates end time of each event
		 */
		private function updateEvents():void
		{
			var nextEvent:ActivityTimerData;
			
			// for each event
			for (var n:Number = 0; n < _events.length; n++)
			{
				// get event
				nextEvent = _events[n];
				// increment end time for each second
				nextEvent.end++;
			}	
		}
		
		// TIME UTILITIES ///////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Get current time since base start time 
		 * @return int time
		 */
		private function getCurrentTime():int 
		{
			// get current time since base start time and convert to seconds
			return Math.floor((getTimer() - _baseStartTime) / 1000);
		}
		
		// Get the total active time.
		private function getTotalTime():Number
		{
			// starting time plus elapsed time
			return (_initialTime + getCurrentTime());
		}
		
		// LSO FUNCTIONS /////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Create event data from lso data 
		 * @param array
		 * @return Vector of ActivityTimerData (event list)
		 */
		private function getLSODataAsEvents(array:Array) :Vector.<ActivityTimerData>
		{
			// create empty vector
			var tempVec:Vector.<ActivityTimerData> = new Vector.<ActivityTimerData>();
			
			// for each event in lso array
			for (var n:Number = 0; n < array.length; n++)
			{
				// create event data and data event objects
				var newEvent:ActivityTimerData = new ActivityTimerData();
				newEvent.event = new ActivityTimerDataEvent();
				
				// store event properties
				newEvent.event.begin = array[n].event.begin;
				newEvent.event.end = array[n].event.end;
				newEvent.event.kill = array[n].event.kill;
				
				// store data properties
				newEvent.started = array[n].started;
				newEvent.start = array[n].start;
				newEvent.campaign = array[n].campaign;
				newEvent.choice = array[n].choice;
				newEvent.persist = array[n].persist;
				
				// retrieve end only if mobile
				if (AppConfig.mobile)
					newEvent.end = array[n].end;
				
				trace("ActivityTimer: getLSODataAsEvents: campaign: " + newEvent.campaign + " start: " +newEvent.start + " end: " + newEvent.end);
				
				// add to array
				tempVec.push(newEvent);
			}
			return tempVec;
		}
		
		/**
		 * Save timer data to LSO 
		 */
		private function saveTimerDataToLSO():void
		{
			// get all event data and apply to lso
			_lso.data.eventData = eventsToLSOFormat();
			// save total time
			_lso.data.totalTime = getTotalTime() * 1000;
			
			// if valid scenes, then save
			if (_validScenes.length != 0)
				_lso.data.validScenes = _validScenes;
			
			// save to lso
			_lso.flush();
		}
		
		/**
		 * Convert events to lso format
		 * @return Array
		 */
		private function eventsToLSOFormat():Array
		{
			var allEventData:Array = new Array();
			var currentEvent:Object;
			
			// for each event
			for (var n:Number = 0; n < _events.length; n++)
			{
				// get event
				currentEvent = _events[n];
				
				// create new objects
				var newEvent:Object = new Object();
				newEvent.event = new Object();
				
				// get event properties
				newEvent.event.begin = currentEvent.event.begin;
				newEvent.event.end = currentEvent.event.end;
				newEvent.event.kill = currentEvent.event.kill;
				
				// get data properties
				newEvent.started = currentEvent.started;
				newEvent.start = currentEvent.start;
				newEvent.campaign = currentEvent.campaign;
				newEvent.choice = currentEvent.choice;
				newEvent.persist = currentEvent.persist;
				newEvent.onlyTrackOnComplete = currentEvent.onlyTrackOnComplete;
				
				// save end time only if mobile
				if (AppConfig.mobile)
					newEvent.end = currentEvent.end;
				
				// add to array
				allEventData.push(newEvent);
			}
			return(allEventData);
		}
		
		/**
		 * Clear lso data 
		 */
		private function clearLSOData():void
		{
			trace("ActivityTimer: clearLSOData");
			// clear lso
			_lso.clear();
		}
		
		// EVENT UTILITIES ///////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Create an event object with defaults 
		 * @param campaign
		 * @return ActivityTimerData
		 */
		private function createEventObject(campaign:String):ActivityTimerData
		{
			// create data record
			var newEvent:ActivityTimerData = new ActivityTimerData();
			// create data event record
			newEvent.event = new ActivityTimerDataEvent();
			// set campaign
			newEvent.campaign = campaign;			
			// set begin event
			newEvent.event.begin = new Array(campaign, AdTrackingConstants.TRACKING_ENTERED_BUILDING);
			return(newEvent);
		}
		
		/**
		 * Get event by name 
		 * @param campaignName
		 * @return ActivityTimerData
		 */
		private function getEvent(campaignName:String):ActivityTimerData
		{
			var nextEvent:ActivityTimerData;
			
			// for each event
			for (var n:Number = 0; n < _events.length; n++)
			{
				// get event
				nextEvent = _events[n];

				// if campaign names match, then return it
				if(nextEvent.campaign == campaignName)
					return nextEvent;
			}
			return null;
		}
		
		/**
		 * Check events to see if campaign is among them 
		 * @param campaign
		 * @return Boolean
		 */
		private function checkCampaign(campaign:String):Boolean
		{
			// for each event
			for (var n:Number = 0; n < _events.length; n++)
			{
				// if match campaign
				if (_events[n].campaign == campaign)
					return true;
			}
			return false;
		}
		
		/**
		 * Get all Events that are currently running
		 * @return Array
		 */
		private function getActiveEvents():Array
		{
			var nextEvent:ActivityTimerData;
			var activeEvents:Array = new Array();
			
			// for each event
			for (var n:Number = 0; n < _events.length; n++)
			{
				// get event
				nextEvent = _events[n];
				// if started then add to array
				if (nextEvent.started)
					activeEvents.push(nextEvent);
			}
			return(activeEvents);
		}
				
		/**
		 * See if a particular event exists in event list
		 * @param eventData
		 * @return Boolean
		 */
		private function checkForEvent(eventData:ActivityTimerData):Boolean
		{
			var nextEvent:ActivityTimerData;
			
			// for each event
			for (var n:Number = 0; n < _events.length; n++)
			{
				// get event
				nextEvent = _events[n];
				// if events match then return true
				if (checkEquality(eventData, nextEvent))
					return true;
			}
			return false;
		}
		
		/**
		 * Check if two events match 
		 * @param event1
		 * @param event2
		 * @return Boolean
		 */
		private function checkEquality(event1:Object, event2:Object):Boolean
		{
			// if end events are null
			if (DataUtils.isNull(event1.event.end) && DataUtils.isNull(event2.event.end))
			{
				// check begin events
				return (checkEventMatch(event1.event.begin, event2.event.begin));
			}
			else
			{
				// if end events are not null
				// check begin and end events
				return (checkEventMatch(event1.event.begin, event2.event.begin) && checkEventMatch(event1.event.end, event2.event.end));
			}
		}
		
		/**
		 * Check if two events match
		 * All event comparisons go through this 'overloaded' method. It uses type to determine how to do a comparison.
		 * @param event1
		 * @param event2
		 * @return Boolean
		 */
		private function checkEventMatch(event1, event2):Boolean
		{		
			//trace("ActivityTimer: checking event match:" + (event1.toString() == event2.toString()));
			// if events are not null
			if (!DataUtils.isNull(event1) && !DataUtils.isNull(event2))
			{
				// if mixed types
				if ((typeof(event1) == "string") && (typeof(event2) == "object"))
				{
					return (Boolean(ArrayUtils.numOccurences(event1, event2)));
				}
				else if ((typeof(event2) == "string") && (typeof(event1) == "object"))
				{
					return (Boolean(ArrayUtils.numOccurences(event2, event1)));
				}
				else
				{
					// if not mixed types
					// if string conversions match
					if (event1.toString() == event2.toString())
					{
						return true;
					}
					else
					{
						// if no matches
						return false;
					}
				}
			}
			else
			{
				// if either event is null
				return false;
			}
		}
		
		/**
		 * Kill all events 
		 * @param time
		 */
		private function killAllEvents():void
		{
			// for each event
			for (var n:Number = 0; n < _events.length; n++)
			{
				// kill event
				killEvent(_events[n]);
			}
		}
		
		/**
		 * Remove event from event list 
		 * @param campaignName
		 */
		private function removeEvent(campaignName:String):void
		{
			// for each event
			for (var n:Number = 0; n < _events.length; n++)
			{
				// if event campaign matches, then remove
				if (_events[n].campaign == campaignName)
					_events.splice(n, 1);
			}
			// save to lso
			saveTimerDataToLSO();
		}
	}
}