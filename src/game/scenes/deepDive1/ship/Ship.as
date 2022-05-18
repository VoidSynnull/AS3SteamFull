package game.scenes.deepDive1.ship
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.systems.AudioSystem;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Zone;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.scene.SceneItemCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Score;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.scenes.deepDive1.shipUnderside.ShipUnderside;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.ProximitySystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	public class Ship extends PlatformerGameScene
	{
		private var _events:DeepDive1Events;
		private var _sub:Entity;
		private var _bucketEmpty:Entity;
		private var _bucketInk:Entity;
		private var _octopus:Entity;
		private var _lid:Entity;
		private var _cam:Entity;
		private var _sailor2:Entity;
		
		private var _canDumpBucket:Boolean;
		private var _canUseEmptyBucket:Boolean;
		
		private var _key:Entity;
		private var _isDumpingEmptyBucket:Boolean;
		private var _camSuccess:Boolean = false;
		
		public function Ship()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive1/ship/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void 
		{
			_events = DeepDive1Events(events);
			super.shellApi.eventTriggered.add( onEventTriggered );
			setup();
			super.addSystem(new ProximitySystem());
			super.addSystem(new AudioSystem(), SystemPriorities.updateSound);
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(1825,1598));	

			super.loaded();
		}
		
		private function setup():void
		{
			_canUseEmptyBucket = false
			_canDumpBucket = false
			
			_sailor2 = getEntityById("sailor2");		
			_cam = getEntityById("cam")
			_lid = getEntityById("lidInteraction");
			
			// setup lid SceneInteraction
			var lidInteraction:SceneInteraction = _lid.get(SceneInteraction);
			lidInteraction.reached.add(reachedLid);
			
			Display(_lid.get(Display)).isStatic = false;
			
			if (shellApi.checkEvent(_events.SUB_OPENED)) {
				removeEntity(_lid);
				makeSubClickable()
			}
			if (shellApi.checkEvent("sailor_reacted_to_ink")) {
				sailor2ApplyInkLook()
			}
			
			if (!shellApi.checkEvent("gotItem_key")) {
				if (!shellApi.checkEvent(_events.PLAYER_SAID_WHATS_GOING_ON)) {
					//sp = _cam.get(Spatial);
					//proximity = new Proximity(300, sp);
					//proximity.entered.addOnce(onNearCamInitial);
					//shellApi.player.add(proximity)
				} else {
					Dialog(_cam.get(Dialog)).setCurrentById("findKey")
				}
			}
			
			var clip:MovieClip;
			clip = super._hitContainer["bucketEmpty"];
			_bucketEmpty = ButtonCreator.createButtonEntity (clip,this,onBucketEmptyClick)
			TimelineUtils.convertClip( clip, null, _bucketEmpty );
			if (shellApi.checkEvent(_events.DUMPED_WATER)) {
				removeEntity (_bucketEmpty)
			}
			
			clip = super._hitContainer["bucketInk"];
			_bucketInk = EntityUtils.createMovingEntity(this,clip)
			TimelineUtils.convertClip( clip, null, _bucketInk );
			Display(_bucketInk.get(Display)).visible = false
			
			clip = super._hitContainer["octopus"];
			_octopus = EntityUtils.createMovingEntity(this,clip)
			TimelineUtils.convertClip( clip, null, _octopus );
			Timeline(_octopus.get(Timeline)).play()
			
			var se:Entity = new Entity();
			var octopusAudio:Audio = new Audio();
			octopusAudio.play(SoundManager.EFFECTS_PATH + "worms_eating_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
			se.add(octopusAudio);
			se.add(new Spatial(_octopus.get(Spatial).x, _octopus.get(Spatial).y));
			se.add(new AudioRange(600, 0, 1, Quad.easeIn));
			addEntity(se);
			
			// setup octopus SceneInteraction
			var sceneInteraction:SceneInteraction = getEntityById("octopusInteraction").get(SceneInteraction);
			sceneInteraction.ignorePlatformTarget = true;
			sceneInteraction.offsetX = -100;
			sceneInteraction.offsetY = -50;
			sceneInteraction.autoSwitchOffsets = false;
			sceneInteraction.faceDirection = CharUtils.DIRECTION_RIGHT;
			sceneInteraction.validCharStates = new <String>[ CharacterState.STAND ];
			sceneInteraction.minTargetDelta.x = 50;
			sceneInteraction.minTargetDelta.y = 100;
			sceneInteraction.reached.add(reachedOctopus);
			
			//Interaction(_lid.get(Interaction)).click.add(onLidClick);
			
			
			
			
			// If they have the key on entering scene, we should do the cam speech and give fish log right away
			if (shellApi.checkHasItem("key") && !shellApi.checkHasItem(_events.FISH_FILES)) {
				setUpProximityToCamKey()
			}
			
			// Birds
			for (var i:int = 1; i <= 2; i++) 
			{
				var bird:Entity = EntityUtils.createMovingEntity(this,_hitContainer["bird"+i]);
				bird = TimelineUtils.convertClip(_hitContainer["bird"+i],this,bird);
				var spatial:Spatial = bird.get(Spatial);
				bird.add(new Id("bird"+i));
				bird.add ( new Sleep(false, true ));
				if (i == 2) {
					var sp:Spatial =  player.get(Spatial);
					var proximity:Proximity = new Proximity(300, sp);
					proximity.entered.addOnce(scareBird);
					bird.add(proximity)
				} else {
					TweenUtils.entityTo(bird,Spatial,10,{x:4100,y:bird.get(Spatial).y,repeat:999});
					Timeline(bird.get(Timeline)).play();
				}
			}
			
			var zoneHitEntity:Entity;
			var zoneHit:Zone;
			
			zoneHitEntity = super.getEntityById("zoneDumpBucket");
			zoneHit = zoneHitEntity.get(Zone);
			zoneHit.entered.add(canDumpBucket);
			zoneHit.exitted.add(cannotDumpBucket);
			zoneHit.shapeHit = false;
			zoneHit.pointHit = true;
			
			zoneHitEntity = super.getEntityById("zoneUseEmptyBucket");
			zoneHit = zoneHitEntity.get(Zone);
			zoneHit.entered.add(canUseEmptyBucket);
			zoneHit.exitted.add(cantUseEmptyBucket);
			zoneHit.shapeHit = false;
			zoneHit.pointHit = true;
			
			Dialog(super.player.get(Dialog)).start.add(onDialogStart);
			Dialog(_cam.get(Dialog)).start.add(onDialogStart);
			
			_key = new Entity();
			_key.add(new Display(super._hitContainer["key"]));
			_key.add(new Spatial());
			_key.add(new Id("key"));
			_key.add(new Sleep());
			
			super.addEntity(_key);
			
			var itemHitSystem:ItemHitSystem = new ItemHitSystem();
			super.addSystem(itemHitSystem, SystemPriorities.resolveCollisions);
			itemHitSystem.gotItem.add(showAndGetItem);
			
			TimelineUtils.convertClip( super._hitContainer["key"], null, _key );
			
			if(super.shellApi.checkEvent(_events.SAILOR_REACTED_TO_INK) && !super.shellApi.checkHasItem(_events.KEY) && !super.shellApi.checkEvent(_events.SUB_OPENED)){
				// activate key
				Timeline(_key.get(Timeline)).gotoAndStop("dropped");
				var sceneItemCreator:SceneItemCreator = new SceneItemCreator();
				sceneItemCreator.make(_key);
			} else {
				// hide key
				Display(_key.get(Display)).visible = false;
			}
			
			_isDumpingEmptyBucket = false
			
			AudioUtils.play(this, SoundManager.AMBIENT_PATH + "lapping_water.mp3",1,true)
			
			if (!shellApi.checkEvent("hasItem_fish_files")) {
				var introPopup:IntroPopup = this.addChildGroup(new IntroPopup(this.overlayContainer)) as IntroPopup;
				introPopup.popupRemoved.addOnce(onIntroPopupClosed);
			}
		}
		
		public function showAndGetItem(item:Entity, type:String = null):void
		{
			var itemID:String = item.get(Id).id;
			super.shellApi.getItem(itemID, type);			
			var itemGroup:ItemGroup = super.getGroupById(ItemGroup.GROUP_ID) as ItemGroup;			
			itemGroup.showItem(itemID);
		}
		
		private function onIntroPopupClosed (...p):void {
			CharUtils.lockControls(this.shellApi.player,true, true);
			SceneUtil.lockInput(this, true);
			CharUtils.setAnim(_cam, Grief, false);
			CharUtils.moveToTarget(shellApi.player,1100,1890,false,sayWhatsGoingOn)
		}

		private function reachedOctopus(...args):void
		{
			Timeline(_octopus.get(Timeline)).gotoAndPlay("squirt")
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "fs_pond_water_03.mp3");
			if (super.shellApi.checkHasItem(_events.BUCKET_EMPTY)) {
				SceneUtil.addTimedEvent( this, new TimedEvent( .4, 1, giveInkBucket));
			}
		}
		
		private function canDumpBucket (...p):void {
			_canDumpBucket = true
		}
		
		private function cannotDumpBucket (...p):void {
			_canDumpBucket = false
		}
		
		private function canUseEmptyBucket (...p):void {
			_canUseEmptyBucket = true
		}
		
		private function cantUseEmptyBucket (...p):void {
			_canUseEmptyBucket = false
		}
		
		private function onNearCamInitial (...p):void {
			if (!shellApi.checkEvent("gotItem_key")) {
				CharUtils.lockControls(this.shellApi.player,true, true);
				SceneUtil.lockInput(this, true);
				CharUtils.moveToTarget(shellApi.player,1100,1890,false,sayWhatsGoingOn)
			}
		}
		private function sayWhatsGoingOn(...p):void {
			CharUtils.faceTargetEntity(player,_cam);
			Dialog(player.get(Dialog)).sayById ("whatsGoingOn")
		}
		
		private function sayFindKey(...p):void {
			SceneUtil.lockInput(this, false);
			CharUtils.lockControls(this.shellApi.player,false, false);
			Dialog(_cam.get(Dialog)).sayById ("findKey")
		}
		
		private function onDialogStart(dialogData:DialogData):void
		{
			trace ("[Ship] ===================onDialogStart:" + dialogData.id)
			switch(dialogData.link){
				case "why":
					CharUtils.lockControls(this.shellApi.player,true, true);
					SceneUtil.lockInput(this, true);
					break
			}
			
			// can't just make them all id becuase link and id seem to conflict somehow?
			switch(dialogData.id){
				case "success":
					CharUtils.lockControls(this.shellApi.player,true, true);
					SceneUtil.lockInput(this, true);
					break;
			}
		}		
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var sp:Spatial
			trace ("[Ship]-------------------------------event*:" + event)
			switch (event){
				case "playerSaidWhatsGoingOn":
					super.shellApi.triggerEvent(_events.PLAYER_SAID_WHATS_GOING_ON );	 // Why do I have to do both?
					super.shellApi.completeEvent(_events.PLAYER_SAID_WHATS_GOING_ON );	
					break
				
				case "camSaidNeedHelp":
					super.shellApi.getItem(_events.FISH_FILES, null, true );
					Dialog(_cam.get(Dialog)).setCurrentById("findKey")
					SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, sayFindKey));
					break;
				
				case "camCompletedInitialSpeech":
					Dialog(_cam.get(Dialog)).setCurrentById("findKey")
					break;
				
				case "sailorDoneReactingToWater":
					SceneUtil.setCameraTarget(this, player);
					SceneUtil.addTimedEvent( this, new TimedEvent( .6, 1, giveEmptyBucket));
					break
				
				case "used_bucket_empty":
					if (_canUseEmptyBucket) {
						Timeline(_octopus.get(Timeline)).gotoAndPlay("squirt")
						SceneUtil.addTimedEvent( this, new TimedEvent( .4, 1, giveInkBucket));
					} else {
						sayCantUseThat()
					}
					break
				
				case "gotItem_key":
					setUpProximityToCamKey()
					break
				
				case _events.USED_BUCKET_FULL:
					if (_canDumpBucket) {
						CharUtils.moveToTarget(shellApi.player,2263,player.get(Spatial).y,true,dumpInkBucket) 
					} else {
						sayCantUseThat()
					}
					break
				case _events.USED_KEY:
					sp = shellApi.player.get(Spatial)
					var d:Number = Utils.distance(sp.x,sp.y, 500, 2000)
					//trace ("              *** d:" + d)
					if (d < 590) {
						moveToCrateAndOpenIt()
					} else {
						SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, sayCantUseThat));
					}
					break;
				
				case "dumped_ink":
					Dialog(_sailor2.get(Dialog)).sayById ("dumpedInk")
					break;
				
				case "sailor_reacted_to_ink":
					SceneUtil.setCameraTarget(this, player);
					break
				
				case "camSaidSuccessSpeech":
					SceneUtil.lockInput(this, false);
					CharUtils.lockControls(this.shellApi.player,false, false);
					_camSuccess = true;
					break;
			}
		}
		
		private function moveToCrateAndOpenIt():void
		{
			CharUtils.moveToTarget(shellApi.player,480,1950,false,openCrate) 			
		}
		
		private function setUpProximityToCamKey():void
		{
			var zoneHitEntity:Entity;
			var zoneHit:Zone;
			
			zoneHitEntity = super.getEntityById("zoneNearCam");
			zoneHit = zoneHitEntity.get(Zone);
			zoneHit.entered.add(onNearCamAfterHaveKey);
			zoneHit.shapeHit = false;
			zoneHit.pointHit = true;
		}
		
		private function onNearCamAfterHaveKey (...p):void {
			if(!_camSuccess){
				CharUtils.lockControls(this.shellApi.player,true, true);
				SceneUtil.lockInput(this, true);
				CharUtils.moveToTarget(shellApi.player,1100,1890,false,reachedCamWithKey)
			}
		}
		
		private function reachedCamWithKey (...p):void {
			CharUtils.faceTargetEntity(_cam,player);
			CharUtils.faceTargetEntity(player,_cam);
			CharUtils.lockControls(this.shellApi.player,false, false);
			SceneUtil.lockInput(this, false);
			_cam.get(Dialog).sayById ("success");
			CharUtils.setAnim( _cam, Score, false);
		}
		
		private function sayCantUseThat ():void {
			player.get(Dialog).sayById("cantUseThatHere");
		}
		
		private function scareBird(e:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wing_flaps_solo_01.mp3")
			
			TweenUtils.entityTo(e,Spatial,3,{x:2900,y:0});
			Timeline(e.get(Timeline)).play();
		}
		
		private function openCrate(...p):void
		{
			super.shellApi.removeItem( _events.KEY );	
			super.shellApi.completeEvent(_events.SUB_OPENED );	
			TweenUtils.globalTo(this,_lid.get(Spatial),3,{y:2800, rotation:180, onComplete:removeLid},"opencrate");
			TweenUtils.globalTo(this,_lid.get(Display),2.5,{alpha:0},"opencrate");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "lock_click_01.mp3")
			SceneUtil.addTimedEvent( this, new TimedEvent( .3, 1, playSplashSound));
		}
		
		private function removeLid():void{
			removeEntity(_lid);
			makeSubClickable();
		}
		
		private function playSplashSound(...p):void{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_splash_05.mp3")
		}
		
		
		private function reachedLid(...p):void{
			if (shellApi.checkEvent("gotItem_key")) {
				openCrate();
			} else {
				player.get(Dialog).sayById("locked");
			}
		}
		
		private function onLidClick (...p):void{
			if (shellApi.checkEvent("gotItem_key")) {
				moveToCrateAndOpenIt()
			} else {
				player.get(Dialog).sayById("locked");
			}
		}
		
		private function onBucketEmptyClick (...p):void{
			//trace (_bucketEmpty.get(Spatial).x + "," +_bucketEmpty.get(Spatial).y)
			
			if (!_isDumpingEmptyBucket) {
				if (_canDumpBucket) {
					_isDumpingEmptyBucket = true
					CharUtils.moveToTarget(shellApi.player,_bucketEmpty.get(Spatial).x,_bucketEmpty.get(Spatial).y, false, dumpEmptyBucket) 
				} else {
					player.get(Dialog).sayById("closer");
				}
			}
		}
		
		private function dumpEmptyBucket(...p):void
		{
			CharUtils.lockControls(this.shellApi.player,true, true);
			SceneUtil.lockInput(this, true);
			shellApi.loadFile
			CharUtils.setDirection(player,false);
			CharUtils.setAnim(player,Place);
			Timeline(_bucketEmpty.get(Timeline)).play();
			SceneUtil.addTimedEvent( this, new TimedEvent(.4, 1, playBucketPourSound));
			SceneUtil.addTimedEvent( this, new TimedEvent(.75, 1, sailor2ReactToWater));
			
			// This moves the player to that spot ?????
			//					var _cameraEntity:Entity = super.getEntityById("camera");
			//					var tSpatial:TargetSpatial = _cameraEntity.get(TargetSpatial);
			//					tSpatial.target.x = _sailor2.get(Spatial).x;
			//					tSpatial.target.y = _sailor2.get(Spatial).y;			
		}
		
		private function giveInkBucket(...p):void {
			super.shellApi.removeItem( _events.BUCKET_EMPTY );	
			super.shellApi.getItem(_events.BUCKET_FULL, null, true );
		}
		
		private function playBucketPourSound():void {
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_splash_09b.mp3")
			SceneUtil.setCameraTarget(this, _sailor2);
		}
		
		private function sailor2ReactToWater():void
		{
			// override dialog first
			Dialog(_sailor2.get(Dialog)).allowOverwrite = true;
			_sailor2.get(Dialog).sayById("water");
			CharUtils.setAnim( _sailor2, Grief, false);
		}
		
		private function giveEmptyBucket ():void {
			
			var success:Boolean = super.shellApi.getItem(_events.BUCKET_EMPTY, null, true );
			if (!success) trace ("[Ship] ***** ERROR. sorry bucket_empty is not a valid item")
			removeEntity(_bucketEmpty,true)
			_isDumpingEmptyBucket = false
			CharUtils.lockControls(this.shellApi.player,false, false);
			SceneUtil.lockInput(this, false);
			
			shellApi.completeEvent(_events.DUMPED_WATER);
		}
		
		private function dumpInkBucket(...p):void
		{
			CharUtils.setDirection(player,false);
			CharUtils.setAnim(player,Place);
			super.shellApi.removeItem( _events.BUCKET_FULL );
			Display(_bucketInk.get(Display)).visible = true
			Timeline(_bucketInk.get(Timeline)).play()
			SceneUtil.addTimedEvent( this, new TimedEvent(.4, 1, playBucketPourSound));
			SceneUtil.addTimedEvent( this, new TimedEvent( .8, 1, sailor2ReactToInk));
		}
		
		private function enactPourInkBucket ():void {
			//	var mc:MovieClip = Display(_bucketInk.get(Display)).displayObject
			//	mc.play()
			//SceneUtil.addTimedEvent( this, new TimedEvent( .6, 1, sailor2ReactToInk));
		}
		
		private function sailor2ReactToInk():void
		{
			sailor2ApplyInkLook()
			shellApi.triggerEvent(_events.DUMPED_INK,true);
			CharUtils.setAnim( _sailor2, Grief, false);
			CharUtils.lockControls(this.shellApi.player,false, false);
			SceneUtil.lockInput(this, false);
			// Note: key is placed by events in the items.xml
			// SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, giveKey));
			
			// play key animation
			Display(_key.get(Display)).visible = true;
			Timeline(_key.get(Timeline)).play();
			
			// make key interactable
			var sceneItemCreator:SceneItemCreator = new SceneItemCreator();
			sceneItemCreator.make(_key);
		}
		
		private function sailor2ApplyInkLook():void
		{
			SkinUtils.setSkinPart( _sailor2, SkinUtils.FACIAL, "dd_ink1" );
			SkinUtils.setSkinPart( _sailor2, SkinUtils.ITEM, "empty" );
		}
		
		private function makeSubClickable():void {
			Dialog(_cam.get(Dialog)).setCurrentById("subOpen")
			_sub = getEntityById("subInteraction");
			
			// setup sub interaction
			var subInteraction:SceneInteraction = _sub.get(SceneInteraction);
			subInteraction.triggered.add(triggered);
			subInteraction.reached.add(enterSub);
			
			Display(_sub.get(Display)).isStatic = false;
		}
		
		private function triggered(...p):void{
			trace("triggered");
		}
		
		private function enterSub(...p):void
		{
			// transition to subsScene inheriting 'shipUnderside' scene
			
			trace("enterSub");
			
			CharUtils.lockControls(this.shellApi.player,true, true);
			SceneUtil.lockInput(this, true);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "door_pressure_short_01.mp3")
			SceneUtil.addTimedEvent( this, new TimedEvent(.2, 1, gotoShipUnderside));
		}
		
		private function gotoShipUnderside (...p):void {
			shellApi.loadScene(ShipUnderside,320,202);
		}
		
		public function showKey():void{
			// play key animation
			Display(_key.get(Display)).visible = true;
			Timeline(_key.get(Timeline)).play();
			
			// make key interactable
			var sceneItemCreator:SceneItemCreator = new SceneItemCreator();
			sceneItemCreator.make(_key);
		}
		
	}
}