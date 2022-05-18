package game.scenes.deepDive3.laboratory
{
	import com.greensock.plugins.HexColorsPlugin;
	import com.greensock.plugins.TweenPlugin;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.data.AudioWrapper;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Sleep;
	import game.components.entity.collider.CircularCollider;
	import game.components.entity.collider.GravityWellCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.GravityWell;
	import game.components.hit.Radial;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.Zone;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.deepDive3.laboratory.particles.WaterVortexParticles;
	import game.scenes.deepDive3.shared.DroneGroup;
	import game.scenes.deepDive3.shared.MemoryModuleGroup;
	import game.scenes.deepDive3.shared.SubsceneLightingGroup;
	import game.scenes.deepDive3.shared.components.Drone;
	import game.scenes.deepDive3.shared.components.TriggerDoor;
	import game.scenes.deepDive3.shared.drone.states.DroneState;
	import game.scenes.deepDive3.shared.groups.LifeSupportGroup;
	import game.scenes.deepDive3.shared.groups.TriggerDoorGroup;
	import game.systems.hit.GravityWellSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	TweenPlugin.activate([HexColorsPlugin]);
	
	public class Laboratory extends SubScene
	{
		public function Laboratory()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive3/laboratory/";
			
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
			super.loaded();
			
			_events3 = DeepDive3Events(events);

			_moduleGroup = MemoryModuleGroup(addChildGroup(new MemoryModuleGroup(this,_hitContainer,_events3.STAGE_3_ACTIVE)));
			
			if(super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE))
			{
				if(!super.shellApi.checkEvent(_events3.STAGE_3_ACTIVE))
				{
					_moduleGroup.finishedMemory.addOnce(finishedMemory);
				}
			}
			
			_lightingGroup = super.addChildGroup(new SubsceneLightingGroup(this)) as SubsceneLightingGroup;

			setupHoles();
			setupZones();
			_lifeSupportGroup = super.addChildGroup(new LifeSupportGroup(this)) as LifeSupportGroup;
			setupPipes();
			setupCreature();
			setupGravityWell();
			_triggerDoorGroup = super.addChildGroup(new TriggerDoorGroup()) as TriggerDoorGroup;
			setupTriggerDoor();
			setupButton();
			setupDrone();
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH){
				createParticles();
			}

			if(super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE)){
				removeGlassWall();
			}
			
			
			_soundEntity = new Entity();
			// all that is needed to playback sounds from an entity is an Audio component.
			_soundEntity.add(new Audio());
			
			// adding an id to an entity allows it to be associated with sound effects specified in 'sounds.xml'.  This is not required unless you want
			//   to map sounds from sounds.xml to it.
			_soundEntity.add(new Id("soundEntity"));
			super.addEntity(_soundEntity);
			
			try{
				soundManager.cache(SoundManager.EFFECTS_PATH + "metal_impact_02.mp3"); // precache sound
				soundManager.cache(SoundManager.EFFECTS_PATH + "metal_impact_03.mp3"); // precache sound
				soundManager.cache(SoundManager.EFFECTS_PATH + "hork.mp3"); // precache sound
				soundManager.cache(SoundManager.EFFECTS_PATH + "monsters_1.mp3"); // precache sound
			} catch($error:Error){
				trace($error.getStackTrace());
			}
		}
		
		private function createParticles():void{
			_particles = new WaterVortexParticles();
			_particlesEmitter = EmitterCreator.create(this, _hitContainer, _particles);
			
			Spatial(_particlesEmitter.get(Spatial)).x = 3000;
			Spatial(_particlesEmitter.get(Spatial)).y = 1800;
			
			_particles.init(_particlesEmitter.get(Spatial));
			
			//_particles.sparkle();
		}
		
		public function testAlarm():void{
			_lightingGroup.alarmFlash();
		}
		
		public function playMsg():void{
			this.playAlienMessage("this", "that", 3, endAlienTransmission);
		}
		
		private function endAlienTransmission():void{
			
		}
		
		private function setupDrone():void
		{
			_droneGroup = new DroneGroup(this, super._hitContainer);
			this.addChildGroup(_droneGroup);
			
			if(!super.shellApi.checkEvent(_events3.STAGE_3_ACTIVE))
			{
				_drone = _droneGroup.makeDrone(super._hitContainer["drone"], DroneState.SLEEP);
			} else {
				super._hitContainer["drone"].visible = false;
				_droneGroup.dronesCreated.addOnce(setupDronePointsOfInterest);
				_droneGroup.createSceneDrones(2, new <Spatial>[
				this.getEntityById("zoneF3").get(Spatial),
				this.getEntityById("zoneS").get(Spatial)]);
			}
		}
		
		private function setupDronePointsOfInterest(...p):void{
			_droneGroup.setNeanderSpatials(new <Spatial>[
			new Spatial(1266,748),							// broken creature tank
			this.getEntityById("zoneF3").get(Spatial),		// large hole in wall
			new Spatial(636,1216),							// creature tank
			new Spatial(1084,1892)]);						// creature tank
		}
		
		public function finishedMemory(...p):void{
			wakeDrone();
		}
		
		public function wakeDrone():void{
			var fsmControl:FSMControl = _drone.get(FSMControl);
			fsmControl.setState("wake");
			Drone(_drone.get(Drone)).stateChange.add(finishWake);
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this, _drone);
		}
		
		private function finishWake(state:String):void{
			if(state == "idle"){
				Drone(_drone.get(Drone)).stateChange.removeAll();
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, followPlayer));
			}
		}
		
		private function followPlayer():void{
			SceneUtil.setCameraTarget(this, this.shellApi.player);
			// scan player
			var fsmControl:FSMControl = _drone.get(FSMControl);
			fsmControl.setState("scan");
			SceneUtil.addTimedEvent(this, new TimedEvent(4, 1, neanderDrone));
		}
		
		private function neanderDrone():void{
			playMsg();
			var fsmControl:FSMControl = _drone.get(FSMControl);
			fsmControl.setState("neander");
			SceneUtil.lockInput(this, false);
		}
		
		private function setupButton():void
		{
			BitmapUtils.convertContainer(_hitContainer["doorButton"],1);
			_doorButton =  EntityUtils.createMovingTimelineEntity(this, _hitContainer["doorButton"]);
			var inter:Interaction = InteractionCreator.addToEntity(_doorButton,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.autoSwitchOffsets = false;
			sceneInter.offsetX = 50;
			sceneInter.minTargetDelta.y = 20;
			sceneInter.minTargetDelta.x = 20;
			sceneInter.reached.add(pushButton);
			_doorButton.add(sceneInter);
			_doorButton.add(new Sleep(false,true));
			ToolTipCreator.addToEntity(_doorButton);
		}
		
		private function pushButton(player:Entity, button:Entity):void
		{
			shellApi.triggerEvent("switchHit");
			Timeline(_doorButton.get(Timeline)).gotoAndPlay("up");
			TweenUtils.globalTo(this,shellApi.player.get(Spatial),0.9,{x:shellApi.player.get(Spatial).x+30, onComplete:buttonPressed},"button_go");
		}
		
		public function buttonPressed():void
		{
			if(shellApi.checkEvent(_events3.STAGE_2_ACTIVE))
			{
				toggleDoors();
			}
			Timeline(_doorButton.get(Timeline)).gotoAndPlay("rise");
		}
		
		private function toggleDoors():void
		{
			if(_redClosed)
			{
				_triggerDoorGroup.closeDoors("set2");
				_triggerDoorGroup.openDoors("set1");
			}
			else
			{
				_triggerDoorGroup.closeDoors("set1");
				_triggerDoorGroup.openDoors("set2");
			}
			_redClosed = !_redClosed;
			shellApi.triggerEvent("openDoor");
		}
		
		private function setupTriggerDoor():void
		{
			_triggerDoorGroup.setupDoors( this, super._hitContainer, "dclip", "d" );
			
			super.getEntityById("dclip1").get(TriggerDoor).doorSets = ["set1"];
			super.getEntityById("dclip2").get(TriggerDoor).doorSets = ["set2"];
			
			_triggerDoorGroup.openDoors("set2");
			_redClosed = true;
		}
		
		private function setupGravityWell():void
		{
			_well = EntityUtils.createSpatialEntity(this, _hitContainer["gravityWell"], _hitContainer);
			_well.add(new GravityWell(1000, 2300, 100, false));
			//_well.add(new GravityWell(1000, 2300, 50, false));
			this.addSystem(new GravityWellSystem());
		}
		
		private function setupCreature():void
		{
			if(super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE) || !super.shellApi.checkEvent(_events3.STAGE_1_ACTIVE))
			{
				this._hitContainer.removeChild(this._hitContainer["creature"]);
			} 
			else 
			{
				_creature = EntityUtils.createSpatialEntity(this, this._hitContainer["creature"], this._hitContainer);
				_creature = TimelineUtils.convertClip(this._hitContainer["creature"], this, _creature);
				
				BitmapUtils.convertContainer(this._hitContainer["creature"],PerformanceUtils.defaultBitmapQuality);
				
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST){
					DisplayUtils.moveToTop(this._hitContainer["creature"]);
				}
				
				if(super.shellApi.checkEvent(_events3.LAB_CREATURE_REVEALED)){
					Timeline(_creature.get(Timeline)).gotoAndStop("on");
				} else {
					// TODO :: Could use a single handler instead of 6. - bard
					Timeline(_creature.get(Timeline)).handleLabel("flicker1", flicker, false);
					Timeline(_creature.get(Timeline)).handleLabel("flicker2", flicker, false);
					Timeline(_creature.get(Timeline)).handleLabel("flicker3", flicker, false);
					Timeline(_creature.get(Timeline)).handleLabel("flicker4", flicker, false);
					Timeline(_creature.get(Timeline)).handleLabel("flicker5", flicker, false);
					Timeline(_creature.get(Timeline)).handleLabel("flicker6", flicker, false);
				}
			}
		}
		
		private function flicker(...p):void{
			super.shellApi.triggerEvent("containerFlicker");
		}
		
		private function setupPipes():void
		{
			var pipeId:String = "lsPipe";
			if(super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE))
			{
				var foreground:DisplayObjectContainer;
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST)
				{
					var foregroundEntity:Entity = super.getEntityById("foregroundS2");
					if( foregroundEntity )
					{
						foreground =  EntityUtils.getDisplayObject(foregroundEntity);
					}
				}
				_lifeSupportGroup.activatePipes( super._hitContainer, foreground, pipeId );
			}
			else
			{
				_lifeSupportGroup.pipesRemove( super._hitContainer, pipeId );
			}
		}
		
		private function removeGlassWall():void
		{
			this.getEntityById("glassWall").remove(Radial);
		}
		
		private function setupHoles():void
		{
			var clip:MovieClip = _hitContainer["hole1"];
			BitmapUtils.convertContainer( clip, PerformanceUtils.defaultBitmapQuality );
			fishHole1 = TimelineUtils.convertClip(clip, this, null, null, false);
			
			clip = _hitContainer["hole2"];
			BitmapUtils.convertContainer( clip, PerformanceUtils.defaultBitmapQuality );
			fishHole2 = TimelineUtils.convertClip(clip, this, null, null, false);
			
			clip = _hitContainer["hole3"];
			BitmapUtils.convertContainer( clip, PerformanceUtils.defaultBitmapQuality );
			fishHole3 = TimelineUtils.convertClip(clip, this, null, null, false);
			
			Timeline(fishHole3.get(Timeline)).labelReached.add(labelHandlerCreature);
		}
		
		private function labelHandlerCreature( label:String ):void
		{
			switch(label)
			{
				case "bite":
					super.shellApi.triggerEvent("creatureChomp");
					break;			
				case "popOut":
					super.shellApi.triggerEvent("creaturePopOut");
					break;
				case "popIn":
					_eating = false;
					super.shellApi.triggerEvent("creaturePopIn");
					// reset suck 
					//Timeline(fishHole3.get(Timeline)).handleLabel("suck", suckIn, true);	// Not sure why this is necessary?
					break;
				case "suck":
					if(!_eating){
						suckIn();
					}
					break;
				case "munchEnd":
					checkEat();
					break;
				case "spitOut":
					spitPlayer();
					break;
				case "crunch1":
				case "crunch2":
				case "crunch3":
					super.shellApi.triggerEvent("crunch");
					break;
				default:
					break;
			}
		}
		
		private function suckIn(...p):void{
			// play sucking sound
			AudioUtils.playSoundFromEntity(fishHole3, SoundManager.EFFECTS_PATH + "myth_water_fall_01_loop.mp3", 500, 0.2, 1.8);
			
			_eating = true;
			
			// suck either memory module or player in
			if(_suckEntityID != "player"){
				var orbMotion:Motion = _moduleGroup.memoryOrb.get(Motion);
				orbMotion.zeroAcceleration();
				orbMotion.zeroMotion();
				
				var tween:Tween = _moduleGroup.memoryOrb.get(Tween);
				var spatial:Spatial = _moduleGroup.memoryOrb.get(Spatial);
				tween.to(spatial, 0.6, {x:2993, y:1791, onComplete:eatOrb});
			} else {
				// disable player controls and stop ship
				SceneUtil.lockInput(this);
				Motion(shellApi.player.get(Motion)).zeroAcceleration();
				Motion(shellApi.player.get(Motion)).zeroMotion();
				
				shellApi.player.add(new GravityWellCollider());
				// add collider check between player and gravity well center
				GravityWell(_well.get(GravityWell)).hitSignal.addOnce(eatPlayer);
			}
			if(_particles)
				_particles.sparkle();
		}
		
		private function eatOrb():void{
			fishHole3.remove(Audio);
			
			if(_particles)
				_particles.sparkle(0);
			
			_moduleGroup.fadeOrb(false, true);
			Timeline(fishHole3.get(Timeline)).gotoAndPlay("startBite");
		}
		
		private function eatPlayer():void
		{
			fishHole3.remove(Audio);
			
			if(_moduleGroup.memoryOrb){
				if(_moduleGroup.memoryOrb.get(SceneObjectHit).active){
					_moduleGroup.fadeOrb(false);
				}
			}
			
			super.shellApi.player.remove(GravityWellCollider);
			
			if(_particles)
				_particles.sparkle(0);
			
			var motion:Motion = super.shellApi.player.get(Motion);
			
			motion.zeroAcceleration();
			motion.zeroMotion();
			
			Display(super.shellApi.player.get(Display)).alpha = 0;
			
			Timeline(fishHole3.get(Timeline)).gotoAndPlay("startBite");
		}
		
		private function checkEat():void
		{
			if(_suckEntityID == "player"){
				Timeline(fishHole3.get(Timeline)).gotoAndPlay("spit");
			} else {
				Timeline(fishHole3.get(Timeline)).gotoAndPlay("retractActual");
			}
		}
		
		private function cancelEat():void{
			if(_moduleGroup.memoryOrb != null)
				_moduleGroup.fadeOrb(false);
			
			fishHole3.remove(Audio);
			super.shellApi.player.remove(GravityWellCollider);
			
			if(_particles)
				_particles.sparkle(0);
			
			Timeline(fishHole3.get(Timeline)).gotoAndPlay("retractActual");
			
			// restore player control
			//CharUtils.lockControls(this.shellApi.player, false);
			
			// if orb is out, let it be bounced again
		}
		
		private function spitPlayer():void{
			super.shellApi.triggerEvent("hork");
			Display(super.shellApi.player.get(Display)).alpha = 1;
			
			var motion:Motion = super.shellApi.player.get(Motion);
			motion._rotation = 100;
			motion.velocity = new Point(-1000,0);
			
			var sceneObjectCollider:SceneObjectCollider = new SceneObjectCollider();
			
			shellApi.player.add(sceneObjectCollider);
			shellApi.player.add(new CircularCollider());
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, releasePlayer));
		}
		
		private function releasePlayer():void{
			SceneUtil.lockInput(this, false);
			//CharUtils.lockControls(this.shellApi.player, false);
		}
		
		private function setupZones():void
		{
			// zone L
			entity = super.getEntityById("zoneL");
			zone = entity.get(Zone);
			zone.pointHit = true;
			zone.entered.add(handleZoneEntered);
			
			if(!super.shellApi.checkEvent(_events3.STAGE_3_ACTIVE))
			{
				// zone 1
				var entity:Entity = super.getEntityById("zoneF1");
				var zone:Zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
				
				// zone 2
				entity = super.getEntityById("zoneF2");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
				
				// zone 3
				entity = super.getEntityById("zoneF3");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
				
				// zone S
				entity = super.getEntityById("zoneS");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
				
				// zone P
				entity = super.getEntityById("zoneP");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
				
				// zone P2
				entity = super.getEntityById("zoneP2");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
				
				// zone D
				entity = super.getEntityById("zoneD");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
				
				// zone D2
				entity = super.getEntityById("zoneD2");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
				
			}
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{
			switch(zoneId){
				case "zoneF1":
					if(!fishHole1Played){
						Timeline(fishHole1.get(Timeline)).play();
						fishHole1Played = true;
						//super.shellApi.triggerEvent("hearMovement2");
					}
					break;
				case "zoneF2":
					if(!fishHole2Played){
						Timeline(fishHole2.get(Timeline)).play();
						fishHole2Played = true;
						super.shellApi.triggerEvent("hearMovement2");
					}
					break;
				case "zoneF3":
					if(!super.shellApi.checkEvent(_events3.STAGE_3_ACTIVE)){
						if(!_eating){
							_suckEntityID = characterId;
						}
						Timeline(fishHole3.get(Timeline)).play();
						if(!_firstPopout){
							super.shellApi.triggerEvent("revealCreature");
							_firstPopout = true;
						}
					}
					break;
				case "zoneS":
					if(super.shellApi.checkEvent(_events3.STAGE_1_ACTIVE) && !super.shellApi.checkEvent(_events3.LAB_CREATURE_REVEALED) && !super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE)){
						lookAtGlass();
					} else if(super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE) && !_creatureEscaped1){
						creatureEscaped();
					}
					break;
				case "zoneL":
					if(super.shellApi.checkEvent(_events3.STAGE_1_ACTIVE) && !super.shellApi.checkEvent(_events3.LAB_CREATURES)){
						//super.playerSay("living", resetControl);
						super.shellApi.completeEvent(_events3.LAB_CREATURES);
					}
					break;
				case "zoneP":
					if(!_creatureEscaped2){
						creatureEscaped2();
					}
					break;
				case "zoneP2":
					if(!_creatureEscaped3){
						creatureEscaped3();
					}
					break;
				case "zoneD":
					if(_eating && characterId == "player"){
						cancelEat();
					}
					break;
				case "zoneD2":
					if(_eating && characterId == "player"){
						cancelEat();
					}
					break;
			}
		}
		
		private function creatureEscaped():void
		{
			super.playerSay("creatureEscaped1", hearMovement);
			SceneUtil.lockInput(this);
			
			var motion:Motion = super.shellApi.player.get(Motion);
			
			faceRight();
			
			//motion.pause = true;
			motion.zeroAcceleration();
			motion.zeroMotion();
			
			TweenUtils.entityTo(super.shellApi.player, Spatial, 1, {x:980,y:748, onComplete:faceRight});
		}
		
		private function creatureEscaped2():void
		{
			// flicker and dim lights
			_lightColor1 = _lightingGroup.lightOverlay.color;
			_lightColor2 = _lightingGroup.playerLight.color2;
			_lightAlpha = _lightingGroup.playerLight.lightAlpha;
			_darkAlpha = _lightingGroup.playerLight.darkAlpha;
			
			_lightingGroup.flickerLights(lightsOff);
			
			// play spooky sound
			super.shellApi.triggerEvent("hearMovement3");
			
			_creatureEscaped2 = true;
		}
		
		
		private function creatureEscaped3():void
		{
			super.shellApi.triggerEvent("hearMovement3");
			_lightingGroup.flickerLights(lightsOn);
			_creatureEscaped3 = true;
		}
		
		private function lightsOff():void{
			_lightingGroup.tweenLightAlpha(0.9, 0.6, 1);
		}
		
		private function lightsOn():void{
			_lightingGroup.tweenLightAlpha(_darkAlpha, _lightAlpha, 1);
		}
		
		private function hearMovement(...p):void{
			super.shellApi.triggerEvent("hearMovement");
			
			_camPoint2 = EntityUtils.createSpatialEntity(this, _hitContainer["camPoint2"], _hitContainer);
			SceneUtil.setCameraTarget(this, _camPoint2, false, .1);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, heardSomething));
			_creatureEscaped1 = true;
		}
		
		private function heardSomething(...p):void{
			resetControl();
			super.playerSay("creatureEscaped2");
		}
		
		private function lookAtGlass():void{
			super.shellApi.triggerEvent(_events3.LAB_CREATURE_REVEALED, true);
			
			super.playerSay("creature",revealCreature);
			SceneUtil.lockInput(this);
			
			// move player to point
			
			var tween:Tween = new Tween();
			var spatial:Spatial = super.shellApi.player.get(Spatial);
			var motion:Motion = super.shellApi.player.get(Motion);
			super.shellApi.player.add(tween);
			
			//motion.pause = true;
			motion.zeroAcceleration();
			motion.zeroMotion();
			
			tween.to(spatial, 1, {x:980,y:748, onComplete:faceRight});
			
			// pan camera over slowly
			//var cTween:Tween = new Tween();
			//_camPoint = EntityUtils.createSpatialEntity(this, _hitContainer["camPoint"], _hitContainer);
			//_camPoint.add(cTween);
			
			//var cSpatial:Spatial = _camPoint.get(Spatial);
			
			//cTween.to(cSpatial, 3, {x:1100,y:748});
			
			//SceneUtil.setCameraTarget(this, _camPoint);
			
			// zoom in camera
			
			//var cameraEntity:Entity = super.getEntityById("camera");
			//var camera:Camera = cameraEntity.get(Camera);
			//camera.scaleTarget = 1.15;
			
			//CharUtils.moveToTarget(super.shellApi.player, 960, 748);
		}
		
		private function faceRight():void{
			CharUtils.setDirection(super.shellApi.player, true);
		}
		
		private function revealCreature(...p):void
		{
			//SceneUtil.setCameraTarget(this, _creature);
			Timeline(_creature.get(Timeline)).gotoAndPlay("reveal");
			super.shellApi.triggerEvent("revealCreature");
			super.playerSay("creature2", resetControl);
		}
		
		
		private function resetControl(...p):void{
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = 1;
			
			var motion:Motion = super.shellApi.player.get(Motion);
			motion.pause = false;
			
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, super.shellApi.player);
		}
		
		public function viewMemorySlot():void{
			SceneUtil.setCameraTarget(this, this.getEntityById("memorySlotZone"));
		}
		
		public function activateMemory():void{
			_moduleGroup.activateMemory();
		}
		
		private var _events3:DeepDive3Events;
		
		private var fishHole1:Entity;
		private var fishHole2:Entity;
		private var fishHole3:Entity;
		
		private var fishHole1Played:Boolean = false;
		private var fishHole2Played:Boolean = false;
		
		private var _camPoint:Entity;
		private var _camPoint2:Entity;
		private var _creature:Entity;
		
		private var _creatureEscaped1:Boolean = false;
		private var _creatureEscaped2:Boolean = false;
		private var _creatureEscaped3:Boolean = false;
		
		private var _firstPopout:Boolean = false;
		
		private var _lightOverlay:Entity;
		
		private var _lightColor1:uint;
		private var _lightColor2:uint;
		
		private var _lightAlpha:Number;
		private var _darkAlpha:Number;

		private var _moduleGroup:MemoryModuleGroup;
		private var _triggerDoorGroup:TriggerDoorGroup;
		private var _lifeSupportGroup:LifeSupportGroup;
		private var _droneGroup:DroneGroup;
		
		private var _eating:Boolean = false;
		private var _suckEntityID:String;
		private var _well:Entity;
		private var _redClosed:Boolean;
		private var _doorButton:Entity;
		private var _drone:Entity;

		private var _suckAudio:AudioWrapper;
		private var _lightingGroup:SubsceneLightingGroup;
		private var _particles:WaterVortexParticles;
		private var _particlesEmitter:Entity;
		
		[Inject]
		public var soundManager:SoundManager;
		private var _soundEntity:Entity;
	}
}