package game.scenes.deepDive3.mainDeck
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Zone;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.deepDive3.shared.DroneGroup;
	import game.scenes.deepDive3.shared.MemoryModuleGroup;
	import game.scenes.deepDive3.shared.SubsceneLightingGroup;
	import game.scenes.deepDive3.shared.components.TriggerDoor;
	import game.scenes.deepDive3.shared.groups.LifeSupportGroup;
	import game.scenes.deepDive3.shared.groups.ShipTakeOffGroup;
	import game.scenes.deepDive3.shared.groups.TriggerDoorGroup;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class MainDeck extends SubScene
	{
		public var galaxySound:String = SoundManager.EFFECTS_PATH+"computer_processing_01_loop.mp3";
		
		private var _lowQuality:Boolean;
		private var _redClosed:Boolean;
		
		private var _events3:DeepDive3Events;
		
		private var _moduleGroup:MemoryModuleGroup;
		private var _triggerDoorGroup:TriggerDoorGroup;
		private var _droneGroup:DroneGroup;
		private var _lightingGroup:SubsceneLightingGroup;
		private var _lifeSupportGroup:LifeSupportGroup;
		
		private var _lightOverlay:Entity;
		private var _doorButton:Entity;
		private var _doorButton2:Entity;
		private var _galaxyInteraction:Entity;
		private var _doorOn:Entity;

		public function MainDeck()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive3/mainDeck/";
			
			super.init(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}

		// all assets ready
		override public function loaded():void
		{
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				_lowQuality = true;	
			}
			else{
				_lowQuality = false;
			}
			
			_moduleGroup = MemoryModuleGroup(addChildGroup(new MemoryModuleGroup(this,_hitContainer,_events3.STAGE_2_ACTIVE)));
			
			_triggerDoorGroup = super.addChildGroup(new TriggerDoorGroup()) as TriggerDoorGroup;
			setupTriggerDoor();
		
			setupButtons();
			
			_lightingGroup = super.addChildGroup(new SubsceneLightingGroup(this)) as SubsceneLightingGroup;
			
			setupLights();
			
			setupTank();
			
			_lifeSupportGroup = super.addChildGroup(new LifeSupportGroup(this)) as LifeSupportGroup;
			setupPipes();
			
			setupCockpitDoor();
			
			setupLabDoor();
			
			setupFirstAlienContact();
			
			if(!shellApi.checkEvent(_events3.STAGE_2_ACTIVE)){
				_moduleGroup.startMemory.addOnce(startMemory);
				_moduleGroup.finishedMemory.addOnce(finishedMemory);
			}
			
			if(shellApi.checkEvent(_events3.SPOKE_WITH_AI)){
				// launch sequence stuff
				SceneUtil.addTimedEvent(this, new TimedEvent(2.2,0,toggleDoors));
				AudioUtils.play(this, SoundManager.AMBIENT_PATH + "alarm_01.mp3", 1.0, true);			
			}
			
			// if stage 3 - add 2 drones to scene
			if(super.shellApi.checkEvent(_events3.STAGE_3_ACTIVE) && !super.shellApi.checkEvent(_events3.SPOKE_WITH_AI))
			{
				_droneGroup = new DroneGroup(this, super._hitContainer);
				_droneGroup.dronesCreated.addOnce(setupDrones);
				this.addChildGroup(_droneGroup);
				
				_droneGroup.createSceneDrones(2, new <Spatial>[
					new Spatial(352,1354),
					new Spatial(804,2652)]);
			}
			
			if(this.shellApi.checkEvent(_events3.SPOKE_WITH_AI)){
				addChildGroup( new ShipTakeOffGroup( this, _lightingGroup.lightOverlayEntity ));// this, .9, true ));
			//	this.addSystem( new ShipTakingOffSystem(this,_lightingGroup.lightOverlayEntity, .9, true, false));
			}
			super.loaded();
		}
		
		private function setupDrones(...p):void{
			_droneGroup.setNeanderSpatials(new <Spatial>[
				new Spatial(980,566),							// galaxy map
				new Spatial(1048,2700),							// kelp at bottom of scene
				new Spatial(1650,550)]);						// creature in tank
		}
		
		private function setupLabDoor():void
		{
			// kill door
			var door:Entity = getEntityById("door2");
			var wall:Entity = getEntityById("labGate");
			
			// bitmap drones
			convertContainer(_hitContainer["droid0"],PerformanceUtils.defaultBitmapQuality);
			convertContainer(_hitContainer["droid1"],PerformanceUtils.defaultBitmapQuality);
			
			// drones block lab
			if(shellApi.checkEvent(_events3.SPOKE_WITH_AI))
			{
				addSystem(new WaveMotionSystem());
				removeEntity(door);
				var d1:Entity = EntityUtils.createMovingEntity(this, _hitContainer["droid0"]);
				MotionUtils.addWaveMotion(d1,new WaveMotionData("y",10,.040),this);
				var d2:Entity =	EntityUtils.createMovingEntity(this, _hitContainer["droid1"]);
				MotionUtils.addWaveMotion(d2,new WaveMotionData("y",10,.042),this);
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["droid0"]);
				_hitContainer.removeChild(_hitContainer["droid1"]);
				removeEntity(wall);
			}
		}
		
		private function startMemory(...p):void
		{
			super.playerSay("happenAgain");
		}
		
		private function finishedMemory(...p):void
		{
			super.playerSay("something", alienTalk);
		}
		
		private function alienTalk(...p):void
		{
			lifesupportOn();
			this.playAlienMessage("this", "that", 2, what);
		}		
		
		private function what(...p):void
		{
			super.playerSay("what");	// TODO :: This should be in the dialogue xml. -bard
		}
		
		private function lifesupportOn():void
		{
			_lightingGroup.updateToStage2();
			setupTank();
			setupPipes();
		}
		
		private function setupCockpitDoor():void
		{
			if( shellApi.checkEvent(_events3.STAGE_3_ACTIVE) )
			{
				_hitContainer.removeChild(_hitContainer["doorOff"]);
				var clip:MovieClip;
				
				if(shellApi.checkEvent(_events3.SPOKE_WITH_AI))
				{
					clip = _hitContainer["doorOn"];
					clip.gotoAndStop("open");
					super.convertToBitmap( clip );
					removeEntity(getEntityById("door0"));	//remove exit to cockpit
				}
				else
				{
					// create door open entity
					clip = _hitContainer["doorOn"];
					convertContainer( clip, PerformanceUtils.defaultBitmapQuality);
					_doorOn = EntityUtils.createSpatialEntity(this, clip);
					TimelineUtils.convertClip(clip, this, _doorOn, null, false);
					
					// remove radial hit blocking entrance into the cockpit
					removeEntity(getEntityById("bigGate"));
					
					if( !shellApi.checkEvent(_events3.COCKPIT_UNLOCKED) )
					{
						// pause and show this door opening to player
						seeGateOpen();
						shellApi.completeEvent(_events3.COCKPIT_UNLOCKED);
					}
					else
					{
						Timeline(_doorOn.get(Timeline)).gotoAndStop("opened");
					}
				}
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["doorOn"]);
				super.convertToBitmap( _hitContainer["doorOff"] );
				removeEntity(getEntityById("door0"));	//remove exit to cockpit
			}
		}
		
		private function seeGateOpen():void
		{
			SceneUtil.lockInput(this, true, false);
			var tl:Timeline = Timeline(_doorOn.get(Timeline));
			var handler:Function = Command.create(tl.gotoAndPlay,"open");
			tl.handleLabel("opened", cameraToPlayer);
			tl.handleLabel("opened", Command.create(playerSay,"heyDoor"));
			SceneUtil.setCameraTarget(this, _doorOn, false, 0.2);
			SceneUtil.delay(this, 1.8, handler);
		}
		
		private function cameraToPlayer(...p):void
		{
			SceneUtil.setCameraTarget(this, shellApi.player, false, 0.05);
			SceneUtil.lockInput(this, false,false);
		}
		
		private function setupTank():void
		{
			var clip:MovieClip;
			var quality:Number = PerformanceUtils.defaultBitmapQuality;
			if(shellApi.checkEvent(_events3.STAGE_2_ACTIVE))
			{
				clip = _hitContainer["tankOn"];
				clip.visible = true;
				super.convertToBitmapSprite( clip, null, true, quality );
				
				_hitContainer.removeChild(_hitContainer["tankOff"]);
			}
			else
			{
				clip = _hitContainer["tankOff"];
				super.convertToBitmapSprite( clip, null, true, quality );
				
				clip = _hitContainer["tankOn"];
				clip.visible = false;
			}
		}
		
		private function setupPipes():void
		{
			var pipeId:String = "lsPipe";
			if(super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE))
			{
				var foregroundId:String = ( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST ) ? "foreground" : "foreground_mobile";
				var foreground:DisplayObjectContainer =  super.getEntityById(foregroundId).get(Display).displayObject;
				
				_lifeSupportGroup.activatePipes( super._hitContainer, foreground, pipeId );
			}
			else if(super.shellApi.checkEvent(_events3.STAGE_1_ACTIVE))
			{
				_lifeSupportGroup.pipesOff( super._hitContainer, pipeId );
			}
			else
			{
				_lifeSupportGroup.pipesRemove( super._hitContainer, pipeId );
			}
		}
		
		/**
		 * Create galaxy display is stage 3 has been actived, otherwise remove.
		 */
		private function setupLights():void
		{
			var i:int = 0
			var totalLights:int = 3
			if( shellApi.checkEvent(_events3.STAGE_3_ACTIVE) )
			{
				// bitmap lights
				var clip:MovieClip;
				for ( i; i <= totalLights; i++) 
				{
					clip = _hitContainer["light"+i];
					DisplayUtils.moveToTop(clip);
					super.convertToBitmap( clip, PerformanceUtils.defaultBitmapQuality);
				}
				
				//create galaxy
				clip = _hitContainer["galaxy"];
				convertContainer( clip, PerformanceUtils.defaultBitmapQuality );	// TODO :: May need to increase this due to rotation
				if(!this._lowQuality){
					var galaxy:Entity = EntityUtils.createSpatialEntity( this, clip );
					TimelineUtils.convertClip( clip, this, galaxy );
				}else{
					clip.stop();
				}
				//create galaxy interaction
				_galaxyInteraction = EntityUtils.createSpatialEntity(this, _hitContainer["galaxyArea"]);
				ToolTipCreator.addToEntity(_galaxyInteraction);
				var inter:Interaction = InteractionCreator.addToEntity(_galaxyInteraction,[InteractionCreator.CLICK]);
				inter.click.addOnce(lookGalaxy);
				
				AudioUtils.playSoundFromEntity(_galaxyInteraction,galaxySound, 700, 0.1, 1.2, Quad.easeInOut);

			}
			else
			{
				for ( i; i <= totalLights; i++) 
				{
					_hitContainer.removeChild(_hitContainer["light"+i]);
				}
				_hitContainer.removeChild(_hitContainer["galaxy"]);
				_hitContainer.removeChild(_hitContainer["galaxyArea"]);
			}
		}
		
		private function lookGalaxy(...p):void
		{
			SceneUtil.setCameraTarget(this, _galaxyInteraction,false, .1);
			SceneUtil.lockInput(this, true, false);
			playerSay("notAtlantis",finishMap);
		}
		
		private function finishMap(...p):void
		{
			_galaxyInteraction.get(Interaction).click.addOnce(lookGalaxy);
			cameraToPlayer();
		}
		
		private function setupButtons():void
		{
			convertContainer(_hitContainer["doorButton"],1);
			_doorButton =  EntityUtils.createMovingTimelineEntity(this, _hitContainer["doorButton"]);
			var inter:Interaction = InteractionCreator.addToEntity(_doorButton,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.autoSwitchOffsets = false;
			sceneInter.offsetY = 60;
			sceneInter.minTargetDelta.y = 30;
			sceneInter.minTargetDelta.x = 30;
			sceneInter.reached.add(Command.create(pushButton,0,50));
			_doorButton.add(sceneInter);
			_doorButton.add(new Sleep(false,true));
			ToolTipCreator.addToEntity(_doorButton);

			convertContainer(_hitContainer["doorButton1"],1);
			_doorButton2 =  EntityUtils.createMovingTimelineEntity(this, _hitContainer["doorButton1"]);
			inter = InteractionCreator.addToEntity(_doorButton2,[InteractionCreator.CLICK]);
			sceneInter = new SceneInteraction();
			sceneInter.autoSwitchOffsets = false;
			sceneInter.offsetX = 50;
			sceneInter.minTargetDelta.y = 20;
			sceneInter.minTargetDelta.x = 20;
			sceneInter.reached.add(Command.create(pushButton,50,0));
			_doorButton2.add(sceneInter);
			_doorButton2.add(new Sleep(false,true));
			ToolTipCreator.addToEntity(_doorButton2);
		}
		
		private function pushButton(player:Entity, button:Entity, offX:Number, offY:Number):void
		{
			shellApi.triggerEvent("switchHit");
			Timeline(button.get(Timeline)).gotoAndPlay("up");
			var targ:Point = EntityUtils.getPosition(shellApi.player);
			targ.x -= offX;
			targ.y -= offY;
			TweenUtils.globalTo(this,shellApi.player.get(Spatial),0.9,{x:targ.x,y:targ.y, onComplete:buttonPressed, onCompleteParams:[button]},"button_go");
		}
		
		public function buttonPressed(button:Entity):void
		{
			if(shellApi.checkEvent(_events3.STAGE_1_ACTIVE)){
				toggleDoors();
			}else{
				SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,Command.create(playerSay,"buttonPower")));
			}
			Timeline(button.get(Timeline)).gotoAndPlay("down");
		}
		
		private function toggleDoors():void
		{
			if(_redClosed){
				_triggerDoorGroup.closeDoors("set2");
				_triggerDoorGroup.openDoors("set1");
				_redClosed = false;
			}
			else{
				_triggerDoorGroup.closeDoors("set1");
				_triggerDoorGroup.openDoors("set2");
				_redClosed = true;
			}
			shellApi.triggerEvent("openDoor");
		}
		
		private function setupTriggerDoor():void
		{
			_triggerDoorGroup.setupDoors( this, super._hitContainer, "dclip", "d" );
			
			// red
			super.getEntityById("dclip2").get(TriggerDoor).doorSets = ["set1"];
			super.getEntityById("dclip3").get(TriggerDoor).doorSets = ["set1"];
			super.getEntityById("dclip4").get(TriggerDoor).doorSets = ["set1"];
			// green
			super.getEntityById("dclip1").get(TriggerDoor).doorSets = ["set2"];
			super.getEntityById("dclip5").get(TriggerDoor).doorSets = ["set2"];
			super.getEntityById("dclip6").get(TriggerDoor).doorSets = ["set2"];
			
			_triggerDoorGroup.openDoors("set1");
		}

		private function setupFirstAlienContact():void 
		{
			var doorZone:Entity = getEntityById("doorTalkZone");
			if(!shellApi.checkEvent(_events3.HEARD_ALIEN_IN_CB))
			{
				Zone(doorZone.get(Zone)).entered.addOnce(runAlienContact);
			}else{
				removeEntity(doorZone);
			}
		}
		
		private function runAlienContact(...p):void 
		{
			SceneUtil.lockInput(this, true);
			this.playAlienMessage("alienSpeak", "englishSpeak", 0, endAlienTransmission);
		}

		private function endAlienTransmission():void 
		{
			shellApi.completeEvent(_events3.HEARD_ALIEN_IN_CB);
			var dummy:Entity = getEntityById(SubScene.PLAYER_ID);
			var dialog:Dialog = dummy.get(Dialog);
			dialog.sayById("whatWasThat");
			SceneUtil.lockInput(this, false);
		}
	}
}