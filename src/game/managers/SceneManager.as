package game.managers
{
	/**
	 * Creates and cleans up a scene.  Handles hiding and fading a scene and creates its base container (camera).
	 */
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.core.SFSEvent;
	
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.MouseCursorData;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.Manager;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.SpriteSheet;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.managers.GroupManager;
	import engine.managers.SoundManager;
	import engine.nodes.AudioNode;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.input.Input;
	import game.components.motion.FollowInput;
	import game.components.ui.Cursor;
	import game.components.ui.CursorLabel;
	import game.components.ui.NavigationArrow;
	import game.data.game.GameData;
	import game.data.profile.ProfileData;
	import game.data.text.TextStyleData;
	import game.data.ui.ToolTipType;
	import game.scene.SceneSound;
	import game.scene.template.SFSceneGroup;
	import game.systems.PerformanceMonitorSystem;
	import game.systems.SystemPriorities;
	import game.systems.input.InputMapSystem;
	import game.systems.motion.FollowInputSystem;
	import game.systems.ui.CursorSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.transitions.ITransition;
	import game.ui.transitions.LogoLoadingScreen;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import flash.utils.getTimer;
	
	import org.osflash.signals.Signal;

	public class SceneManager extends Manager
	{
		private var keepAliveTime:int = getTimer();
		
		public function SceneManager()
		{
			if (!PlatformUtils.inBrowser) {
				/*
				Drew Martin
				There are some places in our code that need to save or clean-up once the application is done running.
				To fix this, we will listen for when the application is closing, or "exiting". Removing the scene
				cleans up most of the game, including Entities, Systems, Nodes, etc. This DOESN'T handle ShellApi,
				Managers, etc.
				*/
				NativeApplication.nativeApplication.addEventListener(Event.EXITING, onApplicationExiting);
			}
		}

		private function onApplicationExiting(event:Event):void
		{
			trace(this, "onApplicationExiting()");
			NativeApplication.nativeApplication.removeEventListener(Event.EXITING, onApplicationExiting);
			this.removeScene();
		}

		override protected function construct():void
		{
			super.construct();
			
			if(shellApi.getManager(ScreenManager))
			{
				getScreenManager(shellApi.getManager(ScreenManager));
			}
			else
			{
				super.shellApi.managerAdded.add(getScreenManager);
			}
		}
		
		private function getScreenManager(manager:Manager):void
		{
			if(manager is ScreenManager)
			{
				super.shellApi.managerAdded.remove(getScreenManager);
				
				_container = ScreenManager(manager).sceneContainer;
			}
		}
				
		/**
		 * Load a new scene.  NOTE : This should be called through the shellApi to ensure all xml related to an island is loaded first.
		 * @param   scene : The new scene's class or instance of a scene class.
		 * @param   [playerX, playerY] : x and y position to place the player in the scene.  If left undefined the player will load into the default x/y position in the scenes scene.xml.
		 * @param   [direction] : Direction to face the player in the scene.  Can be 'left' or 'right'.  Will default to the value in scene.xml if undefined.
		 */
		public function loadScene(scene:*, playerX:Number = NaN, playerY:Number = NaN, direction:String = null, fadeInTime:Number = NaN, fadeOutTime:Number = NaN):void
		{
			_newScene = scene;
			_newSceneX = playerX;
			_newSceneY = playerY;
			_newSceneDirection = direction;
			
			if(!isNaN(fadeInTime)) { _sceneFadeInTime = fadeInTime; }
			if(!isNaN(fadeOutTime)) { _sceneFadeOutTime = fadeOutTime; }
			
			shellApi.profileManager.active.lastX = _newSceneX;
			shellApi.profileManager.active.lastY = _newSceneY;
			shellApi.profileManager.active.lastDirection = _newSceneDirection;
			
			// first time on island setup should happen before scene load....
			// If another scene currently exists, remove it from memory before creating a new one.
			if (_scene != null)
			{
				fadeOutScene();	// begins remove scene sequence, once complete createScene is called
			}
			else
			{
				createScene(scene);
			}
		}
		
		/**
		 * Removes the current scene
		 */
		public function removeScene():void
		{
			if(_scene)
			{
				// store the name of the previous scene class in case we need know after the new one loads.
				if(_scene.sceneData)
				{
					if(_scene.sceneData.saveLocation)
					{
						this.previousScene = ClassUtils.getNameByObject(_scene);
						
						var position:Point = EntityUtils.getPosition(shellApi.player);
						if(position != null)
						{
							this.previousSceneX = int(position.x);
							this.previousSceneY = int(position.y);
						}
						else
						{
							this.previousSceneX = _sceneX;
							this.previousSceneY = _sceneY;
						}
						
						this.previousSceneDirection = _sceneDirection;
						var islandName:String = ProxyUtils.getIslandFromScene(_scene);
						if (islandName != "clubhouse")
						{
							trace("UPDATING PREVIOUS ISLAND", islandName);
							shellApi.profileManager.active.previousIsland = islandName;
						}
					}
					else
					{
						trace("ABSOLUTELY WILL NOT CHANGE PREVIOUS SCENE from", previousScene, "to", _scene, "because saveLocation is false");
					}
				}
				
				// remove all assets from assetLoader (TODO : might need to revisit and keep some stuff around).
				shellApi.clearFileCache();
				// add a listener for when the scene is done its cleanup
				_scene.removed.addOnce(sceneRemoved);
				// remove the scene from _groupManager which calls scene.destroy
				GroupManager(shellApi.getManager(GroupManager)).remove(_scene);
				
				shellApi.eventTriggered.removeAll();
			}
		}
		
		public function reloadScene():void
		{
			var className:String = ClassUtils.getNameByObject(_scene);
			var sceneClass:Class = ClassUtils.getClassByName(className);
			loadScene(sceneClass);
		}
		
		/**
		 * Creates a scene.  A scenes base 'container' serves as the camera for panning around and zooming.  A scenes 'groupContainer' contains all entities and layers for a scene.
		 */
		private function createScene(scene:*):void
		{
			var groupManager:GroupManager = GroupManager(shellApi.getManager(GroupManager));
			shellApi.gameEventManager.checkEventGroups(shellApi.island);
						
			if(_sceneSound == null)
			{
				_sceneSound = new SceneSound();
				shellApi.injector.map(SceneSound).toValue(_sceneSound);
				shellApi.injector.injectInto(_sceneSound);
			}
						
			// create a new scene instance
			if(scene is Class)
			{
				_scene = groupManager.create(scene) as Scene;
			}
			else
			{
				_scene = scene;
				groupManager.add(_scene);
			}
			
			groupManager.defaultGroup = _scene;
						
			_scene.ready.addOnce(sceneReady);
			
			// create the scene's camera container.  Hide it until the scene is 'ready'.
			var cameraContainer:Sprite = new Sprite();
			//cameraContainer.alpha = 0;
			cameraContainer.mouseEnabled = false;
			cameraContainer.name = 'cameraContainer';
			// add the scene's camera container to the scene container in the shell.
			_container.addChild(cameraContainer);
			// init the scene - the scene's internal container is created here.
			_scene.init(cameraContainer);
			
			// create input entity if not yet present
			if( _scene.getEntityById( INPUT_ID ) == null )
			{
				shellApi.inputEntity = createInputEntity(shellApi.backgroundContainer, _scene, _container, this.toolTipData);
			}

			if(_sceneFadeInTime > 0 && _sceneFadeOutTime > 0)
			{
				showLoadingTransition(_scene);
			}
			
			//trace("WE CREATED THE SCENE", _scene);
			//trace("active", shellApi.profileManager.active);
		}
		
		/////////////////////////////////////////////// MULTIPLAYER ///////////////////////////////////////////////
		
		/**
		 * Attempts to goto a multiplayer enabled scene where a multiplayer connection is required to enter the scene. Often should be used at doorways to multiplayer-required scenes like the Arcade.
		 * @param	sceneClass: Scene class to load if successful.
		 */
		public function gotoMultiplayerScene(sceneClass:Class, overrideReturnScene:String = null):void
		{
			// show loading
			SceneUtil.lockInput(this.currentScene);

			var parse:Array = flash.utils.getQualifiedClassName(sceneClass).split(".");
			var parse2:Array = parse[parse.length - 1].split("::");
			var sceneName:String = parse2[parse2.length - 1];
			var currentScene:Scene = this.currentScene;
			
			// determine smartfox
			if (!shellApi.smartFox.isConnected)
			{
				// on successful login - enter the arcade
				shellApi.smartFoxManager.loggedIn.addOnce(enterSFScene);
				// listen for a login fail
				shellApi.smartFoxManager.loginError.addOnce(cancel);
				// connect to smartFox
				shellApi.smartFoxManager.connect(false);
			} 
			else 
			{
				enterSFScene();
			}
			
			function enterSFScene():void{
				if(shellApi.smartFox.isConnected && shellApi.smartFox.currentZone == AppConfig.multiplayerZone){
					shellApi.track(SmartFoxManager.TRACK_SFS_CONNECT, sceneName);
					shellApi.loadScene( sceneClass );
					if (overrideReturnScene != null) {
						shellApi.overrideReturnScene = overrideReturnScene;
					}
				} else {
					var event:SFSEvent = new SFSEvent("error",{popupMsg:"Error trying to load the "+sceneName+"."});
					cancel(event);
				}
				shellApi.smartFoxManager.loginError.removeAll();
			}
			
			function cancel(event:SFSEvent):void{
				SceneUtil.lockInput(currentScene, false);
				
				var dialogBox:ConfirmationDialogBox;
				if(event.params.type == "timeout" || event.params.popupMsg == "Your connection timed out, please try again later."){
					dialogBox = currentScene.addChildGroup(new ConfirmationDialogBox(1, "It's taking too long to enter the "+sceneName+"! Please make sure you are connected to the internet.")) as ConfirmationDialogBox;
				} else {
					dialogBox = currentScene.addChildGroup(new ConfirmationDialogBox(1, event.params.popupMsg)) as ConfirmationDialogBox;
				}
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(currentScene.overlayContainer);
				
				shellApi.smartFoxManager.loggedIn.removeAll();
				
				if(shellApi.smartFox.isConnected){
					shellApi.smartFoxManager.disconnect();
				}
			}
		}
		
		/**
		 * Enables multiplayer on the current scene.
		 * @param	[debug]: Enable debug features.  Defaults to false.
		 * @param	[alertUser]: Inform users of disconnect or problems.  Defaults to true.
		 * @param   [softCapped]: Whether or not the scene's multiplayer is softCapped and set to lower priority to make space on the server. Defaults to false.
		 */
		public function enableMultiplayer(debug:Boolean = false, alertUser:Boolean = true, softCapped:Boolean = false):void
		{
			var sfSceneGroup:SFSceneGroup = new SFSceneGroup(debug, alertUser, softCapped, clubhouseLogin);
			currentScene.addChildGroup(sfSceneGroup);
		}
		
		/////////////////////////////////////////////// INPUT DISPLAY ///////////////////////////////////////////////
		
		/**
		 * Create an Entity that follows input coordinates and handles input.
		 * An input Entity is created as part of scene creation.
		 * @param	inputContainer
		 * @param	group
		 * @return
		 */
		public function createInputEntity(inputContainer:DisplayObjectContainer, group:Group = null, cursorContainer:DisplayObjectContainer = null, toolTipData:Dictionary = null):Entity
		{			
			var entity:Entity = new Entity();
			var input:Input = new Input();
			var spatial:Spatial = new Spatial();
			var sprite:Sprite = new Sprite();
			
			if(group != null)
			{
				group.addSystem(new FollowInputSystem());	
				group.addSystem(new InputMapSystem());
				group.addEntity(entity);
			}
			
			if(inputContainer != null)
			{
				input.addInput(inputContainer);
			}
			
			if(cursorContainer)
			{
				if(cursorContainer)
				{
					cursorContainer.addChild(sprite);
				}
			}
			
			entity.add(new Display(sprite, cursorContainer));
			entity.add(spatial);
			entity.add(new FollowInput(.25));
			entity.add(input);
			entity.add(new Id(INPUT_ID));
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = false;
			entity.add(sleep);
			entity.ignoreGroupPause = true;
			
			if(PlatformUtils.isDesktop)
			{
				var cursor:Cursor = new Cursor(ToolTipType.CLICK);
				
				// Create a MouseCursorData object
				var cursorData:MouseCursorData = new MouseCursorData();
				cursor._cursorData = cursorData;
				
				// cursor images and animation are stored in a spritesheet component.
				entity.add(new SpriteSheet());
				entity.add(cursor);
				entity.add(new SpatialOffset());
				
				if(group != null)
				{
					var cursorSystem:CursorSystem = new CursorSystem(toolTipData);
					group.addSystem(cursorSystem, SystemPriorities.update);
					
					if(!PlatformUtils.inBrowser)
					{
						cursorSystem.neverUseNativeCursors = true;
					}
				}
				
				addCursorLabel(group, cursorContainer, input);
			}
			else
			{
				if(group != null)
				{
					addMobileNavCursor(entity, group);
				}
			}
			
			return(entity);
		}
		
		private function addCursorLabel(group:Group, container:DisplayObjectContainer, input:Input):void
		{
			var entity:Entity = new Entity();
			var display:Display = new Display();
			display.displayObject = new Sprite();
			
			var filterMobile:DropShadowFilter = new DropShadowFilter(0, 0, 0xFFFFFF, 1, 3, 3, 12, BitmapFilterQuality.HIGH);
			var textField:TextField = new TextField();
			textField.autoSize = TextFieldAutoSize.CENTER;
			textField.filters = [filterMobile];
			
			var testStyle:TextStyleData = group.shellApi.textManager.getStyleData( "ui", "tooltip" );
			if( testStyle )
			{
				TextUtils.applyStyle(testStyle, textField);
			}

			display.displayObject.addChild(textField);
			display.displayObject.mouseEnabled = false;
			display.displayObject.mouseChildren = false;
			container.addChild(display.displayObject);
			
			entity.add(display);
			entity.add(new Spatial());
			entity.add(new FollowInput(.2));
			entity.add(input);
			entity.add(new CursorLabel(textField));
			
			group.addEntity(entity);
		}
		
		private function addMobileNavCursor(entity:Entity, group:Group):void
		{
			entity.add(new Cursor(ToolTipType.NAVIGATION_ARROW));
			group.shellApi.loadFile(group.shellApi.assetPrefix + "ui/toolTip/navigationArrow.swf", mobileNavCursorLoaded, entity);
		}
		
		private function mobileNavCursorLoaded(clip:MovieClip, entity:Entity):void
		{
			var display:Display = entity.get(Display);
			
			display.displayObject = Sprite(display.container.addChild(clip));
			display.displayObject.mouseChildren = false;
			display.displayObject.mouseEnabled = false;
			entity.get(Spatial).scale = 2;
			clip.visible = display.visible = false;
			
			if(clip.totalFrames > 1)
			{
				TimelineUtils.convertClip(MovieClip(display.displayObject), null, entity);
			}
			
			entity.add(new NavigationArrow());
		}
		
		//////////////////////////////////////////////////////////////////////////////////

		private function sceneRemoved(scene:Scene):void
		{
			_scene = null;
			shellApi.camera = null;
			shellApi.inputEntity = null;
			shellApi.player = null;
			
			// remove the scene's camera container from the scene container in the shell.  This will happen automatically with camera cleanup in most scenes.
			if(scene.container && _container.contains(scene.container))
			//if(_container.contains(scene.container))
			{
				_container.removeChild(scene.container);
			}
			
			// remove all entities and systems (TODO : might need to keep some around).
			GroupManager(shellApi.getManager(GroupManager)).removeAll();
			
			SoundManager(shellApi.getManager(SoundManager)).clearSoundCache();
			
			System.gc();	//triggers garbage collection
			
			// If we're creating a new scene, do it here as cleanup is now complete. TODO : make sure it really is complete.
			if (_newScene != null)
			{
				createScene(_newScene);
			}
		}
		
		private function sceneReady(scene:Group):void
		{
			var profileManager:ProfileManager = shellApi.profileManager;
			var profile:ProfileData = profileManager.active;
			var playerX:Number = _newSceneX;
			var playerY:Number = _newSceneY;
			var playerDir:String = _newSceneDirection;
			
			if(_scene.sceneData)
			{
				if(_scene.sceneData.startPosition)
				{
					if(isNaN(playerX)) { _newSceneX = playerX = _scene.sceneData.startPosition.x; }
					if(isNaN(playerY)) { _newSceneY = playerY = _scene.sceneData.startPosition.y; }
				}
				
				if(playerDir == null) { _newSceneDirection = playerDir = _scene.sceneData.startDirection; }
				
				if(profile != null)
				{
					var currentIsland:String = shellApi.island;
					var canSaveIslandLocation:Boolean = true;
					if(shellApi.islandEvents)
					{
						canSaveIslandLocation = shellApi.islandEvents.canSaveIslandLocation;
					}
					if ('hub' == currentIsland) {
						canSaveIslandLocation = false;
					}
					if(canSaveIslandLocation && _scene.sceneData.saveLocation)
					{
						if (profile.island)
						{
							if (profile.island != "clubhouse")
							{
								trace("\nSceneManager::sceneReady() updates profile prevIsle to", profile.island);
								profile.previousIsland = profile.island;
							}
						}
						else
						{
							trace("NOT GONNA NULL OUT profile's prevIsle:", profile.previousIsland);
						}
						trace("NOW WE UPDATE PROFILE island to shellApi.island:", shellApi.island);
						trace("LET'S TRY UPDATING CHAR. last_island will be", profile.previousIsland, 'last_room', profile.lastScene[profile.previousIsland]);
						trace('isle', shellApi.island, 'room (storage)', ProxyUtils.convertSceneToStorageFormat(_scene), 'room (server)', ProxyUtils.convertSceneToServerFormat(_scene));
						var charLSO:SharedObject = ProxyUtils.as2lso;
						charLSO.data.last_island	= shellApi.island;
						charLSO.data.last_room		= ProxyUtils.convertSceneToServerFormat(_scene);
						profile.island = shellApi.island;
						profile.scene = ClassUtils.getNameByObject(_newScene);
						profileManager.save();
						
						shellApi.storeSceneVisit(currentScene, playerX, playerY, playerDir);
					}
					else
					{
						// if we're not saving this scene, revert position to default.
						profile.lastX = NaN;
						profile.lastY = NaN;
						profile.lastDirection = null;
					}
				}
			}

			_sceneSound.initScene(_scene.getData("sounds.xml", true), _scene);
			
			this.fadeIn(_sceneFadeInTime);
			//_scene.screenEffects.fadeFromBlack(_sceneFadeInTime);
			
			hideLoadingTransition(_scene);

			_scene.addSystem(new PerformanceMonitorSystem(_container), SystemPriorities.preUpdate);
			
			// store scene vars in case we need them later.
			_sceneX = _newSceneX;
			_sceneY = _newSceneY;
			_sceneDirection = _newSceneDirection;
			
			// reset scene properties to defaults after a scene has loaded.  They will be repopulated when loading a new scene.
			_sceneFadeInTime = DEFAULT_SCENE_FADE_IN_TIME;
			_sceneFadeOutTime = DEFAULT_SCENE_FADE_OUT_TIME;
			_newScene = null;
			_newSceneX = NaN;
			_newSceneY = NaN;
			_newSceneDirection = null;
			
			// restore special abilities on each new scene
			if( shellApi.player && shellApi.specialAbilityManager) 
			{
				shellApi.specialAbilityManager.restore(profile.specialAbilities);
			}

			sceneLoaded.dispatch(scene);
		}
		
		///////////////////////////////// SCENE TRANSITION /////////////////////////////////

		/**
		 * Creates a fade out transition before removing the current scene.
		 * @param removeSceneOnComplete - default to true, if true calls removeScene once fade is complete
		 */
		public function fadeOutScene( removeSceneOnFadeComplete:Boolean = true ):void
		{
			leavingScene.dispatch(_scene);
			// TODO :: May want allow more variability here as to what color we fade to - bard
			var onFadeCompleteMethod:Function;
			if( removeSceneOnFadeComplete )
			{
				_sceneSound.exitScene();
				fadeOutSceneSounds();
				_scene.removalPending = true;
				onFadeCompleteMethod = removeScene;
			}
			
			hideLoadingTransition(_scene);
			
			if( !_isSceneFaded )
			{
				// TODO :: May need to check if scene is still in process of fading, don't want to attempt fading twice
				_scene.screenEffects.fadeToBlack(_sceneFadeOutTime, Command.create(fadeOutComplete, onFadeCompleteMethod));
			}
			else
			{
				if( onFadeCompleteMethod != null ) { onFadeCompleteMethod(); }
			}
		}
		
		private function fadeOutComplete( completeHandler:Function = null ):void
		{
			// may want to set flag at this point that we can check against, and/or send a signal? - bard
			_isSceneFaded = true;
			if( completeHandler != null ) { completeHandler(); }
		}

		/**
		 * Fades out the scene's sounds 
		 */
		private function fadeOutSceneSounds():void 
		{
			var soundNodes:NodeList = GroupManager(shellApi.getManager(GroupManager)).systemManager.getNodeList(AudioNode);
			var node:AudioNode;
			var fadeStep:Number = 1 / (_sceneFadeOutTime * 60);
			
			for( node = soundNodes.head; node; node = node.next )
			{
				node.audio.fadeAll(0, fadeStep);
			}
		}
		
		private function fadeIn( fadeDuration:Number = NaN ):void
		{
			_isSceneFaded = false;
			if( isNaN(fadeDuration) ) { fadeDuration = _sceneFadeInTime; }
			_scene.screenEffects.fadeFromBlack(fadeDuration);
		}
		
		private function hideLoadingTransition(scene:Scene):void
		{
			var transition:ITransition = scene.getGroupById(LOADING_SCREEN_ID) as ITransition;
			if(transition)
			{
				if(transition.manualClose)
				{
					SceneUtil.showHud(scene, false);
					scene.groupContainer.visible = false;
					scene.pause();
					Group(transition).unpause();
					transition.transitionReady();
				}
				else
				{
					trace(this, "hideLoadingTransition()", "transition = true", "manualClose = false");
					Group(transition).ready.remove(loadingTransitionReady);
					transition.transitionOut();
				}
			}
		}
		
		private function showLoadingTransition(scene:Scene):void
		{
			if(!scene.isReady)
			{
				if(loadingTransitionClass)
				{
					// first check to see if a loading screen already exists, if so just use that
					if( scene.getGroupById(LOADING_SCREEN_ID) != null )
					{
						trace(this," :: WARNING :: showLoadingTransition : transition class already exists" );
					}
					else
					{
						var transition:ITransition = new loadingTransitionClass(scene.transitionContainer);
						Group(transition).id = LOADING_SCREEN_ID;
						scene.addChildGroup(Group(transition));
						Group(transition).ready.addOnce(loadingTransitionReady);
					}
				}
			}
		}
		
		private function loadingTransitionReady(transition:ITransition):void
		{
			transition.transitionIn();
		}
		
		///////////////////////////////// VARIABLES /////////////////////////////////
		
		public function get gameData():GameData { return this._gameData; }
		public function set gameData(gameData:GameData):void
		{
			if(!_gameData)
			{
				_gameData = gameData;
			}
		}
		
		public function get sceneSound():SceneSound 
		{
			return(_sceneSound);
		}

		public function get currentScene():Scene 
		{
			return(_scene);
		}

		public function get sceneX():Number { return this._sceneX; }
		public function get sceneY():Number { return this._sceneY; }

		//public function get defaultScene():String { return(_gameData.defaultScene); }
		public var sceneLoaded:Signal = new Signal(Group);
		public var leavingScene:Signal = new Signal(Group);
		public var connectingSceneDoors:Dictionary;
		public var loadingTransitionClass:Class = LogoLoadingScreen;
		public var toolTipData:Dictionary;
		public var clubhouseLogin:String = null;
		
		public var previousScene:String;
		public var previousSceneX:Number;
		public var previousSceneY:Number;
		public var previousSceneDirection:String;
		private var _scene:Scene;
		private var _sceneX:Number;
		private var _sceneY:Number;
		private var _sceneDirection:String;
		private var _newScene:*;
		private var _newSceneX:Number;
		private var _newSceneY:Number;
		private var _newSceneDirection:String;
		
		private var _container:DisplayObjectContainer;
		private var _sceneSound:SceneSound;
		private var _blackScreen:Sprite;
		private var _sceneFadeInTime:Number = DEFAULT_SCENE_FADE_IN_TIME;
		private var _sceneFadeOutTime:Number = DEFAULT_SCENE_FADE_OUT_TIME;
		private var _isSceneFaded:Boolean = false;
		
		private var _gameData:GameData;
		
		private var _eventGroups:String;
		private var _language:String;
		private var _languageFile:String;
	
		private const DEFAULT_SCENE_FADE_IN_TIME:Number = .7;
		private const DEFAULT_SCENE_FADE_OUT_TIME:Number = .5;
		private const LOADING_SCREEN_ID:String = "loadingScreen";
		private const INPUT_ID:String = "input";
	}
}
