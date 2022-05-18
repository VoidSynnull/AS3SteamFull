package game.scenes.virusHunter.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.systems.CameraZoomSystem;
	import engine.systems.PositionalAudioSystem;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.data.TimedEvent;
	import game.data.item.SceneItemData;
	import game.data.scene.SceneParser;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.CollisionGroup;
	import game.scene.template.DoorGroup;
	import game.scene.template.GameScene;
	import game.scene.template.ItemGroup;
	import game.scene.template.PhotoGroup;
	import game.scene.template.SceneUIGroup;
	import game.scenes.virusHunter.shared.components.WeaponControlInput;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.systems.PickupSystem;
	import game.scenes.virusHunter.shared.ui.ShipDialogWindow;
	import game.systems.SystemPriorities;
	import game.systems.audio.HitAudioSystem;
	import game.systems.entity.SleepSystem;
	import game.systems.hit.ItemHitSystem;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.scene.SceneInteractionSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.ui.hud.Hud;
	import game.ui.popup.CharacterDialogWindow;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	public class ShipScene extends Scene
	{
		public function ShipScene()
		{
			super();
		}
		
		override public function destroy():void
		{			
			super.shellApi.eventTriggered.removeAll();
			
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.init(container);
			load();
		}
		
		// initiate asset load of scene configuration.
		override public function load():void
		{
			super.loadFiles([GameScene.SCENE_FILE_NAME], false, true, parseSceneData);
		}
		
		override public function loaded():void
		{
			// remove all special abilities
			this.removeSystemByClass(SpecialAbilityControlSystem);
			
			// disable costumizer
			(super.getGroupById( Hud.GROUP_ID ) as Hud).disableButton( Hud.COSTUMIZER );
			super.loaded();
		}
		
		// all assets ready
		private function setupShipGroup():void
		{
			var audioGroup:AudioGroup = addAudio();
			
			addCamera();
			
			addCollisions(audioGroup);
			
			addDoors(audioGroup);
			
			var itemHitSystem:ItemHitSystem = new ItemHitSystem();
			super.addSystem(itemHitSystem, SystemPriorities.resolveCollisions);
			itemHitSystem.gotItem.add(gotItem);
			
			addItems();
			addPhotos();
			
			var shipGroup:ShipGroup = new ShipGroup(null);
			shipGroup.setupScene(this, _hitContainer, allShipsLoaded, audioGroup);
			shipGroup.loadShip(super.shellApi.profileManager.active.lastX, super.shellApi.profileManager.active.lastY, true, "player");
			
			super.addSystem(new SceneInteractionSystem(), SystemPriorities.sceneInteraction);
			super.addSystem(new InteractionSystem(), SystemPriorities.update);
			super.addSystem(new HitAudioSystem(), SystemPriorities.updateSound);
			super.addSystem(new PositionalAudioSystem(), SystemPriorities.updateSound);
			super.addSystem(new TimelineClipSystem());
			super.addSystem(new TimelineControlSystem(), SystemPriorities.timelineControl);
			super.addSystem(new FollowTargetSystem(), SystemPriorities.move);
			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			super.addSystem(new PickupSystem(this, shipGroup.shipCreator), SystemPriorities.checkCollisions);
			super.addSystem(new TweenSystem(), SystemPriorities.move);
		}
		
		protected function addCamera():void
		{
			var cameraGroup:CameraGroup = new CameraGroup();
			cameraGroup.setupScene(this, this.initialScale);
			// keep a reference to the hit layer so we can refer to it later when adding other entities.
			_hitContainer = Display(super.getEntityById("interactive").get(Display)).displayObject;
		}
		
		protected function addCollisions(audioGroup:AudioGroup):void
		{
			var collisionGroup:CollisionGroup = new CollisionGroup();
			var data:XML = SceneUtil.mergeSharedData(this, GameScene.HITS_FILE_NAME, SceneUtil.FILES_IGNORE);
			
			collisionGroup.setupScene(this, data, _hitContainer, audioGroup, this.showHits);
		}
		
		protected function addUI():void
		{
			// this group creates all standard scene ui like the hud, inventory and costumizer.
			var sceneUIGroup:SceneUIGroup = new SceneUIGroup(super.overlayContainer);
			sceneUIGroup.ready.addOnce(uiLoaded);
			super.addChildGroup(sceneUIGroup);
		}
		
		public function gotItem(item:Entity):void
		{
			var itemID:String = item.get(Id).id;
			var shipGroup:ShipGroup = super.getGroupById(ShipGroup.GROUP_ID) as ShipGroup;
			var cameraZoom:CameraZoomSystem = super.getSystem(CameraZoomSystem) as CameraZoomSystem;
			cameraZoom.scaleTarget = 1.5;  // camera will zoom into 1.5x scale.
			
			lockControls(true);
			
			if(itemID != WeaponType.SHIELD && itemID != WeaponType.ANTIGRAV)
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, showWeapons));
				if(!super.shellApi.checkEvent("got_" + itemID))
				{
					shipGroup.addWeapon(super.shellApi.player, itemID);
				}
			}
			else
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, Command.create(delayedAddWeapon, itemID)));
			}
			
			super.shellApi.completeEvent("got_" + itemID);
			playMessage( itemID + "_online", false, itemID + "_online" );
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, restoreZoom));
		}
		
		private function delayedAddWeapon(weapon:String):void
		{
			var shipGroup:ShipGroup = super.getGroupById(ShipGroup.GROUP_ID) as ShipGroup;
			shipGroup.addWeapon(super.shellApi.player, weapon);
		}
		
		private function showWeapons():void
		{
			var weaponControlInput:WeaponControlInput = super.shellApi.player.get(WeaponControlInput);
			weaponControlInput.triggerWeaponSelection = true;
		}
		
		private function restoreZoom():void
		{
			var cameraZoom:CameraZoomSystem = super.getSystem(CameraZoomSystem) as CameraZoomSystem;
			cameraZoom.scaleTarget = 1;  // camera will zoom into 1.5x scale.
			
			lockControls(false);
		}
		
		public function lockControls(lock:Boolean):void
		{
			CharUtils.lockControls(super.shellApi.player, lock, lock);
			SceneUtil.lockInput(this, lock);
			if(lock) { MotionUtils.zeroMotion(super.shellApi.player); }
		}
		
		public function addSceneItem(item:String, x:Number, y:Number):void
		{
			var itemGroup:ItemGroup = super.getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			if(!itemGroup)
			{
				itemGroup = new ItemGroup();
				itemGroup.setupScene(this, null, _hitContainer);
			}
			
			var itemData:SceneItemData = new SceneItemData();
			itemData.id = item;
			itemData.asset = item + ".swf";
			itemData.x = x;
			itemData.y = y;
			
			itemGroup.addSceneItemByData(itemData, true);
		}
		
		public function playMessage(id:String, useCharacter:Boolean = true, graphicsFrame:String = null, characterId:String = "drLang", callback:Function = null):void
		{
			if(graphicsFrame == null)
			{
				graphicsFrame = id;
			}
			
			_dialogWindow.playShipMessage(id, useCharacter, graphicsFrame, characterId);

			if(callback)
			{
				_dialogWindow.messageComplete.addOnce(callback);
			}
		}
		
		protected function addItems():void
		{
			var itemGroup:ItemGroup = new ItemGroup();
			var itemData:XML = super.getData(GameScene.ITEMS_FILE_NAME, true);
			if( itemData != null )
			{
				itemGroup.setupScene(this, super.getData(GameScene.ITEMS_FILE_NAME, true), _hitContainer);
			}
		}
		
		protected function addPhotos():void
		{
			var data:XML = super.getData(GameScene.PHOTOS_FILE_NAME, true);
			trace(shellApi.sceneName, "ShipScene::addPhotos(): data is", data);
			if(data != null)
			{
				var photoGroup:PhotoGroup = new PhotoGroup();
				photoGroup.setupScene(this, data, _hitContainer);
			}
		}
		
		protected function parseSceneData():void
		{
			var parser:SceneParser = new SceneParser();
			var sceneXml:XML = super.getData(GameScene.SCENE_FILE_NAME);
			super.sceneData = parser.parse(sceneXml);	
			
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
			super.loadFiles(super.sceneData.data, false, true, loadAssets);
		}
		
		protected function loadAssets():void
		{		
			super.loadFiles(super.sceneData.assets, false, true, setupShipGroup);
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
		
		protected function allShipsLoaded():void
		{
			super.shellApi.player = super.getEntityById("player");
			
			// Make the player follow input (the mouse or touch input).
			MotionUtils.followInputEntity(super.shellApi.player, super.shellApi.inputEntity, true);
			
			super.shellApi.defaultCursor = ToolTipType.TARGET;
			
			createCharacterDialogWindow();
		}
		
		protected function createCharacterDialogWindow(asset:String = "dialogWindow.swf", groupPrefix:String = "scenes/virusHunter/shared/"):void
		{
			_dialogWindow = new ShipDialogWindow(super.overlayContainer);
			_dialogWindow.config( null, null, false, false, false, false );
			_dialogWindow.configData( groupPrefix, asset );
			_dialogWindow.ready.addOnce(characterDialogWindowReady);
			_dialogWindow.messageComplete.add(messageCompleteHandler);
			
			super.addChildGroup(_dialogWindow);
		}
		
		protected function messageCompleteHandler():void
		{
			
		}
		
		protected function characterDialogWindowReady(charDialog:CharacterDialogWindow):void
		{
			/*
			var transitionData:TransitionData = new TransitionData();
			var xPos:int = super.shellApi.viewportWidth/2 - charDialog.screen.width/2;
			transitionData.init( xPos, -150, xPos, 50, Strong.easeOut, 0, 1 );
			charDialog.transitionIn = transitionData;
			charDialog.transitionOut = transitionData.duplicateSwitch( Strong.easeOut );
			*/
			charDialog.screen.x = super.shellApi.viewportWidth/2 - charDialog.screen.width/2;
			// adjust character
			charDialog.adjustChar( "player", charDialog.screen.shipText, new Point(20, 45), .5 );
			
			if(super.shellApi.profileManager.active.look)
			{
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.EYES, super.shellApi.profileManager.active.look.eyes );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.SKIN_COLOR, super.shellApi.profileManager.active.look.skinColor );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.MOUTH, super.shellApi.profileManager.active.look.mouth );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.EYE_STATE, super.shellApi.profileManager.active.look.eyeState );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.MARKS, super.shellApi.profileManager.active.look.marks );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.FACIAL, super.shellApi.profileManager.active.look.facial );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.HAIR, super.shellApi.profileManager.active.look.hair );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.HAIR_COLOR, super.shellApi.profileManager.active.look.hairColor );
			}
			
			charDialog.adjustChar( "drLang", charDialog.screen.shipText, new Point(20, 45), .5 );
			// assign textfield
			charDialog.textField = TextUtils.refreshText( charDialog.screen.shipText.text );	
			charDialog.textField.embedFonts = true;
			
			charDialog.textField.defaultTextFormat = new TextFormat("CreativeBlock BB", 16, 0xffffff);
			_bodyMap = TimelineUtils.convertClip( MovieClip( charDialog.screen.shipText.bodyMap ), this );
			
			if(_useHud) 
			{ 
				addUI(); 
			}
			else
			{
				updateCameraTarget();
			}
		}
		
		private function updateCameraTarget():void
		{
			// use the target entity's motion to set the zoom level.
			//_cameraGroup.setZoomTarget(super.shellApi.player.get(Motion), 1.25, minCameraScale);
			
			// Set the initial camera target.
			var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			cameraGroup.setTarget(super.shellApi.player.get(Spatial), true);
			
			// This triggers the 'ready' signal in the superclass 'DisplayGroup' that shows this scene.
			cameraGroup.ready.addOnce(cameraReady);
		}
		
		private function cameraReady(...args):void
		{
			var sleep:SleepSystem = new SleepSystem();
			sleep.awakeArea = super.shellApi.camera.viewport;                           // for entities that sleep but don't have a display component to hittest against
			sleep.visibleArea = super.shellApi.backgroundContainer;                     // for entities that have a display component to be used with hitTestObject.
			super.addSystem(sleep, SystemPriorities.update);
			
			loaded();
		}
		
		private function uiLoaded(group:Group):void
		{
			updateCameraTarget();
		}
		
		protected var _hitContainer:DisplayObjectContainer;
		protected var minCameraScale:Number = 1;
		protected var initialScale:Number = 1;
		protected var showHits:Boolean = false;
		protected var _dialogWindow:ShipDialogWindow;
		protected var _bodyMap:Entity;
		protected var _useHud:Boolean = true;
	}
}