package game.util
{
	import flash.display.LoaderInfo;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	
	import game.scene.template.ui.CardGroup;

	public class ProxyUtils
	{
		//public static const TRIBE_FIELD:String = "Tribe";
		public static const GENDER_MALE:String = "M";
		public static const GENDER_FEMALE:String = "F";
		public static const AS2_ISLANDS:Vector.<String> = new <String>[
			'astro', 'backlot', 'bignate', 'boardwalk', 'charlie', 'counter', 'cryptid', 'early', 'gameshow', 'ghost', 'japan', 'legendaryswords', 'moon', 'nabooti', 'nightwatch',
			'peanuts', 'reality', 'shark', 'shipwreck', 'spy', 'steam', 'super', 'trade', 'train', 'vampire', 'villain', 'west', 'wimpy', 'woodland', 'zombie'
		];

		public static var permanentEvents:Array;  // an array of events that are 'permanent' and should be saved to the server.  All other island events only persist for the length of the session.

		/**
		 * Dictionary mapping island items, key is numeric id used by server mapping to textual id used by code 
		 */
		public static var idToItemMap:Dictionary = new Dictionary();

		/**
		 * Dictionary mapping island items, key is textual id used by code mapping to numeric id used by server 
		 */
		public static var itemToIdMap:Dictionary = new Dictionary();

		public function ProxyUtils()
		{
		}

		public static function isAS2Island(islandName:String):Boolean
		{
			return AS2_ISLANDS.indexOf(islandName.toLowerCase()) > -1;
		}

		public static function isTestServer(serverURL:String):Boolean
		{
			var runningOnExt2:Boolean	= serverURL.indexOf('ext2') > -1;
			var runningOnProof:Boolean	= serverURL.indexOf('proof') > -1;
			var runningOnDev:Boolean	= serverURL.indexOf('dev') > -1;
			var runningOnMobile:Boolean	= serverURL.indexOf('mobile') > -1;
			var runningOnIsland:Boolean	= serverURL.indexOf('island') > -1;
	
			var isOnlineTesting:Boolean = (runningOnProof || runningOnExt2 || runningOnDev || runningOnMobile || runningOnIsland);
			var runningOnDeviceOrSimulator:Boolean = (0 == serverURL.toLowerCase().indexOf('app:/'));
			
			return isOnlineTesting || runningOnDeviceOrSimulator;
		}
		
		/**
		 * Returns browser host from <code>LoaderInfo</code> url variable.
		 * Example of url of local desktop build: "app:/Game.swf"
		 * Example of url of browser build: "NEED EXAMPLE"
		 * @param url - url provided by shell's <code>LoaderInfo</code>
		 * @return 
		 */
		public static function getBrowserHostFromLoaderUrl(url:String):String
		{
			// make sure application is running within browser 
			// use url prefix to determine application type 
			var isApp:Boolean = (0 == url.indexOf("app:/"));
			var isLocalBrowserTest:Boolean = (0 == url.indexOf('file:/'));
			
			var browserHost:String = "";
			// if in browser check validity of url, create appropriate prefix
			// we are online in the browser
			if (!(isApp || isLocalBrowserTest))
			{	
				var URLParts:Array = url.split("//");
				if (("http:" != URLParts[0]) && ("https:" != URLParts[0])) 
				{
					throw new Error("Can't handle unknown URL protocol " + url);
				}
				
				var location:String = URLParts[1];
				while ('/' == location.charAt(0)) 
				{
					location = location.substr(1);		// chop off first char
				}
				
				URLParts = location.split('/');
				if (URLParts.length < 2) 
				{
					throw new Error("Can't find the hostname in " + location);
				}

				browserHost = URLParts[0];
			}
			else
			{
				trace( "Error :: ProxyUtils : getBrowserHostLoaderUrl : not a browser url: " +  url);
			}
			return browserHost;
		}

		public static function getQueryStringData(li:LoaderInfo, paramName:String=null):Object 
		{
			var result:Object = li.parameters;
			
			return paramName ? result[paramName] : result;
		}

		/**
		 * Converts an event into the format used on the server which is the the island name preceding the event.
		 */
		public static function convertEventToServerFormat(event:String, island:String):String
		{
			//grrrrr
			if(event == "started") { event = "as3_started"; }
			
			return(island.toLowerCase() + "_" + event);
		}
		
		/**
		 * Converts a full scene name into the format as2 expects which is first letter capitalized.
		 */
		public static function convertIslandToAS2Format(island:String):String
		{
			if (island.indexOf("_as3") != -1)
			{
				island.substr(0, island.length - 4);
			}
			
			return(island.substr(0,1).toUpperCase() + island.substr(1));
		}
		
		/**
		 * Converts an island name to the format expected by the server for as3 islands.
		 */
		public static function convertIslandToServerFormat(island:String):String
		{
			return(island.substr(0,1).toUpperCase() + island.substr(1) + "_as3");
		}
		
		/**
		 * Converts an island name to the format expected by as3 from the format stored on the server.
		 */
		public static function convertIslandFromServerFormat(island:String):String
		{
			return(island.substr(0,1).toLowerCase() + island.substr(1, island.length - (String("_as3").length + 1)));
		}
		
		/**
		 * Converts an item name to the number format expected by the server if a match exists in the lookup table.
		 * If map is given but no corresponding key is found, NaN is returned. 
		 * @param item - id of card item, in the case of island cards the id will be a word, while campaign &amp; store cards remain numeric.
		 * @param type - card set item is part of includes islands( i.e. "carrot", "myth", "survival1" ) "store", &amp; "custom"
		 * @param map - Dictionary that maps card item id to a number, necessary for island card items.
		 * @return 
		 */
		public static function convertItemToServerFormat(itemId:String, type:String = "", map:Dictionary = null):Number
		{
			var formattedItemId:Number;
			if( DataUtils.validString( type ) )
			{
				if( type == CardGroup.STORE || type == CardGroup.PETS || type == CardGroup.CUSTOM )	// if store or pet or campaign card id should already be numeric, does not require mapping
				{
					formattedItemId = Number(itemId);
				}
				else														// if island card id is word and requires mapping to a numeric id
				{
					if(map != null)
					{
						if( map.hasOwnProperty(itemId) )	{ formattedItemId = Number(map[itemId]); }
						else { trace( "Error :: ProxyUtils :: convertItemToServerFormat :: card " + itemId + " from island " + type + " was not able to find a numeric id mapping." ); }
					}  
					else
					{
						trace( "Error :: ProxyUtils :: convertItemToServerFormat :: card " + itemId + " is from island " + type + " and requires mapping to a numeric id." );
					}
				}
			}
			else
			{
				formattedItemId = Number(itemId);
				if(map != null)
				{
					if( map.hasOwnProperty(itemId) )	{ formattedItemId = Number(map[itemId]); }
					else { trace( "Error :: ProxyUtils :: convertItemToServerFormat :: card " + itemId + " from island " + type + " was not able to find a numeric id mapping." ); }
				} 
			}
			
			if(isNaN( formattedItemId )) { trace("ProxyUtils :: Warning, item " + itemId + " cannot be converted to a number and will not be saved to the server!"); }
			return( formattedItemId );
		}
		
		public static function convertSceneToStorageFormat(scene:Object):String
		{
			return convertSceneNameToStorageFormat(ClassUtils.getNameByObject(scene));
		}

		public static function convertSceneNameToStorageFormat(sceneName:String):String
		{
			// replace :: with .
			var pos:int = sceneName.indexOf(":");
			
			return(sceneName.substr(0,pos) + "." + sceneName.substr(pos + 2));
		}

		/**
		 * Converts a full scene name into just the scene name that the server uses to identify a scene.
		 * ex : game.scenes.carrot.mainStreet.MainStreet::MainStreet &gt; mainStreet
		 * @param scene
		 * @return 
		 * 
		 */
		public static function convertSceneToServerFormat(scene:*):String
		{
			var sceneName:String;
			if(scene is String)
			{
				sceneName = scene;
			}
			else
			{
				sceneName = ClassUtils.getNameByObject(scene)
			}
			
			var sceneParts:Array = sceneName.split(".");
			return(sceneParts[3].split("::")[0]);
		}
		
		/**
		 * Pull the island id from the given scene. 
		 * @param scene - Can pass scene in form of String or Class ( ex : game.scenes.carrot.mainStreet.MainStreet )
		 * @return - returns island id scene is associated with
		 * 
		 */
		public static function getIslandFromScene(scene:*):String
		{
			var sceneName:String;
			if(scene is String)
			{
				sceneName = scene;
			}
			else
			{
				sceneName = ClassUtils.getNameByObject(scene)
			}
			
			var sceneParts:Array = sceneName.split(".");
			if( sceneParts.length > 2 )
			{
				return(sceneParts[2]);
			}
			else
			{
				return null;
			}
		}
		
		/**
		 * Converts a scene + island string into the scenes class (assuming it has been imported in the IslandEvents class for that island).
		 */
		public static function getSceneClass(scene:String, island:String):Class
		{
			var qualifiedClassName:String = getSceneClassName(scene, island);
			var sceneClass:Class = ClassUtils.getClassByName(qualifiedClassName);
			
			return(sceneClass);
		}
		
		/**
		 * Converts a scene + island string into the scenes full class name.
		 */
		public static function getSceneClassName(scene:String, island:String):String
		{
			return("game.scenes." + island + "." + (scene.substr(0,1).toLowerCase() + scene.substr(1)) + "." + (scene.substr(0,1).toUpperCase() + scene.substr(1)));
		}

		public static function getSceneFilePath(scene:String):String
		{
			var arr:Array = String(scene.split("::")[0]).split(".");
			var path:String = arr[1] + "/" + arr[2] + "/" + arr[3] + "/";
			
			return(path);
		}

		// 
		/**
		 * Given a fully qualified scene name, extract the package name of
		 * the island and the package name of the scene.
		 * @param sceneName	Either <code>game.scenes.&lt;islandPackage&gt;.&lt;scenePackage&gt;::&lt;ClassName&gt;</code> or <code>game.scenes.&lt;islandPackage&gt;.&lt;scenePackage&gt;.&lt;Classname&gt;</code>
		 * @return An <code>Array</code> of the form: <code>[&lt;islandName&gt;,&lt;sceneName&gt;]</code>
		 */		
		public static function getIslandAndScene(sceneName:String):Array
		{
			var fields:Array = String(sceneName.split("::")[0]).split(".");
			return [fields[2], fields[3]];
		}

		public static function convertGenderToServerFormat(gender:String):String
		{
			var alreadyInServerFormat:Boolean = (GENDER_MALE == gender) || (GENDER_FEMALE == gender);
			if (! alreadyInServerFormat) {
				if (gender == SkinUtils.GENDER_FEMALE) {
					gender = GENDER_FEMALE;
				} else {
					gender = GENDER_MALE;
				}
			}
			return gender;
		}
		
		public static function convertGenderFromAS2ToServerFormat(gender:Number):String
		{
			if(gender == 0) { return(GENDER_FEMALE); }
			else { return(GENDER_MALE); }
		}
		
		public static function get as2lso():SharedObject
		{
			var sharedObject:SharedObject = SharedObject.getLocal("Char", "/");
			
			sharedObject.objectEncoding = ObjectEncoding.AMF0;
			
			return(sharedObject);
		}
		
		public static function getAS2LSO(name:String):SharedObject
		{
			var sharedObject:SharedObject = SharedObject.getLocal(name, "/");
			
			sharedObject.objectEncoding = ObjectEncoding.AMF0;
			
			return(sharedObject);
		}

		private static function extractPermanentEvents(events:Array, canExtractAll:Boolean=false):Array 
		{
			var eventsToSave:Array = [];
			var listLength:int = events.length;
			for (var i:int=0; i<listLength; i++) {
				var shouldSaveEvent:Boolean = 'started' == events[i];
				if (permanentEvents) {
					if (permanentEvents.indexOf(events[i]) > -1) {
						shouldSaveEvent = true;
					}
				} else {	// island has NO permanent events listed
					if (canExtractAll) {
						shouldSaveEvent = true;
					}
				}
				if (shouldSaveEvent) {
					eventsToSave.push(events[i]);
				} else {
					trace("SiteProxy :: completeEvent " + events[i] + " is a temp event and will not be saved to the server.");
				}
			}
			return eventsToSave;
		}

		public static function AS3IslandNameFromAS2IslandName(islandName:String):String
		{
			islandName = islandName.toLowerCase();
			switch (islandName) {
				case 'bignate':
					return 'bigNate';
				case 'gameshow':
					return 'gameShow';
				case 'nightwatch':
					return 'nightWatch';
				case 'superpower':
					return 'superPower';

				case 'deepdive1':
					return 'deepDive1';
				case 'deepdive2':
					return 'deepDive2';
				case 'deepdive3':
					return 'deepDive3';
				case 'virushunter':
					return 'virusHunter';
				case 'legendaryswords':
					return 'legendarySwords';
				default:
					break;
			}
			return islandName;
		}

		public static function parsePopURL(popURL:String):Object
		{
			var result:Object = {
				section:	'',
				island:		'',
				room:		'',		// 'room' and 'scene' are synonymous
				scene:		'',
				playerX:	NaN,
				playerY:	NaN,
				direction:	'left',
				popup:		'',
				args:		null
			};
			var parts:Array = popURL.split('://'); // only the second part is interesting, we ignore the 'pop://'
			if ('pop' == parts[0]) {
				parts = parts[1].split('/');
				if (parts.length > 0) {
					result.section = parts.shift();
					
					if ('gameplay' == result.section) {
						if (parts.length > 0) {
							result.island = parts.shift();
							if (parts.length > 0) {
								result.room = result.scene = parts.shift();
								if (parts.length > 0) {
									result.playerX = parts.shift();
									if (parts.length > 0) {
										result.playerY = parts.shift();
										if (parts.length > 0) {
											result.direction = parts.shift();
										}
									}
								}
							}
						}
					} else {	// this was not a popURL for a gameplay section
						
						if ('popup' == result.section) {
							if (parts.length > 0) {
								result.popup = parts.shift();
								if (parts.length > 0) {
									result.args = parts;
								}
							}
						} else {	// this popURL was neither for a gameplay section or a popup
							if (parts.length > 0) {
								result.args = parts;	// any items following the section are considered args
							}
						}
					}
				}
			}
			return result;
		}

	}
}
