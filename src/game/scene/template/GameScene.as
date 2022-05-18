
package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.creators.CameraLayerCreator;
	import engine.group.Scene;
	import engine.systems.CameraSystem;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	import engine.systems.TweenSystem;
	
	import game.components.motion.TargetSpatial;
	import game.data.ui.ToolTipType;
	import game.managers.PhotoManager;
	import game.managers.SceneDataManager;
	import game.systems.SystemPriorities;
	import game.systems.entity.SleepSystem;
	import game.systems.entity.character.DialogInteractionSystem;
	import game.systems.input.InteractionSystem;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.EdgeSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.scene.SceneInteractionSystem;
	import game.util.ArrayUtils;
	import game.util.DataUtils;
	import game.util.GroupUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	public class GameScene extends Scene
	{
		public function GameScene()
		{
			super();
		}

		override public function destroy():void
		{						
			_hitContainer = null;
			this.uiLayer = null;
			
			super.destroy();
		}
		
		/**
		 * Pre-load setup
		 * when overriding, should set groupPrefix prior loading configuration.
		 */
		override public function init(container:DisplayObjectContainer = null):void
		{			
			// generate a default groupPrefix based on the classpath.  This elminates the need to override this in a specific group
			//  or scene instance as long as your asset/data path matches the classpath (which is usually the case.)
			if( !DataUtils.validString( super.groupPrefix ) )
			{
				super.groupPrefix = GroupUtils.generateGroupPrefixFromClassPath(this);
			}
			super.init(container);
			load();
		}
		
		override public function load():void
		{
			// TODO :: should we pass file mappping along to SceneDataManager as well?
			_sceneDataManager = new SceneDataManager(this);
			_sceneDataManager.loaded.addOnce(addGroups);
			_sceneDataManager.loadSceneConfiguration( SCENE_FILE_NAME );
		}
		
		override public function loaded():void
		{
			addSleep();
			
			// SceneManager is listening for dispatch, sceneReady is handler, this.shellApi.unpause() game, 
			// calls showScene at end of update, or when chars complete
			super.loaded();
			
			super.shellApi.defaultCursor = defaultCursor;
		}
			
		/**
		 * Handles adjustment of the scene container after the viewport resizes.
		 */
		override public function resize(viewportWidth:Number, viewportHeight:Number):void
		{
			var camera:CameraSystem = this.systemManager.getSystem(CameraSystem) as CameraSystem;
			camera.resize(viewportWidth, viewportHeight, camera.areaWidth, camera.areaHeight);
			
			super.container.x = camera.viewportWidth * .5;
			super.container.y = camera.viewportHeight * .5;
			
			// propogates viewport change to all Viewport componnets
			super.resize( viewportWidth, viewportHeight );
		}
		
		/**
		 * Add required Groups for scene, Groups added is determined by scene data and presences of scene files
		 */
		protected function addGroups():void
		{
			// This group holds a reference to the parsed sound.xml data and can be used to setup an entity with its sound assets if they are defined for it in the xml.
			var audioGroup:AudioGroup = addAudio();
			// if scene has layers or dialog, create layers & camera
			var dialogXML:XML = super.getData(DIALOG_FILE_NAME);	// standard dialog file for scene
			var hasDialog:Boolean = ArrayUtils.getMatchingElements(DIALOG_FILE_NAME, sceneData.absoluteFilePaths) || dialogXML != null;			
			
			if (super.sceneData.layers || hasDialog)		// dialog needs layers to create dialog balloons
			{
				addCamera();
			}
			else
			{
				_waitingOnCameraUpdate = false;
			}

			// if interactive layer exists use CollisionGroup to add hit/interactive Entities.
			// Creates all hit/interactive areas defined by symbols & color in hits.xml.
			if ( _hitContainer )
			{
				addCollisions(audioGroup);
			}
					
			// if npcs or player have been specified load characters -AND- the scene allows characters add appropriate systems
			//if ( super.getData("npcs.xml") != null && !super.sceneData.noCharacters )
			if ( ( super.getData(NPCS_FILE_NAME) != null || super.sceneData.hasPlayer ) && !super.sceneData.noCharacters )
			{
				addCharacters();
				
				// CharacterDialogGroup parses dialog.xml and adds dialog components to all entity ids referred to in the xml.  
				// It also creates the dialogView for displaying word balloons.
				// TODO :: in future would like to detangle dialog from characters
				if (hasDialog)
				{
					addCharacterDialog(this.uiLayer);
				}
			}
			else
			{
				allCharactersLoaded();
			}
			addDoors(audioGroup);
			addItems();
			addActions();
			// Photos are not available on all platforms, check for manager first
			if ( shellApi.getManager( PhotoManager ) ) {
				addPhotos();
			}
			addBaseSystems();
		}
		
		protected function addBaseSystems():void
		{
			super.addSystem(new SceneInteractionSystem(), SystemPriorities.sceneInteraction);
			super.addSystem(new InteractionSystem(), SystemPriorities.update);	
			super.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);			
			super.addSystem(new TargetEntitySystem(), SystemPriorities.update);
			super.addSystem(new FollowTargetSystem(), SystemPriorities.move);
			super.addSystem(new RenderSystem(), SystemPriorities.render);
			super.addSystem(new EdgeSystem(), SystemPriorities.postRender);
			super.addSystem(new TweenSystem(), SystemPriorities.update);
			super.addSystem(new MotionSystem(), SystemPriorities.move);	
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
		}
		
		/**
		 * Adds CameraGroup, which creates camera layer Entities based on the sceneData.
		 * Some scenes using GameScene may not want to use camera layers in the standard way, allows for override. 
		 */
		protected function addCamera():void
		{			
			var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			
			if(cameraGroup == null)
			{
				cameraGroup = new CameraGroup();
			}
			
			var offsetCameraPosition:Boolean = true;
			
			if(super.sceneData.cameraLimits == null)
			{
				offsetCameraPosition = false;
				super.sceneData.cameraLimits = new Rectangle(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
			}
			
			// This method of cameraGroup does all setup needed to add a camera to this scene.  After calling this method you just need to assign cameraGroup.target to the spatial component of the Entity you want to follow.
			cameraGroup.setupScene(this, this.initialScale, offsetCameraPosition);
			
			// store a reference to the hits layer after the camera group creates it.
			var interactiveLayer:Entity = super.getEntityById("interactive");
			if(interactiveLayer == null) { interactiveLayer = super.getEntityById("hits"); }
			if(interactiveLayer != null) { _hitContainer = Display(interactiveLayer.get(Display)).displayObject; }
			
			// add a camera layer for ui that needs to move with the scene panning (fixed ui like the hud get added to this scenes overlayContainer).
			var cameraLayerCreator:CameraLayerCreator = new CameraLayerCreator();
			this.uiLayer = new Sprite();
			this.uiLayer.name = 'uiLayer';
			// add the ui layer above all the other camera layers.
			super.addEntity(cameraLayerCreator.create(this.uiLayer, 1, "uiLayer"));
			super.groupContainer.addChild(this.uiLayer);
		}
		
		protected function addCharacterDialog(dialogContainer:Sprite):void
		{
			// this group parses dialog.xml and adds dialog components to all entity id's referred to in the xml.  It also creates the dialogView for displaying word balloons.
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			// merge scene dialog xml with universal dialog xml
			var dialogXML:XML = SceneUtil.mergeSharedData(this, DIALOG_FILE_NAME, SceneUtil.FILES_COMBINE);		
			
			characterDialogGroup.setupGroup(this, dialogXML, dialogContainer);
		}
		
		protected function addCharacters():void
		{
			var charContainer:DisplayObjectContainer = ( _hitContainer ) ? _hitContainer : super.groupContainer;
			// this group handles loading characters, npcs (parses npcs.xml), and creates the player character.
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupScene( this, charContainer, super.getData(GameScene.NPCS_FILE_NAME), allCharactersLoaded, super.sceneData.hasPlayer);
			//characterGroup.setupScene( this, super.getData("npcs.xml"), charContainer, allCharactersLoaded, (super.sceneData.startPosition!=null), super.getData("npcs.xml") != null);
			
			super.addSystem(new DialogInteractionSystem(), SystemPriorities.lowest);
			super.addSystem(new NavigationSystem(), SystemPriorities.update);
		}
						
		protected function addSleep():void
		{
			var sleep:SleepSystem = new SleepSystem();
			// for entities that sleep but don't have a display component to hittest against
			if( super.shellApi.camera ) { sleep.awakeArea = super.shellApi.camera.viewport; }  
			// for entities that have a display component to be used with hitTestObject.
			if( super.shellApi.backgroundContainer) { sleep.visibleArea = super.shellApi.backgroundContainer; }   
			
			super.addSystem(sleep, SystemPriorities.update);
		}
				
		protected function addCollisions(audioGroup:AudioGroup):void
		{
			// this group adds all the hits inside this scene's hit layer as well as hit areas defined by color in hits.xml.
			var collisionGroup:CollisionGroup = new CollisionGroup();
			var data:XML = SceneUtil.mergeSharedData(this, HITS_FILE_NAME, SceneUtil.FILES_IGNORE);
			collisionGroup.setupScene(this, data, _hitContainer, audioGroup, this.showHits);
		}
		
		protected function addItems():void
		{
			var itemGroup:ItemGroup = new ItemGroup();
			itemGroup.setupScene(this, super.getData(ITEMS_FILE_NAME, true), _hitContainer, allItemsLoaded);
		}
		
		protected function addAudio():AudioGroup
		{
			var audioGroup:AudioGroup;
			var data:XML = SceneUtil.mergeSharedData(this, SOUNDS_FILE_NAME, SceneUtil.FILES_COMBINE);
			
			if(data != null)
			{
				audioGroup = new AudioGroup();
				audioGroup.setupGroup(this, data);
			}
			
			return(audioGroup);
		}
		
		protected function addActions():void
		{
			var data:XML = super.getData("actions.xml", true);
			if(data)
			{
				var actionsGroup:ActionsGroup = new ActionsGroup();
				actionsGroup.setupGroup(this, data);
			}
		}
				
		protected function addPhotos():void
		{
			var data:XML = super.getData(PHOTOS_FILE_NAME, true);
			
			if(data != null)
			{
				var photoGroup:PhotoGroup = new PhotoGroup();
				photoGroup.setupScene(this, data, _hitContainer);
			}
		}
		
		protected function addDoors(audioGroup:AudioGroup, data:XML = null):void
		{
			// create doors from xml files specified in scene.xml if they exist.
			if(data == null)
			{
				data = super.getData(DOORS_FILE_NAME, true);
			}
			
			// TODO :: This can get overwritten, need to allow for this. -bard
			if(data != null)
			{
				var doorGroup:DoorGroup = new shellApi.islandManager.doorGroupClass();
				doorGroup.setupScene(this, data, _hitContainer, audioGroup);
			}
		}
		
		/**
		 * Sets the camera target and starts the camera update wait.  Once the camera has had time to update and the layers reposition, 
		 *   we can complete the scene loading and fade in (to eliminate the camera jump).
		 */
		protected function setTarget(entity:Entity):void
		{
			// Set the initial camera target.
			var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			
			if(cameraGroup != null)
			{
				cameraGroup.setTarget(entity.get(Spatial), true);
				waitForCameraUpdate();
			}
			
			// Make the player follow input (the mouse or touch input).
			MotionUtils.followInputEntity(entity, super.shellApi.inputEntity, true);
		}
		
		protected function allCharactersLoaded():void
		{
			if( super.shellApi.player )
			{
				// set camera to player position
				setTarget(super.shellApi.player);
				// setup nav cursor
				super.shellApi.inputEntity.add(new TargetSpatial(super.shellApi.player.get(Spatial)));	
				// don't want the player to block clicks.
				Display( super.shellApi.player.get(Display) ).displayObject.mouseEnabled = false;
			}
			else
			{
				//If there is no player, then we shouldn't have to wait for a camera update since the camera has no target.
				if(super.getGroupById(CameraGroup.GROUP_ID) != null) 
				{
					_waitingOnCameraUpdate = false;// true;  //TODO : this should be true, but leaving as is for now to cleanup scenes that are depending on it being false...
				} 
			}
			
			if(!_waitingOnCameraUpdate)
			{
				cameraReady();
			}
		}
		
		private function waitForCameraUpdate():void
		{
			// This triggers the 'ready' signal in the superclass 'DisplayGroup' that shows this scene.
			_waitingOnCameraUpdate = true;
			var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			cameraGroup.ready.addOnce(cameraReady);
		}
		
		private function cameraReady(...args):void
		{
			_waitingOnCameraUpdate = false;
			
			if(_allItemsLoaded)
			{
				loaded();
			}
			else
			{
				_waitingOnItemLoad = true;
			}
		}
		
		private function allItemsLoaded():void
		{
			_allItemsLoaded = true;
			
			if(!_waitingOnCameraUpdate)
			{
				loaded();
			}
		}
		
		public function get player():Entity { return(super.shellApi.player); }
		public function get hitContainer():DisplayObjectContainer {return (_hitContainer);}
		public function get sceneDataManager():SceneDataManager { return(_sceneDataManager); }
		
		public var minCameraScale:Number = 1;
		public var initialScale:Number = 1;
		public var uiLayer:Sprite;
		public var defaultCursor:String = ToolTipType.TARGET;
		protected var _hitContainer:DisplayObjectContainer;
		protected var showHits:Boolean = false;
		private var _sceneDataManager:SceneDataManager;
		private var _allItemsLoaded:Boolean = false;
		private var _waitingOnItemLoad:Boolean = false;
		private var _waitingOnCameraUpdate:Boolean = true;
		
		/** standard name for dialog files, used to find dialog files that should be merged with scene dialog file whichmay have a different file name */
		static public const SCENE_FILE_NAME:String 	= "scene.xml";
		static public const DIALOG_FILE_NAME:String = "dialog.xml";
		static public const NPCS_FILE_NAME:String 	= "npcs.xml";
		static public const ITEMS_FILE_NAME:String 	= "items.xml";
		static public const SOUNDS_FILE_NAME:String = "sounds.xml";
		static public const PHOTOS_FILE_NAME:String = "photos.xml";
		static public const DOORS_FILE_NAME:String 	= "doors.xml";
		static public const HITS_FILE_NAME:String 	= "hits.xml";
	}
}
