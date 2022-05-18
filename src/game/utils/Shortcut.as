package game.utils
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	public dynamic class Shortcut extends MovieClip
	{
		// list of all islands
		private const _ISLANDS:Array = ["arab1","arab2","arab3","carnival","carrot","con1","con2","con3","deepDive1","deepDive2","deepDive3","ghd","hub","lands","mocktropica","myth","poptropolis","prison","shrink","survival1","survival2","survival3","survival4","survival5","time","timmy","tutorial","viking","virusHunter"];
		private const _CARROT_COORDS:Array = [3494,920];
		private var _isBoy:Boolean = true; // gender flag
		private var _queryIsland:String; // island name from query string
		private var _queryScene:String; // scene name from query string
		private var _queryOverride:Boolean = false; // query override flag
		private var _coords:Array; // avatar coordinates on main street
		
		/**
		 * Constructor 
		 */
		public function Shortcut()
		{
			trace("AdShortCut: version 1.1");
			
			// setup buttons
			this.goButton.addEventListener(MouseEvent.CLICK, onClickGo);
			this.goButton.buttonMode = true;
			this.boyButton.addEventListener(MouseEvent.CLICK, onBoy);
			this.boyButton.buttonMode = true;
			this.boyButton.gotoAndStop(2);
			this.girlButton.addEventListener(MouseEvent.CLICK, onGirl);
			this.girlButton.buttonMode = true;
			
			// get island and scene from query string
			var flashVars:Object = this.loaderInfo.parameters;
			_queryIsland = flashVars.island;
			_queryScene = flashVars.scene;
			
			// if island and scene provided
			if ((_queryIsland) && (_queryScene))
			{
				// set override flag
				_queryOverride = true;
				// hide dest box and scenes label and age box
				this.destBox.visible = false;
				this.mcLabel.visible = false;
				this.mcAge.visible = false
			}
			else
			{
				// if not overriding by query
				// add event listeners for enter frame and text fields
				this.addEventListener(Event.ENTER_FRAME, updateAdScenes);
				this.sceneList.addEventListener(MouseEvent.CLICK, onClickScene);
				this.islandList.addEventListener(MouseEvent.CLICK, onClickIslands);
				
				// update island list
				var str:String = "";
				for each (var scene:String in _ISLANDS)
				{
					str = str + scene + "\n";
				}
				this.islandList.text = str;
				
				// show carrot coords
				showCoords(_CARROT_COORDS, true);
			}
		}
		
		/**
		 * Click go to scene button 
		 * @param e
		 */
		private function onClickGo(e:MouseEvent):void
		{
			var islandName:String;
			var sceneName:String;
			
			// if query overriding, then use data from query string
			if (_queryOverride)
			{
				islandName = _queryIsland;
				sceneName = _queryScene;
			}
			else
			{
				// else use data from input text
				islandName = this.destBox.islandName.text;
				sceneName = this.destBox.sceneName.text;
			}
			
			// build destination class string
			var firstChar:String = sceneName.charAt(0);
			var restScene:String = sceneName.substr(1);
			var dest:String = "game.scenes." + islandName + "." + firstChar.toLowerCase() + restScene + "." + firstChar.toUpperCase() + restScene;
			
			// set variables
			var login:String = "TESTGUEST" + Math.floor(1000000 * Math.random());
			var gender:Number;
			var skinCol:Number;
			var hairCol:Number;
			var lineCol:Number;
			var eyeLids:Number;
			var eyes:Number;
			var marks:Number = 1;
			var pants:String;
			var lw:Number = 4;
			var shirt:Number;
			var hair:String;
			var mouth:Number;
			
			// set gender specific variables
			if (_isBoy)
			{
				gender		= 1;
				skinCol 	= 14193168;
				hairCol 	= 5382915;
				lineCol 	= 11301900;
				eyeLids 	= 66;
				eyes		= 2;
				pants		= "Sears2";
				shirt		= 15;
				hair		= "mthjack";
				mouth		= 12;
			}
			else
			{
				gender		= 0;
				skinCol 	= 16768981;
				hairCol 	= 16763955;
				lineCol 	= 4803959;
				eyeLids 	= 100;
				eyes		= 3;
				pants		= "sponsorCTCgirl";
				shirt		= 7;
				hair		= "sponsor_selenag";
				mouth		= 6;
			}
			
			// update char LSO ----------------------------------------------
			var lso:SharedObject = SharedObject.getLocal("char","/");
			lso.objectEncoding = ObjectEncoding.AMF0;
			
			lso.clear();
			
			lso.data.enteringNewIsland = false;
			lso.data.gender 		= gender;
			lso.data.age 			= int(this.mcAge.age.text);
			lso.data.Registred 		= false;
			lso.data.login 			= login;
			lso.data.firstName 		= "Brave";
			lso.data.lastName 		= "Hero";
			lso.data.dir 			= 1;
			
			lso.data.HomeyPos 		= 274;
			lso.data.HomexPos 		= 1354;
			
			lso.data.skinColor 		= skinCol;
			lso.data.hairColor 		= hairCol;
			lso.data.lineColor 		= lineCol;
			lso.data.eyelidsPos		= eyeLids;
			lso.data.eyesFrame		= eyes;
			lso.data.marksFrame		= marks;
			lso.data.pantsFrame		= pants;
			lso.data.lineWidth 		= lw;
			lso.data.shirtFrame 	= shirt;
			lso.data.hairFrame 		= hair;
			lso.data.mouthFrame 	= mouth;
			lso.data.itemFrame 		= 1;
			lso.data.packFrame 		= 1;
			lso.data.facialFrame 	= 1;
			lso.data.overshirtFrame = 1;
			lso.data.overpantsFrame = 1;
			
			// to prevent Poptropolis tribe popup
			lso.data.userData = {Tribe:4007};
			// to prevent Poptropolis intro
			lso.data.completedEvents = {Poptropolis:["poptropolis_poptropolis_started","poptropolis_selected_tribe"]};
			
			lso.flush();
			
			// clear all campaigns --------------------------------------
			lso = SharedObject.getLocal("campaignData","/");
			lso.objectEncoding = ObjectEncoding.AMF0;
			lso.clear();
			
			// go to game
			navigateToURL(new URLRequest("/game/"));
		}
		
		/**
		 * Click on boy buttton
		 * @param e
		 */
		private function onBoy(e:MouseEvent):void
		{
			_isBoy = true;
			this.boyButton.gotoAndStop(2);
			this.girlButton.gotoAndStop(1);
		}

		/**
		 * Click on girl buttton
		 * @param e
		 */
		private function onGirl(e:MouseEvent):void
		{
			_isBoy = false;
			this.boyButton.gotoAndStop(1);
			this.girlButton.gotoAndStop(2);
		}
		
		/**
		 * Click on list of islands 
		 * @param e
		 */
		private function onClickIslands(e:MouseEvent):void
		{
			// get line clicked on
			var line:int = e.currentTarget.getLineIndexAtPoint(e.localX, e.localY);
			// get text on line
			var str:String = this.islandList.getLineText(line);
			// strip off trailing line return
			str = str.substr(0, str.length-1);
			// put island name into dest box
			this.destBox.islandName.text = str;
			// get list of ad scens for island
			var list:Array = updateAdScenes();
			// put first item in list into scene box
			this.destBox.sceneName.text = list[0];
			// if coords available, then display them
			showCoords(_coords, true);
		}
		
		/**
		 * Click on list of ad scenes 
		 * @param e
		 */
		private function onClickScene(e:MouseEvent):void
		{
			// get line clicked on
			var line:int = e.currentTarget.getLineIndexAtPoint(e.localX, e.localY);
			// get text on line
			var str:String = this.sceneList.getLineText(line);
			// strip off trailing line return
			str = str.substr(0, str.length-1);
			// put scene name into dest box
			this.destBox.sceneName.text = str;
			// update ad scenes to get coords
			updateAdScenes();
			// if click first scene (main street scene) and coords available, then display coords
			showCoords(_coords, (line == 0));
		}
		
		/**
		 * Update list of ad scenes
		 * @param e
		 * @return Array
		 */
		private function updateAdScenes(e:Event = null):Array
		{
			var islandName:String = this.destBox.islandName.text;
			var list:Array;
			var coords:Array;
			
			// check island name
			switch (islandName)
			{
				// standard islands
				case "carnival":
					list = ["mainStreet","adStreet","adStreet2"];
					coords = [4195,1285];
					break;
				case "carrot":
					list = ["mainStreet","adGroundH3","adGroundH3R"];
					coords = _CARROT_COORDS;
					break;
				case "ghd":
					list = ["spacePort","adMixed1","adMixed2","adStreet1","adStreet2"];
					coords = [3094,1400];
					break;
				case "hub":
					list = ["town"];
					coords = [3657,952]; // these coords are correct, but the scene forces the player to stand on the bridge next to Amelia
					break;
				case "mocktropica":
					list = ["mainStreet","adStreet"];
					coords = [4930,1742];
					break;
				case "myth":
					list = ["mainStreet","adGroundH9","adGroundH9R","adStreet"];
					coords = [4962,1110];
					break;
				case "poptropolis":
					list = ["mainStreet","adGroundH22","adDeadEnd"];
					coords = [3399,1700];
					break;
				case "prison":
					list = ["mainStreet","adStreet1","adMixed2","adStreet3"];
					coords = [4503,1698];
					break;
				case "shrink":
					list = ["mainStreet","adMixed","adStreet2","adStreet3","adStreet4"];
					coords = [5000,1464];
					break;
				case "time":
					list = ["mainStreet","adStreet","adDeadEnd"];
					coords = [4290,1930];
					break;
				case "timmy":
					list = ["mainStreet","adMixed1","adMixed2","adStreet3"];
					coords = [4070,1575];
					break;
				case "viking":
					list = ["jungle","adStreet1","adStreet2"];
					coords = [780,1100];
					break;
				case "virusHunter":
					list = ["mainStreet","adStreet","adStreetR"];
					coords = [3650,1440];
					break;
				
				// lands has only one ad scene
				case "lands":
					list = ["adMixed1"];
					break;
				
				// episodic islands
				case "arab1":
				case "arab2":
				case "arab3":
				case "survival1":
				case "survival2":
				case "survival3":
					list = ["adMixed1","adMixed2","adStreet3"];
					break;
				case "con1":
				case "deepDive1":
				case "deepDive2":
				case "deepDive3":
					list = ["adMixed","adMixed2","adStreet3"];
					break;
				case "con2":
					list = ["adMixed","adMixed2","adStreet3","adStreet4"];
					break;
				case "con3":
					list = ["adMixed","adMixed2","adStreet"];
					break;
				case "survival4":
					list = ["adMixed1","adMixed2","adStreet1","adStreet2"];
					break;
				case "survival5":
					list = ["adMixed1","adMixed2","adStreet2"];
					break;
			}
			// if null list then set message
			if (list == null)
			{
				this.sceneList.text = "No scenes found for " + islandName;
			}
			else
			{
				// else display list of ad scenes
				var str:String = "";
				for each (var scene:String in list)
				{
					str = str + scene + "\n";
				}
				this.sceneList.text = str;
			}
			// remember coordinates
			_coords = coords;
			// return list of ad scenes
			return list;
		}
		
		/**
		 * Display coords 
		 * @param coords
		 * @param test Boolean applied to display (if false then suppress)
		 */
		private function showCoords(coords:Array, test:Boolean):void
		{
			if ((coords) && (test))
				this.coords.text = "Coords: " + coords[0] + "," + coords[1];
			else
				this.coords.text = "";
		}
	}
}