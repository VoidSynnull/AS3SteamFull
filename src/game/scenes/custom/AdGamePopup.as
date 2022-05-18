package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.data.character.LookData;
	import game.managers.ads.AdManager;

	public class AdGamePopup extends AdBasePopup
	{
		protected var xmlPath:String;
		protected var _looks:Vector.<LookData>;
		protected var _selection:int = -1;
		protected var _musicFile:String; // name of music MP3 file
		
		public function AdGamePopup()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			// set tracking to empty so that it will be game ID only
			_popupType = "";
			// set gametype to Game for popup game
			_gameType= "Game";
			
			super.init(container);
			
			id += "Game";//don't want character select force closing the main game
		}
		
		override public function load():void
		{
			// get path to swf and xml
			_swfPath = _questName + _swfName;
			xmlPath = _swfPath.replace(".swf", ".xml");
			trace(xmlPath);
			super.loadFile(xmlPath, loadedXML);
		}
		
		protected virtual function loadedXML(gameXML:XML):void
		{
			if(gameXML != null)
				parseXML(gameXML);
			else
				trace("xml not found @: " + xmlPath);
			super.loadFile(_swfPath, loadedSwf);
		}
		
		protected virtual function parseXML(gameXML:XML):void
		{
			// if xml object, then setup
			if (gameXML != null)
			{
				if(gameXML.hasOwnProperty("looks"))
				{
					setUpLooks(gameXML.looks);
				}
				// parse game xml
				var items:XMLList = gameXML.children();
				// for each group in xml
				for (var i:int = items.length() - 1; i != -1; i--)
				{
					var propID:String = "_" + items[i].name();
					var value:String = items[i].valueOf();
					// get type (needed for arrays when there is only one value)
					var type:String = String(items[i].attribute("type"));
					try
					{
						// check number value
						var numberVal:Number = Number(value);
						// if true
						if (value.toLowerCase() == "true")
						{
							this[propID] = true;
						}
						else if (value.toLowerCase() == "false")
						{
							// if false
							this[propID] = false;
						}
						else if (type == "array")
						{
							this[propID] = [value];
						}
						else if (isNaN(numberVal))
						{
							// if string
							// if contains pipe or type is array, then assume array
							if (value.indexOf("|") != -1)
							{
								var arr:Array = value.split("|");
								// convert to numbers if array has numbers
								for (var j:int = arr.length-1; j != -1; j--)
								{
									numberVal = Number(arr[j]);
									// if number, then swap
									if (!isNaN(numberVal))
										arr[j] = numberVal;
								}
								this[propID] = arr;
							}
							else
							{
								this[propID] = value;
							}
						}
						else
						{
							// if number
							this[propID] = numberVal;
						}
					}
					catch (e:Error)
					{
						trace("public game property " + propID + " does not exist in class!");
					}
				}
			}
			else
			{
				trace("Game XML not loaded");
			}
		}
		
		protected virtual function setUpLooks(xml:XMLList):void
		{
			_looks = new Vector.<LookData>();
			for(var i:int = 0; i < xml.children().length(); i++)
			{
				_looks.push(new LookData(xml.children()[i]));
			}
		}
		
		protected virtual function playerSelection(selection:int = -1):void
		{
			_selection = selection;
			playerSelected();
		}
		
		protected virtual function playerSelected(...args):Boolean
		{
			// if player exits out of player selection
			if(_selection == -1 && _looks != null)
			{
				AdManager(super.shellApi.adManager).stopCampaignMusic();
				close();
				return false;
			}
			return true;
		}
		
		protected virtual function loadedSwf(clip:MovieClip):void
		{
			// save clip to screen
			super.screen = clip;
			
			super.loaded();
			
			// play music
			if (_musicFile != null)
			{
				AdManager(super.shellApi.adManager).playCampaignMusic(_musicFile);
			}
		}
		
		protected virtual function winGame():void
		{
			loadGamePopup("AdWinGamePopup");
		}
		
		protected function gameOver():void
		{
			loadGamePopup("AdLoseGamePopup");
		}
		
		protected function finalizeGame(...args):void
		{
			super.loaded();
		}
		
		override public function remove():void
		{
			if (_musicFile != null)
			{
				AdManager(super.shellApi.adManager).stopCampaignMusic();
			}
			super.remove();
		}
	}
}