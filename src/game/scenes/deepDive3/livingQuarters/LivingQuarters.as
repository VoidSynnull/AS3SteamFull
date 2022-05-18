package game.scenes.deepDive3.livingQuarters
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.data.display.SharedBitmapData;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.deepDive3.shared.DroneGroup;
	import game.scenes.deepDive3.shared.MemoryModuleGroup;
	import game.scenes.deepDive3.shared.SubsceneLightingGroup;
	import game.scenes.deepDive3.shared.components.TriggerDoor;
	import game.scenes.deepDive3.shared.groups.LifeSupportGroup;
	import game.scenes.deepDive3.shared.groups.TriggerDoorGroup;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class LivingQuarters extends SubScene
	{
		private var _moduleGroup:MemoryModuleGroup;
		private var _triggerDoorGroup:TriggerDoorGroup;
		private var _lifeSupportGroup:LifeSupportGroup;
		
		private var _events3:DeepDive3Events;
		
		private var doorButton:Entity;
		private var redClosed:Boolean = false;
		private var lowQuality:Boolean;
		private var lights:Array;
		//private var lifeSupportGroup:LifeSupportGroup;
		private var lightOverlay:Entity;
		private var _droneGroup:DroneGroup;
		private var _lightingGroup:SubsceneLightingGroup;
		
		public function LivingQuarters()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive3/livingQuarters/";
			
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
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				lowQuality = true;	
			}
			else{
				lowQuality = false;
			}
			
			_moduleGroup = MemoryModuleGroup(addChildGroup(new MemoryModuleGroup(this,_hitContainer,_events3.STAGE_1_ACTIVE)));
			
			if(!shellApi.checkEvent(_events3.STAGE_1_ACTIVE)){
				//moduleGroup.startMemory.addOnce(startMemory);
				_moduleGroup.finishedMemory.addOnce(finishedMemory);
			}
			
			//if(shellApi.checkEvent(_events3.STAGE_2_ACTIVE)){
				//lifeSupportGroup = LifeSupportGroup(addChildGroup(new LifeSupportGroup(this,_hitContainer)));
			//}
			
			_triggerDoorGroup = super.addChildGroup(new TriggerDoorGroup()) as TriggerDoorGroup;
			setupTriggerDoor();

			setupButton();
			
			//super.shellApi.eventTriggered.add(handleEventTriggered);
			
			_lightingGroup = super.addChildGroup(new SubsceneLightingGroup(this)) as SubsceneLightingGroup;

			setupLights();
			
			_lifeSupportGroup = super.addChildGroup(new LifeSupportGroup(this)) as LifeSupportGroup;
			setupPipes();
			
			// if stage 3 - add 2 drones to scene
			if(super.shellApi.checkEvent(_events3.STAGE_3_ACTIVE))
			{
				_droneGroup = new DroneGroup(this, super._hitContainer);
				_droneGroup.dronesCreated.addOnce(setupDronePointsOfInterest);
				this.addChildGroup(_droneGroup);
				
				_droneGroup.createSceneDrones(2, new <Spatial>[
					new Spatial(444,1564),
					new Spatial(2756,488)]);
			
			}

			super.loaded();
		}
		
		private function setupDronePointsOfInterest(...p):void{
			_droneGroup.setNeanderSpatials(new <Spatial>[
				new Spatial(444,1564),							// point of interest
				new Spatial(2272,2112),							// point of interest
				new Spatial(2756,488)]);						// point of interest
		}
		
		private function setupPipes():void
		{
			var pipeId:String = "lsPipe";
			if(super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE))
			{
				var foregroundEntity:Entity = this.getEntityById("foreground");
				if(!foregroundEntity)
				{
					foregroundEntity = this.getEntityById("foreground_mobile");
				}
				var foreground:DisplayObjectContainer = foregroundEntity.get(Display).displayObject;
				_lifeSupportGroup.activatePipes( super._hitContainer, foreground, pipeId );
			}
			else
			{
				_lifeSupportGroup.pipesRemove( super._hitContainer, pipeId );
			}
		}
		
		
		// generate shared bitmaped lights for each  type
		private function setupLights():void
		{
			lights = new Array();
			var light:Entity;
			var lightClip:MovieClip;
			var data:SharedBitmapData;
			var quality:Number = .6;
			for (var i:int = 0; i <= 9; i++) 
			{
				lightClip = _hitContainer["light"+i];
				if(!data){
					data = BitmapUtils.createBitmapData(lightClip, quality);
				}
				light = EntityUtils.createSpatialEntity(this,BitmapUtils.createBitmapSprite(lightClip, quality, null, true, 0, data), _hitContainer);
				lights.push(light);
				lightClip.parent.removeChild(lightClip);
				Display(light.get(Display)).moveToBack();
			}
			data = null;
			for (i=10; i <= 14; i++) 
			{
				lightClip = _hitContainer["light"+i];
				if(!data){
					data = BitmapUtils.createBitmapData(lightClip, quality);
				}
				light = EntityUtils.createSpatialEntity(this,BitmapUtils.createBitmapSprite(lightClip,quality,null,true,0, data),_hitContainer);
				lights.push(light);
				lightClip.parent.removeChild(lightClip);
				Display(light.get(Display)).moveToBack();
			}
			data = null;
			for (i=15; i <= 26; i++) 
			{
				lightClip = _hitContainer["light"+i];
				if(!data){
					data = BitmapUtils.createBitmapData(lightClip, quality);
				}
				light = EntityUtils.createSpatialEntity(this,BitmapUtils.createBitmapSprite(lightClip,quality,null,true,0, data),_hitContainer);
				lights.push(light);
				lightClip.parent.removeChild(lightClip);
				Display(light.get(Display)).moveToBack();
			}
			data = null;
			for (i=0; i <= 8; i++) 
			{
				lightClip = _hitContainer["glow"+i];
				if(!data){
					data = BitmapUtils.createBitmapData(lightClip, quality);
				}
				light = EntityUtils.createSpatialEntity(this,BitmapUtils.createBitmapSprite(lightClip,quality,null,true,0, data),_hitContainer);
				lights.push(light);
				lightClip.parent.removeChild(lightClip);
				Display(light.get(Display)).moveToBack();
			}
			// hide lights if event unfinished
			if(!shellApi.checkEvent(_events3.STAGE_1_ACTIVE)){
				updateLights(false);
			}
		}
		
		private function updateLights(on:Boolean=true):void
		{
			for each (var light:Entity in lights) 
			{
				Display(light.get(Display)).visible = on;	
			}
		}
		
		private function startMemory(...p):void
		{
			SceneUtil.lockInput(this,true);
			//super.playerSay("feelStrange");
		}
		
		private function finishedMemory(...p):void
		{
			super.playerSay("whatARush",alienTalk);
			SceneUtil.addTimedEvent(this, new TimedEvent(.1,1,Command.create(SceneUtil.lockInput,this,true)));
		}
		
