package game.scenes.arab2.treasureKeep
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.motion.MotionTarget;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.BigStomp;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Read;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Think;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.TwirlPistol;
	import game.data.animation.entity.character.Walk;
	import game.data.animation.entity.character.WalkNinja;
	import game.data.comm.PopResponse;
	import game.particles.FlameCreator;
	import game.scene.template.CameraGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab1.shared.particles.EmberParticles;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.scenes.arab2.Arab2Events;
	import game.scenes.arab2.cells.Cells;
	import game.scenes.arab2.entrance.Entrance;
	import game.scenes.arab2.shared.MagicSandGroup;
	import game.scenes.arab2.treasureKeep.particles.GoldSparkleParticle;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class TreasureKeep extends PlatformerGameScene
	{
		
		public function TreasureKeep()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab2/treasureKeep/";
			
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
			
			_events = new Arab2Events();
			// setup interactives
			setupInteractives();
			setupLampSequence();
			setupMagicSand();
			setupFire();
			
			// setup click for lamps
			_lampsClick = getEntityById("lampInteraction");
			Display(_lampsClick.get(Display)).alpha = 0;
			if(!this.shellApi.checkItemEvent(_events.MEDAL))
			{
				SceneInteraction(_lampsClick.get(SceneInteraction)).minTargetDelta = new Point(50,50);
				SceneInteraction(_lampsClick.get(SceneInteraction)).validCharStates = new <String>[CharacterState.STAND];
				SceneInteraction(_lampsClick.get(SceneInteraction)).reached.add(onLampsClick);
			}
			
			// setup gold sparkle
			shellApi.loadFile(shellApi.assetPrefix + "scenes/arab2/shared/glint_particle.swf", setupGoldSparkle);
			
			if(!shellApi.checkEvent(_events.PLAYER_ESCAPED_CELL)){
				// First time entering treasureKeep -- cinematic of prisoner placing wrong lamp
				setupNPCs1();
				intro1();
				shellApi.triggerEvent("lamp_action");
				// setup particles for alter smoke
				shellApi.loadFile(shellApi.assetPrefix + "scenes/arab2/shared/smoke_particle_altar.swf", setupAltarSmoke);
				
				// hide unnecessaries
				_hitContainer["correctLamp"].visible = false;
			} else if(shellApi.checkEvent(_events.PLAYER_ESCAPED_CELL) && !shellApi.checkEvent(_events.VIZIER_FOLLOWING)){
				// Second time entering treasureKeep -- to collect white clothes / quickSilver
				setupNPCs2();
				
				this.removeCrumble();
				
				setupCatchZones();
				
				// hide unnecessaries
				_hitContainer["correctLamp"].visible = false;
			} else if(shellApi.checkEvent(_events.VIZIER_FOLLOWING) && !shellApi.checkEvent(_events.PLAYER_CAUGHT_WLAMP)){
				// Third time entering treasureKeep -- with vizier to get lamp.
				setupNPCs3();
				
				this.removeCrumble();
				
				setupVizierZone1();
				
				// put player at entrance by cells
				Spatial(player.get(Spatial)).x = 150;
				Spatial(player.get(Spatial)).y = 1000;
				
				// setup particles for alter smoke
				shellApi.loadFile(shellApi.assetPrefix + "scenes/arab2/shared/smoke_particle_altar.swf", setupAltarSmoke);
				
				// hide unnecessaries
				_hitContainer["correctLamp"].visible = false;
			} else if(shellApi.checkEvent(_events.PLAYER_CAUGHT_WLAMP) && !this.shellApi.checkItemEvent(_events.MEDAL)){
				// Final time entering treasureKeep -- player forced to use lamp on alter
				setupNPCs4();
				intro2();
				
				shellApi.triggerEvent("lamp_action");
				
				this.removeCrumble();
				
				// setup correct lamp
				_correctLamp = EntityUtils.createSpatialEntity(this, _hitContainer["correctLamp"], _hitContainer);
				Display(_correctLamp.get(Display)).visible = false;
				
				// setup genie smoke (for correct lamp)
				shellApi.loadFile(shellApi.assetPrefix + "scenes/arab2/shared/smoke_particle_genie.swf", setupGenieSmoke);
			}
			else
			{
				//Island has been completed
				this.removeCrumble();
				this.removeEntity(this.getEntityById("goldCoins"));
				this.removeEntity(this.getEntityById("masterCoin"));
				this.removeEntity(this.getEntityById("masterThief"));
				this.removeEntity(this.getEntityById("vizier"));
				this.removeEntity(this.getEntityById("jailer"));
				this.removeEntity(this.getEntityById("enforcer"));
				this.removeEntity(this.getEntityById("prisoner"));
			}
		}
		
		private function removeCrumble():void
		{
			this.removeEntity(_crumblePlat);
			_hitContainer.removeChild(_hitContainer["crumble"]);
			this.removeEntity(_crumble);
		}
		
		private function onLampsClick(...p):void
		{
			useLamps();
		}
		
		private function useLamps(...p):void{
			
			if(_goldCoinsFell && shellApi.checkEvent(_events.VIZIER_FOLLOWING)){	
				// lamp popup
				EntityUtils.position(player, _vizier.get(Spatial).x + 150, _vizier.get(Spatial).y);
				MotionUtils.zeroMotion(player);
				CharUtils.setDirection(player, true);
				//SceneUtil.lockInput(this,true);
				var popup:LampPopup = super.addChildGroup(new LampPopup(super.overlayContainer)) as LampPopup;
				popup.id = "lamp_popup";
				popup.completeSignal = new Signal();
				popup.completeSignal.addOnce(gotLamp);
			} else {
				Dialog(player.get(Dialog)).sayById("examineLamps");
			}
		}
		
		private function gotLamp(sucess:Boolean):void{
			if(sucess == true){
				var actChain:ActionChain = new ActionChain(this);
				actChain.lockInput = true;
				actChain.addAction( new SetSkinAction(player, SkinUtils.ITEM, "an2_lamp2", false, true) );
				actChain.addAction( new PanAction(_vizier) );
				actChain.addAction( new TalkAction(_vizier, "gotLamp") );
				actChain.addAction( new CallFunctionAction(enterThiefEnforcer) );
				actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setDirection, player, true) ));
				actChain.addAction( new PanAction(_masterThief) );
				actChain.addAction( new TalkAction(_masterThief, "gotLamp2") );
				actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setDirection, player, false) ));
				actChain.addAction( new PanAction(_vizier) );
				actChain.addAction( new TalkAction(_vizier, "gotLamp3") );
				actChain.addAction( new TalkAction(_vizier, "gotLamp4") );
				actChain.addAction( new MoveAction(_vizier, lampTableTarget, new Point(50, 50)));
				actChain.addAction( new WaitAction(0.01) );
				actChain.addAction( new AnimationAction(_vizier, PointItem, "", 20) );
				actChain.addAction( new SetSkinAction(_vizier, SkinUtils.ITEM, "an2_lamp1", false, true) );
				actChain.addAction( new CallFunctionAction(takeLamp));
				actChain.addAction( new MoveAction(_vizier, altarTarget, new Point(50, 50)));
				actChain.addAction( new WaitAction(0.1) );
				actChain.addAction( new SetSpatialAction(_vizier, new Point( altarTarget.x, 530)));
				actChain.addAction( new SetDirectionAction( player, true));
				actChain.addAction( new CallFunctionAction(faceVizier) );
				actChain.addAction( new WaitAction(0.5) );
				actChain.addAction( new AnimationAction(_vizier, Score, "", 35) );
				actChain.addAction( new CallFunctionAction(lampOnAltar2) );
				actChain.addAction( new PanAction(player) )
				actChain.addAction( new SetDirectionAction( player, true));
				actChain.addAction( new TalkAction(player, "gotLamp5") );
				actChain.addAction( new CallFunctionAction( wrongLamp ) );
				actChain.addAction( new PanAction(_vizier) );
				actChain.addAction( new TalkAction(_vizier, "gotLamp6") );
				actChain.addAction( new CallFunctionAction(doLampMusic) );
				actChain.addAction( new PanAction(player) );
				actChain.addAction( new MoveAction(player, lampTableTarget, new Point(50, 50) ));
				actChain.addAction( new WaitAction(0.01) );
				actChain.addAction( new MoveAction(player, new Point( 1455, 340), new Point(50, 50) ));
				actChain.addAction( new WaitAction(0.01) );
				actChain.addAction( new MoveAction(player, new Point( 1300, 240), new Point(50, 50) ));
				actChain.addAction( new WaitAction(0.01) );
				actChain.addAction( new PanAction(_vizier) );
				actChain.addAction( new WaitAction(1) );
				actChain.addAction( new CallFunctionAction(poof2) );
				actChain.addAction( new WaitAction(2) );
				actChain.addAction( new PanAction(_masterThief) );
				actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setDirection, _masterThief, false) ));
				if(shellApi.profileManager.active.gender == "male"){
					actChain.addAction( new TalkAction(_masterThief, "getAwayM") );
				}else{
					actChain.addAction( new TalkAction(_masterThief, "getAwayF") );
				}
				actChain.addAction( new MoveAction(_enforcer, new Point(1550, 675),new Point(50, 100)) );
				actChain.addAction( new CallFunctionAction( endEscape ));
				
				actChain.execute();
			}
		}
		
		private function doLampMusic(...p):void
		{
			shellApi.triggerEvent("lamp_action");
		}
		
		private function endEscape():void{
			// finish event
			shellApi.completeEvent(_events.PLAYER_ESCAPED_WLAMP);
			SceneUtil.lockInput(this);	
			shellApi.loadScene(Entrance, 855, 2300);
		}
		
		private function enterThiefEnforcer():void{
			Display(_enforcer.get(Display)).visible = true;
			Display(_masterThief.get(Display)).visible = true;
			
			CharUtils.moveToTarget(_enforcer, 2080, 735);
			CharUtils.moveToTarget(_masterThief, 2160, 735);
		}
		
		private function faceVizier():void{
			// face vizier
			CharUtils.setDirection(_enforcer, true);
			CharUtils.setDirection(_masterThief, true);
			
			// shield faces -- add in animation to shield faces (consult with jordan on this)
		}
		
		private function poof2():void{
			this.removeEntity(_vizier);
			makePoof();
			
			this.removeEntity(_redGlow);
			Display(_wrongLamp2.get(Display)).visible = false;
			
			TweenUtils.entityTo(_lightOverlayEntity, Display, 1.5, {alpha:0});
			cameraShake();
		}
		
		private function makePoof():void
		{
			_smokeParticles.puff();
			_emberParticles.puff();		
			AudioUtils.play(this, POOF_SOUND, 2.0);
		}
		
		private function lampOnAltar2():void{
			SkinUtils.emptySkinPart(_vizier, SkinUtils.ITEM );
			// show lamp on altar
			Display(_wrongLamp2.get(Display)).visible = true;
		}
		
		private function setupMagicSand():void
		{
			magicSandGroup = getGroupById(MagicSandGroup.GROUP_ID) as MagicSandGroup;
			if(!magicSandGroup){
				magicSandGroup = MagicSandGroup(this.addChildGroup(new MagicSandGroup(_hitContainer)));
			}			
			magicSandGroup.setupPlatforms();
			magicSandGroup.platEffected.addOnce(fallCoins);
			magicSandGroup.resetTimerEnabled = false;
			//magicSandGroup.effectDuration = 6;
		}
		
		private function fallCoins(...p):void
		{
			var zoneEnt:Entity = super.getEntityById("zoneVizierSneak");
			var zone:Zone = zoneEnt.get(Zone);
			zone.entered.removeAll();
			zone.inside.removeAll();
			removeEntity(getEntityById("zoneCaughtLeft"));
			removeEntity(getEntityById("zoneCaughtRight"));
			removeEntity(getEntityById("zoneVizierStop"));
			
			if(_mcActChain){
				_mcActChain.clearActions();
				_masterCoin.remove(MotionTarget);
			}
			
			updateGoldSparkle();
			var goldCoins:Entity = this.getEntityById("goldCoins");
			Timeline(goldCoins.get(Timeline)).play();
			Timeline(goldCoins.get(Timeline)).handleLabel("end", playCoinSound);
			//var actChain:ActionChain = new ActionChain(this);
			//actChain.lockInput = true;
			_mcActChain = new ActionChain(this);
			_mcActChain.lockInput = true;
			
			_mcActChain.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection, _masterCoin, false)) );
			_mcActChain.addAction(new PanAction(_masterCoin));
			_mcActChain.addAction(new SetSkinAction(_masterCoin, SkinUtils.MOUTH, "distressedMom", true, true) );
			_mcActChain.addAction(new CallFunctionAction(Command.create(CharUtils.setAnim, _masterCoin, Grief)) );
			if(shellApi.checkEvent(_events.DROPPED_COINS)){
				_mcActChain.addAction(new TalkAction(_masterCoin, "chaseGold3"));
			}else{
				_mcActChain.addAction(new TalkAction(_masterCoin, "chaseGold1"));
			}
			_mcActChain.addAction(new MoveAction(_masterCoin, new Point(1180, 735), new Point(20,1000)));
			_mcActChain.addAction(new MoveAction(_masterCoin, new Point(1180, 1260), new Point(50,60)));
			_mcActChain.addAction(new CallFunctionAction( resetSand ) );
			_mcActChain.addAction(new AnimationAction(_masterCoin, Place, "", 120) );
			_mcActChain.addAction(new CallFunctionAction(Command.create(CharUtils.setAnim, _masterCoin, Read)) );
			_mcActChain.addAction(new TalkAction(_masterCoin, "chaseGold2"));
			_mcActChain.addAction(new MoveAction(_masterCoin, new Point(900, 1260), new Point(50,50)));
			_mcActChain.addAction(new CallFunctionAction(countSingleCoin));
			_mcActChain.addAction(new AnimationAction(_masterCoin, Place, "", 90) );
			_mcActChain.addAction(new MoveAction(_masterCoin, new Point(670, 1260), new Point(50,50)));
			_mcActChain.addAction(new CallFunctionAction(countSingleCoin));
			_mcActChain.addAction(new AnimationAction(_masterCoin, Place, "", 90) );
			_mcActChain.addAction(new MoveAction(_masterCoin, new Point(300, 1260), new Point(50,50)));
			_mcActChain.addAction(new CallFunctionAction(countSingleCoin));
			_mcActChain.addAction(new AnimationAction(_masterCoin, Place, "", 90) );
			_mcActChain.addAction(new MoveAction(_masterCoin, new Point(-100, 1260), new Point(50,50)));
			if(_vizier){
				// cant do this without vizier
				_mcActChain.addAction(new PanAction(_vizier));
				_mcActChain.addAction(new MoveAction(_vizier, new Point(870, 725), new Point(50,30)));
				_mcActChain.addAction(new TalkAction(_vizier, "fineWork"));
				_mcActChain.addAction(new PanAction(player));
				_mcActChain.execute(toTheLamps);
			}else{
				_mcActChain.execute(unlock);
			}
			
			shellApi.triggerEvent(_events.DROPPED_COINS, true);
			_goldCoinsFell = true;
		}
		
		private function resetSand():void
		{
			magicSandGroup.resetTimerEnabled = true;
			magicSandGroup.resetSand(getEntityById("magicSandPlat0"),getEntityById("magicSandArt0"));
		}
		
		private function playCoinSound(...p):void
		{
			AudioUtils.play(this, COINS_SOUND, 1.7);
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false, false);
			SceneUtil.setCameraTarget(this, player);
			removeEntity(getEntityById("zoneCaughtRight"));
		}
		
		private function countSingleCoin():void{
			Dialog(_masterCoin.get(Dialog)).allowOverwrite = true;
			Dialog(_masterCoin.get(Dialog)).say(String(_singleCounts)+"...");
			_singleCounts++;
		}
		
		private function toTheLamps(...p):void{
			
			Dialog(player.get(Dialog)).say("Right!");
			
			var actChain:ActionChain = new ActionChain(this);
			
			actChain.addAction(new MoveAction(_vizier, new Point(1650, 735), new Point(50,50)));
			actChain.addAction(new WaitAction(0.01));
			actChain.addAction(new MoveAction(_vizier, sideTableTarget, new Point(50,50)));
			
			actChain.execute();
		}
		
		private function countCoins(...p):void{
			_mcActChain = new ActionChain(this);
			
			_mcActChain.onComplete = countCoins; // loop over and over again
			
			_mcActChain.addAction( new AnimationAction(_masterCoin, PointItem, "", 120) );
			_mcActChain.addAction( new AnimationAction(_masterCoin, Read, "", 120) );
			_mcActChain.addAction( new AnimationAction(_masterCoin, Stand, "", 50) );
			_mcActChain.addAction( new AnimationAction(_masterCoin, PointItem, "", 120) );
			_mcActChain.addAction( new AnimationAction(_masterCoin, Read, "", 120) );
			_mcActChain.addAction( new AnimationAction(_masterCoin, Stand, "", 50) );
			_mcActChain.addAction( new CallFunctionAction( Command.create(changedFaceDirection, false) ) );
			_mcActChain.addAction( new MoveAction(_masterCoin, new Point( 1120, Spatial(_masterCoin.get(Spatial)).y)) ); // come back to main pile of coins
			
			if(_countCount >= 2){
				// pocket the gold (every third coin)
				_mcActChain.addAction( new AnimationAction(_masterCoin, Place, "", 120) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Stand, "", 50) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Read, "", 120) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Think, "", 90) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, TwirlPistol, "", 200) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Stand, "", 50) );
				_countCount = 0;
			} else {
				// place coin on pile
				_mcActChain.addAction( new AnimationAction(_masterCoin, Place, "", 120) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Stand, "", 50) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Read, "", 120) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Place, "", 120) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Read, "", 120) );
				_mcActChain.addAction( new AnimationAction(_masterCoin, Stand, "", 50) );
				_countCount++;
			}
			
			_mcActChain.addAction( new CallFunctionAction( Command.create(changedFaceDirection, true) ) );
			_mcActChain.addAction( new MoveAction(_masterCoin, new Point( 1385, Spatial(_masterCoin.get(Spatial)).y)) );  // go to small pile to right
			
			_mcActChain.execute();
			
		}
		
		private function updateGoldSparkle():void{
			// remove coins in sparkleMap
			if(_coinSparkles){
				_coinSparkles.pause();
				_coinSparkles.killAllParticles();
				_coinSparkles.stop();
			}
			if(_goldCoinEmitter){
				removeEntity(_goldCoinEmitter);
			}
			/*			
			_goldSparkleMap.removeChild(_goldSparkleMap["goldCoins"]);
			var sparkleMap:BitmapData = BitmapUtils.createBitmapData(_goldSparkleMap, 1, null, true);
			
			// remake gold sparkles
			_goldSparkles = new GoldSparkleParticle();
			_goldSparkleEmitter = EmitterCreator.create(this, _hitContainer, _goldSparkles, _hitContainer["sparkleMap"].x, _hitContainer["sparkleMap"].y );
			_goldSparkles.init(sparkleMap, _goldSparkleClip);
			
			DisplayUtils.moveToBack(Display(_goldSparkleEmitter.get(Display)).displayObject);*/
		}
		
		
		private function setupMagicSandParticles():void{
			/*var collisionGroup:CollisionGroup = this.getGroupById("collisionGroup") as CollisionGroup;
			var bitmap:Bitmap = new Bitmap(collisionGroup.hitBitmapData);
			bitmap.x = -collisionGroup.hitBitmapOffsetX;
			bitmap.y = -collisionGroup.hitBitmapOffsetY;
			bitmap.scaleX = bitmap.scaleY = 2;
			
			_hitContainer.addChild(bitmap);
			
			_magicSand = new MagicSandParticle();
			_magicSandEmitter = EmitterCreator.create(this, _hitContainer, _magicSand);
			
			_magicSand.init(collisionGroup.hitBitmapData, collisionGroup.hitBitmapOffsetX, collisionGroup.hitBitmapOffsetY, 2);*/
		}
		
		private function setupCatchZones():void
		{
			// zones in which the player will get "caught" if seen by the master of coin
			var entity:Entity;
			var zone:Zone;
			
			entity = super.getEntityById("zoneCaughtLeft");
			zone = entity.get(Zone);
			zone.pointHit = true;
			zone.inside.add(handleCaught);
			
			entity = super.getEntityById("zoneCaughtRight");
			zone = entity.get(Zone);
			zone.pointHit = true;
			zone.inside.add(handleCaught);
		}
		
		private function handleCaught(zoneId:String, characterId:String):void{
			if(characterId == "player" && !_caughtPlayer){
				switch(zoneId){
					case "zoneCaughtLeft":
						if(!_mcFacingRight){
							catchPlayer();
						}
						break;
					case "zoneCaughtRight":
						if(_mcFacingRight){
							catchPlayer();
						}
						break;
				}
			}
		}
		
		private function setupVizierZone1():void{
			var entity:Entity;
			var zone:Zone;
			
			entity = super.getEntityById("zoneVizierGo");
			zone = entity.get(Zone);
			zone.pointHit = true;
			zone.entered.addOnce(handleVizier);
		}
		
		private function setupVizierZone2():void{
			var entity:Entity;
			var zone:Zone;
			
			entity = super.getEntityById("zoneVizierSneak");
			zone = entity.get(Zone);
			zone.pointHit = true;
			zone.entered.addOnce(handleVizier);
		}
		
		private function handleVizier(zoneId:String, characterId:String):void{
			
			var actChain:ActionChain = new ActionChain(this);
			
			if(characterId == "player"){
				switch(zoneId){
					case "zoneVizierGo":
						actChain.lockInput = true;
						actChain.addAction(new TalkAction(_vizier, "follow"));
						actChain.addAction(new MoveAction(_vizier, new Point(600, 890), new Point(50,50)));
						actChain.addAction(new MoveAction(_vizier, new Point(940, 880), new Point(50,50)));
						actChain.addAction(new CallFunctionAction(setupVizierZone2));
						actChain.addAction(new CallFunctionAction(Command.create(CharUtils.setAnim, _vizier, DuckDown)) );
						actChain.execute();
						break;
					case "zoneVizierSneak":
						actChain.lockInput = true;
						actChain.addAction(new PanAction(_masterCoin));
						if(shellApi.checkEvent(_events.DROPPED_COINS)){
							actChain.addAction(new TalkAction(_masterCoin, "finalyCounted"));
						}
						actChain.addAction(new WaitAction(2));
						actChain.addAction(new PanAction(player));
						actChain.addAction(new TalkAction(_vizier, "distract"));
						actChain.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection, _vizier, true)) );
						actChain.execute();
						break;
				}
			}
		}
		
		private function catchPlayer():void{
			if(!checkDisguise()){
				_caughtPlayer = true;
				SceneUtil.lockInput(this);
				if(_mcActChain){
					_mcActChain.clearActions();
				}
				//CharUtils.freeze(_masterCoin, true);
				Display(_enforcer.get(Display)).visible = true;
				//CharUtils.moveToTarget(_enforcer, Spatial(player.get(Spatial)).x + 100, Spatial(player.get(Spatial)).y, false, failScene);
				MotionUtils.zeroMotion(_masterCoin);
				// master of coin stops counting and calls for help
				_mcActChain = new ActionChain(this);
				_mcActChain.addAction( new PanAction(_masterCoin) );
				_mcActChain.addAction( new CallFunctionAction(Command.create(CharUtils.faceTargetEntity, _masterCoin, player)) );
				_mcActChain.addAction( new SetSkinAction(_masterCoin, SkinUtils.MOUTH, "distressedMom", true, true) );
				_mcActChain.addAction( new WaitAction(0.5) );
				_mcActChain.addAction( new CallFunctionAction(Command.create(CharUtils.setAnim, _masterCoin, Grief)) );
				_mcActChain.addAction( new TalkAction(_masterCoin, "catchPlayer") );
				_mcActChain.addAction( new PanAction(_enforcer) );
				_mcActChain.addAction( new MoveAction(_enforcer, new Point(Spatial(player.get(Spatial)).x + 70, Spatial(_masterCoin.get(Spatial)).y),new Point(30,50)) );
				_mcActChain.addAction( new AnimationAction(_enforcer, BigStomp, "", 45) );
				Timeline(_enforcer.get(Timeline)).handleLabel("sumoStomp",playStompSound);
				_mcActChain.addAction( new CallFunctionAction(failScene) );
				_mcActChain.execute();
			}
			else if(!coinComment){
				// in disguise!
				_mcActChain.clearActions();
				_mcActChain.addAction( new TalkAction(_masterCoin, "dontTouchCoins") );
				_mcActChain.execute();
				coinComment = true;
			}
		}
		
		private function checkDisguise():Boolean
		{
			var wearingThiefOutfit:Boolean = true;
			
			if(!SkinUtils.hasSkinValue(player, SkinUtils.FACIAL, "an2_player"))
			{
				wearingThiefOutfit = false;
			}
			if(!SkinUtils.hasSkinValue(player, SkinUtils.OVERSHIRT, "an2_player"))
			{
				wearingThiefOutfit = false;
			}
			if(wearingThiefOutfit){
				if(!shellApi.checkEvent(_events.PLAYER_DISGUISED)){
					shellApi.triggerEvent(_events.PLAYER_DISGUISED,true);
				}
			}else{
				shellApi.removeEvent(_events.PLAYER_DISGUISED);
			}
			return wearingThiefOutfit;
		}
		
		private function failScene(...p):void{
			// fial popup
			var caughtPopup:DialogPicturePopup = new DialogPicturePopup(this.overlayContainer);
			caughtPopup.updateText("You were captured!", "Try Again");
			caughtPopup.configData("caughtPopup.swf", "scenes/arab2/shared/");
			caughtPopup.buttonClicked.add(onCaughtPopupClicked);
			this.addChildGroup(caughtPopup);
		}
		
		private function onCaughtPopupClicked(...p):void
		{
			shellApi.loadScene(Cells);
		}
		
		private function setupInteractives():void
		{
			// setup scene interaction
			//this.addSystem(new ItemHitSystem(), SystemPriorities.checkCollisions);
			//var itemHitSystem:ItemHitSystem = super.getSystem(ItemHitSystem) as ItemHitSystem;
			//itemHitSystem.gotItem.removeAll();
			//itemHitSystem.gotItem.add(handleGotItem);
			
			//var sceneItemCreator:SceneItemCreator = new SceneItemCreator();
			
			// crumbling platform underneath player
			_crumblePlat = this.getEntityById("stone");
			var clip:MovieClip = _hitContainer["crumble"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			_crumble = TimelineUtils.convertClip(clip, this);
			
			// prisoner's garb (thieves garb) -poof animation
			clip = _hitContainer["clothes"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			_clothes = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip(_hitContainer["clothes"], this, _clothes);
			// the actual item
			_clothsItem = getEntityById("white_robe");
			if(shellApi.checkEvent(_events.PLAYER_ESCAPED_CELL)){
				removeEntity(_clothes);
			}else{
				// hide collectible
				removeEntity(_clothsItem);
				// hide poof stuff until needed
				EntityUtils.visible(_clothes, false, true);
			}
			
			/*			if(!shellApi.checkEvent(_events.PLAYER_ESCAPED_CELL) && !shellApi.checkHasItem(_events.WHITE_ROBE)){
			Display(_clothes.get(Display)).visible = false; // doesn't work for some reason
			_hitContainer["clothes"].visible = false;
			} else if(!shellApi.checkEvent("gotItem_"+_events.WHITE_ROBE)){
			Timeline(_clothes.get(Timeline)).gotoAndStop("end");
			sceneItemCreator.make(_clothes, new Point(40, 100));
			} else {
			this.removeEntity(_clothes);
			}*/
			
			// quickSilver
			/*_quickSilver = EntityUtils.createSpatialEntity(this, _hitContainer["quickSilver"], _hitContainer);
			_quickSilver.add(new Id("quickSilver"));
			
			if(!shellApi.checkHasItem(_events.QUICKSILVER)){
			sceneItemCreator.make(_quickSilver, new Point(40, 100));
			} else {
			this.removeEntity(_quickSilver);
			}*/
			
			// gold coins
			clip = _hitContainer["goldCoins"];
			convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			var goldCoins:Entity = EntityUtils.createSpatialEntity(this,clip, _hitContainer);
			TimelineUtils.convertClip(clip, this, goldCoins);
			goldCoins.add(new Id("goldCoins"));
		}
		
		//		public function handleGotItem(item:Entity):void{
		//			switch(item){
		//				case _clothes:
		//					shellApi.getItem(_events.WHITE_ROBE, null, true);
		//					Dialog(player.get(Dialog)).say("These look just like the thieves' clothes, except they're not black.");
		//					break;
		//				case _quickSilver:;
		//					shellApi.getItem(_events.QUICKSILVER, null, true);
		//					break;
		//			}
		//		}
		
		private function setupGoldSparkle(clip:DisplayObjectContainer):void
		{
			_goldSparkleClip = clip;
			
			var emitter:GoldSparkleParticle;
			var entity:Entity;
			
			//Table Coins
			emitter = new GoldSparkleParticle();
			entity = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1340, 660, 1340 + 120, 660 + 38), 2);
			Display(entity.get(Display)).moveToBack();
			
			//Lamps
			emitter = new GoldSparkleParticle();
			entity = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1693, 474, 1693 + 188, 474 + 48), 2);
			Display(entity.get(Display)).moveToBack();
			
			//Coins Between Lamps
			emitter = new GoldSparkleParticle();
			entity = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1944, 604, 1944 + 248, 604 + 58), 2);
			Display(entity.get(Display)).moveToBack();
			
			//Coins Under Lamps
			emitter = new GoldSparkleParticle();
			entity = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1618, 660, 1618 + 890, 660 + 78), 4);
			Display(entity.get(Display)).moveToBack();
			
			//Coins Near Water
			emitter = new GoldSparkleParticle();
			entity = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1295, 1060, 1295 + 1232, 1060 + 122), 4);
			Display(entity.get(Display)).moveToBack();
			
			//Falling Coins
			var goldCoins:Entity = this.getEntityById("goldCoins");
			if(goldCoins)
			{
				_coinSparkles = new GoldSparkleParticle();
				_goldCoinEmitter = EmitterCreator.create(this, _hitContainer, _coinSparkles );
				_coinSparkles.init(clip, new RectangleZone(1044, 632, 1044 + 178, 632 + 110), 2);
				
				DisplayUtils.moveToBack(Display(goldCoins.get(Display)).displayObject);
				DisplayUtils.moveToBack(Display(_goldCoinEmitter.get(Display)).displayObject);
			}
		}
		
		private function setupAltarSmoke(clip:DisplayObjectContainer):void
		{
			_smokeParticles = new SmokeParticles();
			_smokeParticleEmitter = EmitterCreator.create(this, _hitContainer, _smokeParticles, 2220, 530, null, null);
			_smokeParticles.init(this, clip, 2.0, 70);
			
			_emberParticles = new EmberParticles();
			_emberParticleEmitter = EmitterCreator.create(this, _hitContainer, _emberParticles, 2220, 550, null, null);
			_emberParticles.init(this);
		}
		
		private function setupGenieSmoke(clip:DisplayObjectContainer):void{
			_smokeParticles = new SmokeParticles();
			_smokeParticleEmitter = EmitterCreator.create(this, _hitContainer, _smokeParticles, Spatial(_correctLamp.get(Spatial)).x, Spatial(_correctLamp.get(Spatial)).y);
			_smokeParticles.init(this, clip, 2.0, 5, 5, 1.0, -300, -40.0, true);
			
			_emberParticles = new EmberParticles();
			_emberParticleEmitter = EmitterCreator.create(this, this.overlayContainer, _emberParticles, 0, 0, null, null); 
			_emberParticles.initViewPort(this, shellApi.viewportWidth, shellApi.viewportHeight); // scene wide
		}
		
		private function setupNPCs1():void{
			this.removeEntity(this.getEntityById("vizier"));
			
			_prisoner = this.getEntityById("prisoner");
			_enforcer = this.getEntityById("enforcer");
			_masterThief = this.getEntityById("masterThief");
			_jailer = this.getEntityById("jailer");
			_masterCoin = this.getEntityById("masterCoin");
			
			EntityUtils.removeInteraction(_prisoner);
			EntityUtils.removeInteraction(_enforcer);
			EntityUtils.removeInteraction(_masterThief);
			EntityUtils.removeInteraction(_jailer);
			//EntityUtils.removeInteraction(_masterCoin);
			
			var charGroup:CharacterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM(_prisoner);
			charGroup.addFSM(_enforcer);
			charGroup.addFSM(_masterThief);
			charGroup.addFSM(_jailer);
			charGroup.addFSM(_masterCoin);
			
			( ( player.get(FSMControl) as FSMControl ).getState( CharacterState.WALK ) as WalkState ).walkAnim = WalkNinja;
			
			CharacterMotionControl(_prisoner.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(_enforcer.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(_masterThief.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(_jailer.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(_masterCoin.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(player.get(CharacterMotionControl)).maxVelocityX = 300;
			
			// eyes on thief
			CharUtils.eyesFollowTarget(_enforcer, _prisoner);
		}
		
		private function setupNPCs2():void{
			var charGroup:CharacterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			
			this.removeEntity(this.getEntityById("vizier"));
			this.removeEntity(this.getEntityById("prisoner"));
			this.removeEntity(this.getEntityById("masterThief"));
			this.removeEntity(this.getEntityById("jailer"));
			
			// enforcer is hidden until called on by master of coin
			_enforcer = this.getEntityById("enforcer");
			Spatial(_enforcer.get(Spatial)).x = 2200;
			Spatial(_enforcer.get(Spatial)).y = 680;
			Display(_enforcer.get(Display)).visible = false;
			
			EntityUtils.removeInteraction(_enforcer);
			charGroup.addFSM(_enforcer);
			CharacterMotionControl(_enforcer.get(CharacterMotionControl)).maxVelocityX = 400;
			
			// master of coin is busy counting coins
			_masterCoin = this.getEntityById("masterCoin");
			Spatial(_masterCoin.get(Spatial)).x = 1385;
			Spatial(_masterCoin.get(Spatial)).y = 715;
			
			//EntityUtils.removeInteraction(_masterCoin);
			charGroup.addFSM(_masterCoin);
			CharacterMotionControl(_masterCoin.get(CharacterMotionControl)).maxVelocityX = 300;
			
			countCoins();
		}
		
		private function setupNPCs3():void{
			var charGroup:CharacterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			
			this.removeEntity(this.getEntityById("prisoner"));
			this.removeEntity(this.getEntityById("jailer"));
			
			// enforcer is hidden until called on by master of coin or at the lamp table
			_enforcer = this.getEntityById("enforcer");
			Spatial(_enforcer.get(Spatial)).x = 2200;
			Spatial(_enforcer.get(Spatial)).y = 680;
			Display(_enforcer.get(Display)).visible = false;
			
			EntityUtils.removeInteraction(_enforcer);
			charGroup.addFSM(_enforcer);
			CharacterMotionControl(_enforcer.get(CharacterMotionControl)).maxVelocityX = 400;
			
			// master thief is hidden until at the lamp table
			_masterThief = this.getEntityById("masterThief");
			Spatial(_masterThief.get(Spatial)).x = 2300;
			Spatial(_masterThief.get(Spatial)).y = 715;
			Display(_masterThief.get(Display)).visible = false;
			
			EntityUtils.removeInteraction(_masterThief);
			charGroup.addFSM(_masterThief);
			CharacterMotionControl(_masterThief.get(CharacterMotionControl)).maxVelocityX = 400;
			
			// master of coin is nearby the lamps blocking the player/vizier access
			_masterCoin = this.getEntityById("masterCoin");
			Spatial(_masterCoin.get(Spatial)).x = 1300;
			Spatial(_masterCoin.get(Spatial)).y = 715;
			
			//EntityUtils.removeInteraction(_masterCoin);
			charGroup.addFSM(_masterCoin);
			CharacterMotionControl(_masterCoin.get(CharacterMotionControl)).maxVelocityX = 300;
			
			
			// vizier is following the player
			_vizier = this.getEntityById("vizier");
			EntityUtils.removeInteraction(_vizier);
			charGroup.addFSM(_vizier);
			//CharUtils.followEntity(_vizier, player, new Point(200,200));
			CharacterMotionControl(_vizier.get(CharacterMotionControl)).maxVelocityX = 400;
			var zone:Entity = getEntityById("zoneVizierStop");
			Zone(zone.get(Zone)).entered.add(vizStopPlayer);
		}
		
		private function vizStopPlayer(z:String, ch:String):void
		{
			if(ch == "player" && !_goldCoinsFell){
				SceneUtil.lockInput(this, true);
				CharUtils.moveToTarget(player, 1115, 1016,false,null,new Point(30,3000));
				SceneUtil.setCameraTarget(this,_vizier);
				Dialog(_vizier.get(Dialog)).sayById("stop");
				Dialog(_vizier.get(Dialog)).complete.addOnce(unlock);
			}
		}
		
		// final seqence
		private function setupNPCs4():void{
			this.removeEntity(this.getEntityById("vizier"));
			this.removeEntity(this.getEntityById("prisoner"));
			this.removeEntity(this.getEntityById("clothes"));
			
			_enforcer = this.getEntityById("enforcer");
			_masterThief = this.getEntityById("masterThief");
			_jailer = this.getEntityById("jailer");
			_masterCoin = this.getEntityById("masterCoin");
			
			//if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
			// bypass walking up to the altar on low qualitys
			Spatial(player.get(Spatial)).x = 2220;
			Spatial(player.get(Spatial)).y = 520;
			CharUtils.setDirection( player, false);
			
			Spatial(_enforcer.get(Spatial)).x = 2100;
			Spatial(_enforcer.get(Spatial)).y = 620;
			
			Spatial(_masterThief.get(Spatial)).x = 1980;
			Spatial(_masterThief.get(Spatial)).y = 700;
			
			Spatial(_jailer.get(Spatial)).x = 1800;
			Spatial(_jailer.get(Spatial)).y = 700;
			
			Spatial(_masterCoin.get(Spatial)).x = 1700;
			Spatial(_masterCoin.get(Spatial)).y = 700;
			/*}
			else{	
			Spatial(player.get(Spatial)).x = 1800;
			Spatial(player.get(Spatial)).y = 635;
			
			Spatial(_enforcer.get(Spatial)).x = 1700;
			Spatial(_enforcer.get(Spatial)).y = 635;
			
			Spatial(_masterThief.get(Spatial)).x = 1550;
			Spatial(_masterThief.get(Spatial)).y = 715;
			
			Spatial(_jailer.get(Spatial)).x = 1450;
			Spatial(_jailer.get(Spatial)).y = 715;
			
			Spatial(_masterCoin.get(Spatial)).x = 1350;
			Spatial(_masterCoin.get(Spatial)).y = 715;
			
			var charGroup:CharacterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM(_enforcer);
			charGroup.addFSM(_masterThief);
			charGroup.addFSM(_jailer);
			charGroup.addFSM(_masterCoin);
			
			CharacterMotionControl(_enforcer.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(_masterThief.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(_jailer.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(_masterCoin.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(player.get(CharacterMotionControl)).maxVelocityX = 300;
			}
			*/
			EntityUtils.removeInteraction(_enforcer);
			EntityUtils.removeInteraction(_masterThief);
			EntityUtils.removeInteraction(_jailer);
			EntityUtils.removeInteraction(_masterCoin);
			EntityUtils.removeInteraction(_lampsClick);
			// eyes on player
			CharUtils.eyesFollowTarget(_enforcer, player);
		}
		
		private function intro2():void{
			// position NPCs
			
			// player gets escorted to alter and the correct lamp is placed!
			/*if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH){
			CharUtils.moveToTarget(_enforcer, 2100, 635);
			CharUtils.moveToTarget(_masterThief, 1980, 715);
			CharUtils.moveToTarget(_jailer, 1800, 715);
			CharUtils.moveToTarget(_masterCoin, 1700, 715);
			}*/
			
			SceneUtil.lockInput(this, true);
			var actChain:ActionChain = new ActionChain(this);
			//actChain.lockInput = true;
			
			actChain.addAction( new SetSkinAction(player, SkinUtils.ITEM, "an2_lamp2", false, true) );
			/*if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH){
			actChain.addAction( new MoveAction(player, new Point( 2220, 520),new Point(50,50)) );
			actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setDirection, player, false)) );
			}*/
			actChain.addAction( new WaitAction(0.6) );
			actChain.addAction( new CallFunctionAction(lockControl) );
			actChain.addAction( new WaitAction(1.0) );
			actChain.addAction( new PanAction(_masterThief) );
			actChain.addAction( new TalkAction(_masterThief, "useLamp") );
			actChain.addAction( new TalkAction(player, "useLamp2") );
			actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setAnim, _masterThief, Laugh)) );
			actChain.addAction( new TalkAction(_masterThief, "useLamp3") );
			actChain.addAction( new TalkAction(_masterCoin, "useLamp4") );
			actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setDirection, _masterThief, false)) );
			actChain.addAction( new TalkAction(_masterThief, "useLamp5") );
			actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setDirection, _masterThief, true)) );
			actChain.addAction( new TalkAction(_masterThief, "useLamp6") );
			actChain.addAction( new AnimationAction(_enforcer, BigStomp, "", 45) );
			Timeline(_enforcer.get(Timeline)).handleLabel("sumoStomp",playStompSound);
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new PanAction(player) );
			actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setDirection, player, true)) );
			actChain.addAction( new TalkAction(player, "useLamp7") );
			actChain.addAction( new AnimationAction(player, Score, "", 35) );
			actChain.addAction( new CallFunctionAction( lampOnAltar3 ) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new CallFunctionAction( correctLamp) );
			
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,actChain.execute));
			//actChain.execute();
		}
		
		private function lockControl():void
		{
			SceneUtil.lockInput(this, false);
			// lock up only player movement
			CharUtils.lockControls(player);
			//player.remove(MotionControl);
		}
		
		private function playStompSound(...p):void
		{
			AudioUtils.play(this, STOMP_SOUND, 1.2);
		}
		
		private function correctLamp():void{
			SceneUtil.lockInput(this);
			
			DisplayUtils.moveToTop(Display(_purpGlow.get(Display)).displayObject);
			TweenUtils.entityTo(_purpGlow, Display, 3, {alpha:1});
			TweenUtils.entityTo(_lightOverlayEntity, Display, 1, {alpha:1, onComplete:smokeLamp});
			AudioUtils.play(this, LIGHT_SOUND, 1.7);
			cameraShake();
		}
		
		private function smokeLamp():void{
			SceneUtil.lockInput(this);
			TweenUtils.entityTo(_lightOverlayEntity, Display, 1, {alpha:0, onComplete:darkenScene});
			_emberParticles.sparkle();
			_smokeParticles.stream(10, 25);
		}
		
		private function darkenScene():void{
			darkenOverlay();
			TweenUtils.entityTo(_lightOverlayEntity, Display, 3, {alpha:1, onComplete:endScene});
		}
		
		private function endScene():void
		{		
			// award medallion
			if(!shellApi.checkHasItem(_events.MEDAL))
			{
				//shellApi.completedIsland();
				var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
				itemGroup.showAndGetItem( _events.MEDAL, null, medallionReceived );
				unlock();
			}
			else
			{
				// open final popup
				medallionReceived();
			}
		}
		
		private function medallionReceived():void
		{
			shellApi.completedIsland('', showOutroPopup);
		}
		
		private function showOutroPopup(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false, false);
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
		}
		
		private function lampOnAltar3():void{
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM);
			
			// show lamp on altar
			Display(_correctLamp.get(Display)).visible = true;
		}
		
		private function intro1():void{
			// player discovers treasure keep for the first time and witnesses the prisoner disappear when he places it on the alter
			
			var actChain:ActionChain = new ActionChain(this);
			actChain.lockInput = true;
			
			actChain.onComplete = endIntro1;
			
			actChain.addAction( new MoveAction(player, new Point( 1100, Spatial(player.get(Spatial)).y)) );
			actChain.addAction( new AnimationAction(player, DuckDown, "", 30) );
			actChain.addAction( new PanAction(_prisoner) );
			actChain.addAction( new TalkAction(_masterThief, "getLamp") );
			actChain.addAction( new TalkAction(_masterThief, "getLamp2") );
			actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setAnim, _prisoner, Tremble)) );
			actChain.addAction( new TalkAction(_prisoner, "getLamp3") );
			actChain.addAction( new TalkAction(_masterThief, "getLamp4") );
			actChain.addAction( new TalkAction(_masterThief, "getLamp5") );
			actChain.addAction( new MoveAction(_enforcer, new Point( 1750, Spatial(_enforcer.get(Spatial)).y)) );
			actChain.addAction( new AnimationAction(_enforcer, BigStomp, "", 45) );
			Timeline(_enforcer.get(Timeline)).handleLabel("sumoStomp",playStompSound);
			actChain.addAction( new AnimationAction(_prisoner, Grief, "", 60) );
			actChain.addAction( new AnimationAction(_prisoner, PointItem, "", 20) );
			actChain.addAction( new SetSkinAction(_prisoner, SkinUtils.ITEM, "an2_lamp1", false, true) );
			actChain.addAction( new CallFunctionAction(takeLamp) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new MoveAction(_prisoner, altarTarget, new Point(50,50)) );
			actChain.addAction( new WaitAction(0.01) );
			actChain.addAction( new SetSpatialAction(_prisoner, new Point( altarTarget.x, 530)));
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new AnimationAction(_prisoner, Score, "", 35) );
			actChain.addAction( new CallFunctionAction( lampOnAltar ) );
			actChain.addAction( new WaitAction(2) );
			actChain.addAction( new AnimationAction(_prisoner, Stand, "", 45) );
			actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setDirection, _prisoner, false)) );
			actChain.addAction( new TalkAction(_prisoner, "getLamp6") );
			actChain.addAction( new CallFunctionAction( wrongLamp ) );
			actChain.addAction( new TalkAction(_prisoner, "getLamp7") );
			actChain.addAction( new AnimationAction(_prisoner, Grief, "", 35) );
			actChain.addAction( new CallFunctionAction( poof ) );
			actChain.addAction( new WaitAction(2) );
			actChain.addAction( new PanAction(_masterThief) );
			actChain.addAction( new CallFunctionAction(Command.create(CharUtils.setAnim, _masterThief, Stomp)) );
			actChain.addAction( new TalkAction(_masterThief, "getLamp8") );
			actChain.addAction( new TalkAction(_masterThief, "getLamp9") );
			actChain.addAction( new PanAction(player) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new CallFunctionAction( playerFall ) );
			actChain.addAction( new WaitAction(2) );
			actChain.addAction( new CallFunctionAction( approachPlayer ) );
			actChain.addAction( new TalkAction(player, "fallIn") );
			actChain.addAction( new PanAction(_masterThief) );
			actChain.addAction( new TalkAction(_masterThief, "fallIn2") );
			actChain.addAction( new CallFunctionAction( escortPlayerOut ) );
			actChain.addAction( new TalkAction(_masterThief, "fallIn3") );
			actChain.addAction( new CallFunctionAction( backToWork1 ) );
			actChain.addAction( new WaitAction(3) );
			actChain.addAction( new CallFunctionAction( backToWork2 ) );
			
			actChain.execute();
			
		}
		
		private function setupLampSequence():void{
			var disp:DisplayObject = _hitContainer["redGlow"];
			if(PlatformUtils.isMobileOS)
				disp = createBitmapSprite(disp);
			_redGlow = EntityUtils.createSpatialEntity(this,disp, _hitContainer);
			Display(_redGlow.get(Display)).alpha = 0;
			
			disp = _hitContainer["purpleGlow"];
			if(PlatformUtils.isMobileOS)
				disp = createBitmapSprite(disp);
			_purpGlow = EntityUtils.createSpatialEntity(this, disp, _hitContainer);
			Display(_purpGlow.get(Display)).alpha = 0;
			
			
			disp = _hitContainer["fakeLamp1"];
			if(PlatformUtils.isMobileOS)
				disp = createBitmapSprite(disp);
			_wrongLamp1 = EntityUtils.createSpatialEntity(this, disp, _hitContainer);
			disp = _hitContainer["fakeLamp2"];
			if(PlatformUtils.isMobileOS)
				disp = createBitmapSprite(disp);
			_wrongLamp2 = EntityUtils.createSpatialEntity(this, disp, _hitContainer);
			
			Display(_wrongLamp2.get(Display)).visible = false;
			
			// light overlay
			
			var lightOverlay:Sprite = new Sprite();
			super.overlayContainer.addChildAt(lightOverlay, 0);
			lightOverlay.mouseEnabled = false;
			lightOverlay.mouseChildren = false;
			lightOverlay.graphics.clear();
			if(!shellApi.checkEvent(_events.PLAYER_CAUGHT_WLAMP)){
				lightOverlay.graphics.beginFill(0xFF0000, 0.35);
			} else {
				lightOverlay.graphics.beginFill(0xC7C7EE, 0.65);
			}
			
			lightOverlay.graphics.drawRect(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
			
			var display:Display = new Display(lightOverlay);
			
			_lightOverlayEntity = EntityUtils.createSpatialEntity(this, lightOverlay, super.overlayContainer);
			
			Display(_lightOverlayEntity.get(Display)).alpha = 0;
		}
		
		private function darkenOverlay():void{
			var sprite:Sprite = Display(_lightOverlayEntity.get(Display)).displayObject as Sprite;
			sprite.graphics.clear();
			sprite.graphics.beginFill(0x000000, 1);
			sprite.graphics.drawRect(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
		}
		
		private function takeLamp():void{
			Display(_wrongLamp1.get(Display)).visible = false;
		}
		
		private function lampOnAltar():void{
			CharUtils.setAnim( _prisoner, Tremble );
			SkinUtils.emptySkinPart(_prisoner, SkinUtils.ITEM);
			
			// show lamp on altar
			Display(_wrongLamp2.get(Display)).visible = true;
		}
		
		private function wrongLamp():void{
			// lamp glows red
			TweenUtils.entityTo(_redGlow, Display, 3, {alpha:1});
			TweenUtils.entityTo(_lightOverlayEntity, Display, 4, {alpha:1});
			AudioUtils.play(this, LIGHT_SOUND, 1.7);
			cameraShake();
		}
		
		private function poof():void{
			DisplayUtils.moveToTop(Display(_clothes.get(Display)).displayObject);
			this.removeEntity(_prisoner);
			( ( player.get(FSMControl) as FSMControl ).getState( CharacterState.WALK ) as WalkState ).walkAnim = Walk;
			CharUtils.setAnim(player, DuckDown);
			
			EntityUtils.visible(_clothes);
			Timeline(_clothes.get(Timeline)).play();
			
			makePoof();
			
			this.removeEntity(_redGlow);
			EntityUtils.visible(_wrongLamp2, false);
			
			TweenUtils.entityTo(_lightOverlayEntity, Display, 1.5, {alpha:0});
			cameraShake();
		}
		
		private function playerFall():void{
			// rock crumbles
			_crumblePlat.remove(Platform);
			Timeline(_crumble.get(Timeline)).play();
			
			AudioUtils.play(this, BREAK_SOUND, 2.0);
			
			CharUtils.moveToTarget(player, Spatial(player.get(Spatial)).x, 735, true);
			
			CharUtils.setDirection(_masterCoin, false);
			CharUtils.setDirection(_masterThief, false);
			CharUtils.setDirection(_jailer, false);
			CharUtils.setDirection(_enforcer, false);
			
			CharUtils.eyesFollowTarget(_enforcer, player);
		}
		
		private function approachPlayer():void{
			CharacterMotionControl(_jailer.get(CharacterMotionControl)).maxVelocityX = 500;
			CharacterMotionControl(_masterThief.get(CharacterMotionControl)).maxVelocityX = 500;
			CharUtils.moveToTarget(_jailer, 1300, 735);
			CharUtils.moveToTarget(_masterThief, 1510, 735);
			CharUtils.moveToTarget(_masterCoin, 1400, 735);
			CharUtils.moveToTarget(_enforcer, 1200, 735);
		}
		
		private function escortPlayerOut():void{
			CharacterMotionControl(_jailer.get(CharacterMotionControl)).maxVelocityX = 300;
			CharacterMotionControl(_masterThief.get(CharacterMotionControl)).maxVelocityX = 300;
			CharUtils.moveToTarget(_enforcer, Spatial(player.get(Spatial)).x + 60, 735, false, moveOut);
		}
		
		private function moveOut(...p):void{
			CharUtils.moveToTarget(player, 400, 735, true);
			CharUtils.moveToTarget(_enforcer, 460, 735);
		}
		
		private function backToWork1():void{
			CharUtils.moveToTarget(_jailer, 400, 735);
			CharUtils.moveToTarget(_masterCoin, 1385, 735, false, countCoins);
		}
		
		private function changedFaceDirection(right:Boolean):void{
			_mcFacingRight = right;
		}
		
		private function backToWork2():void{
			var spatial:Spatial = new Spatial(Spatial(_masterThief.get(Spatial)).x, Spatial(_masterThief.get(Spatial)).y);
			(super.getGroupById("cameraGroup") as CameraGroup).setTarget(spatial, true);
			
			CharUtils.moveToTarget(_masterThief, 2400, 735);
		}
		
		private function endIntro1(...p):void{
			SceneUtil.lockInput(this);
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 0, gotoCellScene));	
		}
		
		private function gotoCellScene():void{
			shellApi.loadScene(Cells);
		}
		
		private function cameraShake():Boolean
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion= cameraEntity.get(WaveMotion);
			
			if(waveMotion != null){
				cameraEntity.remove(WaveMotion);
				var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
				spatialAddition.y = 0;
				return(false);
			} else {
				if(!super.hasSystem(WaveMotionSystem))
				{
					super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
				}
				waveMotion = new WaveMotion();
			}
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 0.4;
			waveMotionData.rate = 1;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			return(true);
		}
		
		private function setupFire():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, _hitContainer[ "fire" + 0 ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var flame:Entity;
			for( var i:uint = 0; _hitContainer[ "fire" + i ] != null; i ++ )
			{
				clip = _hitContainer[ "fire" + i ];
				flame = _flameCreator.createFlame( this, clip, true );
			}
		}
		
		// targets
		private var lampTableTarget:Point = new Point(1790, 520);
		private var sideTableTarget:Point = new Point(1700,520);
		private var altarTarget:Point = new Point(2200, 520);
		
		// core events
		private var _events:Arab2Events;
		
		// npcs
		private var _prisoner:Entity;
		private var _enforcer:Entity;
		private var _masterThief:Entity;
		private var _jailer:Entity;
		private var _masterCoin:Entity;
		private var _vizier:Entity;
		
		// interactives
		private var _crumblePlat:Entity;
		private var _crumble:Entity;
		private var _clothes:Entity;
		private var _wrongLamp1:Entity;
		private var _wrongLamp2:Entity;
		private var _lampsClick:Entity;
		private var _correctLamp:Entity;
		
		// particles and effects
		private var _goldSparkles:GoldSparkleParticle;
		private var _goldSparkleEmitter:Entity;
		//private var _goldShimmerEmitter:Entity;
		private var _smokeParticles:SmokeParticles;
		private var _smokeParticleEmitter:Entity;
		private var _emberParticles:EmberParticles;
		private var _emberParticleEmitter:Entity;
		private var _redGlow:Entity;
		private var _purpGlow:Entity;
		private var _lightOverlayEntity:Entity;
		private var _goldSparkleMap:DisplayObjectContainer;	
		
		private var _coinMap:DisplayObjectContainer;
		
		
		// master of coin interaction
		private var _mcActChain:ActionChain;
		private var _countCount:int;
		private var _mcFacingRight:Boolean = true;
		private var _caughtPlayer:Boolean = false;
		private var _goldCoinsFell:Boolean;
		private var _singleCounts:uint = 1;
		
		// dev test
		//private var _magicSand:MagicSandParticle;
		//private var _magicSandEmitter:Entity;
		
		// magic sand
		private var magicSandGroup:MagicSandGroup;
		private var _goldSparkleClip:DisplayObjectContainer;
		private var _flameCreator:FlameCreator;
		
		private const BREAK_SOUND:String = SoundManager.EFFECTS_PATH + "collapsing_wood_01.mp3";
		private const POOF_SOUND:String = SoundManager.EFFECTS_PATH + "poof_01.mp3";
		private const STOMP_SOUND:String = SoundManager.EFFECTS_PATH + "big_pow_05.mp3";
		private const LIGHT_SOUND:String = SoundManager.EFFECTS_PATH + "lamps_curse.mp3";
		private const COINS_SOUND:String = SoundManager.EFFECTS_PATH +"coins_large_rustle_01.mp3";
		
		private var _clothsItem:Entity;
		private var coinComment:Boolean;
		
		private var _coinSparkles:GoldSparkleParticle;
		private var _goldCoinEmitter:Entity;
		
		
	}
}