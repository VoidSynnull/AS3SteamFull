package engine
{
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.INativeAppMethods;
	import com.poptropica.interfaces.INetworkMonitor;
	import com.poptropica.interfaces.IPlatform;
	import com.smartfoxserver.v2.SmartFox;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.data.LanguageCode;
	import engine.group.Scene;
	import engine.managers.FileManager;
	import engine.managers.GroupManager;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	import engine.util.DevTools;
	
	import game.components.ui.Cursor;
	import game.data.TrackingEvents;
	import game.data.ads.AdData;
	import game.data.ads.PlayerContext;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.data.comm.PopResponse;
	import game.data.game.GameEvent;
	import game.data.island.IslandEvents;
	import game.data.profile.ProfileData;
	import game.data.scene.DoorData;
	import game.data.ui.card.CardSet;
	import game.managers.DLCManager;
	import game.managers.GameEventManager;
	import game.managers.LanguageManager;
	import game.managers.LongTermMemoryManager;
	import game.managers.ManifestCheckManager;
	import game.managers.PhotoManager;
	import game.managers.ProfileManager;
	import game.managers.SceneManager;
	import game.managers.ScreenManager;
	import game.managers.SmartFoxManager;
	import game.managers.SpecialAbilityManager;
	import game.managers.TextManager;
	import game.managers.interfaces.IAdManager;
	import game.managers.interfaces.IIslandManager;
	import game.managers.interfaces.IItemManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.FENErrorLogger;
	import game.proxy.GatewayConstants;
	import game.proxy.IDataStore2;
	import game.proxy.ILegacyDataManager;
	import game.proxy.ITrackingManager;
	import game.scene.template.PhotoGroup;
	import game.scenes.custom.questGame.QuestGame;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	import org.swiftsuspenders.Injector;
	
	public class ShellApi
	{
		public var languageChanged:Signal;
		
		private var _managers:Dictionary 	= new Dictionary();
		private var _managerAdded:Signal 	= new Signal(Manager);
		private var _managerRemoved:Signal 	= new Signal(Manager);
		private var keepAliveTimer:Timer;
		
		public function ShellApi(shell:Shell)
		{
			_shell = shell;
			_shellApi = this;
			
			// timer every minute
			keepAliveTimer = new Timer(60*1000);
			keepAliveTimer.addEventListener(TimerEvent.TIMER, onKATimer);
			keepAliveTimer.start();
			
			fileLoadComplete = new Signal();
			languageChanged = new Signal(XML);
			if (ExternalInterface.available)
			{
				var queryString:String = String(ExternalInterface.call("function() { return window.location.search; }"));
				// note: query string includes "?" at beginning
				if (queryString.indexOf("cmg_iframe=1") != -1)
				{
					cmg_iframe = true;
				}
			}
		}
		
		// keep alive timer
		private function onKATimer(event:TimerEvent):void {
			track("KeepAlive");
		}
						
		//////////////////////////////////////// MANAGERS ////////////////////////////////////////
		
		public function get managerAdded():Signal 		{ return this._managerAdded; }
		public function get managerRemoved():Signal 	{ return this._managerRemoved; }
		
		/**
		 * Returns requested manager class.  
		 * All manager classes extend Manager.
		 * @param managerClass
		 * @return 
		 */
		public function getManager(managerClass:Class):Manager
		{
			return this._managers[managerClass];
		}
		
		/**
		 * Return all mangers within a Vector.
		 * Vector is created on each request, so try not to call more than necessary. 
		 * @return 
		 */
		public function get managers():Vector.<Manager>
		{
			var managers:Vector.<Manager> = new Vector.<Manager>();
			for each(var manager:Manager in this._managers)
			{
				managers.push(manager);
			}
			return managers;
		}
		
		/**
		 * Add a manager Class.
		 * @param manager - instantiated Class extending Manager
		 * @param managerClass - Class, extending Manager
		 * @return - instantiated manager class 
		 */
		public function addManager(manager:Manager, managerClass:Class = null):Manager
		{
			if(manager)
			{
				if(!managerClass)
				{
					managerClass = ClassUtils.getClassByObject(manager);
				}
				if(!this._managers[managerClass] && !manager.shellApi)
				{
					this._managers[managerClass] = manager;
					manager.addedToEngine(this);
					this._managerAdded.dispatch(manager);
					return manager;
				}
			}
			return null;
		}
		
		/**
		 * Remove a manager Class 
		 * @param managerClass
		 * @return - instantiated manager class 
		 */
		public function removeManager(managerClass:Class):Manager
		{
			const manager:Manager = this._managers[managerClass];
			if(manager)
			{
				delete this._managers[managerClass];
				manager.removedFromEngine();
				this._managerRemoved.dispatch(manager);
				return manager;
			}
			return null;
		}
		
		//////////////////////////////////////// NETWORK ////////////////////////////////////////
		
		/**
		 * Returns true if network connectivity is available
		 * @return - Boolean : true if network connectivity is available
		 */
		public function networkAvailable():Boolean
		{
			//If this platform has an implementation of INetworkMonitor (ios only for now)
			// TODO :: Network availability should be detectable, regardless of platform. - bard
			
			if(this.platform.checkClass(INetworkMonitor))
			{
				return (networkMonitor.networkAvailable && AppConfig.networkAllowed);
			}
			return (networkMonitor.networkAvailable && AppConfig.networkAllowed);
		}
		public function showNeedNetworkPopup():void
		{
			var dialogBox:ConfirmationDialogBox = currentScene.addChildGroup(new ConfirmationDialogBox(1, "Please check Internet connection.")) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(currentScene.overlayContainer);
		}
		/**
		 * Updates networkMonitor that a failure has occurred with a web service.
		 */
		[Deprecated (message="We should NOT be calling this. The NetworkMonitor shouldn't be told what its status is.")]
		public function networkDisconnected() : void
		{
			//If this platform has an implementation of INetworkMonitor (ios only for now)
			if(this.platform.checkClass(INetworkMonitor))
			{
				this.networkMonitor.networkAvailable = false;
			}
		}

		//////////////////////////////////////// FILE MANAGEMENT ////////////////////////////////////////
		
		/**
		 * Clear the cache of loaded files.  This happens automatically between scenes.  If no url is specified the entire cache is cleared.
		 * @param   [url] : A specific file to clear from the cache.
		 */
		public function clearFileCache():void
		{
			this.fileManager.clearCache();
		}
		
		/**
		 * Load and cache a file.  The file will remain in cache for later access until 'clearFileCache' is called.
		 * @param   url : Path to the file.
		 * @param   [callback] : A method to call after the file has loaded.  Gets the file content as its first parameter.
		 * @param   [...args] : Arguments to pass to the callback method.  Note that the first parameter is reserved for the file content, so any added args will start at the second argument.
		 */
		public function cacheFile(url:String, callback:Function = null, ... args):void
		{
			this.fileManager.cacheFile(url, callback, args);
		}
		
		/**
		 * Store relationship between file url and file via Dictionary
		 * Allows files to be retrieved by use of their url
		 * @param url - url of file, funtions as a key to retrive file
		 * @param file - file to maintain reference to
		 */
		public function setCache(url:String, file:*):void
		{
			this.fileManager.setCache(url, file);
		}

		/**
		 * Load a file.  Supports any file type that flash can load.
		 * @param   url : Path to the file.
		 * @param   [callback] : A method to call after the file has loaded.  Gets the file content as its first parameter.
		 * @param   [...args] : Arguments to pass to the callback method.  Note that the first parameter is reserved for the file content, so any added args will start at the second argument.
		 */
		public function loadFile(url:String, callback:Function = null, ... args):void
		{
			this.fileManager.loadFile(url, callback, args);
		}
		
		/**
		 * Load a file, if file not found in storage requests from host.  Supports any file type that flash can load.
		 * @param url : Path to the file.
		 * @param callback : A method to call after the file has loaded.  Gets the file content as its first parameter.
		 * @param args : Arguments to pass to the callback method.  Note that the first parameter is reserved for the file content, so any added args will start at the second argument.
		 */
		public function loadFileWithServerFallback(url:String, callback:Function = null, ... args):void
		{
			this.fileManager.loadFile(url, callback, args, null, AppConfig.assetHost);
		}
		
		/**
		 * Loads a server XML and app-storage XML with the given URL. Both of the XMLs will be returned with the callback Function,
		 * and it's up to the developer to do any comparisons or version checks to determine if the server XML is what they want.
		 * 
		 * <p>There are several utility classes to aid in the process of checking XMLs and saving them.
		 * <li><b>VersionUtils:</b> Utility for version String comparisons in the format of "0.0.0.0".</li>
		 * <li><b>FileUtils:</b> Utility for writing XMLs to app-storage.</li>
		 * </p>
		 * 
		 * <p><b>Note:</b> As a standard, all XMLs loaded like this should ideally have a <code>version</code> attribute. This
		 * <code>version</code> attribute should be checked in your code in the event that an XML's format has changed so it
		 * can be parsed according to its version.</p>
		 * 
		 * @see game.util.FileUtils
		 * @see game.util.VersionUtils
		 * @param url The URL of the XML file. Server and app-storage prefixes will be added automatically as:
		 * <ul>
		 * <li>Server: shellApi.serverPrefix + url</li>
		 * <li>App-Storage: "app-storage:/" + url</li>
		 * </ul>
		 * @param callback A callback Function to receive the XMLs. The callback should be formatted as:
		 * <ul>
		 * <li>callback(xmlServer:XML, xmlStorage:XML, ...args)
		 * </ul>
		 * @param args Any arguments needed to go along with the callback Function.
		 */
		public function loadXMLFromServerAndAppStorage(url:String, callback:Function = null, ...args):void
		{
			this.fileManager.loadXMLFromServerAndAppStorage(url, callback, args);
		}
		
		// TODO :: This should probably go somewhere else
		public function get serverPrefix():String
		{
			if( _serverPrefix == null )
			{
				if( AppConfig.production )
				{
					// TODO :: possible that siteProxy is not yet defined when this is called... lame - Bard
					//_serverPrefix = String( "http://" + siteProxy.commData.staticHost + "/game/" );
					_serverPrefix = "https://static.poptropica.com/game/";

				}
				else
				{
					// NOTE :: Should pull from xpop, but xpop won't allow downloads for some reason
					_serverPrefix =  "https://www.poptropica.com/game/";
					// _serverPrefix =  "https://" + this.siteProxy.fileHost + "/game/";
				}
			}
			return _serverPrefix;
		}
		
		/**
		 * Load an array of files.
		 * @param   urls : Path to the files.
		 * @param   [callback] : A method to call after all files have been loaded.
		 * @param   [...args] : Arguments to pass to the callback method.
		 */
		public function loadFiles(urls:Array, callback:Function = null, ... args):void
		{
			if(callback == null)
			{
				this.fileManager.loadFiles(urls, fileLoaded);
			}
			else
			{
				this.fileManager.loadFiles(urls, callback, args);
			}
		}

		/**
		 * Load an array of files. if file not found in storage requests from host.  Supports any file type that flash can load.
		 * @param   urls : Path to the files.
		 * @param   [callback] : A method to call after all files have been loaded.
		 * @param   [...args] : Arguments to pass to the callback method.
		 */
		public function loadFilesWithServerFallback(urls:Array, callback:Function = null, ... args):void
		{
			if (callback == null)
			{
				this.fileManager.loadFiles(urls, fileLoaded, null, null, AppConfig.assetHost);
			}
			else
			{
				this.fileManager.loadFiles(urls, callback, args, null, AppConfig.assetHost);
			}
		}
		
		private function fileLoaded():void
		{
			fileLoadComplete.dispatch();
		}
		
		/**
		 * Get a file that's already been loaded.
		 * @param   url : Path to the file for lookup.
		 * @param   [clear] : Clear the file from the cache after it has been retrieved.
		 */
		public function getFile(url:String, clear:Boolean = false):*
		{
			return this.fileManager.getFile(url, clear);
		}
		
		public function deleteFiles(list:Array):void
		{
			this.fileManager.deleteFiles(list);
		}
		
		/**
		 * Stop loading a list of files.
		 * @param   [urls] : Files to stop loading.
		 */
		public function stopFileLoad(urls:Array):void
		{
			this.fileManager.stopLoad(urls);
		}
		
		/**
		 * Load an array of files, returns loaded files as callback parameters.
		 * Order of returned files is same order as urls within urls param.
		 * @param   urls : Path to the files.
		 * @param   [callback] : A method to call after all files have been loaded.
		 * @param   [...args] : Arguments to pass to the callback method.
		 */
		public function loadFilesReturn(urls:Array, callback:Function, ... args):void
		{
			args.unshift( callback ); 
			args.unshift( urls ); 
			this.fileManager.loadFiles(urls, filesLoaded, args);
		}

		/**
		 * Load an array of files, returns loaded files as callback parameters.
		 * if file not found in storage requests from host.  Supports any file type that flash can load.
		 * Order of returned files is same order as urls within urls param.
		 * @param   urls : Path to the files.
		 * @param   [callback] : A method to call after all files have been loaded.
		 * @param   [...args] : Arguments to pass to the callback method.
		 */
		public function loadFilesReturnWithServerFallback(urls:Array, callback:Function, ... args):void
		{
			args.unshift( callback ); 
			args.unshift( urls );
			this.fileManager.loadFiles(urls, callback, args, null, AppConfig.assetHost);
		}
		
		/**
		 * Handler for loadFilesReturn, gets files and includes them in callback params.
		 * @param	urls
		 * @param	callback
		 * @param	... args
		 */
		private function filesLoaded( urls:Array, callback:Function, ... args):void
		{
			var i:uint = urls.length;
			for ( i; i > 0; i-- )
			{
				args.unshift( getFile(urls[i-1]) );	// push files to front of args Array
			}
			callback.apply( null, args );
		}
		
		public function keepInCache(url:String, file:*):void
		{
			this.fileManager.keepInCache(url, file);
		}
		
		//////////////////////////////////////// LANGUAGE ////////////////////////////////////////
		
		/**
		 * Returns preferred language in active profile. 
		 * @return - preferred language by its integer value stored in active profile
		 */
		public function get preferredLanguage():String 
		{
			var languageString:String;
			switch( profileManager.active.preferredLanguage)
			{
				case LanguageCode.NUMBER_EN:
					return LanguageCode.LANGUAGE_EN;
				case LanguageCode.NUMBER_FR:
					return LanguageCode.LANGUAGE_FR;
				case LanguageCode.LANGUAGE_ES:
					return LanguageCode.LANGUAGE_ES;
				case LanguageCode.NUMBER_PT:
					return LanguageCode.LANGUAGE_PT;
				case LanguageCode.NUMBER_BR:
					return LanguageCode.LANGUAGE_BR;
			}
			
			return LanguageCode.LANGUAGE_EN;
		}
		
		public function set preferredLanguage(newLanguage:String):void
		{
			switch(newLanguage)
			{
				case LanguageCode.LANGUAGE_EN:
					profileManager.active.preferredLanguage = LanguageCode.NUMBER_EN;
					break;
				case LanguageCode.LANGUAGE_FR:
					profileManager.active.preferredLanguage = LanguageCode.NUMBER_FR;
					break;
				case LanguageCode.LANGUAGE_ES:
					profileManager.active.preferredLanguage = LanguageCode.NUMBER_ES;
					break;
				case LanguageCode.LANGUAGE_PT:
					profileManager.active.preferredLanguage = LanguageCode.NUMBER_PT;
					break;
				case LanguageCode.LANGUAGE_BR:
					profileManager.active.preferredLanguage = LanguageCode.NUMBER_BR;
					break;
			}
		}
		
		[Deprecated (message="Changed this to an actual setter for preferredLanguage.")]
		public function updateLanguage(newLanguage:String):void {
			//profileManager.active.preferredLanguage = newLanguage;
		}
		
		[Deprecated (message="This is our old way of parsing languages. Refer to language manager")]
		public function localizeFilename( fileName:String ):String 
		{
			var localeSuffixes:Array = ['', '_fr', '_es', '_pt'];
			var index:int = fileName.lastIndexOf(".");
			return String( fileName.slice(0,index) + localeSuffixes[preferredLanguage] + fileName.slice(index) );
		}
		
		private function onDialogXMLLoaded(newDialogXML:XML):void 
		{
			languageChanged.dispatch(newDialogXML);
		}
		
		//////////////////////////////////////// GENERAL SETTINGS ////////////////////////////////////////
		
		/**
		 * General settings for game.
		 * If a parameter is not given will default to the value found in active Profile.
		 * TODO :: When alternate language is available it can becoem the 5th parameter. 
		 * @param musicVolume
		 * @param effectsVolume
		 * @param dialogSpeed
		 */
		public function setGeneralSettings( musicVolume:Number = NaN, effectsVolume:Number = NaN, dialogSpeed:Number = NaN, qualityLevel:Number = NaN ):void
		{
			var profileManager:ProfileManager = this.profileManager;
			var profile:ProfileData = profileManager.active
			
			if( isNaN(musicVolume) ){
				musicVolume = profile.musicVolume;
			}else{
				profile.ambientVolume = profile.musicVolume = musicVolume;
			}
			
			if( isNaN(effectsVolume) ){
				effectsVolume = profile.effectsVolume;
			}else{
				profile.effectsVolume = effectsVolume;
			}
			
			if( isNaN(dialogSpeed) ){
				dialogSpeed = profile.dialogSpeed;
			}else{
				profile.dialogSpeed = dialogSpeed;
			}
			
			trace(this, ":: setGeneralSettings() Pre", "P=", profile.qualityOverride, "Q=", qualityLevel);
			
			if( isNaN(qualityLevel) )
			{
				qualityLevel = profile.qualityOverride;
				if( isNaN(qualityLevel) )
				{
					qualityLevel = -1;
				}
			}
			else
			{
				profile.qualityOverride = qualityLevel;
			}
			
			trace(this, ":: setGeneralSettings() Post", "P=", profile.qualityOverride, "Q=", qualityLevel);
			
			if( AppConfig.storeToExternal )
			{
				siteProxy.store(DataStoreRequest.settingsStorageRequest(musicVolume, effectsVolume, dialogSpeed, qualityLevel, profile.preferredLanguage));
			}
			profileManager.save();
		}
		
		//////////////////////////////////////// PAUSING ////////////////////////////////////////
		
		/**
		 * pause the game, stops tick provider and all updates to systems.
		 */
		public function pause():void
		{
			SceneManager(this.getManager(SceneManager)).currentScene.pause();
			paused = true;
		}
		
		/**
		 * unpause the game, restarts tick provider and all updates to systems.
		 */
		public function unpause():void
		{
			SceneManager(this.getManager(SceneManager)).currentScene.unpause();
			paused = false;
		}
		
		/**
		 * toggle between paused and unpaused states.
		 */
		public function togglePause():void
		{
			if (paused)
			{
				unpause();
			}
			else
			{
				pause();
			}
		}
		//////////////////////////////////////// GENERAL SETTINGS ////////////////////////////////////////
		
		public function needToStoreOnServer():Boolean
		{
			// if storing data on server or not guest (mobile)
			if ((AppConfig.storeToExternal) || (!profileManager.active.isGuest))
			{
				return true;
			}
			return false;
		}
		//////////////////////////////////////// EVENTS ////////////////////////////////////////
		
		/**
		 * Remove an event from the list of completed events in GameEventManager.
		 * @param   event : The event to remove.
		 * @param   [island] : The island to remove the event from.  Defaults to the current island.
		 */
		public function removeEvent(event:String, island:String = null, refreshEvents:Boolean = true):void
		{
			if (island == null)
			{
				island = this.island;
			}
			
			// check if we've completed the event we're trying to remove.
			if(this.gameEventManager.remove(event, island, refreshEvents))
			{
				if(AppConfig.storeToExternal) 
				{ 
					siteProxy.store(DataStoreRequest.eventsDeletedStorageRequest([event], island));
				}
			}
		}
		
		/**
		 * Check to see if the player has completed an event.
		 * @param   event : The event to check for.
		 * @param   [island] : The island to check the event for.  Defaults to the current island.
		 * @return - Boolean : returns true is event is found.
		 */
		public function checkEvent(event:String, island:String = null):Boolean
		{
			if (island == null)	{ island = this.island; }
			return(this.gameEventManager.check(event, island));
		}
		
		/**
		 * Check to see if the player has ever gotten an item.  Even if the user has since lost the item (ex : given to an npc) this will still return 'true' to indicate they once had it.  
		 * To check if the item is currently in the player's inventory, use 'checkItem(item)'.
		 * @param   item : The item to check for.
		 * @param   [hasItemCurrently] : If the user currently has the item in their inventory.  If false, will only return true if they've never had it.
		 * @param   [island] : The island to check the item for.  Defaults to the current island.
		 */
		public function checkItemEvent(item:String, hasItemCurrently:Boolean = false, island:String = null):Boolean
		{
			if (island == null)	{ island = this.island; }
			if(hasItemCurrently)
			{
				return(this.gameEventManager.check(GameEvent.HAS_ITEM + item, island));
			}
			else
			{
				return(this.gameEventManager.check(GameEvent.GOT_ITEM + item, island));
			}
		}	
		
		/**
		 * Checks if an item was acquired but then 'given' away.
		 * If item GOT is true but HAS is false, item was used, and method returns true. 
		 * @param item
		 * @param island
		 * @return
		 */
		public function checkItemUsedUp(item:String, island:String = null):Boolean
		{
			if (island == null)	{ island = this.island; }
			
			return(checkItemEvent(item, false, island) && !checkItemEvent(item, true, island)); // if GOT is true & HAS is false
		}
		
		// NOTE :: this appears to be the same as checkIfUsedItem?
		[Deprecated (message="Use checkItemUsedUp instead.")]
		public function checkItemReturned(item:String, island:String = null):Boolean
		{
			return checkItemUsedUp( item, island );
		}
		
		// TODO: accomodate the AMFPHP gateway's ability to log multiple events at once
		/**
		 * Complete a game event and store it in the list of completed events.
		 * @param   event : The event to complete.
		 * @param   [island] : The island to complete the event in.  Defaults to the current island.
		 * @return	A <code>Boolean</code> indicating whether the event was sent to the server.
		 */
		public function completeEvent(event:String, island:String=null):Boolean
		{
			island = DataUtils.useString(island, this.island);
			
			// make sure we haven't already completed this event before sending it to the server and tracking.
			var couldComplete:Boolean = gameEventManager.complete(event, island);
			if (couldComplete) 
			{
				if(AppConfig.storeToExternal) 
				{ 
					track(TrackingEvents.COMPLETE_EVENT, event);
					siteProxy.store(DataStoreRequest.eventsCompletedStorageRequest([event], island));
				}
			}
			
			return couldComplete;
		}
		
		/**
		 * Trigger an event to update game state.  This will cause any npc data associated with the event (position, skin, animaiton) to update.  Dialog will also be updated to match this event if applicable.
		 * @param   event : The event to trigger.
		 * @param   [island] : The island to complete the event in.  Defaults to the current island.
		 */
		public function triggerEvent(event:String, save:Boolean = false, makeCurrent:Boolean = true, island:String = null):void
		{
			if (island == null)
			{
				island = this.island;
			}
			
			var newEvent:Boolean = this.gameEventManager.trigger(event, island, save, makeCurrent);
			
			if(newEvent)
			{
				if( save && AppConfig.storeToExternal ) 
				{
					track(TrackingEvents.COMPLETE_EVENT, event);
					siteProxy.store(DataStoreRequest.eventsCompletedStorageRequest([event], island));
				}
			}
		}
		
		/**
		 * Get a list of completed events.
		 * @param   [island] : The island to list.  Defaults to the current island.
		 */
		public function getEvents(island:String = null):Vector.<String>
		{
			if (island == null)
			{
				island = this.island;
			}
			
			return(this.gameEventManager.getEvents(island));
		}
		
		/**
		 * Setup a component to receive eventTrigger updates.
		 * Any time an eventTrigger occurs this component will be updated.
		 * This will set the latest event to current based on completedEvents.
		 */
		public function setupEventTrigger(component:*):void
		{
			var events:Vector.<String> = this.getEvents().slice();
			events.unshift(GameEvent.DEFAULT);
			
			// run through current events
			for (var n:uint = 0; n < events.length; n++)
			{
				component.eventTriggered(events[n], true, true);
			}
			
			this.eventTriggered.add(component.eventTriggered);
		}
		
		//////////////////////////////////////// USERFIELDS ////////////////////////////////////////
		
		/**
		 * Retrieve a userfield value for current player.
		 * Requests is channeled through SiteProxy if it exists, if not handled by current Profile
		 * @param fieldId - id of userfield
		 * @param islandName - optional parameter, if specified will look for userfield associated with given island
		 * @param fromServer - if true will try retrieve from external source, if false will try retrieve from current profile
		 * @param callback - userfield value is returned as callback parameter
		 * @return - returns value directly, if you know you don't need the callback
		 */
		public function getUserField( fieldId:String, islandName:String = "", callback:Function = null, fromServer:Boolean = false ):*
		{
			// attempt to retrive userfield from profile first
			var value:*;
			value = currentProfile.getUserField( fieldId, islandName );

			// if not found in profile check external sources (for pop this is as2LSO & server) 
			if( AppConfig.storeToExternal && DataUtils.isNull(value) )
			{
				//check legacy data manager
				var legacyManager:ILegacyDataManager = _managers[ILegacyDataManager];
				if( legacyManager != null )
				{
					value = legacyManager.getUserField( fieldId );
				}

				if( !DataUtils.isNull(value) )	// if value found, update profile
				{
					this.profileManager.active.setUserField( fieldId, value, islandName );
					this.profileManager.save();	// NOTE :: Do we want always want to save at this point? - bard
				}
				else if( fromServer )			// otherwise check server
				{
					if (AppConfig.storeToExternal) {
						siteProxy.retrieve(DataStoreRequest.userFieldRetrievalRequest(fieldId, islandName), callback);
						return;
					}
				}
			}
			
			if( callback != null )	{ callback(value); }
			return value;
		}	
		
		/**
		 * Retrieve userfield values for current player.
		 * @param fieldIdArray - Array of userfield ids, each user field id should be in String format
		 * @param islandName - optional parameter, if specified will look for userfields associated with given island
		 * @param fromServer - if true will try retrieve from external source, if false will try retrieve from current profile
		 * @param callback - userfield values returned as callback parameter, the Dictionary uses fieldId as key
		 * @return - returns Dictionary using fieldId as key
		 */
		public function getUserFields( fieldIds:Array, islandName:String = "", callback:Function = null, fromServer:Boolean = false ):Dictionary
		{
			// NOTE :: if one field value is missing we try again at next stage
			var fieldValues:Dictionary = new Dictionary();
			var fieldId:String;
			var value:*;
			var i:int;
			
			// check profile for userfields
			for (i = 0; i < fieldIds.length; i++) 
			{
				fieldId = fieldIds[i];
				value = currentProfile.getUserField( fieldId, islandName )
				if( DataUtils.isNull( value ) )
				{
					trace( this,":: getUserFields : checked profile, value for userfield : " + fieldId + " was null" );
					fieldValues = null;
					break;
				}
				else
				{
					fieldValues[fieldId] = value;
				}
			}
			
			if( fieldValues == null && AppConfig.storeToExternal )
			{
				//check legacy data manager 
				// POP-BROWSER ONLY - required due to as2LSO nonsense, hopefully this will go away some day
				var legacyManager:ILegacyDataManager = _managers[ILegacyDataManager];
				if( legacyManager != null )
				{
					fieldValues = legacyManager.getUserFields( fieldIds );
					// if valid dictionar is returned store values to profile
					if( fieldValues != null )
					{
						for (i= 0; i < fieldIds.length; i++) 
						{
							fieldId = fieldIds[i];
							currentProfile.setUserField( fieldId, fieldValues[fieldId], islandName )
						}
						this.profileManager.save();
					}
				}
				
				// check server
				if( fieldValues == null && fromServer )
				{
					if (AppConfig.storeToExternal) {
						siteProxy.retrieve(DataStoreRequest.userFieldsRetrievalRequest(fieldIds, islandName), callback);
						return null;
					}
				} 
			}
			
			if( callback != null )	{ callback(fieldValues); } 
			return fieldValues;
		}	
		
		/**
		 * Save userfield value. 
		 * @param fieldId - id of user field
		 * @param fieldValue - value of userfield
		 * @param islandName - island userfield is associated with (optional)
		 * @param saveToServer - flag determining is vaue shoudl be saved to server
		 * @param callback - if saving to server callback triggered when complete, otherwise called directly within method
		 * @param save - if true value is saved to profile & longterm storage, with save icon displayed
		 * 
		 */
		public function setUserField( fieldId:String, fieldValue:*, islandName:String = "", saveToServer:Boolean = false, callback:Function = null, save:Boolean = true ):void
		{
			trace(this," :: setUserField : fieldId : " + fieldId + " fieldValue: " + fieldValue + " islandName: " + islandName + " saving to server: " + saveToServer );
			// save to profile first		
			currentProfile.setUserField( fieldId, fieldValue, islandName );
			
			// store to external sources (for pop this is as2LSO & server) 
			if( AppConfig.storeToExternal && saveToServer ) 
			{
				// set user fields to AS2 LSO (reeally only necessray for guest users)
				var legacyManager:ILegacyDataManager = _managers[ILegacyDataManager];
				if( legacyManager != null )
				{
					// NOTE :: We don't pass the island, since it reflects what the database expects, which is a flat strcuture. - bard
					legacyManager.setUserField(fieldId, fieldValue);	
				}
				
				// set user fields to server
				trace(this," :: setUserField : attempting storage request" );
				siteProxy.store(DataStoreRequest.userFieldStorageRequest(fieldId, fieldValue, islandName), callback);
				callback = null;
			}
	
			if( save )	
			{ 
				this.profileManager.save();
				trace("Current Scene: " + currentScene);
				if(currentScene)
					SceneUtil.createSaveIcon(currentScene);
			}
			if( callback != null ) 	{ callback(); }
		}

		//////////////////////////////////////// SCENE COORDINATES ////////////////////////////////////////
		
		/**
		 * Convert a scene coordinate into a global coordinate.
		 * @param   x : The number to offset.
		 */
		public function offsetX(x:Number):Number
		{			
			// TEMP : adding offset to deal with scaling error TODO : fix offset calculation
			if(this.camera)
			{
				var deltaX:Number;
				var scale:Number;
				
				if(this.viewportScale != 1)
				{
					deltaX = x + this.camera.x;
					scale = 1 - this.viewportScale;
					
					x -= deltaX * scale;
				}
				
				if(this.camera.scale != 1)
				{
					deltaX = x + this.camera.x;
					scale = 1 - this.camera.scale;
					
					x -= deltaX * scale;
				}
				
				return(x + this.camera.x + (this.viewportWidth * .5) * this.viewportScale);
			}
			else
			{
				return(x);
			}
		}
		
		/**
		 * Convert a scene coordinate into a global coordinate.
		 * @param   y : The number to offset.
		 */
		public function offsetY(y:Number):Number
		{
			// TEMP : adding offset to deal with scaling error TODO : fix offset calculation
			if(this.camera)
			{
				var deltaY:Number;
				var scale:Number;
				
				if(this.viewportScale != 1)
				{
					deltaY = y + this.camera.y;
					scale = 1 - this.viewportScale;
					
					y -= deltaY * scale;
				}
				
				if(this.camera.scale != 1)
				{
					deltaY = y + this.camera.y;
					scale = 1 - this.camera.scale;
					
					y -= deltaY * scale;
				}
				
				return(y + this.camera.y + (this.viewportHeight * .5) * this.viewportScale);
			}
			else
			{
				return(y);
			}
		}		
		
		public function sceneToGlobal(val:Number, axis:String):Number
		{
			// TEMP : adding offset to deal with scaling error TODO : fix offset calculation
			if(this.camera)
			{
				var delta:Number;
				var scale:Number;
				var viewportOffset:Number;
				var cameraOffset:Number;
				
				if(axis == "x")
				{
					cameraOffset = this.camera.x;
					viewportOffset = this.viewportWidth * .5;
				}
				else
				{
					cameraOffset = this.camera.y;
					viewportOffset = this.viewportHeight * .5;
				}
				/*
				if(this.viewportScale != 1)
				{
				delta = val + cameraOffset;
				scale = 1 - this.viewportScale;
				
				val -= delta * scale;
				}
				*/
				if(this.camera.scale != 1)
				{
					delta = val + cameraOffset;
					scale = 1 - this.camera.scale;
					
					val -= delta * scale;
				}
				
				return(val + cameraOffset + viewportOffset/* * this.viewportScale*/);
			}
			else
			{
				return(val);
			}
		}
		
		public function globalToScene(val:Number, axis:String):Number
		{
			// TEMP : adding offset to deal with scaling error TODO : fix offset calculation
			if(this.camera)
			{
				var delta:Number;
				var scale:Number;
				var viewportOffset:Number;
				var cameraOffset:Number;
				
				if(axis == "x")
				{
					cameraOffset = this.camera.x;
					viewportOffset = this.viewportWidth * .5;
				}
				else
				{
					cameraOffset = this.camera.y;
					viewportOffset = this.viewportHeight * .5;
				}
				
				/*
				if(this.viewportScale != 1)
				{
				delta = val - cameraOffset;
				scale = 1 - this.viewportScale;
				
				val += delta * scale;
				}
				*/
				
				if(this.camera.scale != 1)
				{
					delta = (val - viewportOffset) / this.camera.scale;
					scale = 1 - this.camera.scale;
					val += delta * scale;
				}
				
				return(val - cameraOffset - viewportOffset/*/ this.viewportScale*/);
			}
			else
			{
				return(val);
			}
		}
		
		//////////////////////////////////////// USER ////////////////////////////////////////
		
		public function saveGame():void
		{
			if(!profileManager.active.isGuest)
			{
				if(getUserField("gameType") != "Flash") {
					setUserField("gameType", "Flash","",true);
				}
			}
			
			this.profileManager.save();
			
			if(this.currentScene)
			{
				SceneUtil.createSaveIcon(this.currentScene);
				this.currentScene.registrationSuccess();
			}
		}

		public function testScenes():void
		{
			siteProxy.call(new DataStoreRequest(DataStoreRequest.RETRIEVAL_REQUEST_TYPE, 9999), onTestScenesData);
		}
		private function onTestScenesData(response:PopResponse):void
		{
			trace("test scene data:", response);
			trace(JSON.stringify(response.data));
		}

		/**
		 * Save active player's look 
		 * @param source - optional, accepts LookData or Entity, defaults to player Entity, derives LookDatas in case of Entity
		 * @param callback - in case where look is saved to backend, callback fired on request return
		 */
		public function saveLook(source:* = null, callback:Function = null):void
		{
			var lookData:LookData;
			
			if(source != null)
			{
				if(source is LookData)
				{
					lookData = source;
				}
				else if(source is Entity)
				{
					lookData = SkinUtils.getLook( source );
				}
			}
			else
			{
				lookData = SkinUtils.getLook( this.player );
			}
			
			if(lookData != null)
			{
				this.profileManager.active.look = new LookConverter().playerLookFromLookData( lookData );
				this.profileManager.save();
				
				if( AppConfig.storeToExternal ) 
				{
					//check legacy data manager 
					// POP-BROWSER ONLY - required due to as2LSO nonsense, hopefully this will go away some day
					var legacyManager:ILegacyDataManager = _managers[ILegacyDataManager];
					if( legacyManager != null )
					{
						legacyManager.savePlayerLook( lookData );
					}
					
					// save to backend
					siteProxy.store(DataStoreRequest.playerLookStorageRequest(player, lookData), callback);
					this.setUserField("specialAbilities", profileManager.active.specialAbilities);
				}
				
				// NOTE :: Adding this for multi-player, don't love having it here, might be a better way to handle this? - bard
				// NOTE :: Might be better to just dispatch an event?
				trace("ShellApi : saveLook : look saved.");
				this.profileManager.onLookSaved.dispatch( lookData );
			}
			else
			{
				trace("Warning :: ShellApi : saveLook : LookData is null and cannot be saved.");
			}
		}
		

		/**
		 * Save look to active profile's closet
		 * @param lookData - LookData to be saved to closet
		 * @param onRequestHandler - callback for backend request, should takes a <code>PopResponse</code> as its first argument.
		 * @param onClosetFullHandler - called if closet is full, if backend request required full closet response should be handled within onRequestHandler 
		 */
		public function saveLookToCloset( lookData:LookData, onRequestHandler:Function = null, onClosetFullHandler:Function = null ):void
		{
			if( lookData != null )
			{
				//This does not include desktop/local testing. Local testing will default to mobile closet.
				if( !isNaN(profileManager.active.dbid) )
				{
					// in case of browser we let backend determine if user can save to closet and whether there is enough room
					if (AppConfig.storeToExternal) siteProxy.store(DataStoreRequest.closetLookStorageRequest(lookData), onRequestHandler);
				}
				else
				{
					// on mobile we don't need to consult backend, can save directly to ProfileData
					var playerLooks:Vector.<PlayerLook> = profileManager.active.closetLooks;
					if(playerLooks.length < ProfileManager.MAX_CLOSET_LOOKS)
					{
						var converter:LookConverter = new LookConverter();
						playerLooks.unshift(converter.playerLookFromLookData(lookData));
						saveGame();
					}
					else
					{
						if( onClosetFullHandler ) { onClosetFullHandler(); }
					}
				}
			}
		}

		/**
		 * Reset profile data
		 * Also reset events and items for current island.
		 */
		public function resetData(id:String = null):void
		{
			profileManager.clear(id);
			// clears all events and items
			this.gameEventManager.reset();
			this.itemManager.reset();
			// events and items Arrays should be recreated for the current island.
			this.gameEventManager.reset(this.island);
			this.itemManager.reset(this.island);
		}
		
		public function resetIslandData(island:String):void
		{
			this.gameEventManager.reset(island);
			this.itemManager.reset(island);
			// TODO :: Should we be clearing userfields in the AS2LSO & database as well?
			profileManager.active.resetUserFieldsForIsland(island);
			profileManager.active.lastScene[island] = null;
			var islandEvents:String = "game.scenes." + island + "." + ProxyUtils.convertIslandToAS2Format(island) + "Events";
			SceneUtil.removeIslandParts(this.currentScene, islandEvents, false);
			profileManager.save();
		}

		//////////////////////////////////////// ISLAND SPECIFIC ////////////////////////////////////////
		
		/**
		 * If island can be reset
		 * @return <code>true</code> if the island can be restarted
		 */		
		public function get islandCanReset():Boolean 
		{		
			if( islandEvents != null )
			{
				return islandEvents.canReset;
			}
			return false;
		}
		
		/**
		 * Load a new scene.
		 * @param   scene : The new scene's class.
		 * @param   [playerX, playerY] : x and y position to place the player in the scene.  If left undefined the player will load into the default x/y position in the scenes scene.xml.
		 * @param   [direction] : Direction to face the player in the scene.  Can be 'left' or 'right'.  Will default to the value in scene.xml if undefined.
		 */
		public function loadScene(scene:*, playerX:Number = NaN, playerY:Number = NaN, direction:String = null, fadeInTime:Number = NaN, fadeOutTime:Number = NaN, onFailure:Function = null):void
		{
			if(scene is DoorData)
			{
				playerX = DoorData(scene).destinationSceneX;
				playerY = DoorData(scene).destinationSceneY;
				direction = DoorData(scene).destinationSceneDirection;
				scene = ClassUtils.getClassByName(DoorData(scene).destinationScene);
			}
			else if(DataUtils.validString(overrideReturnScene) && !(scene == QuestGame || scene == "game.scenes.custom.questGame::QuestGame") ||
				overrideReturnSceneClass != null && !(scene == QuestGame || scene == "game.scenes.custom.questGame::QuestGame"))
			{
				trace(scene + " : " + (scene == QuestGame));
				if(DataUtils.validString(overrideReturnScene))
				{
					var returnInfo:Array = overrideReturnScene.split(",");
					scene = ClassUtils.getClassByName(returnInfo[0]);
					if(returnInfo.length == 3)
					{
						playerX = returnInfo[1];
						playerY = returnInfo[2];
					}
				}
				else
				{
					scene = overrideReturnSceneClass;
				}
				overrideReturnSceneClass = null;
				overrideReturnScene = null;
				arcadeGame = null;
			}
			
			IIslandManager(this.getManager(IIslandManager)).loadScene(scene, playerX, playerY, direction, fadeInTime, fadeOutTime, onFailure);
		}
		
		public function removeScene():void
		{
			SceneManager(this.getManager(SceneManager)).removeScene();
		}
		
		/**
		 * Reset island
		 * Have to do some monkeying around if island has an AS2 counterpart
		 * @param island
		 * @param callback
		 * @param as2Format
		 */
		public function resetIsland(island:String = null, callback:Function=null, as2Format:Boolean = false):void
		{
			if(island == null)
			{
				island = this.island;
			}
			
			// RLH: this fails for new players who don't have a password
			if(( AppConfig.storeToExternal ) && (!profileManager.active.isGuest))
			{
				siteProxy.store(DataStoreRequest.islandResetStorageRequest(island, as2Format), callback);
				siteProxy.store(DataStoreRequest.islandStartStorageRequest(island, as2Format));
			}
			
			this.resetIslandData(island);
			
			if (profileManager.active.isGuest && callback)
			{
				callback(null);
			}
		}
		
		public function returnToIslandFirstScene():void
		{
			if(this.islandEvents)
			{
				var sceneEntrance:DoorData = this.islandEvents.sceneEntrance;
				
				if(sceneEntrance)
				{
					loadScene(sceneEntrance);
				}
			}
		}

		public function storeSceneVisit(aScene:Scene, playerX:Number, playerY:Number, playerDir:String):void 
		{
			var sceneClassName:String = ClassUtils.getNameByObject(aScene);
			if ('game.scenes.hub.town::Town' == sceneClassName) {
				trace("SO SORRY, hub/town not for saving<<<<<<<<<<<<<<<<<<<<<");
				return;
			}
			if(AppConfig.storeToExternal) 
			{
				siteProxy.store(DataStoreRequest.sceneVisitStorageRequest(aScene, playerX, playerY, playerDir));
			}
		}
		
		/**
		 * Method to call when island is completed, will log completion to storage/server
		 * @param completedIsland - name of island to complete
		 * @param callback - Function called once island completion has been properly logged, may return PopResponse if communicating with server
		 */
		public function completedIsland( completedIsland:String, callback:Function):void
		{
			if( !DataUtils.validString( completedIsland ) ) {
				completedIsland = island;
			}
			
			track('IslandCompleted', completedIsland);
			if (!profileManager.active.isGuest && AppConfig.storeToExternal) {
				siteProxy.store(DataStoreRequest.islandFinishStorageRequest(completedIsland), Command.create(onCompletionStored, callback));
			} else {
				// RLH: update profile for guests
				if (profileManager.active.islandCompletes[completedIsland] == null)
					profileManager.active.islandCompletes[completedIsland] = 1;
				else
					profileManager.active.islandCompletes[completedIsland]++;
				onCompletionStored(new PopResponse(GatewayConstants.AMFPHP_PROBLEM, null, "External DataStore disallowed"), callback);
			}
		}

		private function onCompletionStored(response:PopResponse, callback:Function):void
		{
			if(PlatformUtils.inBrowser)
			{
				if (response.data) {
					for (var islandName:String in response.data.island_completions) {
						profileManager.active.islandCompletes[islandName.charAt(0).toLowerCase() + islandName.substr(1)] = response.data.island_completions[islandName];
					}
				} else trace("WARNING :: number of completions were not received");
			}
			else
			{
				var islandCompletions:int = profileManager.active.islandCompletes[island];
				islandCompletions += 1;
				profileManager.active.islandCompletes[island] = islandCompletions;
			}
			
			if (callback) {
				callback(response);
			}
			
			this.saveGame();
		}
		
		//////////////////////////////////////// ITEMS ////////////////////////////////////////
		
		/**
		 * Remove an item from the list of current items in ItemManager.
		 * @param   item : The item to remove.
		 * @param   [island] : The island to remove the item from.  Defaults to the current island.
		 */
		public function removeItem(item:String, type:String = null):void
		{
			if (type == null)	{ type = this.island; }
			
			// check if we actually have the item we're trying to remove.
			if(this.itemManager.remove(item, type))
			{
				// remove has item event
				this.gameEventManager.remove(GameEvent.HAS_ITEM + item, type, true);
				
				// remove item from storage
				if( AppConfig.storeToExternal )
				{
					if (!profileManager.buildingProfile) 
					{
						siteProxy.store(DataStoreRequest.itemRemovedStorageRequest(item, type));
					}
				}
			}
		}
		
		public function clearItems(type:String = null):void
		{
			var cardSet:CardSet;
			if(type != null)
			{
				cardSet = this.itemManager.getMakeSet(type);
				//Duplicate the list so iteration doesn't skip once card ids are removed.
				var cardIds:Vector.<String> = cardSet.cardIds.concat();
				for each(var cardId:String in cardIds)
				{
					this.removeItem(cardId, type);
				}
			}
			else
			{
				var cardSets:Vector.<CardSet> = this.itemManager.getSets();
				for each(cardSet in cardSets)
				{
					clearItems(cardSet.id);
				}
			}
		}
		
		/**
		 * Get an card item.
		 * @param   item : The id of the item, can be an int or String.
		 * @param   [type] : The card type to add the item to.  Defaults to the current island.
		 * @param	showCard : optionally show the item's card
		 * @param	showCompleteCallback : optionally handler called once card has completed it's 'show' transition
		 */
		public function getItem(item:*, type:String = null, showCard:Boolean = false, showCompleteCallback:Function = null):Boolean
		{
			return itemManager.getItem(item, type, showCard, showCompleteCallback );
		}
		
		/**
		 * Display an card item, triggers visual aspects of card retrieval only.
		 * @param itemId
		 * @param type
		 */
		public function showItem( itemId:String, type:String, transitionCompleteHandler:Function = null ):void
		{
			itemManager.showItem( itemId, type, transitionCompleteHandler );
		}
		
		/**
		 * Check to see if the player has an item in their inventory.
		 * Note if they've gotten the item and then had it removed (ex : given it to an npc)
		 * this will evaluate to 'false' since the item isn't in the users inventory.
		 * To check if the player has EVER had an item, use <code>checkItemEvent(item)</code>.
		 * @param item - String : The item to check for.
		 * @param island - String : The type of item (custom, store, carrot, survival1, etc.). Defaults to the current island.
		 */
		public function checkHasItem(item:String, type:String = null):Boolean
		{
			if (type == null)	{ type = this.island; }
			return(this.itemManager.checkHas(item, type));
		}		
		
		/**
		 * Get a CardSet that containing card ids of the players current inventory items.
		 * @param type : The set to check inventory for.  Defaults to the current island.
		 * @param filterExpired : flag to filter out expired campaign cards
		 * @return - <code>CardSet</code>
		 */
		public function getCardSet( type:String = null, filterExpired:Boolean = false ):CardSet
		{
			if (type == null)	{ type = this.island; }
			return(this.itemManager.getMakeSet(type, filterExpired));
		}	
		
		//////////////////////////////////////// PHOTOS ////////////////////////////////////////

		/**
		 * Determines if photo should be taken or not, if so photo is taken
		 * @param photoId : id of photo to take, refer to photos.xml for ids
		 * @param callback : Call on photo completion, or regardless if forceHandler is trre
		 * @param forceHandler : flag to determine if completeHandler will be called even if photo is not taken
		 * @return - returns true if taking photo, false if not
		 */
		public function takePhoto(photoId:String, callback:Function = null, forceCallback:Boolean = true):Boolean
		{
			var photoManager:PhotoManager = this.getManager(PhotoManager) as PhotoManager;
			if( photoManager )
			{
				var photoGroup:PhotoGroup = this.currentScene.getGroupById( PhotoGroup.GROUP_ID ) as PhotoGroup;
				if( photoGroup )
				{
					return photoGroup.takePhoto(photoId, this.island, callback, forceCallback);
				}
			}
			
			if( forceCallback && ( callback != null ) )  { callback(); }
			return false;
		}
		
		/**
		 * Determines if photo should be taken or not, if so photo is taken
		 * @param photoId : The photo to check for.
		 * @param callback : 
		 * @return - returns true if taking photo, false if not
		 */
		public function takePhotoByEvent(photoEvent:String, callback:Function = null, forceCallback:Boolean = true):Boolean
		{
			var photoManager:PhotoManager = this.getManager(PhotoManager) as PhotoManager;
			if( photoManager )
			{
				var photoGroup:PhotoGroup = this.currentScene.getGroupById( PhotoGroup.GROUP_ID ) as PhotoGroup;
				if( photoGroup )
				{
					return photoGroup.takePhotoByEvent(photoEvent, callback, forceCallback);
				}
			}
			
			if( forceCallback && ( callback != null ) )  { callback(); }
			return false;
		}

		/**
		 * Mostly used for development, remove a photo that has been taken
		 * @param photoID
		 * @param islandID
		 */
		public function removePhoto(photoID:String, islandID:String=null):void
		{
			if (null == islandID) { islandID = island; }
			PhotoManager(this.getManager(PhotoManager)).remove(photoID, islandID);
		}

		//////////////////////////////////////// TRACKING ////////////////////////////////////////
		
		/**
		 * TODO :: Need description. 
		 * @param msgs
		 */
		public function logWWW(...msgs):void 
		{
			var dbugStr:String = msgs.join(' ');
			if (ExternalInterface.available) 
			{
				ExternalInterface.call('dbug', dbugStr);
			}
			trace(this,"logWWW : " + dbugStr);
		}

		/**
		 * Handles links within the as2 application which could either be internal or http.
		 * <p>All internal links should follow the standard <code>section,subsection,arg1,arg2...argN</code></p>
		 * 
		 * <p>example parameters:</p>
		 * <listing version="3.0">
		 * 
		 * scenes:
		 * 'gameplay',island,scene,'X,Y'
		 * 'gameplay','Astro','Fire1','200,400'
		 * 
		 * load an island's default starting scene:
		 * gameplay,island,scene,'START'
		 * 
		 * popups:
		 * popup,nanoCombatTraining
		 * popup,travelmap
		 * 
		 * popup with 'exit' button and darkened background hidden:
		 * popup,nanoCombatTraining,false
		 * 
		 * store:
		 * stats
		 * 
		 * member tour:
		 * membershipTour
		 *
		 * </listing>
		 * @param section	A String indicating the destination section. Valid values are <code>gameplay|popup|stats|membershiptour</code>
		 * @param args	Additional String arguments to specify where in section to link to
		 */
		public function generateInternalLink(section:String, ...args):String
		{
			var link:String = "pop://" + section;
			
			for(var n:String in args)
			{
				link += "/" + args[n];
			}
			logWWW("generateInternalLink(): popURL = |" + link + "|");
			return(link);
		}

		/**
		 * Track an event on the server (track.php) and Google Analytics.
		 * @param  event : Event to track.
		 * @param  [campaign] : A string to appear in the 'campaign' field of brain tracking.
		 * @param  [choice] : A string to appear in the 'choice' field of brain tracking.
		 * @param  [subChoice] : A string to appear in the 'subChoice' field of brain tracking.
		 * @param  [numValLabel] : A label for a numeric value to average.
		 * @param  [numVal] : A numeric value to average accross all events.
		 */
		public function track(event:String, choice:* = null, subChoice:* = null, campaign:String = null, numValLabel:String = null, numVal:Number = NaN, count:String = null, vars:URLVariables = null):void
		{
			// to avoid sandbox security violations, we want to suppress network activity
			// when in Flash Professional or Flash Player app or standalone.
			// Tracking is allowed when using AIR or AIR simulator or browser-based play
			//if (AppConfig.networkAllowed && Capabilities.playerType != "External" && Capabilities.playerType != "StandAlone")
			
			var tracking:String = "Track: event:" + event + " choice:" + choice + " subChoice:" + subChoice + " campaign:" + campaign + " numValLabel:" + numValLabel + " numVal:" + numVal + " count:" + count;
			trace(tracking);
			if (ExternalInterface.available) {
				ExternalInterface.call('dbug', tracking);
			}
			if (AppConfig.networkAllowed) 	
			{	
				var eventTracker:ITrackingManager = this.trackManager;
				if( eventTracker != null )
				{
					var age:int;
					var gender:String = "";
					if( this.profileManager.active )
					{
						age = this.profileManager.active.age;
						gender = this.profileManager.active.gender;
					}
					
					if (age == 0)
					{
						age = PlayerContext.DEFAULT_AGE;
					}	
					if ( gender == "" )
					{
						gender = PlayerContext.DEFAULT_GENDER;
					}
					// Note: the server expects grade not age so 5 is subtracted to get grade from age
					var grade:String = String(age - 5);
					gender = ProxyUtils.convertGenderToServerFormat(gender);
					
					// get island
					var currentIsland:String = this.island;
					eventTracker.track(event, AppConfig.platformType, choice, subChoice, campaign, currentIsland, this.sceneName, grade, gender, numValLabel, numVal, count, vars);
				}
			}
		}
		
		public function trackPageView():void
		{
			// TODO :: Would like a cleaner way to handle this, should avoid hardcoded strings. -bard
			// Note: we could examine the current scene for realms-specific properties, but this goes only so far
			if ('Lab1' != sceneName) 	// Realms does pageviews a little differently, since the "scenes" are generated procedurally
			{		
				var eventTracker:ITrackingManager = getManager(ITrackingManager) as ITrackingManager;
				if (eventTracker)
				{
					eventTracker.trackPageView(this.island, sceneName);
					// TODO: switch to trackPageview(vars) <= notice the lowercase v
				}
			}
		}
		
		//////////////////////////////////////// DEV TOOLS ////////////////////////////////////////
		
		/**
		 * Output a message to the log.
		 * @param  message : A string to output.
		 * @param  [source] : If called within a class, you can pass 'this' here to prefix the output with the class name.
		 * @param  [clear] : Clear the log panel before displaying the message.
		 */
		public function log(message:*, source:*=null, clear:Boolean=true):void
		{
			if(this.devTools)
			{
				this.devTools.console.log(message, source, clear);
			}
		}
		
		public function logError(message:*, source:*=null):void
		{
			if(this.devTools)
			{
				this.devTools.console.logError(message, source);
			}
		}
		
		/**
		 * NOT IN USE 
		 * DEBUG ONLY
		 * HAS AIR code - can only be used on local builds, will break web version.
		 * Outputs dynamically created manifests to a file 
		 */
		public function outputLog(): void
		{
			var fileRef:FileReference = new FileReference()
			var manifestManager:ManifestCheckManager = this.fileManager.manifestCheckManager;
			if( manifestManager )
			{
				fileRef.save( manifestManager.loadedFiles, "assetsInUse.csv" );	
			}
		}
		
		public function toggleConsole():void
		{
			if(this.devTools)
			{
				this.devTools.toggleConsole();
			}
		}
		
		public function showConsole():void
		{
			if(this.devTools)
			{
				this.devTools.showConsole();
			}
		}
		
		public function hideConsole():void
		{
			if(this.devTools)
			{
				this.devTools.hideConsole();
			}
		}
		
		public function setFPS(newFrameRate:int):void
		{		// for debugging only _RAM
			screenManager.stage.frameRate = newFrameRate;
		}

		//////////////////////////////////////// OPERATING SYSTEM ////////////////////////////////////////

		private var appMethods:INativeAppMethods;

		/**
		 * On iOS or Android, the app may be invoked not by the tap of a user, but by a custom URI scheme
		 * @return An array of data describing the the invocation
		 */		
		public function get invokeURLArgs():Array {
			return appMethods ? appMethods.invokeURLArgs : null;
		}

		public function setupNativeAppMethods():INativeAppMethods {
			appMethods = platform.getInstance(INativeAppMethods) as INativeAppMethods;
			return appMethods;
		}

		/**
		 * Rasterizes and stores a MovieClip's imagery. No scaling, rotation, clipping or transparency
		 * will be applied.
		 * @param mc	The MovieClip to be rasterized and stored
		 * @param clipRect	Optional clipping rectangle
		 * @param callback	Optional callback when successful
		 * @param failure	Optional callback if failure
		 * @return <code>false</code> on failure, <code>true</code> otherwise.
		 * Note that a <code>true</code> return value doesn't necessarily imply success.
		 */		
		public function saveMovieClipToCameraRoll(mc:MovieClip, clipRect:Rectangle = null, fileName:String = null, callback:Function = null, failure:Function = null):Boolean
		{
			if (!appMethods)
			{
				if (failure)
					failure();
				return false;
			}
			var bmd:BitmapData;
			if (clipRect)
			{
				var matrix:Matrix = new Matrix();
				// if clipRect has negative values (centered clip), then shift
				if ((clipRect.x < 0) && (clipRect.y < 0))
				{
					// move image down and right so aligned at upper left
					matrix.translate(-clipRect.x, -clipRect.y);
					clipRect.x = 0;
					clipRect.y = 0;
				}
				bmd = new BitmapData(clipRect.width, clipRect.height, false);
				bmd.draw(mc, matrix, null, null, clipRect);
			}
			else
			{
				bmd = new BitmapData(mc.width, mc.height, false);
				bmd.draw(mc);
			}
			return appMethods.exportToCameraRoll(bmd, fileName, callback, failure);
		}
		
		/**
		 * 
		 * @param bmd	The finalized BitmapData to be stored
		 * @param callback	Optional callback when successful
		 * @param failure	Optional callback if failure
		 * @return <code>false</code> on failure, <code>true</code> otherwise.
		 * Note that a <code>true</code> return value doesn't necessarily imply success.
		 */		
		public function saveBitmapDataToCameraRoll(bmd:BitmapData, fileName:String = null, callback:Function = null, failure:Function = null):Boolean
		{
			if (!appMethods)
			{
				if (failure)
					failure();
				return false;
			}
			return appMethods.exportToCameraRoll(bmd, fileName, callback, failure);
		}

		//////////////////////////////////////// GETTERS SETTERS ////////////////////////////////////////

		public function set defaultCursor(type:String):void
		{
			if(this.inputEntity)
			{
				var cursor:Cursor = this.inputEntity.get(Cursor);
				if(cursor)
				{
					cursor.defaultType = type;
				}
			}
		}
		
		public function get defaultCursor():String
		{
			if(this.inputEntity)
			{
				var cursor:Cursor = this.inputEntity.get(Cursor);
				if(cursor)
				{
					return(cursor.defaultType);
				}
			}
			return(null);
		}
		
		public function get dataPrefix():String { return this.fileManager.dataPrefix; }
		public function get assetPrefix():String { return this.fileManager.assetPrefix; }
		/**
		 * returns Signal with event as String, and Boolean flag for trigger
		 */
		public function get eventTriggered():Signal { return(this.gameEventManager.eventTriggered); }
		public function get backgroundContainer():Sprite { return ScreenManager(this.getManager(ScreenManager)).backgroundContainer; }
		public function get currentScene():Scene { return SceneManager(this.getManager(SceneManager)).currentScene; }
		public function get currentProfile():ProfileData { return profileManager.active }
		public function get smartFox():SmartFox { return SmartFoxManager(this.getManager(SmartFoxManager)).smartFox }

		//Shortcuts for accessing Managers.
		public function get siteProxy():IDataStore2 {
			return _managers[IDataStore2];
		}
		public function get adManager():IAdManager {
			return _managers[IAdManager];
		}
		public function get itemManager():IItemManager {
			return _managers[IItemManager];
		}
		public function get islandManager():IIslandManager {
			return _managers[IIslandManager];
		}
		public function get trackManager():ITrackingManager {
			return _managers[ITrackingManager];
		}
		
		public function get sceneManager():SceneManager {
			return _managers[SceneManager] as SceneManager;
		}
		public function get gameEventManager():GameEventManager {
			return _managers[GameEventManager] as GameEventManager;
		}
		public function get profileManager():ProfileManager {
			return _managers[ProfileManager] as ProfileManager;
		}
		public function get dlcManager():DLCManager {
			return _managers[DLCManager] as DLCManager;
		}
		public function get screenManager():ScreenManager {
			return _managers[ScreenManager] as ScreenManager;
		}
		public function get fileManager():FileManager {
			return _managers[FileManager] as FileManager;
		}
		public function get groupManager():GroupManager {
			return _managers[GroupManager] as GroupManager;
		}
		public function get textManager():TextManager {
			return _managers[TextManager] as TextManager;
		}
		public function get languageManager():LanguageManager {
			return _managers[LanguageManager] as LanguageManager;
		}
		public function get longTermMemoryManager():LongTermMemoryManager {
			return _managers[LongTermMemoryManager] as LongTermMemoryManager;
		}
		public function get photoManager():PhotoManager {
			return _managers[PhotoManager] as PhotoManager;
		}
		public function get specialAbilityManager():SpecialAbilityManager {
			return _managers[SpecialAbilityManager] as SpecialAbilityManager;
		}
		public function get smartFoxManager():SmartFoxManager {
			return _managers[SmartFoxManager] as SmartFoxManager;
		}
		
		//////////////////////////////////////// VARIABLES ////////////////////////////////////////

		public var fileLoadComplete:Signal;
		public var viewportWidth:Number;
		public var viewportHeight:Number;
		public var viewportScale:Number;
		public var viewportDeltaX:Number;
		public var viewportDeltaY:Number;
		/** Id of currently selected island */
		public var island:String;
		/** Full name of currently selected island */
		public var islandName:String;
		public var sceneName:String;
		public var arcadeGame:String;
		public var arcadePoints:int = 0;
		public var legoStart:Number = 0;
		public var legoTime:Number = 0;
		public var paused:Boolean = false;
		public var camera:CameraSystem;
		public var player:Entity;
		public var injector:Injector;
		public var devTools:DevTools;
		public var inputEntity:Entity;
		public var islandEvents:IslandEvents;
		public var platform:IPlatform;
		public var networkMonitor:INetworkMonitor;
		public var errorLogger:FENErrorLogger;
		public var pets:Dictionary = new Dictionary(); // to manage whether custom pet data has been pulled down this session
		public var cmg_iframe:Boolean = false;
		public var overrideReturnScene:String;
		public var overrideReturnSceneClass:Scene;
		
		
		//TEMP FIX
		public var forcedAdData:AdData;
		
		private var _shell:Shell;
		private var _serverPrefix:String;
		
		public function get ShellBase():Shell{return _shell;}
		//adding static reference so that you do not need reference to a group or pass it along just to use
		private static var _shellApi:ShellApi;
		public static function get SHELL_API():ShellApi
		{
			return _shellApi;
		}
	}
}