//		private function whatMean(...p):void
//		{
//			super.playerSay("whatARush2",alienTalk);
//		}
		
		private function alienTalk(...p):void
		{
			updateLights(true);
			_lightingGroup.updateToStage1();
			this.playAlienMessage("this", "that", 1, thatyou);
		}		
		
		private function thatyou(...p):void
		{
			super.playerSay("thatYou",closeDoor);
		}
		
		private function closeDoor(...p):void{
			// close red door
			_triggerDoorGroup.closeDoors("set1");
			shellApi.triggerEvent("openDoor");
			
			lookAtLockedDoor();
		}
		
		private function lookAtLockedDoor():void
		{
			var door:Entity = getEntityById("dclip3");
			SceneUtil.setCameraTarget(this,door,false,0.2);
			SceneUtil.lockInput(this, true,false);
			SceneUtil.addTimedEvent(this, new TimedEvent(2.3, 1, cameraToPlayer));
		}
		
		private function cameraToPlayer():void
		{
			SceneUtil.setCameraTarget(this, shellApi.player, false, 0.2);
			SceneUtil.addTimedEvent(this, new TimedEvent(.5, 1,Command.create( playerSay,"trapped", unlock)));
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this,false,false);
		}
		
		private function toggleDoors():void
		{
			if(redClosed){
				_triggerDoorGroup.closeDoors("set2");
				_triggerDoorGroup.openDoors("set1");
				redClosed = false;
			}
			else{
				_triggerDoorGroup.closeDoors("set1");
				_triggerDoorGroup.openDoors("set2");
				redClosed = true;
			}
			shellApi.triggerEvent("openDoor");
		}
		
		private function setupTriggerDoor():void 
		{	
			_triggerDoorGroup.setupDoors( this, super._hitContainer, "dclip", "d" );
			
			super.getEntityById("dclip1").get(TriggerDoor).doorSets = ["set2"];
			super.getEntityById("dclip2").get(TriggerDoor).doorSets = ["set2"];
			super.getEntityById("dclip3").get(TriggerDoor).doorSets = ["set1"];
			
			// default to 1 door open unless door system is powered
			if(shellApi.checkEvent(_events3.STAGE_1_ACTIVE))
			{
				_triggerDoorGroup.openDoors("set2");	
				redClosed = true;
			}
			else{
				_triggerDoorGroup.openDoors("set1");
			}
		}
		
		private function setupButton():void
		{
			BitmapUtils.convertContainer(_hitContainer["doorButton"],1);
			doorButton =  EntityUtils.createMovingTimelineEntity(this, _hitContainer["doorButton"]);
			var inter:Interaction = InteractionCreator.addToEntity(doorButton,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.autoSwitchOffsets = false;
			sceneInter.offsetY = 50;
			sceneInter.minTargetDelta.y = 30;
			sceneInter.minTargetDelta.x = 30;
			sceneInter.reached.add(Command.create(pushButton,0,50));
			doorButton.add(sceneInter);
			doorButton.add(new Sleep(false,true));
			ToolTipCreator.addToEntity(doorButton);
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
			}
			Timeline(button.get(Timeline)).gotoAndPlay("down");
		}
		
		
	}
}