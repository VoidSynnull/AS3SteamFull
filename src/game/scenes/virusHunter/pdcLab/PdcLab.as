package game.scenes.virusHunter.pdcLab {
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.data.AudioWrapper;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Wall;
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.KeyboardTyping;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.scene.hit.MovingHitData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.SceneSound;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.virusHunter.pdcLab.components.DoorWalls;
	import game.scenes.virusHunter.pdcLab.components.SensorMC;
	import game.scenes.virusHunter.pdcLab.components.SensorTargetMC;
	import game.scenes.virusHunter.pdcLab.components.Sensors;
	import game.scenes.virusHunter.pdcLab.particles.ParticleExample1;
	import game.scenes.virusHunter.pdcLab.systems.SensorsSystem;
	import game.systems.SystemPriorities;
	import game.ui.card.CardView;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	
	public class PdcLab extends PlatformerGameScene
	{
		
		private var isMember:Boolean;
		//private var startPosition:Point;
		
		public function PdcLab()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/pdcLab/";
			//super.showHits = true;
			//isMember = shellApi.profileManager.active.isMember;
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
			virusEvents = super.events as VirusHunterEvents;
			
			// Elevator
			elevator = super.getEntityById("elevator");
			
			var downMC:MovieClip = super._hitContainer["eDownButton"];
			var upMC:MovieClip = super._hitContainer["eUpButton"];
			
			_downButton = new Entity();
			_upButton = new Entity();
			
			_downButton.add(new Display(downMC)); // add mc display
			_upButton.add(new Display(upMC)); 
			
			var interaction:Interaction = InteractionCreator.addToEntity(_downButton, [InteractionCreator.DOWN]);
			interaction.down.add(downClicked);
			
			var interaction2:Interaction = InteractionCreator.addToEntity(_upButton, [InteractionCreator.DOWN]);
			interaction2.down.add(upClicked);
			
			var tipDown:Entity = ToolTipCreator.create( ToolTipType.CLICK, downMC.x, downMC.y );
			EntityUtils.addParentChild( tipDown, _downButton );
			this.addEntity( tipDown );
			
			var tipUp:Entity = ToolTipCreator.create( ToolTipType.CLICK, upMC.x, upMC.y );
			EntityUtils.addParentChild( tipUp, _upButton );
			this.addEntity( tipUp );
			
			super.addEntity(_downButton);
			super.addEntity(_upButton);
			
			// Doors and paired Sensors
			/*_hitContainer.swapChildren(Display(super.player.get(Display)).displayObject, _hitContainer["animalGlass"]);
			_hitContainer.swapChildren(Display(super.player.get(Display)).displayObject, _hitContainer["doorA"]);
			_hitContainer.swapChildren(_hitContainer["doorB"], _hitContainer["doorA"]);
			_hitContainer.swapChildren(_hitContainer["doorC"], _hitContainer["doorB"]);*/
			
			
			super.addSystem(new SensorsSystem(super._hitContainer), SystemPriorities.autoAnim);
			
			var doorA:Entity = new Entity()
				.add(new SensorTargetMC(super._hitContainer["doorA"]))
				.add(new Id("doorA"))
				.add(new SensorMC(super._hitContainer["sensorA"]));
			var doorB:Entity = new Entity()
				.add(new SensorTargetMC(super._hitContainer["doorB"]))
				.add(new Id("doorB"))
				.add(new SensorMC(super._hitContainer["sensorB"]));
			var doorC:Entity = new Entity()
				.add(new SensorTargetMC(super._hitContainer["doorC"]))
				.add(new Id("doorC"))
				.add(new SensorMC(super._hitContainer["sensorC"], true));
			
			super._hitContainer["doorC"].doorMech.passLight.gotoAndStop("locked");
			_doorC = doorC;
			
			super.addEntity(doorA);
			super.addEntity(doorB);
			super.addEntity(doorC);
			
			_sensors = new Entity()
				.add(new DoorWalls(new <Entity>[super.getEntityById("wallA"), super.getEntityById("wallB"), super.getEntityById("wallC")]))
				.add(new Sensors(new <Entity>[doorA, doorB, doorC], new <Entity>[super.player]));
			
			super.addEntity(_sensors);
			
			// npc interaction(s)
			var dr1:Entity = super.getEntityById("npc");
			var dr2:Entity = super.getEntityById("npc2");
			var lange:Entity = super.getEntityById("npc3");
			var clerk:Entity = super.getEntityById("npc4");
			
			//CharUtils.setDirection(clerk, true);
			//startPosition = new Point(612, 494);//sceneData.startPosition;	// startPosition is no good, would like to get the door's x and y from previous scene
			
			//var interaction3:Interaction = InteractionCreator.addToEntity(lange, [InteractionCreator.DOWN]);
			//interaction3.down.add(langeClicked);
			var langeInteraction:SceneInteraction = lange.get(SceneInteraction);
			langeInteraction.reached.removeAll();
			langeInteraction.reached.add(langeClicked);
			
			//trace(clerk.getAll());
			//CharUtils.addCollisions(clerk);
			
			// events
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			// particles
			initParticles();
			
			/*var zoneHitEntity:Entity = new Entity()
			.add(new Display(super._hitContainer["gasZone"]))
			.add(new Platform())
			.add(new Zone());
			
			//var zoneHitEntity:Entity = super.getEntityById("gasZone");
			var zoneHit:Zone = zoneHitEntity.get(Zone);*/
			
			var zoneHitEntity:Entity = super.getEntityById("zoneGas");
			var zoneHit:Zone = zoneHitEntity.get(Zone);
			
			zoneHit.entered.add(startParticles);
			zoneHit.exitted.add(stopParticles);
			//zoneHit.inside.add(startParticles);
			zoneHit.shapeHit = false;
			zoneHit.pointHit = true;
			
			//back room zone, to get players out who are stuck behind door
			var zoneBackRoomEntity:Entity = super.getEntityById("zoneBackRoom");
			var zoneBackRoom:Zone = zoneBackRoomEntity.get(Zone);
			
			zoneBackRoom.entered.add(moveOutOfBackRoom);
			zoneBackRoom.shapeHit = false;
			zoneBackRoom.pointHit = true;
			
			//		(getEntityById("zoneMemberBlock").get(Zone) as Zone).entered.add(handleMemberBlockZone); 
			
			// clean up loose movieClips
			
			super._hitContainer["monitors"].mouseEnabled = false;
			super._hitContainer["server"].mouseEnabled = false;
			super._hitContainer["mixer1"].mouseEnabled = false;
			super._hitContainer["mixer2"].mouseEnabled = false;
			super._hitContainer["labCreatures"].mouseEnabled = false;
			super._hitContainer["labAnimals"].mouseEnabled = false;
			super._hitContainer["animalGlass"].mouseEnabled = false;
			super._hitContainer["monitors"].mouseChildren = false;
			super._hitContainer["server"].mouseChildren = false;
			super._hitContainer["mixer1"].mouseChildren = false;
			super._hitContainer["mixer2"].mouseChildren = false;
			super._hitContainer["labCreatures"].mouseChildren = false;
			super._hitContainer["labAnimals"].mouseChildren = false;
			super._hitContainer["animalGlass"].mouseChildren = false;
			
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToAllEntities();
			
			trace("virusEvents.TALKED_TO_GIRL:"+virusEvents.TALKED_TO_GIRL);
			trace("super.shellApi.checkEvent(talked_to_girl):"+super.shellApi.checkEvent("talked_to_girl"));
			trace("super.shellApi.checkEvent(virusEvents.TALKED_TO_GIRL):"+super.shellApi.checkEvent(virusEvents.TALKED_TO_GIRL));
			
			//lock backRoom door until it's ok to enter
			var doorBackRoom:Entity = super.getEntityById("door2");
			if(!super.shellApi.checkEvent(virusEvents.LANGE_IN_BACK_ROOM)){
				Interaction(doorBackRoom.get(Interaction)).lock = true;
			} else if(!super.shellApi.checkEvent("talked_to_girl")) {
				// open wall
				//super.getEntityById("wallC").remove(Wall);
				//super._hitContainer["doorC"].triggered = true;
				//super._hitContainer["doorC"].gotoAndPlay("Down");
				super._hitContainer["doorC"].doorMech.passLight.gotoAndStop("open");
				
				//super.shellApi.triggerEvent("playDoorSound");
				
				SensorMC(_doorC.get(SensorMC)).locked = false;

				Interaction(doorBackRoom.get(Interaction)).lock = false;
				
				//var zoneBackRoomEntity:Entity = super.getEntityById("zoneBackRoom");
				//var zoneBackRoom:Zone = zoneBackRoomEntity.get(Zone);
				zoneBackRoom.entered.removeAll();
				
				super.removeEntity(lange);
			} else {
				trace("DAY 2 STUFF");
				// day 2
				super._hitContainer["doorC"].doorMech.passLight.gotoAndStop("open");
				
				//super.shellApi.triggerEvent("playDoorSound");
				
				/**
				 * Drew Martin
				 * 
				 * These were changed from false to true so that players don't get stuck in an endless "teleporting loop"
				 * due to the "zoneBackRoom" Zone moving the player outside of the "wallC" area. Players are assuming
				 * they have to go to the Back Room to shrink again to get into the dog for Day 2. To (somewhat) fix this,
				 * we should prevent the sensor door from opening and lock the Back Room door.
				 * 
				 * Alternatively, if we do a zoneBackRoom.entered.removeAll(), then going to the Back Room will
				 * trigger Day 1 dialog, and there'd need to be extra dialog for Day 2 there.
				 */
				SensorMC(_doorC.get(SensorMC)).locked = true;
				Interaction(doorBackRoom.get(Interaction)).lock = true;
				//zoneBackRoom.entered.removeAll();
			}
			
			//if (!isMember) {
			// give the scene a little slice of time in which to render itself
			//Delay.doIt(50, showBlocker);
			//}
			
			//positional flies sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "insect_flies_02_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			//entity.add(new Display(super._hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial(680, 1000));
			entity.add(new AudioRange(500, 0, 0.4, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
			
			if (super.shellApi.checkEvent( virusEvents.COMPLETED_TUTORIAL ) &&
				!this.shellApi.checkEvent(virusEvents.TALKED_TO_GIRL)) {
				super.removeEntity(lange);
			}
			
			for (var i:uint=1; i<=6; i++) {
				this["_beadString" + i] = TimelineUtils.convertClip(super._hitContainer["string" + i], this);
			}
			
			SceneInteraction(super.getEntityById("door1").get(SceneInteraction)).reached.add(shakeBeadDoor);
			
			super.loaded();
		}
		//end loaded()
		
		////////MOVED NON-MEMBER BLOCK TO backRoom
		//private function showBlocker(arg:*=null):void {
		//var blocker:NonMemberBlockPopup = addChildGroup(new NonMemberBlockPopup(overlayContainer)) as NonMemberBlockPopup;
		//blocker.id = 'nonMemberBlockPopup';
		//blocker.popupRemoved.addOnce(returnToVideoStore);
		//}
		
		//private function returnToVideoStore(popup:Popup=null):void {
		//shellApi.loadScene(game.scenes.virusHunter.videoStore.VideoStore);
		//}
		
		private function downClicked($entity:Entity):void
		{
			if(!_elevatorMoving)
			{
				_elevatorMoving = true;
				
				var downMC:MovieClip = Display($entity.get(Display)).displayObject as MovieClip;
				
				downMC.play(); // play button animation
				
				var movingHitData:MovingHitData = elevator.get(MovingHitData);
				movingHitData.pause = false;
				movingHitData.reachedFinalPoint.addOnce(elevatorReachedPoint);
				//movingHitData.pointIndex = 0;
				
				if(_goingUp)
				{
					movingHitData.points.reverse();
					movingHitData.pointIndex = 0;
					_goingUp = false;
				}
				
				//trigger event for sound
				super.shellApi.triggerEvent("playButtonSound");
				var elevatorAudio:Audio = elevator.get(Audio);
				var wrapper:AudioWrapper = elevatorAudio.playCurrentAction("effects");
			}
		}
		
		private var _goingUp:Boolean = false;
		private var _elevatorMoving:Boolean = false;
		
		private function upClicked($entity:Entity):void
		{
			if(!_elevatorMoving)
			{
				_elevatorMoving = true;
				
				var upMC:MovieClip = Display($entity.get(Display)).displayObject as MovieClip;
				
				upMC.play(); // play button animation
				
				//var motion:Motion = elevator.get(Motion);
				
				var movingHitData:MovingHitData = elevator.get(MovingHitData);
				
				if(movingHitData.pointIndex != 0){
					movingHitData.points.reverse();
					movingHitData.pointIndex = 0;
					_goingUp = true;
				} else {
					movingHitData.pause = false;
				}
				movingHitData.reachedFinalPoint.addOnce(elevatorReachedPoint);
				//trigger event for sound
				super.shellApi.triggerEvent("playButtonSound");
				
				var elevatorAudio:Audio = elevator.get(Audio);
				var wrapper:AudioWrapper = elevatorAudio.playCurrentAction("effects");
			}
		}
		
		private function elevatorReachedPoint():void
		{
			_elevatorMoving = false;
			var elevatorAudio:Audio = elevator.get(Audio);
			elevatorAudio.stopActionAudio("effects");
		}
		
		private function langeClicked(player:Entity, npc:Entity):void{
			
			if(!super.shellApi.checkHasItem("dossier")){
				//CharUtils.lockControls( super.player, true, true);
				SceneUtil.lockInput(this, true);
				super.shellApi.triggerEvent("talkToLange");
			} else if(!super.shellApi.checkHasItem("photo")){
				super.shellApi.triggerEvent("findJoe");
			} else if(!super.shellApi.checkEvent("talked_to_girl")){
				// trigger dialog with player and lange on photo
				super.shellApi.triggerEvent("givePicture");
			} else if(!super.shellApi.checkEvent("talked_to_lange_d2")) {
				// day 2 
				SceneUtil.lockInput(this, true);
				Dialog(super.player.get(Dialog)).sayById("borrow_ship");
			} else {
				Dialog(npc.get(Dialog)).sayById("contain_dog");
			}
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var lange:Entity;
			switch(event){
				case "talkedToLange9":
					CharUtils.setAnim( super.player, Tremble, false );
					break;
				case "playerAgrees":
					lange = super.getEntityById("npc3");
					CharUtils.setAnim( lange, KeyboardTyping, false );
					CharUtils.setAnim( super.player, Stand, false );
					
					// 2 seconds later, bring up briefing
					_timer = new Timer(3000, 1);
					_timer.addEventListener(TimerEvent.TIMER_COMPLETE, pullUpBriefing);
					_timer.start();
					break;
				case "showBriefing":
					showPopup();
					break;
				case "showBriefing3":
					//CharUtils.setAnim( super.player, Tremble, false );
					break;
				case "gotItem_camera":
					SceneUtil.lockInput(this, false);
					CharUtils.stateDrivenOn(super.player);
					//CharUtils.lockControls( super.player, false, false );
					break;
				case "givePicture":
					if (usedPhoto || super.shellApi.checkEvent(virusEvents.COMPLETED_TUTORIAL)) {
						Dialog(super.player.get(Dialog)).sayById("alreadyUsedPhoto");
					}
					else if (Spatial(super.player.get(Spatial)).x > 850) {
						Dialog(super.player.get(Dialog)).sayById("hereIsPhoto");
						SceneUtil.lockInput(this, true);
						CharUtils.moveToTarget(super.player, 1350, super.sceneData.bounds.bottom, false, langeStartsTyping);
					}
					else {
						Dialog(super.player.get(Dialog)).sayById("bringPhotoToLange");
					}
					break;
				case "talkAboutJoe5":
					// stop typing
					lange = super.getEntityById("npc3");
					CharUtils.setAnim( lange, Stand, false );
					break;
				case "talkedAboutJoe":
					usedPhoto = true;
					SceneUtil.lockInput(this, false);
					
					// open wall
					super.getEntityById("wallC").remove(Wall);
					super._hitContainer["doorC"].triggered = true;
					super._hitContainer["doorC"].gotoAndPlay("Down");
					super._hitContainer["doorC"].doorMech.passLight.gotoAndStop("open");
					
					super.shellApi.triggerEvent("playDoorSound");
					
					SensorMC(_doorC.get(SensorMC)).locked = false;
					
					var doorBackRoom:Entity = super.getEntityById("door2");
					Interaction(doorBackRoom.get(Interaction)).lock = false;
					
					var zoneBackRoomEntity:Entity = super.getEntityById("zoneBackRoom");
					var zoneBackRoom:Zone = zoneBackRoomEntity.get(Zone);
					zoneBackRoom.entered.removeAll();
					
					// lange walks into next room
					lange = super.getEntityById("npc3");
					var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
					charGroup.addFSM( lange );
					Sleep(lange.get(Sleep)).ignoreOffscreenSleep = true;
					Sleep(lange.get(Sleep)).sleeping = false;
					
					CharUtils.moveToTarget(lange, 1765, 1350, false, reachedTarget); // CAUTION: Point a bit higher than her feet - might be a fix down the line
					
					// wall to next room unlocks
					
					break;
				case "talked_to_lange_d2":
					// remove input block
					SceneUtil.lockInput(this, false);
					break;
			}
		}
		
		private function langeStartsTyping(playerEntity:Entity):void
		{
			CharUtils.setDirection(super.player, true);
			
			CharUtils.setAnim( super.player, Salute, false );
			
			var lange:Entity = super.getEntityById("npc3");
			CharUtils.setAnim( lange, KeyboardTyping, false );
			//CharUtils.setAnim( super.player, Stand, false );
			
			// 2 seconds later, bring up briefing
			_timer = new Timer(3600, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, pullUpJoe);
			_timer.start();
		}
		
		private function pullUpBriefing($event:TimerEvent):void{
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, pullUpBriefing); // [||] Garbage
			
			var lange:Entity = super.getEntityById("npc3");
			CharUtils.setAnim( lange, Stand, false );
			super.shellApi.triggerEvent("pullUpBriefing");
		}
		
		private function pullUpJoe($event:TimerEvent):void{
			super._hitContainer["monitors"].display.play();
			super.shellApi.triggerEvent("talkAboutJoe");
		}
		
		private function reachedTarget($entity:Entity):void{
			// dissapear lange
			Display($entity.get(Display)).visible = false;
			super._hitContainer["doorC"].triggered = false;
			super._hitContainer["doorC"].play();
			
			super.shellApi.triggerEvent("playDoorSound");
			
			// save her in the backroom
			super.shellApi.triggerEvent(virusEvents.LANGE_IN_BACK_ROOM,true);
		}
		
		private function showPopup():void
		{
			// remove sounds
			var sceneSoundEntity:Entity = super.getEntityById(SceneSound.SCENE_SOUND);
			var sceneAudio:Audio = sceneSoundEntity.get( Audio );
			sceneAudio.stop( "Sneaky_Suspense.mp3" );
			sceneAudio.stop( "tech_lab.mp3" );
			
			popup = super.addChildGroup(new VirusPopupVideo(super.overlayContainer)) as VirusPopupVideo;
			popup.id = "virusPopupVideo";
			popup.ready.addOnce(handleStartedVideo);
			
			//var popup:ExamplePopup = super.addChildGroup(new ExamplePopup(super.overlayContainer)) as ExamplePopup;
			//popup.id = "examplePopup";
			
			//add a listener to this popup's custom signal.  This listener will get removed in the popup's 'destroy()' method.
			//popup.finishedVideo.add(finishedVideo);
			
			// An entity within the popup is available on 'ready'.
			//popup.ready.addOnce(tracePopupEntity);
			// ... and is null after 'removed'.  It is cleaned up automatically when the popup is closed.
			popup.removed.addOnce(finishedVideo);
		}
		
		private function handleStartedVideo(group:Group):void
		{
			//this.shellApi.triggerEvent("startedBriefing");
			//delay audio start to sync it up
			//_timer = new Timer(2700, 1);
			//_timer.addEventListener(TimerEvent.TIMER_COMPLETE, startVideoAudio);
			//_timer.start();
			
			//auto close video after, using timer for now until I figure out how to put a signal in the flv
			_timer = new Timer(70000, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, closeVideo);
			_timer.start();
		}
		
	//	private function startVideoAudio($event:TimerEvent):void{
	//		_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, startVideoAudio); // [||] Garbage
	//		this.shellApi.triggerEvent("startedBriefing");
	//	}
		
		private function closeVideo($event:TimerEvent):void
		{
			popup.close();
		}
		
		private function finishedVideo(popup:VirusPopupVideo):void{
			super.shellApi.triggerEvent("shownBriefing");
		}
		
		private function initParticles():void{
			var group:Group = this;
			var container:DisplayObjectContainer = super._hitContainer;
			_gasEmitter = new ParticleExample1();
			_gasEmitter.init();
			
			_gasEmitterEntity = EmitterCreator.create( group, container, _gasEmitter, 665, 1130, null, "gasEmitter" );
		}
		
		private function moveOutOfBackRoom(zoneId:String, characterId:String):void
		{
			if (characterId == "player") {
				Spatial(super.player.get(Spatial)).x = 1530;
			}
		}
		
		private function startParticles(zoneId:String, characterId:String):void{
			//trace("start particles");
			_gasEmitter.startGas();
			var audioComponent:Audio = _gasEmitterEntity.get(Audio);
			audioComponent.playCurrentAction("doorOpened");
			
		}
		
		private function stopParticles(zoneId:String, characterId:String):void{
			//trace("stop particles");
			_gasEmitter.stopGas();
			var audioComponent:Audio = _gasEmitterEntity.get(Audio);
			audioComponent.stopActionAudio("doorOpened");
		}
		
		private function shakeBeadDoor($interactor:Entity, $interacted:Entity):void{
			for (var i:uint=1; i<=6; i++) {
				Timeline(this["_beadString" + i].get(Timeline)).gotoAndPlay(13-i*2);
			}
		}
		
		/*
		// NOTE :: From Bard, we are creating cards differently now, doesn't seem like you are actually using these methods anyway
		private function loadCard():void
		{
		if(cardView != null){
		super.removeGroup(cardView);
		cardView = null;
		}
		cardView = new CardView(super.overlayContainer);
		super.addChildGroup(cardView);
		}
		
		private function centerCard():void{
		cardView.groupContainer.x = super.shellApi.viewportWidth/2;
		cardView.groupContainer.y = super.shellApi.viewportHeight/2;
		cardView.groupContainer.visible = false;
		cardView.introAnimate();
		}
		*/
		
		private var cardView : CardView;
		
		private var _gasEmitter:ParticleExample1;
		private var _gasEmitterEntity:Entity;
		private var _timer:Timer;
		private var _downButton:Entity;
		private var _upButton:Entity;
		private var _movingElevator:Boolean = false;
		private var elevator:Entity;
		private var _downPoints:Array;
		private var _upPoints:Array;
		private var _doorSensors:Entity;
		private var _sensors:Entity;
		private var _doorC:Entity;
		private var virusEvents:VirusHunterEvents;
		private var usedPhoto:Boolean = false;
		private var popup:VirusPopupVideo ;
		
		private var _beadString1:Entity;
		private var _beadString2:Entity;
		private var _beadString3:Entity;
		private var _beadString4:Entity;
		private var _beadString5:Entity;
		private var _beadString6:Entity;
		
	}
}