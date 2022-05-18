package engine.util
{
	import com.adobe.crypto.MD5;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.creators.ObjectCreator;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.components.motion.FollowTarget;
	import game.components.motion.TargetSpatial;
	import game.data.ads.AdData;
	import game.data.profile.ProfileData;
	import game.managers.LongTermMemoryManager;
	import game.managers.SceneManager;
	import game.scene.template.PlatformerGameScene;
	import game.systems.PerformanceMonitorSystem;
	import game.systems.motion.NavigationSystem;
	import game.ui.popup.Popup;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;


	public class Console
	{
		public function Console(container:DisplayObjectContainer)
		{
			_container = container;
			triggerCommand = new Signal(Array);
		}
		
		public function show():void
		{
			MIN_WIDTH = _shellApi.viewportWidth * .5;
			MIN_HEIGHT = 25;// _shellApi.viewportHeight * .1;
			MAX_WIDTH = _shellApi.viewportWidth - TEXT_PADDING;
			MAX_HEIGHT = _shellApi.viewportHeight - TEXT_PADDING;
			
			var labelFormat1:TextFormat = new TextFormat("Arial", 16, 0x00ff00);
			var labelFormat2:TextFormat = new TextFormat("Arial", 12, 0xffffff);
			var labelFormat3:TextFormat = new TextFormat("Arial", 12, 0xff0000);
			var yPosition:Number = 1;
			
			if(!PlatformUtils.isDesktop)
			{
				yPosition = 50;
				createCommandHistoryButtons();
			}
			
			_input = new TextField();
			_input.border = true;
			_input.width = MIN_WIDTH;
			_input.height = MIN_HEIGHT;
			_input.x = 1;
			_input.y = yPosition;
			_input.type = "input";
			_input.multiline = false;
			_input.background = true;
			_input.backgroundColor = 0x000000;
			_input.defaultTextFormat = labelFormat1;
			_input.alpha = .75;
			
			_output = new TextField();
			_output.width = MIN_WIDTH;
			_output.height = MIN_HEIGHT;
			_output.x = 1;
			_output.y = _input.y + _input.height;
			_output.background = true;
			_output.backgroundColor = 0x00000050;
			_output.defaultTextFormat = labelFormat2;
			_output.alpha = .6;
			
			_errorOutput = new TextField();
			_errorOutput.width = MIN_WIDTH;
			_errorOutput.height = MIN_HEIGHT;
			_errorOutput.x = 1;
			_errorOutput.y = _output.y + _output.height;
			_errorOutput.background = true;
			_errorOutput.backgroundColor = 0x000000;
			_errorOutput.defaultTextFormat = labelFormat3;
			_errorOutput.alpha = .75;
			_errorOutput.autoSize = "left";

			_container.addChild(_input);
			_container.addChild(_output);
			_container.addChild(_errorOutput);
			_container.mouseEnabled = false;
			_output.mouseEnabled = false;
			_errorOutput.mouseEnabled = false;
			
			//Should show repo revision
			log(this.versionString);
			log("Platform : " + AppConfig.platformType + "  Quality Level : " + PerformanceUtils.qualityLevel + " Stage Quality : " +_container.stage.quality + " Language: " + _shellApi.preferredLanguage, null, false);
			_stage.focus = _input;
			
		}
		
		public function hide():void
		{
			if(_previousCommandButton) 
			{ 
				_container.removeChild(_previousCommandButton); 
				_previousCommandPressed.removeAll();
				_previousCommandPressed = null;
			}
			
			if(_nextCommandButton) 
			{ 
				_container.removeChild(_nextCommandButton); 
				_nextCommandPressed.removeAll();
				_nextCommandPressed = null;
			}

			_container.removeChild(_input);
			_container.removeChild(_output);
			_container.removeChild(_errorOutput);
			_input = null;
			_output = null;
			_errorOutput = null;
		}
		
		public function toggle():void
		{
			if(_input == null)
			{
				show();
			}
			else
			{
				hide();
			}
		}
		
		public function processCommands():void
		{
			var command:String = _input.text;
			_input.text = "";
			processCommand(command);
		}
		
		public function unlockConsole():void
		{
			LongTermMemoryManager(_shellApi.getManager(LongTermMemoryManager)).devConsoleUnlocked = true;
			_shellApi.track("consoleCommand", "unlocked");
		}
		
		public function get unlocked():Boolean
		{
			return LongTermMemoryManager(_shellApi.getManager(LongTermMemoryManager)).devConsoleUnlocked;
		}
		
		public function shiftCommandHistoryIndex(dir:Number):void
		{
			var commandStack:Array = LongTermMemoryManager(_shellApi.getManager(LongTermMemoryManager)).devCommandHistory;
			var command:String;
			var nextCommand:Boolean = false;
			
			if(commandStack != null)
			{
				if(commandStack.length > 0)
				{
					_commandHistoryIndex += dir;
					
					if(_commandHistoryIndex < 0)
					{
						_commandHistoryIndex = 0;
					}
					else if(_commandHistoryIndex > commandStack.length - 1)
					{
						_commandHistoryIndex = commandStack.length - 1;
					}
					
					command = commandStack[_commandHistoryIndex];
					
					if(command != null)
					{
						_input.text = command;
					}
				}
			}
		}
		
		public function log(message:String, source:*=null, clear:Boolean=true):void
		{
			if(this.active)
			{
				if(source != null)
				{
					var sourceName:String = String(source).slice(8, String(source).length - 1);
					
					message = sourceName + " :: " + message;
				}
				
				if(clear)
				{
					_output.text = message;
				}
				else
				{
					if(_output.text == "")
					{
						_output.appendText(message);
					}
					else
					{
						_output.appendText("\n" + message);
					}
				}
								
				fitText(_output);
			}
		
		}
		
		public function logError(message:String, source:*=null):void
		{
			if(!this.active)
			{
				show();
			}
			
			if(source != null)
			{
				var sourceName:String = String(source).slice(8, String(source).length - 1);
				
				message = sourceName + " :: " + message;
			}
			
			message = "ERROR :: " + message;
			
			if(_errorOutput.textHeight > 200)
			{
				// remove the oldest error on overflow.
				var arr:Array = _errorOutput.text.split("ERROR :: ");
				_errorOutput.text = _errorOutput.text.slice(arr[0].length + 1);
			}
			
			if(_errorOutput.text == "")
			{
				_errorOutput.appendText("\n" + message);
			}
			else
			{
				_errorOutput.appendText("\n" + message);
			}
			
			_errorOutput.mouseEnabled = true;
		}
		
		private function processCommand(command:String):void
		{
			var noWhitespace:String = DataUtils.removeWhiteSpace(command);
			var dispatchCommand:Boolean = true;
			
			if(noWhitespace.length > 0)
			{				
				_commandHistoryIndex = -1;
				
				var commandParts:Array = formatCommand(command);
				
				if(MD5.hash(commandParts[0]) == "351e21152ebf4ae342f2e5413f1c537b")
				{	
					unlockConsole();
					// set age to zero also
					_shellApi.profileManager.active.age = 0;
					_shellApi.profileManager.save();
					_output.text = "Dev console unlocked!";
					return;
				}
				else if(false)
				{
					_output.text = "Dev console locked.";
					return;
				}
				
				_shellApi.track("consoleCommand", command);
				
				switch(commandParts[0])
				{
					case ConsoleCommand.HELP :
						_output.text = "*** Console Commands ***";
						_output.appendText("\n\n Enter a command with parameters seperated by spaces.  Use up/down arrows or buttons to cycle through the command history.");
						_output.appendText("\n Examples : \n 		shell getItem bowlOfMilk\n 		loadScene Vent carrot");
						_output.appendText("\n\n 'help'  : Brings up this help screen.");
						_output.appendText("\n 'hide'  : Hides the console.");
						_output.appendText("\n 'completeEvent EVENT [ISLAND]'  : Complete an event, optionally specify an island.");
						_output.appendText("\n 'triggerEvent EVENT [SAVE] [ISLAND]'  : Trigger an event, optionally save it as completed and optionally specify an island.");
						_output.appendText("\n 'removeEvent EVENT [ISLAND]'  : Remove an event, optionally specify an island.");
						_output.appendText("\n 'getItem ITEM [ISLAND/STORE]'  : Get an item, optionally specify an island or store.");
						_output.appendText("\n 'removeItem [ITEM ISLAND/STORED]'  : Remove an item, optionally specify an island or store.");
						_output.appendText("\n 'fps'  : Opens/closes the performance monitor.");
						_output.appendText("\n 'setPart TYPE ID '  : Assign part to player (ex. setPart hair aphrodite). Valid types: skinColor,hairColor,eyeState,eyes,marks,mouth,facial,hair,pants,shirt,overpants,overshirt,item,pack");
						_output.appendText("\n 'showItems'  : Show the items currently in the inventory.");
						_output.appendText("\n 'showEvents'  : Show all completed events.");
						_output.appendText("\n 'showAllItems'  : Show all obtainable items in this island.");
						_output.appendText("\n 'showAllEvents'  : Show all events that can be completed and saved to the server on this island.");
						_output.appendText("\n 'showAllScenes'  : Show all scenes that can be loaded on this island.");
						_output.appendText("\n 'loadScene SCENE [ISLAND]'  : Loads into a scene's default location, island optional. Can also use full path (ex : game.scenes.carrot.farmHouse.FarmHouse)");
						_output.appendText("\n 'reloadScene [boolean]' : Reloads the current scene, false uses scene default location, true uses the player's current position and is the default.");
						_output.appendText("\n 'loadPopup POPUP'  : Loads a popup. Must use the full path (ex : game.scenes.examples.basicPopup.ExamplePopup).\n       If the POPUP is in the current scene package, then you can use just the popup name (ex : 'loadPopup ExamplePopup').");
						_output.appendText("\n 'saveScene : Forces a save of the current scene.");
						_output.appendText("\n 'clearHistory'  : Clear the history of commands from memory.");
						_output.appendText("\n 'clearItems [island]'  : Clear the list of collected items from the active profile.  Leaving out the island param clears from all islands.");
						_output.appendText("\n 'clearEvents [island]'  : Clear the list of completed events from the active profile.  Leaving out the island param clears from all islands.");
						_output.appendText("\n 'clearProfile [id]'  : Clear the list of completed events from the active profile.    Leaving out the island param clears all profiles (same as reset data).");
						_output.appendText("\n 'shell METHOD'  : Call any public ShellApi methods.  Seperate 'shell' and the method with a space.");
						_output.appendText("\n 'shell MANAGER METHOD'  : Call any public ShellApi manager and thier methods.  Seperate 'shellGet', manager, and method with a space between each.");
						_output.appendText("\n 'sceneGet METHOD'  : Call any public methods in currently loaded scene.  Seperate 'scene' and the method with a space.");
						_output.appendText("\n 'showPath'  : Toggles debugging for navigation, displaying path points and when they have been reached.  When toggled off the path display is lost");
						_output.appendText("\n 'showEntityCount'  : Toggles display of total entities in Ash.");
						_output.appendText("\n 'setQualityLevel [level]'  : A number between 0 - 100 which determines graphics quality.");
						//_output.appendText("\n 'setPlatformType [type]'  : Overrides the current platform with the one specified.  Options : 'mobile', 'tablet', or 'desktop'"); //No longer in use
						_output.appendText("\n 'noClip [rate]'  :  Toggles free camera movement and player positioning.  Optionally specify a movement rate, default is .1");
						_output.appendText("\n 'freeCamera [rate]'  :  Toggles free camera movement.  Optionally specify a movement rate, default is .1");
						_output.appendText("\n 'showProfileLooks' : Shows a list of logins, avatar names, and PlayerLooks for all ProfileDatas. Useful for debugging invalid looks.");	
						_output.appendText("\n 'setGuest' : Toggles the guest status of the current player.");
					break;
					
					case ConsoleCommand.GET_SFS_OVERRIDE:
						_output.text = "";
						showList([_shellApi.smartFoxManager.OverrideHost]);
						break;
					case ConsoleCommand.SET_SFS_OVERRIDE:
						if(commandParts.length == 2)
							_shellApi.smartFoxManager.OverrideHost = commandParts[1];
						else
							_shellApi.smartFoxManager.OverrideHost = "";
						_output.text = "Set SF Server to: " + commandParts[1];
						break;
						
					case ConsoleCommand.SHELL :
						commandParts.shift();
					
					case ConsoleCommand.COMPLETE_EVENT :
					case ConsoleCommand.TRIGGER_EVENT :
					case ConsoleCommand.REMOVE_EVENT :
					case ConsoleCommand.GET_ITEM :
					case ConsoleCommand.REMOVE_ITEM :
						processShellCommand(commandParts);
						break;	
					
					case ConsoleCommand.SHELL_GET :
						commandParts.shift();
						processShellGetCommand(commandParts);
						break;
					
					case ConsoleCommand.SCENE :
						commandParts.shift();
						processSceneCommand(commandParts);
					break;
					
					case ConsoleCommand.LOAD_SCENE :
						loadScene(commandParts);
					break;
					
					case ConsoleCommand.RELOAD_SCENE:
						reloadScene(commandParts);
						break;
					
					case ConsoleCommand.SET_USER_FIELD:
						_shellApi.setUserField(commandParts[1], commandParts[2], _shellApi.island, true);
						break;
					
					case ConsoleCommand.LOAD_POPUP :
						loadPopup(commandParts);
						break;
					
					case ConsoleCommand.CLEAR_HISTORY :
						LongTermMemoryManager(_shellApi.getManager(LongTermMemoryManager)).clearDevCommandHistory();
					break;
					
					case ConsoleCommand.FPS :
						// this gets handled by DevTools
						break;
					
					case ConsoleCommand.SET_PART :
						if( commandParts.length == 3 )
						{
							var partType:String = commandParts[1]
							var partId:String = commandParts[2]
							SkinUtils.setSkinPart( _shellApi.player, partType, partId);
						}
					break;
					
					case ConsoleCommand.SHOW_ITEMS :
						var items:Vector.<String> = _shellApi.getCardSet(commandParts[1]).cardIds;
						
						if(items.length > 0)
						{
							_output.text = "Current Items : \n";
							showList(items);
						}
						else
						{
							_output.text = "No Items.";
						}
					break;
					
					case ConsoleCommand.SHOW_ALL_ITEMS :
						var allItems:Array = new Array();
						
						if(ProxyUtils.itemToIdMap[_shellApi.island])
						{
							for(var n:String in ProxyUtils.itemToIdMap[_shellApi.island])
							{
								allItems.push(n);
							}
						}
						
						if(allItems.length > 0)
						{
							_output.text = "All Items : \n";
							showList(allItems);
						}
						else
						{ 
							_output.text = "No Items in island.xml."; 
						}
					break;
					
					case ConsoleCommand.SHOW_EVENTS :
						var events:Vector.<String> = _shellApi.getEvents(commandParts[1]);
						
						if(events.length > 0)
						{
							_output.text = "Completed Events : \n";
							showList(events);
						}
						else
						{
							_output.text = "No Completed Events.";
						}
					break;
					
					case ConsoleCommand.SHOW_ALL_EVENTS :
						var noEvents:Boolean = true;
						
						if(ProxyUtils.permanentEvents)
						{
							if(ProxyUtils.permanentEvents.length > 0)
							{
								_output.text = "All Events : \n";
								showList(ProxyUtils.permanentEvents);
								noEvents = false;
							}
						}
						
						if(noEvents) { _output.text = "No permanent Events in island.xml."; }
					break;
		
					case ConsoleCommand.SHOW_ALL_SCENES :
						var allScenes:Array = new Array();
						
						if(_shellApi.islandEvents)
						{
							if(_shellApi.islandEvents.scenes)
							{
								_output.text = "All Scenes : \n";
								
								for(var i:int = 0; i < _shellApi.islandEvents.scenes.length; i++)
								{
									allScenes.push(ProxyUtils.convertSceneToServerFormat(_shellApi.islandEvents.scenes[i]));
								}
								
								showList(allScenes);
							}
						}
						
						if(allScenes.length == 0) { _output.text = "No scenes in IslandEvents."; }
						break;
					
					case ConsoleCommand.SAVE_SCENE :
						_shellApi.profileManager.active.island = _shellApi.island;
						_shellApi.profileManager.active.scene = ClassUtils.getNameByObject(_sceneManager.currentScene);
						_shellApi.profileManager.active.lastX = _shellApi.player.get(Spatial).x;
						_shellApi.profileManager.active.lastY = _shellApi.player.get(Spatial).y;
						_shellApi.profileManager.save();
						break;
					
					case ConsoleCommand.HIDE :
						// handled by DevTools
					break;
					
					case ConsoleCommand.UNRECOGNIZED_COMMAND :
						_input.text = "";
						dispatchCommand = false;
					break;
					
					case ConsoleCommand.CLEAR_EVENTS :
						_shellApi.gameEventManager.reset(commandParts[1]);
						_shellApi.profileManager.save();
					break;
					
					case ConsoleCommand.CLEAR_ITEMS :
						_shellApi.clearItems(commandParts[1]);
					break;
					
					case ConsoleCommand.CLEAR_PROFILE :
						_shellApi.profileManager.clear(commandParts[1]);
					break;
					
					case ConsoleCommand.SHOW_PATH :
						var navSystem:NavigationSystem = _sceneManager.currentScene.getSystem( NavigationSystem ) as NavigationSystem;
						if ( navSystem )
						{
							navSystem.debug = !navSystem.debug;
						}
					break;
					
					case ConsoleCommand.SHOW_ENTITY_COUNT :
						var performanceMonitorSystem:PerformanceMonitorSystem = _sceneManager.currentScene.getSystem( PerformanceMonitorSystem ) as PerformanceMonitorSystem;
						performanceMonitorSystem.showEntityCount = !performanceMonitorSystem.showEntityCount;
					break;
					
					/*
					case ConsoleCommand.SHOW_MOBILE_ADS :
						// if still need this, then put function in PlatformUtils
						// removed from adManager
						//_shellApi.adManager.forceMobileAds = true;
						//break;
					*/
					
					case ConsoleCommand.SET_QUALITY_LEVEL :
						PerformanceUtils.qualityLevel = commandParts[1];
					break;
					
					/*
					// NOTE :: No longer supporting this functionality
					case ConsoleCommand.SET_PLATFORM_TYPE :
						PlatformUtils.platformType = commandParts[1];
						LongTermMemoryManager(_shellApi.getManager(LongTermMemoryManager)).setDevProperty("forcePlatformType", commandParts[1]);
					break;
					*/
										
					case ConsoleCommand.NO_CLIP :
						toggleFreeCamera(commandParts[1], true);
					break;
					
					case ConsoleCommand.FREE_CAMERA :
						toggleFreeCamera(commandParts[1], false);
					break;
					
					case ConsoleCommand.SHOW_PROFILE_LOOKS:
						var text:String = "";
						for each(var profileData:ProfileData in _shellApi.profileManager.profiles)
						{
							text += "Login: " + profileData.login + "\n";
							text += "Avatar Name: " + profileData.avatarName + "\n";
							text += "Player Look: " + profileData.look.toString() + "\n";
							text += "\n";
						}
						_output.text = text;
						break;
					
					case ConsoleCommand.SET_LANGUAGE:
						var newLanguage:String = commandParts[1];
						_shellApi.preferredLanguage = newLanguage;
						_shellApi.profileManager.save();
						break;
					
					case ConsoleCommand.SET_GUEST:
						_shellApi.profileManager.active.isGuest = !_shellApi.profileManager.active.isGuest;
						break;
					
					case ConsoleCommand.SET_AGE:
						// set age and save it
						trace("previous age: " + _shellApi.profileManager.active.age);
						_shellApi.profileManager.active.age = Number(commandParts[1]);
						_shellApi.profileManager.save();
						trace("new age: " + _shellApi.profileManager.active.age);
						
						// if web then save to LSO and database
						if (!AppConfig.mobile)
						{
							// save age to lso
							var lso:SharedObject = ProxyUtils.as2lso;
							lso.data.age = _shellApi.profileManager.active.age;
							lso.flush();
						}
						break;
					
					case ConsoleCommand.SHIFT_POSITION:
						if (commandParts[1] != null)
						{
							var coords:Array = commandParts[1].split(",");
							trace( coords);
							if (coords.length == 2)
							{
							_shellApi.player.get(Spatial).x += Number(coords[0]);
							_shellApi.player.get(Spatial).y += Number(coords[1]);
							}
						}
						break;
					
					case ConsoleCommand.TOGGLE_DEV_LOGIN:
						_devLoginEnabled = !_devLoginEnabled;
						_output.text = "Dev login mode enabled : " + _devLoginEnabled;
						break;
					
					default:
						_output.text = "Unrecognized command : '" + commandParts[0] + "'";
						dispatchCommand = false;
				}
				
				fitText(_output);
				
				if(dispatchCommand)
				{
					LongTermMemoryManager(_shellApi.getManager(LongTermMemoryManager)).addDevCommand(decodeURI(command));
					triggerCommand.dispatch(commandParts);
				}
			}
		}
			
		private function toggleFreeCamera(rate:Number = NaN, playerFollow:Boolean = false):void
		{
			if(isNaN(rate)) { rate = .1; }
			
			var camera:Entity = _sceneManager.currentScene.getEntityById("camera");
			var input:Entity = _sceneManager.currentScene.getEntityById("input");
			var noClipTarget:Entity = _sceneManager.currentScene.getEntityById("noClipTarget");
			var player:Entity = _sceneManager.currentScene.getEntityById("player");
			var cameraTarget:TargetSpatial = camera.get(TargetSpatial);
			
			if(noClipTarget == null)
			{
				var sprite:Sprite = new Sprite();
				PlatformerGameScene(_sceneManager.currentScene).hitContainer.addChild(sprite);
				
				noClipTarget = new Entity();
				noClipTarget.add(new Display(sprite));
				noClipTarget.add(new Spatial());
				noClipTarget.add(new Id("noClipTarget"));
				EntityUtils.followTarget( noClipTarget, input, rate, null, true);
				cameraTarget.target = noClipTarget.get(Spatial);
				_sceneManager.currentScene.addEntity(noClipTarget);
				
				if(playerFollow) 
				{
					EntityUtils.followTarget( player, input, rate, null, true);
					
				}
			}
			else
			{
				cameraTarget.target = player.get(Spatial);
				
				if(playerFollow) 
				{
					player.remove(FollowTarget);
				}
				
				_sceneManager.currentScene.removeEntity(noClipTarget);
			}
		}
		
		private function showList(list:Object):void
		{			
			var backupText:String;
			
			for(var n:Number = 0; n < list.length; n++)
			{
				backupText = _output.text;
				
				_output.appendText(list[n]);
				
				if(n != list.length - 1)
				{
					_output.appendText(", ");
				}

				if(_output.textWidth > _shellApi.viewportWidth)
				{
					_output.text = backupText;
					_output.appendText("\n");
					_output.appendText(list[n]);
					
					if(n != list.length - 1)
					{
						_output.appendText(", ");
					}
				}
			}
		}
		
		private function fitText(textField:TextField):void
		{
			if(textField.textWidth + TEXT_PADDING >= MIN_WIDTH)
			{
				if(textField.textWidth + TEXT_PADDING > MAX_WIDTH)
				{
					textField.width = MAX_WIDTH;
					textField.wordWrap = true;
				}
				else
				{
					textField.width = textField.textWidth + TEXT_PADDING;
				}
			}
			else
			{
				textField.width = MIN_WIDTH;
			}
			
			if(textField.textHeight + TEXT_PADDING >= MIN_HEIGHT)
			{
				if(textField.textHeight + TEXT_PADDING > MAX_HEIGHT)
				{
					textField.height = MAX_HEIGHT;
				}
				else
				{
					textField.height = textField.textHeight + TEXT_PADDING;
				}
			}
			else
			{
				textField.height = MIN_HEIGHT;
			}
		}
		
		private function loadScene(commandParts:Array):void
		{			
			var fullClassPath:Array = commandParts[1].split(".");
			var scenePath:String;
			var sceneClass:Class;
			
			if(fullClassPath.length == 1)
			{
				var path:String = "game.scenes.";
				var scene:String = commandParts[1];
				var sceneFirstLetter:String = scene.charAt(0);
				//Scene folder, game.scenes.carrot."diner".Diner
				var scene1:String = sceneFirstLetter.toLowerCase() + scene.slice(1);
				//Scene class, game.scenes.carrot.diner."Diner"
				var scene2:String = sceneFirstLetter.toUpperCase() + scene.slice(1);
				
				//Try assuming commandParts[2] is the island, and the user included the island.
				scenePath = path + commandParts[2] + "." + scene1 + "." +  scene2;
				sceneClass = ClassUtils.getClassByName(scenePath);
				
				if(!sceneClass)
				{
					//If that doesn't work, put the island in commandParts[2] and try again.
					commandParts.splice(2, 0, _shellApi.island);
					scenePath = path + commandParts[2] + "." + scene1 + "." + scene2;
					sceneClass = ClassUtils.getClassByName(scenePath);
				}
			}
			else
			{
				sceneClass = ClassUtils.getClassByName(commandParts[1]);
			}
			
			if(sceneClass)
			{
				//Anything after commandsParts[1]/scene and commandParts[2]/island
				//is considered parameters for the constructor.
				var instance:Scene = ObjectCreator.construct(sceneClass, commandParts.slice(3));
				if(instance != null)
				{
					_shellApi.loadScene(instance);
				}
			}
			else
			{
				_output.text = "ERROR : " + scenePath + " is not a valid scene.";
			}
		}
		
		private function reloadScene(commandParts:Array):void
		{
			var samePosition:Boolean = true;
			
			if(commandParts[1])
			{
				samePosition = DataUtils.getBoolean(commandParts[1]);
			}
			
			var positionX:Number = NaN;
			var positionY:Number = NaN;
			
			if(_shellApi.player && samePosition)
			{
				var playerSpatial:Spatial = _shellApi.player.get(Spatial);
				if(playerSpatial)
				{
					positionX = playerSpatial.x;
					positionY = playerSpatial.y;
				}
			}
			
			var sceneName:String = _shellApi.sceneName;
			var path:String = "game.scenes." + _shellApi.island + "." + sceneName.charAt(0).toLowerCase() + sceneName.slice(1) + "."  + sceneName.charAt(0).toUpperCase() + sceneName.slice(1);
			var sceneClass:Class = ClassUtils.getClassByName(path);
			
			_shellApi.loadScene(sceneClass, positionX, positionY);
		}
		
		private function loadPopup(commandParts:Array):void
		{			
			var popupPath:String = commandParts[1];
			var fullClassPath:Array = commandParts[1].split(".");
			var scene:Scene = _shellApi.sceneManager.currentScene;
			var popupClass:Class;
			
			if(fullClassPath.length == 1)
			{
				var fullScene:Array = ClassUtils.getNameByObject(scene).split(".");
				fullScene[fullScene.length - 1] = fullScene[fullScene.length - 1].split("::")[0];
				fullScene.push(popupPath);
				popupPath = fullScene.join(".");
			}
			
			var errorText:String = " is not a valid Popup.";
			var isAd:Boolean = (popupPath.indexOf("game.scenes.custom.Ad") != -1);
			if (isAd)
				errorText = " doesn't have a corresponding main street quest";
			
			var popupGroup:Group;
			popupClass = ClassUtils.getClassByName(popupPath);
			
			if(popupClass)
			{
				if (isAd)
				{
					var adData:AdData = _shellApi.adManager.getAdData(_shellApi.adManager.mainStreetType, false);
					if (adData)
					{
						var adPopup:Popup = new popupClass();
						adPopup.campaignData = _shellApi.adManager.getActiveCampaign(adData.campaign_name);
						popupGroup = scene.addChildGroup(adPopup);
						popupGroup.shellApi = _shellApi;
						popupGroup['init'](scene.overlayContainer);
					}
				}
				else
				{
					popupGroup = scene.addChildGroup(new popupClass(scene.overlayContainer));
				}
			}
			else
			{
				_output.text = "ERROR : " + popupPath + errorText;
			}
		}
		
		private function processShellCommand(commandParts:Array):void
		{
			var command:String = commandParts.shift();
			
			// convert strings to correct types.
			for(var n:uint = 0; n < commandParts.length; n++)
			{
				commandParts[n] = DataUtils.castToType(commandParts[n]);
			}
			
			_shellApi[command].apply(_shellApi, commandParts);
		}
		
		private function processShellGetCommand(commandParts:Array):void
		{
			var getter:String = commandParts.shift();
			var command:String = commandParts.shift();
			
			// convert strings to correct types.
			for(var n:uint = 0; n < commandParts.length; n++)
			{
				commandParts[n] = DataUtils.castToType(commandParts[n]);
			}
			
			if( (getter != null) && (command != null) )
			{
				_shellApi[getter][command].apply(_shellApi, commandParts);
			}
			else
			{
				_output.text = String("Invalid console usage : processShellGetCommand requires getter: " + getter + " & command: " + command + " to be specifiied.");
			}
		}

		private function processSceneCommand(commandParts:Array):void
		{
			var command:String = commandParts.shift();
			var scene:Scene = _sceneManager.currentScene;
			
			for(var n:uint = 0; n < commandParts.length; n++)
			{
				commandParts[n] = DataUtils.castToType(commandParts[n]);
			}
			
			scene[command].apply(_shellApi, commandParts);
		}
		
		private function formatCommand(command:String):Array
		{
			command = decodeURI(command);
			var commandParts:Array = command.split(" ");
			
			removeExtraWhitespace(commandParts);
			
			return(commandParts);
		}
		
		private function removeExtraWhitespace(command:Array):void
		{
			var part:String;
			
			for(var n:Number = 0; n < command.length; n++)
			{
				part = command[n];
				command[n] = DataUtils.removeWhiteSpace(part);
			}
		}
		
		// ugly code to create ugly buttons for device input...
		private function createCommandHistoryButtons():void
		{
			var buttonSize:Number = _shellApi.viewportHeight * .075;
			var buttonPadding:Number = 40;
			
			_previousCommandButton = new Sprite();
			_nextCommandButton = new Sprite();
			
			_previousCommandButton.graphics.beginFill(0x525252);
			_previousCommandButton.graphics.drawRect(1, 1, buttonSize, buttonSize - 2);
			_previousCommandButton.graphics.endFill();
			
			var labelFormat:TextFormat = new TextFormat("Arial", 40, 0x00ff00);
			
			var previousText:TextField = new TextField();
			
			previousText.text = "<";
			previousText.x = 1 + _shellApi.viewportWidth * .0125;
			previousText.setTextFormat(labelFormat);
			previousText.mouseEnabled = false;
			
			_previousCommandButton.addChild(previousText);
			
			_nextCommandButton.graphics.beginFill(0x525252);
			_nextCommandButton.graphics.drawRect(buttonSize + buttonPadding, 1, buttonSize, buttonSize - 2);
			_nextCommandButton.graphics.endFill();
			
			var nextText:TextField = new TextField();
			
			nextText.text = ">";
			nextText.x = buttonSize + buttonPadding + _shellApi.viewportWidth * .0125;
			nextText.setTextFormat(labelFormat);
			nextText.mouseEnabled = false;
			
			_nextCommandButton.addChild(nextText);
			
			_previousCommandPressed = InteractionCreator.create(_previousCommandButton, InteractionCreator.DOWN);
			_nextCommandPressed = InteractionCreator.create(_nextCommandButton, InteractionCreator.DOWN);
			
			_previousCommandPressed.add(handlePreviousCommandPressed);
			_nextCommandPressed.add(handleNextCommandPressed);
			
			_previousCommandButton.alpha = .6;
			_nextCommandButton.alpha = .6;
			
			_container.addChild(_previousCommandButton);
			_container.addChild(_nextCommandButton);
		}
		
		private function handlePreviousCommandPressed(event:Event):void
		{
			shiftCommandHistoryIndex(1);
		}
		
		private function handleNextCommandPressed(event:Event):void
		{
			shiftCommandHistoryIndex(-1);
		}
		
		public function get active():Boolean { return(_input != null); }
		public function get versionString():String { return _versionString; }
		public function set versionString(newVersionString:String):void { _versionString = newVersionString; }
		public function get devLoginEnabled():Boolean{return _devLoginEnabled;}
		
		public var triggerCommand:Signal;
		private var _commandHistoryIndex:Number = -1;
		private var _container:DisplayObjectContainer;
		private var _input:TextField;
		private var _output:TextField;
		private var _errorOutput:TextField;
		private var MIN_WIDTH:Number;
		private var MIN_HEIGHT:Number;
		private var MAX_WIDTH:Number;
		private var MAX_HEIGHT:Number;
		private var TEXT_PADDING:Number = 10;
		private var _previousCommandButton:Sprite;
		private var _nextCommandButton:Sprite;
		private var _nextCommandPressed:NativeSignal;
		private var _previousCommandPressed:NativeSignal;
		private var _versionString:String = 'Poptropica Core Local Build';
		private var _devLoginEnabled:Boolean = false;
		[Inject]
		public var _shellApi:ShellApi;
		[Inject]
		public var _stage:Stage;
		[Inject]
		public var _sceneManager:SceneManager;
	}
}
