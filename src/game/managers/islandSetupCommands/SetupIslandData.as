package game.managers.islandSetupCommands
{
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	import game.data.island.IslandEvents;
	import game.data.scene.DoorParser;
	import game.managers.ItemManager;
	import game.managers.LanguageManager;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.ProxyUtils;

	/**
	 * SetupIslandData
	 * 
	 * Sets up data related to language, items and events loaded in the 'PreloadScene' step.
	 * @author Billy Belfied
	 */
	public class SetupIslandData extends CommandStep
	{
		// TODO :: In general need better failure check here, if certain data can't be retrieved we should halt island load process. - bard
		
		public function SetupIslandData(island:String, shellApi:ShellApi, newIsland:Boolean = true)
		{
			super();
			
			_island = island;
			_shellApi = shellApi;
			_newIsland = newIsland;
		}
				
		override public function execute():void
		{			
			if(_newIsland)
			{
				// setup langauge
				var language:String 	= _shellApi.preferredLanguage;
				var languageFile:String = _shellApi.dataPrefix + "languages/" + language + "/islands/" + _island + "/language.xml";
				var languageXML:XML 	= _shellApi.getFile(languageFile, true);
				if(languageXML)
				{
					var languageManager:LanguageManager = _shellApi.languageManager;
					languageManager.remove("island");
					languageManager.addXML(languageXML);
				}
				
				//setup island data
				var islandData:XML = _shellApi.getFile(_shellApi.dataPrefix + "scenes/" + _island + "/island.xml") as XML;
				var key:String;
				
				_shellApi.islandEvents = new IslandEvents();
				
				if(islandData != null)
				{
					if(islandData.hasOwnProperty("eventsClass"))
					{
						try
						{
							var eventsClass:Class = ClassUtils.getClassByName( islandData.eventsClass );
							_shellApi.islandEvents = new eventsClass();
						} 
						catch(error:Error) 
						{
							trace( this," :: ERROR :: class defining island events was not valid: " + DataUtils.getString( islandData.eventsClass ) );
							
							// TODO :: What sort of recovery should we attempt?  Should we leave you on current scene or redirect to a 'safe' island such as map? - bard
							/*
							trace( this," :: WARNING :: cannot complete island load redirecting to map as safety");
							redirectToMap();
							return;
							*/
						}
					}
					
					if(islandData.hasOwnProperty("firstScene"))
					{
						var doorParser:DoorParser = new DoorParser();
						
						_shellApi.islandEvents.sceneEntrance = doorParser.parseDoor(islandData.firstScene);
					}
					
					_shellApi.islandName = islandData.name[0] ? islandData.name[0] : DEFAULT_ISLAND_NAME;
					
					// TODO :: Wonder if permanent events should be stored somewhere else than ProxyUtils? - bard
					if(islandData.hasOwnProperty("permanentEvents"))
					{
						ProxyUtils.permanentEvents = [];
						
						var permanentEvents:XMLList = islandData.permanentEvents.event;
						
						for(key in permanentEvents)
						{
							ProxyUtils.permanentEvents.push(DataUtils.getString(permanentEvents[key]));
						}
					}
					
					// create map of valid items
					if(islandData.hasOwnProperty("itemIdMap"))
					{
						if(ProxyUtils.itemToIdMap[_island] == null)
						{
							trace(this," :: creating new item name (frontEnd) to item numeric (server) mapping for island: ",_island);
							ProxyUtils.itemToIdMap[_island] = new Dictionary();
						}
						
						if(ProxyUtils.idToItemMap[_island] == null)
						{
							trace(this," :: creating new item numeric (server) to item name (frontEnd) mapping for island: ",_island);
							ProxyUtils.idToItemMap[_island] = new Dictionary();
						}
						
						var itemIdMap:XMLList = islandData.itemIdMap.item;
						var element:XML;
						var itemManager:ItemManager = _shellApi.itemManager as ItemManager;
//						trace(this," :: itemIdMap for island: " + _island + " xml:\r",itemIdMap);
						
						itemManager.validCurrentItems = new Vector.<String>();
						var itemId:String;
						for(key in itemIdMap)
						{
							element = itemIdMap[key];
							itemId = DataUtils.getString(element.attribute("id"));
							ProxyUtils.itemToIdMap[_island][itemId] = DataUtils.getNumber(element.toString());
							ProxyUtils.idToItemMap[_island][DataUtils.getNumber(element.toString()) as int] = DataUtils.getString(element.attribute("id"));
							itemManager.validCurrentItems.push( itemId );
						}
					}
				}
				else
				{
					// In some cases, scuh as start and map, this doesn;t matter, but for everything else it does.  need better handling here
					trace(this," :: WARNING : failed to retrieve island.xml at: " + _shellApi.dataPrefix + "scenes/" + _island + "/island.xml");
				}
				
				//setup group events
				var groupEventXML:XML = _shellApi.getFile(_shellApi.dataPrefix + "scenes/" + _island + "/eventGroups.xml");
				if( groupEventXML != null )
				{
					_shellApi.gameEventManager.createEventGroups( groupEventXML, _island );
				}
			}
			
			super.complete();
		}
		
		/**
		 * Redirects to Map
		 */
		/*
		private function redirectToMap():void
		{
			var mapClass:Class = _shellApi.islandManager.gameData.mapClass;
			var mapScene:Scene = new mapClass();
			_shellApi.sceneManager.loadScene(mapScene);
			
			// if we need to return to the map to load content, short-circuit the scene-load sequence.
			trace( this," :: ERROR :: Redirecting to map as recovery." );
			super.completeAll();
		}
		*/
		
		private var _island:String;
		private var _shellApi:ShellApi;
		private var _newIsland:Boolean;
		private var DEFAULT_ISLAND_NAME:String = "The Island";
	}
}