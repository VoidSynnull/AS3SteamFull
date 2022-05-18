package game.scenes.backlot.backlotTopDown
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.systems.PositionalAudioSystem;
	import engine.systems.TweenSystem;
	
	import game.data.scene.SceneParser;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.CollisionGroup;
	import game.scene.template.DoorGroup;
	import game.scene.template.GameScene;
	import game.scene.template.ItemGroup;
	import game.scene.template.SceneUIGroup;
	import game.scenes.virusHunter.shared.ui.ShipDialogWindow;
	import game.systems.SystemPriorities;
	import game.systems.audio.HitAudioSystem;
	import game.systems.entity.SleepSystem;
	import game.systems.hit.ItemHitSystem;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.scene.SceneInteractionSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	public class CartScene extends Scene
	{
		public function CartScene()
		{
			super();
		}
		
		override public function destroy():void
		{			
			super.shellApi.fileLoadComplete.remove(loaded);
			super.shellApi.eventTriggered.removeAll();
			
			super.destroy();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.init(container);
			load();
		}
		
		// initiate asset load of scene configuration.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(parseSceneData);
			super.loadFiles([GameScene.SCENE_FILE_NAME]);
		}
		
		override public function loaded():void
		{
			super.loaded();
		}
		
		protected function addUI():void
		{
			// this group creates all standard scene ui like the hud, inventory and costumizer.
			super.addChildGroup(new SceneUIGroup(super.overlayContainer));
		}
		
		protected function gotItem(item:Entity):void
		{
			
		}
		
		protected function addItems():void
		{
			var itemGroup:ItemGroup = new ItemGroup();
			itemGroup.setupScene( this, super.getData( GameScene.ITEMS_FILE_NAME, true ), _hitContainer );
		}
		
		protected function parseSceneData():void
		{
			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData( GameScene.SCENE_FILE_NAME );
			super.sceneData = parser.parse( sceneXml );	
			
			if (isNaN(super.shellApi.profileManager.active.lastX) || isNaN(super.shellApi.profileManager.active.lastY))
			{
				super.shellApi.profileManager.active.lastX = super.sceneData.startPosition.x;
				super.shellApi.profileManager.active.lastY = super.sceneData.startPosition.y;
				super.shellApi.profileManager.active.lastDirection = super.sceneData.startDirection;
			}
			
			if(super.sceneData.absoluteFilePaths.length > 0)
			{
				super.shellApi.fileLoadComplete.addOnce(loadData);
				super.loadFiles(super.sceneData.absoluteFilePaths, true, super.sceneData.prependTypePath);
			}
			else
			{
				loadData();
			}
		}
		
		protected function loadData():void
		{
			super.shellApi.fileLoadComplete.addOnce( loadAssets );
			super.loadFiles( super.sceneData.data );
		}
		
		protected function loadAssets():void
		{		
			super.shellApi.fileLoadComplete.addOnce( setupCarGroup );
			super.loadFiles( super.sceneData.assets );
		}
		
		private function setupCarGroup():void
		{
			var audioGroup:AudioGroup = addAudio();
			
			var cameraGroup:CameraGroup = new CameraGroup();
			cameraGroup.setupScene(this, minCameraScale);
			
			// keep a reference to the hit layer so we can refer to it later when adding other entities.
			_hitContainer = Display(super.getEntityById("interactive").get(Display)).displayObject;
			
			addCollisions(audioGroup);
			
			addDoors(audioGroup);
			
			var itemHitSystem:ItemHitSystem = new ItemHitSystem();
			super.addSystem(itemHitSystem, SystemPriorities.resolveCollisions);
			itemHitSystem.gotItem.add(gotItem);
			
			addItems();
			
			var cartGroup:CartGroup = new CartGroup( null );
			cartGroup.setupScene( this, _hitContainer, allShipsLoaded, audioGroup );
			cartGroup.loadCart( super.shellApi.profileManager.active.lastX, super.shellApi.profileManager.active.lastY, true, "player" );
			
			super.addSystem(new SceneInteractionSystem(), SystemPriorities.sceneInteraction);
			super.addSystem(new InteractionSystem(), SystemPriorities.update);
			super.addSystem(new HitAudioSystem(), SystemPriorities.updateSound);
			super.addSystem(new PositionalAudioSystem(), SystemPriorities.updateSound);
			super.addSystem(new TimelineClipSystem());
			super.addSystem(new TimelineControlSystem(), SystemPriorities.timelineControl);
			super.addSystem(new FollowTargetSystem(), SystemPriorities.move);
			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			//			super.addSystem(new PickupSystem(this, carGroup.shipCreator), SystemPriorities.checkCollisions);
			super.addSystem(new TweenSystem(), SystemPriorities.move);
			
			var sleep:SleepSystem = new SleepSystem();
			sleep.awakeArea = super.shellApi.camera.viewport;                           // for entities that sleep but don't have a display component to hittest against
			sleep.visibleArea = super.shellApi.backgroundContainer;                     // for entities that have a display component to be used with hitTestObject.
			super.addSystem(sleep, SystemPriorities.update);
		}
		
		protected function addAudio():AudioGroup
		{
			var audioGroup:AudioGroup;
			var data:XML = SceneUtil.mergeSharedData(this, GameScene.SOUNDS_FILE_NAME, SceneUtil.FILES_COMBINE);
			
			if(data != null)
			{
				audioGroup = new AudioGroup();
				audioGroup.setupGroup(this, data);
			}
			
			return(audioGroup);
		}
		
		protected function addCollisions(audioGroup:AudioGroup):void
		{
			var collisionGroup:CollisionGroup = new CollisionGroup();
			var data:XML = SceneUtil.mergeSharedData( this, GameScene.HITS_FILE_NAME, SceneUtil.FILES_IGNORE );
			
			collisionGroup.setupScene( this, data, _hitContainer, audioGroup, this.showHits );
		}
		
		protected function addDoors(audioGroup:AudioGroup):void
		{
			// create items and doors from xml files specified in scene.xml if they exist.
			if(super.getData(GameScene.DOORS_FILE_NAME) != null)
			{
				var doorGroup:DoorGroup = new shellApi.islandManager.doorGroupClass();
				doorGroup.setupScene(this, super.getData(GameScene.DOORS_FILE_NAME), _hitContainer, audioGroup);
			}
		}
		
		protected function allShipsLoaded():void
		{
			super.shellApi.player = super.getEntityById("player");
			
			// use the target entity's motion to set the zoom level.
			//_cameraGroup.setZoomTarget(super.shellApi.player.get(Motion), 1.25, minCameraScale);
			
			// Set the initial camera target.
			var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			cameraGroup.setTarget(super.shellApi.player.get(Spatial), true);
			
			// Make the player follow input (the mouse or touch input).
			MotionUtils.followInputEntity(super.shellApi.player, super.shellApi.inputEntity);
			
			super.shellApi.defaultCursor = ToolTipType.TARGET;
			
			//			createCharacterDialogWindow();
			loaded();
		}
		
		
		protected var _hitContainer:DisplayObjectContainer;
		protected var minCameraScale:Number = 1;
		protected var showHits:Boolean = false;
		protected var _dialogWindow:ShipDialogWindow;
		protected var _bodyMap:Entity;
		protected var _useHud:Boolean = true;
	}
}