package game.proxy
{
	import com.poptropica.interfaces.IThirdPartyTracker;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import engine.Manager;
	import engine.util.Command;
	
	import game.data.profile.ProfileData;
	import game.managers.ScreenManager;
	import game.managers.WallClock;
	import game.util.DataUtils;
	import game.util.PlatformUtils;

	public class TrackingManager extends Manager implements ITrackingManager
	{
		public static const AS3_BRAIN_NAME:String = 'Poptropica2';
		//testing if play services was the cause of GA not working
		private var _firstTime:Boolean = true;
		private var _startQueueRelease:Boolean = false;
		
		public function TrackingManager()
		{}
		
		override protected function construct():void
		{
			super.construct();

			var mgr:Manager;
			mgr = shellApi.siteProxy as Manager;
			if (mgr)
			{
				this.getDataStoreManager(mgr);
			}
			else
			{
				this.shellApi.managerAdded.add(this.getDataStoreManager);
			}
			mgr = shellApi.getManager(ScreenManager);
			if (mgr)
			{
				this.getScreenManager(mgr);
			}
			else
			{
				this.shellApi.managerAdded.add(this.getScreenManager);
			}
			
			if (_queueTrackingCalls)
			{
				_trackingTimer = new WallClock(QUEUED_TRACKING_INTERVAL);
				_trackingTimer.chime.add(flushQueue);
			}
		}
		
		private function getDataStoreManager(manager:Manager):void
		{
			if (manager is IDataStore)
			{
				this.shellApi.managerAdded.remove(this.getDataStoreManager);
				
				_connection = new Connection();
				_connection.prefix = "https://" + (manager as IDataStore).gameHost;
			}
		}

		protected function getScreenManager(manager:Manager):void
		{
			// to provide support for interface
		}
		
		/**
		 * Track an event, handles event dispersal among multiple trackers (e.g. braintracker, third party) 
		 * @param event
		 * @param platform
		 * @param choice
		 * @param subchoice
		 * @param campaign
		 * @param cluster
		 * @param scene
		 * @param grade
		 * @param gender
		 * @param numValLabel
		 * @param numVal
		 * @param count
		 * @param vars
		 */
		public function track(event:String, platform:String = null, choice:String = null, subchoice:String = null, campaign:String = null, cluster:String = null, scene:String = null, grade:String = null, gender:String = null, numValLabel:String = null, numVal:Number = NaN, count:String = null, vars:URLVariables = null):void
		{
			triggerQueuing();
			if(!vars)
			{
				vars = new URLVariables();
			}
			
			vars.event				= event;
			// suppress login if guest
			if (!shellApi.profileManager.active.isGuest)
			{
				vars.login			= shellApi.profileManager.active.login;
			}
			vars.brain				= AS3_BRAIN_NAME;
			vars.member				= (shellApi.profileManager.active.isMember ? "Y" : "N");
			if(PlatformUtils.inBrowser){			
				vars.randomNumber		= Math.floor(10000000*Math.random());
			}

//			if (null == platform) {
//				platform = AppConfig.platformType;
//			}

			if(!DataUtils.isNull(platform))				{ vars.platform = PlatformUtils.platformDescription; }
			if(!DataUtils.isNull(choice))				{ vars.choice = choice; }
			if(!DataUtils.isNull(subchoice))			{ vars.subchoice = subchoice; }
			if(!DataUtils.isNull(campaign))				{ vars.campaign = campaign; }
			if(!DataUtils.isNull(cluster))				{ vars.cluster = cluster; }
			if(!DataUtils.isNull(scene) && DataUtils.isNull(vars.scene))				{ vars.scene = scene; }// allow for custom scene name
			if(!DataUtils.isNull(grade))				{ vars.grade = grade; }
			if(!DataUtils.isNull(gender))				{ vars.gender = gender; }
			if(numValLabel != null && !isNaN(numVal))	{ vars.numvals = (numValLabel + ":" + numVal); }
			if(!DataUtils.isNull(count))				{ vars.count = count; }

			//Sends tracking data to third parties 
			for each (var tracker:IThirdPartyTracker in thirdPartyTrackers) 
			{
				if(!tracker)
					continue;
				
				tracker.track(vars);
				if(_firstTime )
				{
					vars.event = "GoogleServicesReadded";
					vars.campaign = "GooglePlayServices";
					tracker.track(vars);
					sendToBrain(vars);
					
				}
			}
			_firstTime = false;
			sendToBrain(vars);

		
			// TODO: TEST amfphp when Dan's braintracking system is ready
			/*
			if (SceneUIGroup.UI_EVENT == event) {
				var btd:BrainTrackingData = BrainTrackingData.instanceFromInitializer({eventName:event, cluster:cluster, choice:choice});
	//			_shellApi.siteProxy.sendBrainTrackingData(btd);
			}
			if (TrackingEvents.SCENE_LOADED == event) {
				_shellApi.siteProxy.trackSceneLoaded(scene);
			}
			*/
		}

		// Your vars should be populated AT A MINIMUM with
		//		event (GA Action) <String>
		//		platform <String>
		//		cluster (GA Category) <String>
		//		choice (GA Label) <String>
		public function trackEventWithVars(vars:URLVariables):void
		{
			triggerQueuing();

			if (!vars.hasOwnProperty('brain')) {
				vars.brain = AS3_BRAIN_NAME;
			}
			vars.platform	= PlatformUtils.platformDescription;
			//Sends tracking data to third parties 
			for each (var tracker:IThirdPartyTracker in thirdPartyTrackers) {
				tracker.track(vars);
			}

			sendToBrain(vars);
		}

		public function trackEvent(eventName:String, data:Object):void
		{
			var profile:ProfileData = shellApi.profileManager.active;

			var vars:URLVariables = new URLVariables();
			vars.event		= eventName;
			vars.platform	= PlatformUtils.platformDescription;
			vars.cluster	= data.cluster;
			vars.choice		= data.choice;
			vars.dimensions = {
				'age':		String(profile.age),
				'gender':	(profile.gender == 'female' ? 'F' : 'M'),
				'isMember':	(profile.isMember ? 'Y' : 'N')
			};
			trackEventWithVars(vars);
		}

		/**
		 * Track a page view, using third party tracking 
		 * @param island
		 * @param scene
		 */
		public function trackPageView(island:String, scene:String):void
		{
			for each (var tracker:IThirdPartyTracker in thirdPartyTrackers) {
				tracker.trackPageView(island, scene);
			}
		}

		public function trackPageViewWithVars(vars:URLVariables):void
		{
			for each (var tracker:IThirdPartyTracker in thirdPartyTrackers) {
				tracker.trackPageview(vars);
			}			
		}

		/**
		 * Send a batch of tracking calls to the server.
		 */
		private function flushQueue():void
		{
			if(shellApi.networkAvailable()){
				
				//this._shellApi.devTools.console.log("Track :: sendTrackingCallsInQueue() Batch size is", _queuedEvents.length)
				trace("BrainTracker :: sendTrackingCallsInQueue() responds to chime. Batch size is", _queuedEvents.length);
				_trackingTimer.stop();
				// if more than one event queued
				if (_queuedEvents.length > 1) {
					// if queue not released
					if (!_startQueueRelease) {
						_startQueueRelease = true;
						var count:String = String(_queuedEvents.length);
						if (count.length == 1) {
							count = "00" + count;
						} else if (count.length == 2) {
							count = "0" + count;
						}
						shellApi.track("QueueReleased", count);
					}
				}
				dequeue();
				trace("BrainTracker :: All queued tracking events sent.");
			}else{
				trace("BrainTracker :: sendTrackingCallsInQueue() !no connection, try again in a few seconds");
				//this._shellApi.devTools.console.log("track sending calls in queue - !no connection, try again in a few seconds");
			}
		}

		private function sendTrackEvent(vars:URLVariables):void
		{
			var curSecond:int = Math.round(new Date().time / 1000);
			if (vars.hasOwnProperty('time')) {
				var numSecondsAgo:int = vars.time - curSecond;
				if (0 > numSecondsAgo) {
					if (numSecondsAgo < (-1*60*60)) {
						trace("We wound up with a VERY NEGATIVE number here", vars.toString());
					}
					vars.time = numSecondsAgo;
				} else {
					delete vars.time;
				}
			}

			trace("TrackingManager::sendTrackEvent() Doing queued track.  " +_queuedEvents.length + " calls remaining.");
			_connection.connect("/brain/track.php", vars, URLRequestMethod.GET, handleLoaded, Command.create(handleError, vars));
		}
		
		// If an event is successfully sent to the server, send any events that were queued up while offline.
		private function handleLoaded(event:Event):void
		{
			dequeue();
		}
		
		private function handleError(event:IOErrorEvent, vars:URLVariables):void
		{
			_waitingForOperation = false;
			trace("BrainTracker :: handleError() queues", vars.toString(), "on error", event.text);
			enqueue(vars);
			//this._shellApi.devTools.console.log("Track :: handleError() queues"+ vars.toString()+ "on error"+ event.text);
			//this.shellApi.networkDisconnected();
		}

		private function enqueue(vars:URLVariables):void
		{
			//this._shellApi.devTools.console.log("queuing tracking call"+vars.event)
			// if queue is not full, then add to beginning
			if(_queuedEvents.length < MAX_EVENT_QUEUE)
			{
				//_queuedEvents.push(vars);
				_queuedEvents.unshift(vars);
				trace("BrainTracker :: Deferred tracking call. Now waiting for " +_queuedEvents.length + " tracking calls.");
			}
			else
			{
				// don't store any more events
				//_queuedEvents.pop();
				//_queuedEvents.unshift(vars);
				trace("BrainTracker :: Hit max queue size.");
			}
		}

		// dequeue events oldest to newest (back to front)
		private function dequeue():void
		{
			if (_queuedEvents.length > 0) {
				sendTrackEvent(_queuedEvents.pop());
			} else {
				_waitingForOperation = false;
				// reset queue release flag
				_startQueueRelease = false;
			}
		}

		//This should trigger queuing if there is no network.
		private function triggerQueuing():void
		{
			if(!shellApi.networkAvailable()){
				
				if(_queueTrackingCalls == false){
					if(!_trackingTimer ){
						_trackingTimer = new WallClock(QUEUED_TRACKING_INTERVAL);
						_trackingTimer.chime.add(flushQueue);
					}else{
						_trackingTimer.start();
					}
					_queueTrackingCalls = true;
				}
				
			}else{
				if( _trackingTimer ){
					_trackingTimer.stop();
				}
				_queueTrackingCalls = false;
			}
		}

		private function sendToBrain(vars:URLVariables):void
		{
			// brain tracker doesn't like extra properties in the vars
			// so we remove the dimensions
			if (vars.hasOwnProperty('dimensions')) {
				delete vars.dimensions;
			}

			if(_queueTrackingCalls)
			{
				if (!PlatformUtils.inBrowser) {
					vars.time = Math.round(new Date().time / 1000);
				}
				trace("BrainTracker :: track() queueing", vars.toString(), "because member flag is set");
				enqueue(vars);
			}
			else
			{
				if(_waitingForOperation)
				{
					trace("BrainTracker :: track();queueing", vars.toString(), "because a prior tracking call is still underway");
					enqueue(vars);
				}
				else
				{
					_waitingForOperation = true;
					if( _connection )
					{
						_connection.connect("https://www.poptropica.com/brain/track.php", vars, URLRequestMethod.GET, handleLoaded, Command.create(handleError, vars));
					}
					else
					{
						trace(this," :: Error :: track : no connection, cannot track." );
					}
					// TODO: implement Quantcast tracking, maybe
				}
			}
		}

		private var _connection:Connection;
		private var _queuedEvents:Vector.<URLVariables> = new Vector.<URLVariables>();
		private var _waitingForOperation:Boolean = false;
		private var _trackingTimer:WallClock;
		private var _queueTrackingCalls:Boolean = false;  // should tracking calls be sent in batches ('true') or immediately upon being called ('false')?
		private const MAX_EVENT_QUEUE:uint = 200;
		private const QUEUED_TRACKING_INTERVAL:Number = 10;  // frequency of sending queued tracking calls in seconds.
		
		protected var thirdPartyTrackers:Vector.<IThirdPartyTracker> = new <IThirdPartyTracker>[];
	}
}
