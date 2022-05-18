package game.scenes.deepDive1.shared
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Sine;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.CameraLayerCreator;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.systems.PositionalAudioSystem;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Swarmer;
	import game.components.render.Light;
	import game.components.render.LightOverlay;
	import game.components.render.LightRange;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.data.item.SceneItemData;
	import game.data.scene.SceneParser;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.managers.EntityPool;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CollisionGroup;
	import game.scene.template.DoorGroup;
	import game.scene.template.GameScene;
	import game.scene.template.ItemGroup;
	import game.scene.template.PhotoGroup;
	import game.scene.template.SceneUIGroup;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.creators.SpawnFishCreator;
	import game.scenes.deepDive1.shared.groups.SubGroup;
	import game.scenes.deepDive1.shared.systems.FishMovementSystem;
	import game.scenes.deepDive1.shared.systems.SpawnSystem;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.scenes.deepDive2.shared.AtlantisMessageWindow;
	import game.systems.SystemPriorities;
	import game.systems.audio.HitAudioSystem;
	import game.systems.entity.SleepSystem;
	import game.systems.hit.ItemHitSystem;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.EdgeSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.render.LightRangeSystem;
	import game.systems.render.LightSystem;
	import game.systems.scene.SceneInteractionSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.ui.hud.Hud;
	import game.ui.popup.CharacterDialogWindow;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class SubScene extends Scene
	{
		public function SubScene()
		{
			super();
			_events = new DeepDive1Events();
			_events2 = new DeepDive2Events();
		}
		
		override public function destroy():void
		{			
			super.shellApi.eventTriggered.removeAll();
			this.uiLayer = null;
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
		
		/////////////////////////////////////////////////////////////////////////
		///////////////////////////// LOAD SEQUENCE ///////////////////////////// 
		/////////////////////////////////////////////////////////////////////////
		
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
			super.loadFiles(super.sceneData.assets, false, true, onAssetsLoaded);
		}
		
		private function onAssetsLoaded():void
		{
			var audioGroup:AudioGroup = addAudio();
			
			var cameraGroup:CameraGroup = new CameraGroup();
			cameraGroup.setupScene(this);
			
			var cameraLayerCreator:CameraLayerCreator = new CameraLayerCreator();
			this.uiLayer = new Sprite();
			this.uiLayer.name = 'uiLayer';
			super.addEntity(cameraLayerCreator.create(this.uiLayer, 1, "uiLayer"));
			super.groupContainer.addChild(this.uiLayer);
			
			// keep a reference to the hit layer so we can refer to it later when adding other entities.
			_hitContainer = Display(super.getEntityById("interactive").get(Display)).displayObject;
			addCollisions(audioGroup);
			addDoors(audioGroup);
			
			addItems();
			
			super.addSystem(new SceneInteractionSystem(), SystemPriorities.sceneInteraction);
			super.addSystem(new InteractionSystem(), SystemPriorities.update);
			super.addSystem(new HitAudioSystem(), SystemPriorities.updateSound);
			super.addSystem(new PositionalAudioSystem(), SystemPriorities.updateSound);
			super.addSystem(new TimelineClipSystem());
			super.addSystem(new TimelineControlSystem(), SystemPriorities.timelineControl);
			super.addSystem(new FollowTargetSystem(), SystemPriorities.move);
			super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			super.addSystem(new TweenSystem(), SystemPriorities.move);
			super.addSystem(new EdgeSystem() );
			
			// create Sub Group
			addSubGroup();
			addPhotos();
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
			var data:XML = SceneUtil.mergeSharedData(this, GameScene.HITS_FILE_NAME, SceneUtil.FILES_IGNORE);
			collisionGroup.setupScene(this, data, _hitContainer, audioGroup, this.showHits);
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
		
		protected function addItems():void
		{
			var itemGroup:ItemGroup = new ItemGroup();
			var itemData:XML = super.getData(GameScene.ITEMS_FILE_NAME, true);
			if( itemData != null )
			{
				itemGroup.setupScene(this, itemData, _hitContainer, null);
			}
			else
			{
				itemGroup.setupScene(this);
				itemGroup.addItemHitSystem();	//add ItemHitSystem regardless if items listed in xml ( in soem cases items are create in scene)
			}
		}
		
		protected function addSubGroup():void
		{
			var subGroup:SubGroup = new SubGroup();
			subGroup.setupGroup(this, _hitContainer, "player", SubScene.PLAYER_ID, onSubGroupLoaded, this.playerSubLook );
		}
		
		protected function onSubGroupLoaded():void
		{
			// keep reference to character within sub
			_playerDummy = getEntityById(SubScene.PLAYER_ID);
			
			// Make the player follow input (the mouse or touch input).
			MotionUtils.followInputEntity(super.shellApi.player, super.shellApi.inputEntity, true);
			
			// setup dialog, now that all entities have been created
			addCharacterDialog(this.uiLayer);	
			
			super.shellApi.defaultCursor = ToolTipType.TARGET;			
			createCharacterDialogWindow();
		}
		
		protected function addPhotos():void
		{
			var data:XML = super.getData(GameScene.PHOTOS_FILE_NAME, true);
			if (data != null) 
			{
				var photoGroup:PhotoGroup = new PhotoGroup()
				photoGroup.setupScene(this, data, _hitContainer);
				photoGroup.photoLook = this.playerSubLook;
			}
		}
		
		protected function addCharacterDialog(container:Sprite):void
		{
			// this group parses dialog.xml and adds dialog components to all entity id's referred to in the xml.  It also creates the dialogView for displaying word balloons.
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			var data:XML = SceneUtil.mergeSharedData(this, GameScene.DIALOG_FILE_NAME, SceneUtil.FILES_COMBINE);
			characterDialogGroup.setupGroup(this, data, container);
		}
		
		protected function createCharacterDialogWindow( asset:String = "dialog_window.swf", groupPrefix:String = "scenes/deepDive1/shared/"):void
		{
			_dialogWindow = new AtlantisMessageWindow(super.overlayContainer);
			_dialogWindow.config( null, null, false, false, false, false );
			_dialogWindow.configData( groupPrefix, asset, true, false );
			_dialogWindow.ready.addOnce(characterDialogWindowReady);
			_dialogWindow.messageComplete.add(messageCompleteHandler);
			super.addChildGroup(_dialogWindow);
		}
		
		protected function characterDialogWindowReady( dialogWindow:CharacterDialogWindow = null ):void
		{
			dialogWindow.screen.x = super.shellApi.viewportWidth/2 - dialogWindow.screen.width/2;
			dialogWindow.screen.y = 0;
			
			// adjust character
			dialogWindow.adjustChar( "cam", dialogWindow.screen.content.charContainer);
			
			// convert message background to bitmap
			super.convertToBitmap(dialogWindow.screen.content.background);
			
			// create transition
			var transitionIn:TransitionData = new TransitionData();
			transitionIn.duration = 0.3;
			transitionIn.startPos = new Point( dialogWindow.screen.x, super.shellApi.viewportHeight + dialogWindow.screen.height);
			transitionIn.endPos = new Point(dialogWindow.screen.x, super.shellApi.viewportHeight);
			transitionIn.ease = Back.easeOut;
			var transitionOut:TransitionData = transitionIn.duplicateSwitch(Sine.easeIn);
			transitionOut.duration = .3;
			dialogWindow.transitionIn = transitionIn;
			dialogWindow.transitionOut = transitionOut;
			
			if(_useHud) 
			{ 
				addUI(); 
			}
			else
			{
				updateCameraTarget();
			}
		}
		
		protected function addUI():void
		{			
			var dummyPlayer:Entity = getEntityById(PLAYER_ID);
			CharUtils.assignDialog(dummyPlayer, this, SubScene.PLAYER_ID, false, 0, .75, true);
			
			// this group creates all standard scene ui like the hud, inventory and costumizer.
			var sceneUIGroup:SceneUIGroup = new SceneUIGroup(super.overlayContainer, this.uiLayer);
			sceneUIGroup.ready.addOnce(uiLoaded);
			super.addChildGroup(sceneUIGroup);
		}
		
		private function uiLoaded(group:Group):void
		{
			updateCameraTarget();
		}
		
		private function updateCameraTarget():void
		{
			// Set the initial camera target.
			// NOTE :: Does this need to happen again?
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
		
		/////////////////////////////////////////////////////////////////////////
		///////////////////////////// HELPER METHODS //////////////////////////// 
		/////////////////////////////////////////////////////////////////////////
		
		public function lockControls(lock:Boolean):void
		{
			CharUtils.lockControls(super.shellApi.player, lock, lock);
			SceneUtil.lockInput(this, lock);
			if(lock) { MotionUtils.zeroMotion(super.shellApi.player); }
		}
		
		/**
		 * Play message in dropdown message window. 
		 * @param dialogId
		 * @param callback
		 * 
		 */
		public function playMessage( dialogId:String, callback:Function = null ):void
		{
			_dialogWindow.playMessage( dialogId, true, true );
			
			if(callback)
			{
				_dialogWindow.messageComplete.addOnce(callback);
			}
		}
		
		public function playStaticMessage(dialogId:String, callback:Function = null):void
		{
			_dialogWindow.playStaticMessage(dialogId);
			if(callback) 
				_dialogWindow.messageComplete.addOnce(callback);
		}
		
		/**
		 * This is to play the dialog with alien image and a mix of alien text and english text. 
		 * You need to format the xml using CDATA to place the text correctly. 
		 * Both textfields are the same size and positioned in the same place.
		 * 
		 * @param alienId - the id name of the dialog for the alien text part of the dialog
		 * @param englishId - the id name of the dialog for the Englidh text part of the dialog
		 * @param level - how much of the alien to show, the higher the number the more alien showed, 0-3 are legal
		 */
		public function playAlienMessage(alienId:String, englishId:String, level:int = 0, callback:Function = null):void
		{
			_dialogWindow.playAlienMessage(alienId, englishId, level);
			if(callback) 
				_dialogWindow.messageComplete.addOnce(callback);
		}
		
		public function playerSay( dialogId:String, callback:Function = null ):void
		{
			var dialog:Dialog = _playerDummy.get(Dialog);
			dialog.sayById( dialogId );
			
			if( callback != null )
			{
				dialog.complete.addOnce(callback);
			}
		}
		
		public function addSceneItem(item:String, x:Number, y:Number):void
		{
			var itemGroup:ItemGroup = super.getGroupById("itemGroup") as ItemGroup;
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
		
		/**
		 * Called when message window completes, available for override. 
		 */
		protected function messageCompleteHandler():void {}
		
		/////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////// LIGHTING METHODS //////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////
		
		public function addLight(entity:Entity, radius:Number = 200, darkAlpha:Number = .9, gradient:Boolean = true, useRange:Boolean = false, color:uint = 0x000099, shipColor:uint = 0x000000, lightAlpha:Number = 0, horizontalRange:Boolean = false, minRange:Number = NaN, maxRange:Number = NaN):Entity
		{
			var lightOverlayEntity:Entity = super.getEntityById("lightOverlay");
			
			if(lightOverlayEntity == null)
			{
				super.addSystem(new LightSystem());
				
				var lightOverlay:Sprite = new Sprite();
				super.overlayContainer.addChildAt(lightOverlay, 0);
				lightOverlay.mouseEnabled = false;
				lightOverlay.mouseChildren = false;
				lightOverlay.graphics.clear();
				lightOverlay.graphics.beginFill(color, darkAlpha);
				lightOverlay.graphics.drawRect(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
				
				var display:Display = new Display(lightOverlay);
				display.isStatic = true;
				
				lightOverlayEntity = new Entity();
				lightOverlayEntity.add(new Spatial());
				lightOverlayEntity.add(display);
				lightOverlayEntity.add(new Id("lightOverlay"));
				lightOverlayEntity.add(new LightOverlay(darkAlpha, color));
				
				super.addEntity(lightOverlayEntity);
				
				if(useRange)
				{
					super.addSystem(new LightRangeSystem());
					
					if(isNaN(minRange))
					{
						minRange = 0;
					}
					
					if(isNaN(maxRange))
					{
						if(horizontalRange)
						{
							maxRange = super.sceneData.cameraLimits.right;
						}
						else
						{
							maxRange = super.sceneData.cameraLimits.bottom;
						}
					}
					
					entity.add(new LightRange(minRange, maxRange, radius, darkAlpha, lightAlpha, horizontalRange));
				}
			}
			
			if(useRange)
			{
				darkAlpha *= 2;
				radius *= 2;
				lightAlpha *= 2;
			}
			
			entity.add(new Light(radius, darkAlpha, lightAlpha, gradient, shipColor, color));
			
			return lightOverlayEntity;
		}
		
		/////////////////////////////////////////////////////////////////////////
		////////////////////////////// FISH METHODS ///////////////////////////// 
		/////////////////////////////////////////////////////////////////////////
		
		/**
		 * Add classes necessary for spawning fish.
		 */
		protected function addSpawnFish(newContainer:DisplayObjectContainer = null):void
		{
			_fishPool = new EntityPool();
			if(newContainer){
				_fishCreator = new SpawnFishCreator(this, newContainer, _fishPool);
			}else{
				_fishCreator = new SpawnFishCreator(this, container, _fishPool);
			}
			_fishCreator.target = super.shellApi.player.get(Spatial);
			this.addSystem(new SpawnSystem(_fishCreator), SystemPriorities.lowest);
			this.addSystem(new FishMovementSystem(_fishCreator), SystemPriorities.moveComplete);
		}
		
		/**
		 * 
		 * @param count - the amount of fish you want to create
		 * @param maxSpeed - the max velocity of the fish (will apply same number to x and y velocities)
		 * @param location - the starting location of these fish
		 * @param swarmer - only add if you want to the fish to be apart of the swarm right away, add component later if you don't
		 * @param handler - returns Vector.&lt;Entity&gt; of fish once all are finished loading
		 * 
		 */
		protected function loadSchoolFish( count:Number, maxSpeed:Number, location:Point, assetPath:String = "scenes/deepDive1/shared/fish/schoolFish.swf", swarmer:Swarmer = null, handler:Function = null):void
		{
			_totalSchoolFish = count;
			this.shellApi.loadFile(this.shellApi.assetPrefix + assetPath, Command.create(schoolFishLoaded,  maxSpeed, location, swarmer, handler));				
		}
		
		private function schoolFishLoaded(clip:MovieClip, maxSpeed:Number, location:Point, swarmer:Swarmer, handler:Function):void
		{
			var entities:Vector.<Entity> = new Vector.<Entity>();
			var bmd:BitmapData = BitmapUtils.createBitmapData(clip);
			
			for(var i:int = 0; i < _totalSchoolFish; i++)
			{
				var entity:Entity = new Entity();
				this.addEntity(entity);
				
				var sprite:Sprite = BitmapUtils.createBitmapSprite(clip, 1, null, true, 0, bmd);
				entity.add( new Display(sprite, _hitContainer) );
				entity.add( new Spatial(location.x, location.y) );
				entity.add( new Tween() );  // not letting me add :(
				
				var motion:Motion = new Motion();
				motion.maxVelocity = new Point(maxSpeed, maxSpeed);
				motion.velocity = new Point(-10, 10);
				motion.acceleration = new Point();
				entity.add(motion);
				if(swarmer != null)
					entity.add(swarmer);
				
				entities.push(entity);
			}
			
			if(handler != null)
				handler(entities);
		}
		
		/**
		 * Makes fish susceptible to filming by sub camera. 
		 * @param entity - Entity to make filmable
		 * @param handler - Function called to notify scene of filmable state, see examples inShipUnderside for example
		 * @param filmDistance - x distance sub will try to position itself from Entity when filming
		 * @param filmDuration - amount of time necessary to successfully film Entity
		 * @param isFilmable - how isFilmable flag is set on creation
		 * @return  
		 */
		public function makeFilmable( entity:Entity, handler:Function = null, filmDistance:int = 300, filmDuration:Number = 4, isFilmable:Boolean = false, hasIntro:Boolean = false, isCaptured:Boolean = false ):Entity
		{
			entity.add(new Sleep(false, true));
			
			var filmable:Filmable = new Filmable( filmDuration, isFilmable );
			filmable.stateSignal.add( handler );
			filmable.hasIntro = hasIntro;
			filmable.captured = isCaptured;
			entity.add( filmable );
			
			var interaction:Interaction = InteractionCreator.addToEntity( entity, [InteractionCreator.UP] );
			interaction.up.add( filmable.onPress );
			
			if(filmDistance > 0){
				
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.offsetX = filmDistance;
				sceneInteraction.ignorePlatformTarget = false;
				sceneInteraction.offsetDirection = true;
				sceneInteraction.approach = false;
				//sceneInteraction.motionToZero = new <String> [ "x", "y" ];
				entity.add( sceneInteraction );
			}
			
			ToolTipCreator.addToEntity( entity );
			
			return entity;
		}
		
		public function removeFilmable( entity:Entity ):void
		{
			entity.remove(Filmable);
			entity.remove(Interaction);
			entity.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity(entity);
		}
		
		/**
		 * Shows the fish file item, calls handler once item has finished showing. 
		 * @param onCompleteHandler
		 * 
		 */
		public function logFish( fishId:String, onCompleteHandler:Function = null ):void
		{
			if(super.shellApi.island == "deepDive2"){
				// check if you have glyph files, if not add it to inventory
				if(!super.shellApi.checkHasItem("glyph_files")){
					shellApi.getItem("glyph_files");
				}
				
				// trigger event - (Do not add to inventory, as they are shown in the popup)
				shellApi.completeEvent(fishId);
			}
			
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( itemGroup == null )
			{
				itemGroup = new ItemGroup();
				itemGroup.setupScene( this );
			}
			itemGroup.showItem( fishId, super.shellApi.island, null, onCompleteHandler );
		}
		
		/////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////// PUZZLE PIECE METHODS ///////////////////////////
		/////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Used specifically to setup puzzle piece items.
		 * Since all pieces are part of the same card item special handling is necessary.
		 * @param displayObject
		 * @param event
		 * @return 
		 * 
		 */
		public function setupPuzzlePiece( displayObject:DisplayObjectContainer, event:String ):Entity
		{
			if(!super.shellApi.checkEvent( event ))
			{
				var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
				var entity:Entity = itemGroup.addSceneItemFromDisplay( displayObject, event );
				
				// TODO really only want to do this once... Bard
				var itemHitSystem:ItemHitSystem = super.getSystem(ItemHitSystem) as ItemHitSystem;
				itemHitSystem.gotItem.removeAll();
				itemHitSystem.gotItem.add( gotPuzzlePiece );
				
				return entity;
			} 
			else 
			{
				displayObject.parent.removeChild( displayObject );
				return null;
			}
		}
		
		private function gotPuzzlePiece( itemId:Entity ):void
		{	
			if(!super.shellApi.checkHasItem(_events2.PUZZLE_KEY)){
				super.shellApi.getItem(_events2.PUZZLE_KEY);
			}
			
			super.shellApi.triggerEvent( itemId.get(Id).id, true ); // for completion sound
			super.shellApi.completeEvent( itemId.get(Id).id ); // for completion sound
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.showItem(_events2.PUZZLE_KEY, super.shellApi.island);
		}

		/////////////////////////////////////////////////////////////////////////
		////////////////////////// TRIGGER DOOR METHODS ///////////////////////// 
		/////////////////////////////////////////////////////////////////////////
		
		/**
		 * Defines the look of the player within the sub.
		 * If a scene wants to vary the look of the player on creation they can override this function. 
		 * @return 
		 */
		protected function createPlayerSubLook():LookData
		{
			var playerLook:PlayerLook = shellApi.profileManager.active.look;
			var lookData:LookData = ( playerLook != null ) ? new LookConverter().lookDataFromPlayerLook(shellApi.profileManager.active.look) : new LookData();			
			lookData.setValue( SkinUtils.FACIAL, "lc_mic2" );
			lookData.setValue( SkinUtils.MARKS, "dd_wetsuit2" );
			lookData.setValue( SkinUtils.PANTS, "dd_diver" );
			lookData.setValue( SkinUtils.OVERSHIRT, "dd_diver" );
			lookData.setValue( SkinUtils.OVERPANTS, "empty" );
			lookData.setValue( SkinUtils.HAIR, "empty" );
			lookData.setValue( SkinUtils.SHIRT, "empty" );
			lookData.setValue( SkinUtils.HAIR, "empty" );
			lookData.setValue( SkinUtils.ITEM, "empty" );

			return lookData;
		}

		private const CHARACTER_TEXT:TextFormat = new TextFormat( "CreativeBlock BB", 16, 0xffffff, false, false, null, null, null, "left", null, 10, null, 0 );
		public static const PLAYER_ID:String = "dummyPlayer";
		
		public var uiLayer:Sprite;
		
		protected var showHits:Boolean = false;
		protected var _events:DeepDive1Events;
		protected var _events2:DeepDive2Events;
		protected var _hitContainer:DisplayObjectContainer;
		protected var _dialogWindow:AtlantisMessageWindow;
		protected var _useHud:Boolean = true;
		
		protected var _playerDummy:Entity;
		public function get playerDummy():Entity	{ return _playerDummy; }
		
		private var _playerSubLook:LookData;
		private function get playerSubLook():LookData
		{
			if( _playerSubLook == null )
			{
				_playerSubLook = createPlayerSubLook();
			}
			return _playerSubLook;
		}
		
		// fish
		private var _totalSchoolFish:Number = 0;
		private var _fishCreator:SpawnFishCreator;
		public function get fishCreator():SpawnFishCreator { return(_fishCreator); }
		public function get hitContainer():DisplayObjectContainer { return(_hitContainer); }
		private var _fishPool:EntityPool;
		public var initialScale:Number = 1;
		
	}
}
