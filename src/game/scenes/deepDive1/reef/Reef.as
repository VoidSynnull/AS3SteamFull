package game.scenes.deepDive1.reef
{
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.Timer;
	import game.components.entity.Sleep;
	import game.components.hit.Mover;
	import game.components.hit.Zone;
	import game.components.motion.Proximity;
	import game.components.motion.RotateControl;
	import game.components.motion.RotateToVelocity;
	import game.components.motion.TargetSpatial;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.sound.SoundModifier;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.CuttleFishTarget;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.Fish;
	import game.scenes.deepDive1.shared.components.FishPath;
	import game.scenes.deepDive1.shared.components.Geyser;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.deepDive1.shared.creators.BubblesCreator;
	import game.scenes.deepDive1.shared.creators.GeyserCreator;
	import game.scenes.deepDive1.shared.data.BubbleGraphics;
	import game.scenes.deepDive1.shared.data.FishData;
	import game.scenes.deepDive1.shared.data.FishPathData;
	import game.scenes.deepDive1.shared.data.OutsideControlled;
	import game.scenes.deepDive1.shared.data.SwimStyle;
	import game.scenes.deepDive1.shared.groups.SubGroup;
	import game.scenes.deepDive1.shared.systems.FishPathSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ProximitySystem;
	import game.systems.motion.RotateToVelocitySystem;
	import game.systems.motion.SwarmSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	
	public class Reef extends SubScene
	{
		private var photoIndexCuttle:Array = [18];
		private var photoIndexStoneFish:Array = [20];
		private var photoIndexBarrel:Array = [3];
		
		// rotations for the fish
		private var rotationGuide:Array = [0,0,180,-180, 0,0 ,0,0,0,0,0,0,0,0,0, 0,0,0,0,0 ,0];
		
		private var barrelEye:Entity;
		private var stoneFish:Entity;
		private var hydroMedusa:Entity;
		
		private var barreleyePath:FishPath;
		private var stoneFishPath:FishPath;
		
		private var _commentToggle:Boolean = false 
		private var _bubbles:Entity; // nape bubbles
		
		// cuttle fish game vars
		private var cuttleFishArray:Vector.<Entity>;
		private var cuttleFishTargets:Vector.<Entity>;
		private var stoneFishHidden:Boolean = true;
		private var barrelMoveDelay:TimedEvent;
		
		private var rightJetHits:Mover;
		private var upJetHits:Mover;		
		
		public function Reef()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive1/reef/";
			
			//super.showHits=true;
			
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
			shellApi.eventTriggered.add(handleEvents);
			
			super.addSystem(new FishPathSystem(),SystemPriorities.move);
			super.addSystem(new RotateToVelocitySystem(),SystemPriorities.move);
			super.addSystem(new ProximitySystem());

			if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH )
			{
				setupBgFish();
			}else{
				removeEntity(getEntityById("fishBackdrop"));
			}

			if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH )
			{
				super.addLight(super.shellApi.player, 450, .45, true, false, 0x000033, 0x000033);
			}

			if(PlatformUtils.isDesktop && PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH)
			{
				setupBubbles();
			}
			
			setupWayPoints();
			
			setupCuttleFishPuzzle();
			
			setupStoneFish();
			
			setupBarrelEyePuzzle();

			setupHyromedusa();
			
			if(shellApi.checkEvent(_events.CAPTURED_ALL_FISH) && !shellApi.checkEvent(_events.SAW_HYDROMEDUSA)){
				startHydroMedusaSeq();
			}
	
			var subCamera:SubCamera = super.shellApi.player.get(SubCamera);
			subCamera.angle = 120;
			subCamera.distanceMax = 400;
			subCamera.distanceMin = 0;
			
			super.loaded();
		}
		
		private function setupHyromedusa():void
		{
			hydroMedusa = addFishEntity("hydroMedusa");
			hydroMedusa.add(setupFishPath(hydroMedusa, 200, 4, 5, null, null));
			hydroMedusa.add(new Sleep(true,true));
		}
		
		private function handleEvents(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.CAPTURED_ALL_FISH){
				startHydroMedusaSeq();
			}
		}
		
		private function startHydroMedusaSeq():void
		{
			if(!shellApi.checkEvent(_events.SAW_HYDROMEDUSA)){
				lock();
				SceneUtil.addTimedEvent(this, new TimedEvent(2,1,medusaMessage));
			}
		}
		
		private function medusaMessage():void
		{
			hydroMedusa.add(new Sleep(false,true));
			SceneUtil.setCameraTarget(this, hydroMedusa);
			super.playMessage("look_jellyfish", exitMedusa);
		}
		
		private function exitMedusa(...p):void
		{
			//leave son!
			var target:Point = EntityUtils.getPosition(getEntityById("nav5"));
			TweenUtils.entityTo(hydroMedusa,Spatial,5.5,{x:target.x, y:target.y, rotation:33, ease:Quadratic.easeInOut, onComplete:Command.create(hideMedusa,hydroMedusa)},"jelly");
		}
		
		private function hideMedusa(medusa:Entity):void
		{
			lookAtPlayer(true);
			removeEntity(medusa);
			shellApi.triggerEvent(_events.SAW_HYDROMEDUSA, true);
		}
		
		private function setupStoneFish():void
		{
			stoneFish = addFishEntity("stoneFish");
			addEyes(stoneFish, EntityUtils.getDisplay(stoneFish).displayObject["pupil"]);
			stoneFishPath = setupFishPath(stoneFish,200, 19, 20, photoIndexStoneFish, new SwimStyle());
			stoneFish.add(stoneFishPath);
			stoneFish.remove(RotateToVelocity);
			var prox:Proximity = new Proximity(400,shellApi.player.get(Spatial));
			prox.entered.add(hideStonefish);
			stoneFish.add(prox);
			var hidingZone:Entity = getEntityById("hiddenZone");
			Zone(hidingZone.get(Zone)).entered.add(hideSub);
			Zone(hidingZone.get(Zone)).exitted.add(hideStonefish);
			stoneFish.add(new Tween());
		}
		
		private function hideSub(...p):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(3.5,1,showStonefish),"stonefishTimer");
		}
		
		private function showStonefish(...p):void
		{
			if(stoneFishHidden){
				stoneFishPath.getCurrentData().swimStyle.advanceTo(1,true);
				var targ:Point = stoneFishPath.getCurrentData().targetPosition;
				Tween(stoneFish.get(Tween)).killAll();
				TweenUtils.entityTo(stoneFish,Spatial,3,{x:targ.x,y:targ.y},"moveStoneFish", 0);
				stoneFishHidden = false;
				shellApi.triggerEvent("fishMoveSound");
			}
		}
		
		private function hideStonefish(...p):void
		{
				var timer:Timer = SceneUtil.getTimer(this, "stonefishTimer");
				if(timer && timer.timedEvents.length > 0){
					for each (var i:TimedEvent in timer.timedEvents) 
					{
						i.stop();
					}
				}
				stoneFishPath.getCurrentData().swimStyle.advanceTo(0,true);
				var targ:Point = stoneFishPath.getCurrentData().targetPosition;
				Tween(stoneFish.get(Tween)).killAll();
				TweenUtils.entityTo(stoneFish,Spatial,1,{x:targ.x,y:targ.y},"moveStoneFish", 0);
				if(!stoneFishHidden){
					shellApi.triggerEvent("fishMoveSound");
				}
				stoneFishHidden = true;
		}
		
		private function setupBarrelEyePuzzle():void
		{
			// jet hits
			var right:Entity = getEntityById("airRight");
			var up:Entity = getEntityById("airUp");
			rightJetHits = right.get(Mover);
			upJetHits = up.get(Mover);
			// fishy
			barrelEye = addFishEntity("barrelEye");
			addEyes(barrelEye, EntityUtils.getDisplay(barrelEye).displayObject["eye"]);
			if(!shellApi.checkEvent(_events.BARRELEYE_CAPTURED)){
				barreleyePath = setupFishPath(barrelEye,400,0,3,photoIndexBarrel, new OutsideControlled());
			}
			else{
				barreleyePath = setupFishPath(barrelEye,400,3,3,photoIndexBarrel, new OutsideControlled());
			}
			barrelEye.add(barreleyePath);
			
			var bubbleBitmapData:BitmapData = BitmapUtils.createBitmapData(_hitContainer["bubbleA"]);	// BitmapData or particles shared by all emitters
			for (var i:int = 0; i < 3; i++) 
			{
				var fishJet:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["jetInt"+i]);
				GeyserCreator.create(fishJet, _hitContainer["jetInt"+i]["bubblePt"], bubbleBitmapData,this, false);
				var interactiveJet:Entity = getEntityById("jetInteraction"+i);
				GeyserCreator.create(interactiveJet, _hitContainer["jetInteraction"+i]["bubblePt"], bubbleBitmapData,this, true);
				
				if(PlatformUtils.isMobileOS)
				{
					this.convertContainer(_hitContainer["jetInteraction"+i]);
					this.convertContainer(_hitContainer["jetInt"+i]);
				}
				
				var jetzone:Zone = getEntityById("jetZone"+i).get(Zone);
				jetzone.exitted.add(Command.create(openJet, fishJet, interactiveJet));
				
				var inter:Interaction = interactiveJet.get(Interaction);
				var sceneInter:SceneInteraction = interactiveJet.get(SceneInteraction);
				sceneInter.minTargetDelta.x = 20;
				sceneInter.minTargetDelta.y = 20;
				
				//inter.click.add(lock);
				inter.click.add(killCollider);
				if(i!=2){
					sceneInter.offsetX += Spatial(shellApi.player.get(Spatial)).width/4;
				}else{
					sceneInter.offsetY -= Spatial(shellApi.player.get(Spatial)).height/4;
				}
				sceneInter.reached.add(Command.create(barreLjetReached,fishJet,barrelEye));
			}
		}
		
		private function barreLjetReached(player:Entity, blockedJet:Entity, fishJet:Entity, fish:Entity):void
		{
			blockJet(blockedJet,fishJet,fish);
			moveFishTest(blockedJet,fishJet,fish);
			blockedJet.get(Timeline).gotoAndPlay("start");
			fishJet.get(Timeline).gotoAndPlay("start");
			Timeline(fishJet.get(Timeline)).handleLabel("startEnd",Command.create(fireJet,fishJet));
			var barrelEyeInter:Entity = getEntityById("barrelEyeInteraction");
			if(barrelEyeInter){
				Interaction(barrelEyeInter.get(Interaction)).removeAll();
				removeEntity(barrelEyeInter,true);
			}
			lock();
		}
		
		private function killCollider(...p):void
		{
			var right:Entity = getEntityById("airRight");
			var up:Entity = getEntityById("airUp");
			if(!rightJetHits){
				rightJetHits = right.get(Mover);
			}
			if(!upJetHits){
				upJetHits = up.get(Mover);
			}
			right.remove(Mover);
			up.remove(Mover);
		}
		
		private function delayRestore(fish:Entity, jet:Entity):void{
			SceneUtil.addTimedEvent(this,new TimedEvent(3.5,1,Command.create(restoreCollider, fish, jet)));
		}
		
		private function restoreCollider(fish:Entity, jet:Entity):void
		{
			var right:Entity = getEntityById("airRight");
			var up:Entity = getEntityById("airUp");
			right.add(rightJetHits);
			up.add(upJetHits);
			fireJet(jet);
		}
		
		private function cameraFollowFish(fish:Entity=null, duration:Number = 0):void
		{
			SceneUtil.setCameraTarget(this,fish,false,0.05);
			
			if( duration > 0 )
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(duration, 1, lookAtPlayer));
			}
		}
		
		private function lookAtPlayer(deLock:Boolean = true):void
		{
			unlock();
			SceneUtil.setCameraTarget(this,shellApi.player,false,0.05);
		}
		
		private function openJet(z:String, zz:String, remoteJet:Entity, blockedJet:Entity):void
		{
			var blockedGeyser:Geyser = blockedJet.get(Geyser);
			var fishGeyser:Geyser = remoteJet.get(Geyser);
			if(!blockedGeyser.on){
				blockedGeyser.on = true;
				blockedGeyser.turnOn();
				fishGeyser.turnOff();
				delayRestore(null,blockedJet);
			}
			AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "LavaSurf_01_L.mp3", "jet");
		}
		
		private function blockJet(blockedJet:Entity, remoteJet:Entity, fish:Entity):void
		{
			var blockedGeyser:Geyser = blockedJet.get(Geyser);
			//var fishGeyser:Geyser = remoteJet.get(Geyser);
			if(blockedGeyser.on){
				blockedGeyser.on = false;
				blockedGeyser.turnOff();
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "LavaSurf_01_L.mp3",3,true, [SoundModifier.FADE],"jet");
			}
		}
		
		// check fo fish in front of jet, move fish
		private function moveFishTest(blockedJet:Entity, fishJet:Entity, fish:Entity):void
		{
			var fishClip:MovieClip = fish.get(Display).displayObject;
			var jetClip:MovieClip = fishJet.get(Display).displayObject;
			if(jetClip.hitTestObject(fishClip)){
				if(barrelMoveDelay){
					barrelMoveDelay.stop();
				}
				barrelMoveDelay = SceneUtil.addTimedEvent(this,new TimedEvent(1.8,1,Command.create(moveBarrelEye,fishJet,blockedJet)));
			}else{
				SceneUtil.addTimedEvent(this,new TimedEvent(2,1,unlock));
				delayRestore(null,blockedJet);
				//SceneUtil.addTimedEvent(this,new TimedEvent(2.2,1,delayRestore));
			}
			//SceneUtil.addTimedEvent(this,new TimedEvent(1.8,1,Command.create(fireJet,fishJet)));
		}
		
		private function fireJet(jet:Entity):void
		{
			var geyser:Geyser = jet.get(Geyser);
			geyser.turnOn();
			Timeline(jet.get(Timeline)).gotoAndPlay("turnOn");
			var str:String = Id(jet.get(Id)).id.substring(0,6);
			if(str == "jetInt"){
				shellApi.triggerEvent("jetBlockSound");
			}
		}
		
		private function moveBarrelEye(remoteJet:Entity, blockedJet:Entity):void
		{
			var pathdata:FishPathData = barreleyePath.getCurrentData();
			barreleyePath.pathTargetReached.addOnce(Command.create(delayRestore, blockedJet));
			pathdata.swimStyle.advanceTo(barreleyePath.currentIndex+1);
			cameraFollowFish(barrelEye,3);
			shellApi.triggerEvent("fishMoveSound");
		}
		
		private function setupWayPoints(hideNavs:Boolean = true):void
		{
			for (var i:int = 0; i <= 20; i++) 
			{
				var targ:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["nav"+i]);
				targ.add(new Id("nav"+i));
				targ.get(Display).visible = !hideNavs;
			}
		}
		
		private function setupCuttleFishPuzzle():void
		{
			// set posible targets or fish
			cuttleFishTargets = new Vector.<Entity>();
			var nav1:Entity = getEntityById("nav14");
			var nav2:Entity = getEntityById("nav15");
			var nav3:Entity = getEntityById("nav16");
			var nav4:Entity = getEntityById("nav17");
			var nav5:Entity = getEntityById("nav18");
			nav1.add(new CuttleFishTarget([nav2,nav3]));
			nav2.add(new CuttleFishTarget([nav1,nav3,nav4,nav5]));
			nav3.add(new CuttleFishTarget([nav1,nav2,nav4]));
			nav4.add(new CuttleFishTarget([nav2,nav3,nav5]));
			nav5.add(new CuttleFishTarget([nav4,nav2]));
			cuttleFishTargets.push(nav1,nav2,nav3,nav4,nav5);
			// load the fish
			cuttleFishArray = new Vector.<Entity>();
			for (var i:int = 0; i < 4; i++)
			{
				var fish:Entity = addFishEntity("cuttlefish"+i);
				addEyes(fish, EntityUtils.getDisplay(fish).displayObject["pupil"]);
				var path:FishPath;
				cuttleFishArray.push(fish);
				if(i == 0){
					path = setupFishPath(fish, 400, 14, 18, photoIndexCuttle, new OutsideControlled());	
					path.currentIndex = i;
					cuttleFishTargets[i].get(CuttleFishTarget).occupant = fish;
				}else{
					path = setupFishPath(fish, 400, 14, 18, null, new OutsideControlled());
					path.currentIndex = i+1;
					cuttleFishTargets[i+1].get(CuttleFishTarget).occupant = fish;
				}
				path.idleLabel = path.movingLabel = "idle";
				fish.add(path);
				var prox:Proximity = new Proximity(400,shellApi.player.get(Spatial));
				prox.entered.add(spookCuttleFish);
				fish.add(prox);
				fish.get(Timeline).gotoAndPlay(path.idleLabel);
			}
		}
		
		private function spookCuttleFish(fish:Entity):void
		{
			// parse targets, find empty one, move cuttle to it
			for (var i:int = 0; i < cuttleFishTargets.length; i++) 
			{
				var nav:Entity = cuttleFishTargets[i];
				var navTarg:CuttleFishTarget = nav.get(CuttleFishTarget);
				var owningFish:Entity = navTarg.occupant;
				if(owningFish == fish){
					var opening:Entity = navTarg.findOpening();
					if(opening){
						var openingTarg:CuttleFishTarget = opening.get(CuttleFishTarget);
						openingTarg.occupant = fish;
						fish.get(FishPath).getCurrentData().swimStyle.advanceTo(cuttleFishTargets.indexOf(opening));
						navTarg.occupant = null;
						shellApi.triggerEvent("squidMoveSound");
						break;
					}
				}
			}
		}
		
		private function addFishEntity(name:String):Entity
		{
			var clip:MovieClip = _hitContainer[name];
			if(!PlatformUtils.isDesktop)
			{
				this.convertContainer(clip);
			}
			
			var fish:Entity = EntityUtils.createMovingEntity(this, clip);
			fish = TimelineUtils.convertClip(clip,this,fish);
			TimelineUtils.convertAllClips(clip, fish, this);
			
			fish.add(new Id(name));
			var rot:RotateToVelocity = new RotateToVelocity(0,0.7);
			rot.mirrorHorizontal = true;
			rot.originY = fish.get(Spatial).scaleY;
			rot.originX = fish.get(Spatial).scaleX;
			fish.add(rot);
			MotionUtils.addWaveMotion(fish, new WaveMotionData("y",7,0.1),this);
			
			var id:String = String(fish.get(Id).id).toLowerCase();
			if(id == "cuttlefish0"){ id = "cuttlefish"; }
			var isCaptured:Boolean = shellApi.checkEvent( id + _events.CAPTURED);
			super.makeFilmable(fish,onFishFilmed,250,4.5,false,true,isCaptured);
			
			return fish;
		}
		
		private function onFishFilmed( fish:Entity ):void
		{
			var id:String = fish.get(Id).id;
			var filmable:Filmable = fish.get(Filmable);
			if(id == "cuttlefish0"){
				handleFilmStates(fish, filmable, _events.CUTTLEFISH_CAPTURED);
			}
			else if(id == "stoneFish"){
				handleFilmStates(fish, filmable, _events.STONEFISH_CAPTURED);
			}
			else if(id == "barrelEye"){
				handleFilmStates(fish, filmable, _events.BARRELEYE_CAPTURED);
			}
			else{
				super.playMessage( "fishNotNeeded" );
			}
		}
		
		private function handleFilmStates(fish:Entity, filmable:Filmable, sucessEvent:String):void
		{
			var fishId:String = fish.get(Id).id;
			if( fishId == "cuttlefish0" ) 
			{
				fishId = "cuttleFish";
			}
			if(!shellApi.checkEvent(sucessEvent))
			{
				switch( filmable.state )
				{
					case filmable.FILMING_OUT_OF_RANGE:
					{
						//super.playMessage( "tooFar" );
						break;
					}
					case filmable.FILMING_BLOCK:
					{
						if( filmable.hasIntro )
						{
							filmable.hasIntro = false;
							this.lock();
							this.cameraFollowFish( fish );
							super.playMessage( fishId + "Intro", lookAtPlayer );
						}
						else
						{
							if( _commentToggle )
							{
								super.playMessage( fishId + "Blocked1" );
							}
							else
							{
								super.playMessage( fishId + "Blocked2" );
							}
							_commentToggle = !_commentToggle;
						}
						break;
					}
					case filmable.FILMING_START:
					{
						super.playMessage( "filmStart" );
						break;
					}
					case filmable.FILMING_STOP:
					{
						super.playMessage( "filmStop" );
						break;
					}
					case filmable.FILMING_COMPLETE:
					{
						SceneUtil.addTimedEvent(this,new TimedEvent(0.3,1,Command.create(super.playMessage,"filmComplete" )));
						shellApi.completeEvent(sucessEvent);
						logFish( String(fishId).toLowerCase() );
						break;
					}
					default:
					{
						trace( "invalid state: " + filmable.state );
						break;
					}
				}
			}
			else
			{
				super.playMessage( "fishAlreadyCaptured" );
			}
		}
		
		private function setupFishPath(fish:Entity,swimSpeed:Number = 200, startIndex:int=0, endIndex:int=1, filmableIndeces:Array=null, swimStyle:SwimStyle= null):FishPath
		{
			var path:FishPath = new FishPath();
			for (var i:int = startIndex; i <= endIndex; i++) 
			{
				var targ:Entity = getEntityById("nav"+i);
				var pathData:FishPathData = new FishPathData(EntityUtils.getPosition(targ),swimSpeed,rotationGuide[i],3,false,null,new SwimStyle());
				if(swimStyle){
					pathData.swimStyle = swimStyle;
				}
				// enable photo oppertunity
				if(filmableIndeces){
					if(filmableIndeces.indexOf(i)>-1){
						pathData.filmable = true;
					}
				}
				path.data.push(pathData);
			}
			return path;
		}
		
		/**
		 * Set up eyes to follow input target (cursor)
		 * @param fish
		 * @param pupilMC
		 */
		private function addEyes(fish:Entity, pupilMC:MovieClip):void
		{
			// Add the pupil and set it up to rotate with the player
			var pupil:Entity = new Entity();
			pupil.add(new Spatial(pupilMC.x, pupilMC.y));
			pupil.add(new Display(pupilMC));
			pupil.add(new Id("playerEye"));
			pupil.add(new TargetSpatial(this.shellApi.inputEntity.get(Spatial)));
			var rotateControl:RotateControl = new RotateControl();
			rotateControl.origin = fish.get(Spatial);
			rotateControl.targetInLocal = true;
			rotateControl.ease = .3;
			//rotateControl.adjustForViewportScale = true;
			rotateControl.syncHorizontalFlipping = true; // TODO :: This is temporary, want a standalone system that manages parent scale and rotation
			pupil.add(rotateControl);
			EntityUtils.addParentChild(pupil, fish);
			this.addEntity(pupil);
		}
		
		private function lock(...p):void
		{
			SceneUtil.lockInput(this,true,true);
		}
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this,false,false);
		}
		
		// not photo fish
		private function setupBgFish():void
		{
			//var fishcontainer:Sprite = new Sprite();
			//EntityUtils.getDisplayObject(getEntityById("backdrop")).addChild(fishcontainer);
			var fishcontainer:DisplayObjectContainer = EntityUtils.getDisplayObject(getEntityById("fishBackdrop"));
			fishcontainer.mouseEnabled = false;
			fishcontainer.mouseChildren = false;
			var fishAsset:String = "scenes/deepDive1/shared/fish/miniFish.swf";
			var group:SubGroup = super.getGroupById(SubGroup.GROUP_ID) as SubGroup;
			var fishData:FishData = new FishData();
			fishData.asset = fishAsset;
			fishData.type = "sil";
			fishData.minVelocity = 50;
			fishData.maxVelocity = 200;
			fishData.targetOffset = 50;
			fishData.friction = 100;
			fishData.component = Fish;
			super.addSpawnFish(fishcontainer);
			super.fishCreator.createOffscreenSpawn("sil", fishData, this, 6, 0.5, super.shellApi.camera.target);
		}
		
		private function setupBubbles():void{
			/**
			 * Some of this code is temporary until I have a firmer setup method - Bart
			 */
			BubbleGraphics.BUBBLE_1 = super._hitContainer["bubble1"]; // get graphic from scene (TEMP)
			BubbleGraphics.BUBBLE_2 = super._hitContainer["bubble2"]; // get graphic from scene (TEMP)
			BubbleGraphics.BUBBLE_3 = super._hitContainer["bubble3"]; // get graphic from scene (TEMP)
			
			var bubbleCreator:BubblesCreator = new BubblesCreator(this, super.shellApi.player, super._hitContainer["bubblesHolder"]); // init creator
			_bubbles = bubbleCreator.CreateBubbleField(60, super._hitContainer.width, super._hitContainer.height, false); // create bubble field
		}
		
		private function fishLoaded(entity:Entity):void
		{
			this.addSystem(new SwarmSystem(), SystemPriorities.update);
		}
	}
}