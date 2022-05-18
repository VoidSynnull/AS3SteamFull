package game.scenes.arab1.desertScope
{
	import com.greensock.easing.Cubic;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Platform;
	import game.components.input.Input;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.render.DynamicWire;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.RunNinja;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.StandNinja;
	import game.data.animation.entity.character.Think;
	import game.data.animation.entity.character.Throw;
	import game.data.animation.entity.character.WalkNinja;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.arab1.Arab1Events;
	import game.scenes.arab1.bazaar.Bazaar;
	import game.scenes.arab1.desert.particles.SandStorm;
	import game.scenes.arab1.desert.particles.WaterChurn;
	import game.scenes.arab1.desertScope.components.WatchThief;
	import game.scenes.arab1.desertScope.systems.WatchThiefSystem;
	import game.scenes.arab1.shared.components.Camel;
	import game.scenes.arab1.shared.creators.CamelCreator;
	import game.scenes.arab1.shared.groups.SmokeBombGroup;
	import game.systems.SystemPriorities;
	import game.systems.TimerSystem;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.touch.StandState;
	import game.systems.motion.DestinationSystem;
	import game.systems.ui.NavigationArrowSystem;
	import game.systems.ui.TextDisplaySystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class DesertScope extends GameScene
	{
		public function DesertScope()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab1/desertScope/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			
			super.addSystem(new DestinationSystem(), SystemPriorities.update);
			super.addSystem(new TextDisplaySystem(), SystemPriorities.update);
			super.addSystem(new NavigationArrowSystem(), SystemPriorities.update);
			super.addSystem(new TimerSystem(), SystemPriorities.update);
		}
		
		override protected function addGroups():void
		{
			// This group holds a reference to the parsed sound.xml data and can be used to setup an entity with its sound assets if they are defined for it in the xml.
			var audioGroup:AudioGroup = addAudio();
			
			addCamera();
			addCollisions(audioGroup);
			addCharacters();
			addCharacterDialog(this.uiLayer);
			//addUI(this.uiLayer);
			addDoors(audioGroup);
			addItems();
			addPhotos();
			addBaseSystems();
		}
		
		private function setupFlags():void
		{
			BitmapUtils.convertContainer(_hitContainer["flag1"], PerformanceUtils.defaultBitmapQuality);
			BitmapUtils.convertContainer(_hitContainer["flag2"], PerformanceUtils.defaultBitmapQuality);
			_flag1 = TimelineUtils.convertClip(_hitContainer["flag1"], this);
			_flag2 = TimelineUtils.convertClip(_hitContainer["flag2"], this);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_events = new Arab1Events;
			
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.TARGET;
			
			_smokeBombGroup = this.addChildGroup(new SmokeBombGroup(this, this._hitContainer)) as SmokeBombGroup;
			
			setupFlags();
			setupParticles();
			setupScope();
			setupMovement();
			setupEntrance();
			setupNPCs();
			setupDias();
			setupCamel();
			setupCloseButton();
			setupSmokeBomb();
			hidePlayer();
			
		}
		
		private function setupSmokeBomb():void
		{
			if(!shellApi.checkHasItem(_events.SMOKE_BOMB)){
				_bomb = TimelineUtils.convertClip(_hitContainer["smokeBomb"], this, null, null, false);
				if(shellApi.checkEvent(_events.SMOKE_BOMB_LEFT)){
					Timeline(_bomb.get(Timeline)).gotoAndStop("end");
				}
			} else {
				_hitContainer["smokeBomb"].visible = false;
			}
		}
		
		private function setupCamel():void
		{
			if(shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				_camelCreator = new CamelCreator(this, _hitContainer);
				_camelCreator.create(new Point(810, 590), null, 120, camelCreated);
			}
		}
		
		private function camelCreated($entity:Entity):void{
			_camel = $entity;
			CharUtils.setScale(_camel, 0.63);
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(_camel), EntityUtils.getDisplayObject(_merchant), false);
			
			Camel(_camel.get(Camel)).walkSpeed = 10;
			
			var edge:Edge = _camel.get(Edge);
			edge.unscaled.bottom += 33;
		}
		
		private function setupCloseButton():void
		{
			ButtonCreator.loadCloseButton(this, this.overlayContainer, onClose);
		}
		
		private function onClose(...p):void{
			this.shellApi.loadScene( Bazaar, 3200 , 425, "right");
		}
		
		private function setupDias():void
		{
			_dias = EntityUtils.createSpatialEntity(this, _hitContainer["dias"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["dias"], this, _dias);
			
			switch(true){
				case shellApi.checkEvent(_events.GRAIN_ON_DIAS) :
					Timeline(_dias.get(Timeline)).gotoAndStop(_events.GRAIN);
					_placedItem = _events.GRAIN;
					break;
				case shellApi.checkEvent(_events.SALT_ON_DIAS) :
					Timeline(_dias.get(Timeline)).gotoAndStop(_events.SALT);
					_placedItem = _events.SALT;
					break;
				case shellApi.checkEvent(_events.CLOTH_ON_DIAS) :
					Timeline(_dias.get(Timeline)).gotoAndStop(_events.CLOTH);
					_placedItem = _events.CLOTH;
					break;
			}
			
		}
		
		private function hidePlayer():void
		{
			// removing the player from the scene XML was causing problems when you load in from another scene
			//this.removeEntity(player);  // thus we remove it in code
			CharUtils.lockControls(player);
			Display(player.get(Display)).visible = false;
		}
		
		private function setupNPCs():void
		{
			_merchant = this.getEntityById("brokeMerchant");
			_thief1 = this.getEntityById("thief1");
			_thief2 = this.getEntityById("thief2");
			_thief3 = this.getEntityById("thief3");
			_thief4 = this.getEntityById("thief4");
			
			/* this can all be done through xml 
			
			CharUtils.setScale(_merchant, 0.26);
			CharUtils.setScale(_thief1, 0.26);
			CharUtils.setScale(_thief2, 0.26);
			CharUtils.setScale(_thief3, 0.26);
			CharUtils.setScale(_thief4, 0.26);
			
			*/
			//should remove interactions and sceneinteractions
			
			EntityUtils.removeInteraction(_merchant);
			EntityUtils.removeInteraction(_thief1);
			EntityUtils.removeInteraction(_thief2);
			EntityUtils.removeInteraction(_thief3);
			EntityUtils.removeInteraction(_thief4);
			
			CharacterGroup(this.getGroupById("characterGroup")).addFSM( _thief1 );
			CharacterGroup(this.getGroupById("characterGroup")).addFSM( _thief2 );
			CharacterGroup(this.getGroupById("characterGroup")).addFSM( _thief3 );
			CharacterGroup(this.getGroupById("characterGroup")).addFSM( _thief4 );
			
			( ( _thief1.get(FSMControl) as FSMControl ).getState( CharacterState.STAND ) as StandState ).standAnim = StandNinja;
			( ( _thief2.get(FSMControl) as FSMControl ).getState( CharacterState.STAND ) as StandState ).standAnim = StandNinja;
			( ( _thief3.get(FSMControl) as FSMControl ).getState( CharacterState.STAND ) as StandState  ).standAnim = StandNinja;
			( ( _thief4.get(FSMControl) as FSMControl ).getState( CharacterState.STAND ) as StandState ).standAnim = StandNinja;
			
			( ( _thief1.get(FSMControl) as FSMControl ).getState( CharacterState.WALK ) as WalkState ).walkAnim = WalkNinja;
			( ( _thief2.get(FSMControl) as FSMControl ).getState( CharacterState.WALK ) as WalkState ).walkAnim = WalkNinja;
			( ( _thief3.get(FSMControl) as FSMControl ).getState( CharacterState.WALK ) as WalkState ).walkAnim = WalkNinja;
			( ( _thief4.get(FSMControl) as FSMControl ).getState( CharacterState.WALK ) as WalkState ).walkAnim = WalkNinja;
			
			( ( _thief1.get(FSMControl) as FSMControl ).getState( CharacterState.RUN ) as RunState ).runAnim = RunNinja;
			( ( _thief2.get(FSMControl) as FSMControl ).getState( CharacterState.RUN) as RunState ).runAnim = RunNinja;
			( ( _thief3.get(FSMControl) as FSMControl ).getState( CharacterState.RUN ) as RunState ).runAnim = RunNinja;
			( ( _thief4.get(FSMControl) as FSMControl ).getState( CharacterState.RUN ) as RunState ).runAnim = RunNinja;
			
			
			if(shellApi.checkEvent(_events.GRAIN_ON_DIAS) || shellApi.checkEvent(_events.SALT_ON_DIAS) || shellApi.checkEvent(_events.CLOTH_ON_DIAS)){
				if(Math.random() > 0.5){
					_activeThief1 = _thief1;
					_activeThief2 = _thief2;
					this.removeEntity(_thief3);
					this.removeEntity(_thief4);
				} else {
					this.removeEntity(_thief1);
					this.removeEntity(_thief2);
					_activeThief1 = _thief3;
					_activeThief2 = _thief4;
				}
				
				_activeThief1.add(new WatchThief());
				_activeThief2.add(new WatchThief());
				
				//Display(_activeThief1.get(Display)).visible = false;
				//Display(_activeThief2.get(Display)).visible = false;
				
				_watchThiefSystem = this.addSystem(new WatchThiefSystem( getEntityById( "camera" ), foundThieves ));
			} else if(shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				_activeThief1 = _thief4;
				_activeThief1.add(new WatchThief());
				
				_watchThiefSystem = this.addSystem(new WatchThiefSystem( getEntityById( "camera" ), foundThieves ));
				
				//Display(_activeThief1.get(Display)).visible = false;
				
				this.removeEntity(_thief1);
				this.removeEntity(_thief2);
				this.removeEntity(_thief3);
			} else {
				this.removeEntity(_thief1);
				this.removeEntity(_thief2);
				this.removeEntity(_thief3);
				this.removeEntity(_thief4);
			}
			
			
		}
		
		public function foundThieves():void{
			SceneUtil.lockInput(this);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, goForDias));
			this.removeSystem(_watchThiefSystem);
			_watchThiefSystem = null;
			
			// follow thief
			if(_activeThief2){
				_trackedThief = _activeThief2;
			} else {
				_trackedThief = _activeThief1;
			}
			
			_camTarg.add(new FollowTarget(_trackedThief.get(Spatial)));
		}
		
		private function goForDias():void{
			if(!shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				sneakToDias(_activeThief1);
				sneakToDias(_activeThief2);
			} else {
				sneakToDias(_activeThief1);
			}
		}
		
		private function sneakToDias($entity:Entity):void{
			if(!shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				CharUtils.moveToTarget($entity, 800, 700, false, poof, new Point(220+(Math.random()*50),200));
			} else {
				CharUtils.moveToTarget($entity, 800, 700, false, poof, new Point(250,200));
			}
			
			// adjust char speed
			var charMotionControl:CharacterMotionControl = $entity.get(CharacterMotionControl);
			charMotionControl.maxVelocityX = 400;
			
			//CharUtils.setAnim(_merchant, Tremble);
		}
		
		private function poof($thief:Entity):void{
			// thief throws bomb on area
			
			if(!_stealInProgress){
				SceneUtil.addTimedEvent(this, new TimedEvent(0.3, 1, smokeDias));
				_stealInProgress = true;
				
				CharUtils.setAnim($thief, Throw);
			}
			
			if($thief == _trackedThief){
				_camTarg.remove(FollowTarget);
				//TweenUtils.entityTo(_camTarg, Spatial, 1.5, {x:Spatial(_dias.get(Spatial)).x, y:Spatial(_dias.get(Spatial)).y, ease:Cubic.easeInOut});
			}
		}
		
		private function smokeDias():void{
			TweenUtils.entityTo(_camTarg, Spatial, 1.5, {x:Spatial(_dias.get(Spatial)).x, y:Spatial(_dias.get(Spatial)).y, ease:Cubic.easeInOut});
			_smokeBombGroup.thiefAt(_dias.get(Spatial), true);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, moveIn));
		}
		
		private function moveIn():void{
			CharUtils.moveToTarget(_activeThief1, 800, 700, false, stealItem, new Point(30,30));
			if(_activeThief2){
				CharUtils.moveToTarget(_activeThief2, 800, 700, false, null, new Point(30,30));
			}
		}
		
		private function stealItem(...p):void{
			
			
			if(!shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				Display(_activeThief1.get(Display)).visible = false;
				Display(_activeThief2.get(Display)).visible = false;
			}
			
			Timeline(_dias.get(Timeline)).gotoAndStop("clear");
			
			//CharacterWander(_merchant.get(CharacterWander)).pause = true;
			
			//CharUtils.setDirection(_merchant, true);
			CharUtils.setAnim(_merchant, Grief);
			
			if(!shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				SceneUtil.lockInput(this, false);
				shellApi.removeEvent(_placedItem+"_on_dias");
				_placedItem = null;
			} else {
				TweenUtils.entityTo(_camTarg, Spatial, 1.5, {x:Spatial(_trackedThief.get(Spatial)).x, y:Spatial(_trackedThief.get(Spatial)).y, ease:Cubic.easeInOut, onComplete:trackThief});
				stealCamelSequence();
			}
			
			if(!shellApi.checkEvent(_events.SMOKE_BOMB_LEFT) && !shellApi.checkHasItem(_events.SMOKE_BOMB)){
				dropSmokeBomb();
			}
			
		}
		
		private function trackThief():void{
			_camTarg.add(new FollowTarget(_trackedThief.get(Spatial)));
		}
		
		private function dropSmokeBomb():void
		{
			shellApi.completeEvent(_events.SMOKE_BOMB_LEFT);
			Timeline(_bomb.get(Timeline)).play();
		}
		
		private function stealCamelSequence():void{
			var edge:Edge = _camel.get(Edge);
			edge.unscaled.bottom -= 33;
			
			_camelCreator.setCamelsHandler(_camel, _activeThief1);
			Display(_activeThief1.get(Display)).visible = true;
			
			CharUtils.setScale(_camel, 0.63);
			
			CharUtils.moveToTarget(_activeThief1, 2330, 700, false, openEntrance, new Point(150,200));
			//CharUtils.moveToTarget(_activeThief1, 1050, 700, false, workCamel, new Point(30,30));
			
			FSMControl(_camel.get(FSMControl)).setState(Camel.PULL);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, workCamel));
		}
		
		private function workCamel(...p):void{
			var spatial:Spatial = _activeThief1.get(Spatial);
			CharUtils.setDirection(_activeThief1, false);
			CharUtils.setAnim(_activeThief1, Pull);
			FSMControl(_camel.get(FSMControl)).setState(Camel.PULL);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, think));
		}
		
		private function think(...p):void{
			CharUtils.setAnim(_activeThief1, Think);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, bribeCamel));
		}
		
		private function bribeCamel(...p):void{
			//CharUtils.setAnim(_activeThief1, Sword);
			SkinUtils.setSkinPart(_activeThief1, SkinUtils.ITEM, "banana");
			CharUtils.moveToTarget(_activeThief1, 860, 700, false, null, new Point(150,200));
			Camel(_camel.get(Camel)).walkSpeed = 200;
			//CharUtils.moveToTarget(_activeThief1, 860, 700, false, camelAccepts, new Point(150,200));
			FSMControl(_camel.get(FSMControl)).setState(MovieclipState.WALK);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, camelAccepts));
		}
		
		private function camelAccepts(...p):void{
			CharUtils.setAnim(_activeThief1, Score);
			FSMControl(_camel.get(FSMControl)).setState(MovieclipState.STAND);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, giveBanana));
			Camel(_camel.get(Camel)).walkSpeed = 200;
		}
		
		private function giveBanana(...p):void{
			Display(_camel.get(Display)).displayObject["Head"]["face"]["banana"].visible = true;
			SkinUtils.emptySkinPart(_activeThief1, SkinUtils.ITEM);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, takeCamelToEntrance));
		}
		
		private function takeCamelToEntrance(...p):void{
			CharUtils.moveToTarget(_activeThief1, 2330, 700, false, openEntrance, new Point(150,200));
			var charMotionControl:CharacterMotionControl = _activeThief1.get(CharacterMotionControl);
			charMotionControl.maxVelocityX = 200;
		}
		
		private function openEntrance(...p):void{
			Spatial(this.player.get(Spatial)).x = 3000;
			Dialog(_thief4.get(Dialog)).say("openSesame");
			
			raiseEntrance();
		}
		
		public function raiseEntrance(...p):void{
			Timeline(_hiddenEntrance.get(Timeline)).gotoAndPlay(2);
			Timeline(_hiddenEntrance.get(Timeline)).handleLabel("end", raised);
			_waterChurn.stream();
			//cameraShake();
		}
		
		private function raised():void{
			_waterChurn.stopStream();
			//cameraShake();
			//_entrancePlatform.add(_entrancePlat);
			
			//Display(_entranceBlind.get(Display)).visible = true;
			_hitContainer["entranceBlind"].visible = true;
			
			CharUtils.moveToTarget(_activeThief1, 2446, 675, false, disappear, new Point(30,30));
			
			//goOnPlat();
		}
		
		private function disappear(...p):void{
			_camelCreator.setCamelsHandler(_camel);
			_smokeBombGroup.thiefAt(_camel.get(Spatial), true, true);
			var camel:Camel = _camel.get(Camel);
			DynamicWire(camel.harnes.get(DynamicWire)).wireSprite.visible = false;
			EntityUtils.visible(_camel, false);
			EntityUtils.visible(_thief4, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, lower));
		}
		
		private function lower():void{
			_hitContainer["entranceBlind"].visible = false;
			Timeline(_hiddenEntrance.get(Timeline)).gotoAndPlay("submerge");
			Timeline(_hiddenEntrance.get(Timeline)).handleLabel("done", endScene);
			_waterChurn.stream();
			
			this.shellApi.completeEvent(_events.CAMEL_TAKEN);
			this.shellApi.removeEvent(_events.CAMEL_ON_DIAS);
		}
		
		private function endScene(...p):void{
			SceneUtil.lockInput(this, false);
			_waterChurn.stopStream();
		}
		
		private function setupParticles():void
		{	
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_LOW){
				_sandStorm = new SandStorm();
				_sandStormEmitter = EmitterCreator.create(this, overlayContainer, _sandStorm);
				_sandStorm.init(this, overlayContainer.width+800, 0, 1400, overlayContainer.height, 100, 300);
				_sandStorm.stream();
			}
			
			_waterChurn = new WaterChurn();
			_waterChurnEmitter = EmitterCreator.create(this, this._hitContainer, _waterChurn, 2380, 730);
			_waterChurn.init(this, 110);
		}
		
		private function setupEntrance():void
		{
			_hiddenEntrance = EntityUtils.createDisplayEntity(this, _hitContainer["hiddenEntrance"], _hitContainer);
			TimelineUtils.convertClip(this._hitContainer["hiddenEntrance"], this, _hiddenEntrance, null, false);
			
			var bitmapQuality:Number = PerformanceUtils.defaultBitmapQuality;
			BitmapUtils.convertContainer(this._hitContainer["hiddenEntrance"]["entrance"], bitmapQuality);
			
			//_entrancePlatform = this.getEntityById("entranceStone");
			//_entrancePlat = _entrancePlatform.get(Platform);
			
			//_entrancePlatform.remove(Platform);
			
			DisplayUtils.moveToTop(_hitContainer["entranceBlind"]);
			
			_entranceBlind = EntityUtils.createDisplayEntity(this, _hitContainer["entranceBlind"], _hitContainer);
			BitmapUtils.convertContainer(_hitContainer["entranceBlind"], bitmapQuality);
			
			_hitContainer["entranceBlind"].visible = false;
		}
		
		
		private function setupMovement():void
		{	
			// resize camera bounds
			
			var widthBuffer:int;
			var heightBuffer:int;
			
			if(PlatformUtils.isMobileOS){
				widthBuffer = super.shellApi.viewportWidth/2 - (SCOPE_RADIUS * 1.3);
				heightBuffer = super.shellApi.viewportHeight/2 - (SCOPE_RADIUS * 1.5); // temp fix to remove the edges being visible on some mobile devices
			} else {
				widthBuffer = super.shellApi.viewportWidth/2 - SCOPE_RADIUS;
				heightBuffer = super.shellApi.viewportHeight/2 - SCOPE_RADIUS;
			}
			
			var camera:Camera = super.shellApi.camera.camera;
			camera.resize( shellApi.viewportWidth, shellApi.viewportHeight, camera.areaWidth + widthBuffer * 2, camera.areaHeight + heightBuffer * 2, -widthBuffer , -heightBuffer );
			
			// map input system to move camera
			_camTarg = EntityUtils.createMovingEntity(this, _hitContainer["camTarg"], _hitContainer);
			_camTarg.add( new MotionBounds( new Rectangle(250,250,2254,443) ) );
			Display(_camTarg.get(Display)).visible = false;
			
			_followTarget = new FollowTarget();
			_followTarget.target = shellApi.inputEntity.get( Spatial );	// the Spatial that will be followed, in this case the main input.
			_followTarget.rate = 0.02;	// rate of target following, 1 is highest causing 1:1 following 
			_followTarget.applyCameraOffset = true;	// this needs be true with scenes using the camera 
			
			(super.getGroupById("cameraGroup") as CameraGroup).setTarget(_camTarg.get(Spatial), true);
			
			var input:Input = SceneUtil.getInput( this );
			input.inputDown.add( onInputDown );
			input.inputUp.add( onInputUp );
			
		}
		
		private function onInputDown( input:Input ):void
		{
			_camTarg.add( _followTarget );
		}
		
		private function onInputUp( input:Input ):void
		{
			_camTarg.remove( FollowTarget );
		}
		
		private function setupScope():void
		{
			var scope:Sprite = this._hitContainer["scope"];
			scope.x = shellApi.camera.viewportWidth*0.5;
			scope.y = shellApi.camera.viewportHeight*0.5;
			
			BitmapUtils.createBitmap(scope);
			
			this.overlayContainer.addChild(scope);
		}
		
		private const SCOPE_RADIUS:int = 243;
		private var _camTarg:Entity;
		private var _followTarget:FollowTarget;
		private var _hiddenEntrance:Entity;
		private var _sandStorm:SandStorm;
		private var _sandStormEmitter:Entity;
		
		private var _merchant:Entity;
		private var _thief1:Entity;
		private var _thief2:Entity;
		private var _thief3:Entity;
		private var _thief4:Entity;
		private var _events:Arab1Events;
		
		private var _activeThief1:Entity;
		private var _activeThief2:Entity;
		private var _trackedThief:Entity;
		private var _watchThiefSystem:System;
		
		private var _stealInProgress:Boolean = false;
		private var _smokeBombGroup:SmokeBombGroup;
		
		private var _dias:Entity;
		private var _placedItem:String;
		private var _flag1:Entity;
		private var _flag2:Entity;
		private var _camelCreator:CamelCreator;
		private var _camel:Entity;
		private var _waterChurn:WaterChurn;
		private var _waterChurnEmitter:Entity;
		private var _entrancePlatform:Entity;
		private var _entrancePlat:Platform;
		private var _entranceBlind:Entity;
		private var _bomb:Entity;
	}
}