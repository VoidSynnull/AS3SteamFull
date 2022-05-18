package game.scenes.arab2.entrance
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.Hazard;
	import game.components.hit.HitTest;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.FightStance;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.Walk;
	import game.data.character.LookData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.sound.SoundModifier;
	import game.particles.FlameCreator;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab2.Arab2Events;
	import game.scenes.arab2.entrance.barrelRoller.BarrelRoller;
	import game.scenes.arab2.entrance.barrelRoller.BarrelRollerSystem;
	import game.scenes.arab2.entrance.enforcer.Enforcer;
	import game.scenes.arab2.entrance.enforcer.EnforcerSystem;
	import game.scenes.arab2.entrance.thiefAttack.ThiefAttack;
	import game.scenes.arab2.entrance.thiefAttack.ThiefAttackSystem;
	import game.scenes.arab2.entrance.thiefAttack.ThiefAttackTarget;
	import game.scenes.arab2.shared.MagicSandGroup;
	import game.scenes.arab2.treasureKeep.TreasureKeep;
	import game.scenes.deepDive2.predatorArea.particles.GlassParticles;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.JumpState;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.SceneObjectHitCircleSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.particles.FlameSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
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
	
	public class Entrance extends PlatformerGameScene
	{
		private var _events:Arab2Events;
		private var _magicSandGroup:MagicSandGroup;
		private var _postFlame:Entity;
		private var _elevator:Entity;
		private var _elevatorButton:Entity;
		private var _elevatorUp:Boolean = false;
		private var _elevatorMoving:Boolean = false;
		private var _enforcerInPosition:Boolean = false;
		private var _barrelEmitter:Entity;
		private var _flameCreator:FlameCreator = new FlameCreator();
		
		public function Entrance()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab2/entrance/";
			
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
			
			this.addSystem(new BitmapSequenceSystem());
			this.addSystem(new ThiefAttackSystem());
			this.addSystem(new HitTestSystem());
			this.addSystem(new SceneObjectMotionSystem());
			this.addSystem(new SceneObjectHitCircleSystem());
			this.addSystem(new BarrelRollerSystem());
			this.addSystem(new FlameSystem());
			this.addSystem(new EnforcerSystem());
			
			checkReset();
			
			if(this.shellApi.checkEvent(_events.PLAYER_ESCAPED_WLAMP) && !this.shellApi.checkItemEvent(_events.MEDAL))
			{
				setupEnforcer();
				setupMasterThief();
				setupBarrelRolling();
				setupFlameBarrelExplodeZone();
			}
			else
			{
				this.removeEntity(this.getEntityById("enforcer"));
				this.removeEntity(this.getEntityById("master_thief"));
				setupThieftOutfit();
			}
			
			setupThiefHazards();
			setupIntro();
			setupBorax();
			setupPlayer();
			setupPost();
			setupElevator();
			setupMagicSand();
			setupBarrelZones();
			setupThiefFallZones();
			setupFlames();
			setupFlameBarrels();
			
		}
		
		private function checkReset():void
		{
			var part:SkinPart;
			if(!shellApi.checkHasItem(_events.MAGIC_SAND)){
				part = SkinUtils.getSkinPart(player,SkinUtils.ITEM);
				if(part.value == "an_magic_sand"){
					SkinUtils.setSkinPart(player, SkinUtils.ITEM, "empty");
				}
			}
			if(!shellApi.checkHasItem(_events.THIEVES_GARB)){
				part = SkinUtils.getSkinPart(player,SkinUtils.FACIAL);
				if(part.value == "an2_player"){
					SkinUtils.setSkinPart(player, SkinUtils.FACIAL, "empty");
				}
				part = SkinUtils.getSkinPart(player,SkinUtils.OVERSHIRT);
				if(part.value == "an2_player"){
					SkinUtils.setSkinPart(player, SkinUtils.OVERSHIRT, "empty");
				}
			}
		}		
		
		private function setupPlayer():void
		{
			var validHit:ValidHit = new ValidHit("barrelRoll");
			validHit.inverse = true;
			this.player.add(validHit);
			this.player.add(new ZoneCollider());
			
			if(this.shellApi.checkEvent(_events.PLAYER_ESCAPED_WLAMP))
			{
				var spatial:Spatial = this.player.get(Spatial);
				spatial.x = 875;
				spatial.y = 2300;
				CharUtils.setDirection(this.player, true);
			}
		}
		
		private function setupBorax():void
		{
			var boraxThief:Entity = this.getEntityById("thief4");
			var borax:Entity = this.getEntityById("borax");
			
			if(borax)
			{
				var sceneInteraction:SceneInteraction = borax.get(SceneInteraction);
				sceneInteraction.minTargetDelta.setTo(0, 0);
				DisplayUtils.moveToBack(Display(borax.get(Display)).displayObject);
				
				this.addThiefHazard(boraxThief);
			}
			else
			{
				this.removeEntity(boraxThief);
			}
		}
		
		private function setupPost():void
		{
			var clip:MovieClip = _hitContainer["barrelPost"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			EntityUtils.createSpatialEntity(this, clip).add(new Id(clip.name));
			
			clip = _hitContainer["woodBeam"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			EntityUtils.createSpatialEntity(this, clip).add(new Id(clip.name));
			this.getEntityById("postDestroyed").remove(Platform);
		}
		
		private function setupMasterThief():void
		{
			var master:Entity = this.getEntityById("master_thief");
			Display(master.get(Display)).visible = false;
		}
		
		private function setupEnforcer():void
		{
			var enforcer:Entity = this.getEntityById("enforcer");
			enforcer.add(new ZoneCollider());
			
			var validHit:ValidHit = new ValidHit("enforcerIgnore");
			validHit.inverse = true;
			enforcer.add(validHit);
			
			var enforcerComponent:Enforcer = new Enforcer();
			enforcerComponent.captured.add(onCaptured);
			enforcer.add(enforcerComponent);
			
			var zone:Zone = new Zone();
			zone.entered.add(onEnforcerCollision);
			enforcer.add(zone);
			
			var path:Vector.<Point> = new Vector.<Point>();
			
			for(var index:int = 1; this._hitContainer["path" + index]; ++index)
			{
				var pathPoint:DisplayObject = this._hitContainer["path" + index];
				path.push(new Point(pathPoint.x, pathPoint.y));
			}
			
			CharUtils.followPath(enforcer, path);
			enforcer.remove(HazardCollider);
			
			//The Enforcer can't use the touch/mobile JumpState, or else he won't make any of his jumps...
			var fsmCreator:FSMStateCreator = new FSMStateCreator();
			fsmCreator.createCharacterState(JumpState, enforcer);
			
			var motionControl:CharacterMotionControl = enforcer.get(CharacterMotionControl);
			motionControl.maxVelocityX = 160;
			motionControl.jumpVelocity = -1150;
			
			var barrelParticles:GlassParticles = new GlassParticles();
			barrelParticles.init(BitmapUtils.createBitmapData(this._hitContainer["barrelArt1"], 1, new Rectangle(-10, -10, 20, 20)), 0);
			this._barrelEmitter = EmitterCreator.create(this, _hitContainer, barrelParticles);
		}
		
		private function onCaptured(enforcer:Entity, player:Entity):void
		{
			this.showCapturePopup();
		}
		
		private function onEnforcerCollision(zoneID:String, colliderID:String):void
		{
			if(colliderID.indexOf("barrel") != -1)
			{
				if(!this._enforcerInPosition)
				{
					this.removeEntity(this.getEntityById(colliderID));
					var emitterSpatial:Spatial = this._barrelEmitter.get(Spatial);
					
					var enforcer:Entity = this.getEntityById("enforcer");
					var enforcerSpatial:Spatial = enforcer.get(Spatial);
					
					emitterSpatial.x = enforcerSpatial.x;
					emitterSpatial.y = enforcerSpatial.y;
					GlassParticles(Emitter(this._barrelEmitter.get(Emitter)).emitter).spark();
					
					Audio(enforcer.get(Audio)).play(SoundManager.EFFECTS_PATH + "wood_break_01.mp3", false, [SoundModifier.EFFECTS]);
				}
			}
			else if(colliderID == "player")
			{
				this.showCapturePopup();
			}
		}
		
		private function showCapturePopup():void
		{
			AudioUtils.play(this, SoundManager.MUSIC_PATH + "caught_by_thieves.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var caughtPopup:DialogPicturePopup = new DialogPicturePopup(this.overlayContainer);
			caughtPopup.updateText("You were captured!", "Try Again");
			caughtPopup.configData("caughtPopup.swf", "scenes/arab2/shared/");
			caughtPopup.buttonClicked.add(onCaughtPopupClicked);
			this.addChildGroup(caughtPopup);
		}
		
		private function onCaughtPopupClicked(confirmed:Boolean):void
		{
			this.shellApi.loadScene(Entrance);
		}
		
		private function setupFlameBarrels():void
		{
			var roller:BarrelRoller = new BarrelRoller();
			roller.makeHazard = false;
			roller.automaticRoll = false;
			roller.barrelDisplay = this._hitContainer["flameBarrelArt1"];
			roller.barrelBitmapData = BitmapUtils.createBitmapData(roller.barrelDisplay);
			this.player.add(roller);
			
			var flameBarrels:Entity = this.getEntityById("flameBarrelInteraction");
			var sceneInteraction:SceneInteraction = flameBarrels.get(SceneInteraction);
			sceneInteraction.reached.add(onFlameBarrelsReached);
		}
		
		private function onFlameBarrelsReached(player:Entity, barrels:Entity):void
		{
			CharUtils.setDirection(this.player, false);
			CharUtils.setAnim(this.player, Place);
			BarrelRoller(this.player.get(BarrelRoller)).manualRoll();
		}
		
		private function setupFlameBarrelExplodeZone():void
		{
			var explodeZone:Entity = this.getEntityById("flameBarrelExplodeZone");
			var zone:Zone = explodeZone.get(Zone);
			zone.entered.add(this.onExplodeZoneEntered);
		}
		
		private function onExplodeZoneEntered(zoneID:String, colliderID:String):void
		{
			var enforcer:Entity = this.getEntityById("enforcer");
			if(colliderID == "enforcer")
			{
				this._enforcerInPosition = true;
				Dialog(enforcer.get(Dialog)).sayById("run");
				SceneUtil.addTimedEvent(this, new TimedEvent(10, 1, catchPlayer));
			}
			else if(colliderID.indexOf("barrel") > -1)
			{
				if(this._enforcerInPosition)
				{
					CharUtils.setAnim(enforcer, Dizzy);
					SkinUtils.setSkinPart(enforcer, SkinUtils.EYES, "hypnotized");
					enforcer.remove(Zone);
					
					this.removeEntity(this.getEntityById("flameBarrelInteraction"));
					this.removeEntity(this.getEntityById(colliderID));
					this.blowUpPost();
					
					SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, sayBlewUpDialog));
				}
			}
				//Testing
			else if(colliderID == "player")
			{
				//this.blowUpPost();
			}
		}
		
		private function sayBlewUpDialog():void
		{
			Dialog(this.player.get(Dialog)).sayById("blew_up");
		}
		
		private function catchPlayer():void
		{
			var enforcer:Entity = this.getEntityById("enforcer");
			
			var motionControl:CharacterMotionControl = enforcer.get(CharacterMotionControl);
			motionControl.maxVelocityX = 800;
			
			CharUtils.followEntity(enforcer, this.player, new Point());
		}
		
		private function blowUpPost():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "explosion_wood_debris_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var explodeZone:Entity = this.getEntityById("flameBarrelExplodeZone");
			var spatial:Spatial = explodeZone.get(Spatial);
			this._magicSandGroup.explodeAt(spatial);
			
			this.removeEntity(this.getEntityById("post"));
			this.getEntityById("postDestroyed").add(new Platform());
			this.removeEntity(explodeZone);
			this.removeEntity(this._postFlame);
			
			removeEntity(getEntityById("barrelPost"));
			TweenUtils.entityTo(getEntityById("woodBeam"),Spatial,.8,{rotation:53, ease:Back.easeIn});
		}
		
		private function setupThieftOutfit():void
		{
			checkForThiefOutfit();
			Skin(player.get(Skin)).lookLoadComplete.add(checkForThiefOutfit);
		}
		
		private function setupElevator():void
		{
			var elevatorClip:MovieClip = this._hitContainer["elevator"];
			
			if(this.shellApi.checkEvent(_events.PLAYER_ESCAPED_WLAMP))
			{
				this._elevatorUp = true;
				elevatorClip.y = -265;
			}
			
			if(PlatformUtils.isMobileOS)
				convertContainer(elevatorClip);
			
			this._elevator = EntityUtils.createSpatialEntity(this, elevatorClip);
			this._elevatorButton = TimelineUtils.convertClip(this._hitContainer["buttonElevator"], this, null, null, false);
			
			var buttonHit:Entity = this.getEntityById("elevatorButton");
			var hitTest:HitTest = new HitTest(moveButtonDown, false, moveButtonUp, false);
			buttonHit.add(hitTest);
			buttonHit.add(new EntityIdList());
		}
		
		private function moveButtonDown(entity:Entity, hitId:String):void
		{
			if(hitId == "player")
			{
				Timeline(this._elevatorButton.get(Timeline)).gotoAndPlay("down");
				moveElevator();
			}
		}
		
		private function moveButtonUp(entity:Entity, hitId:String):void
		{
			if(hitId == "player")
			{
				Timeline(this._elevatorButton.get(Timeline)).gotoAndPlay("up");
			}
		}
		
		private function moveElevator():void
		{
			if(!this._elevatorMoving)
			{
				this._elevatorMoving = true;
				var object:Object = {onComplete:onElevatorComplete};
				object.y = this._elevatorUp ? 275 : -265;
				TweenUtils.entityTo(this._elevator, Spatial, 4, object);
				this._elevatorUp = !this._elevatorUp;
				
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "heavy_rock_drag_01_loop.mp3", 1, true, [SoundModifier.EFFECTS]);
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "heavy_gritty_roll_04_loop.mp3", 1, true, [SoundModifier.EFFECTS]);
				
				//Elevator's coming down and you're trying to escape.
				if(!this._elevatorUp && this.shellApi.checkEvent(_events.PLAYER_ESCAPED_WLAMP))
				{
					SceneUtil.lockInput(this);
					SceneUtil.setCameraTarget(this, this._elevator);
					
					var elevator:DisplayObjectContainer = this._hitContainer["elevator"];
					var charGroup:CharacterGroup = this.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
					var lookData:LookData;
					
					lookData = new LookData();
					lookData.applyLook("male", 0xd2aa72, 0x0, "casual", "skullmainfarmer2", "1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "an_thief1", "an_thief1");
					charGroup.createDummy("elevator_thief_1", lookData, "left", "", elevator, this, null, false, NaN, "dummy", new Point(-142, 175));
					
					lookData = new LookData();
					lookData.applyLook("male", 0xd2aa72, 0x0, "casual", "ce_ranger", "1", "an_thief1", "an_thief2", "an_thief2", "an_thief2", "an_thief2");
					charGroup.createDummy("elevator_thief_2", lookData, "left", "", elevator, this, null, false, NaN, "dummy", new Point(-249, 194));
					
					lookData = new LookData();
					lookData.applyLook("female", 0xd2aa72, 0x0, "casual", "snootygirl", "19", "an_thief1", "an_thief1", "an_thief2", "an_thief2", "an_thief2", "an_thief1");
					charGroup.createDummy("elevator_thief_3", lookData, "left", "", elevator, this, null, false, NaN, "dummy", new Point(-36, 174));
					
					SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, animateElevatorThieves));
					
					Dialog(this.player.get(Dialog)).sayById("open");
				}
			}
		}
		
		private function animateElevatorThieves():void
		{
			var master:Entity = this.getEntityById("master_thief");
			Display(master.get(Display)).visible = true;
			
			CharUtils.setAnim(this.getEntityById("elevator_thief_1"), FightStance);
			CharUtils.setAnimSequence(this.getEntityById("elevator_thief_2"), new <Class>[Laugh], true);
			CharUtils.setAnim(this.getEntityById("elevator_thief_3"), Sit);
		}
		
		private function onElevatorComplete():void
		{
			this._elevatorMoving = false;
			
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "heavy_rock_drag_01_loop.mp3");
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "heavy_gritty_roll_04_loop.mp3");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "deep_impact_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			if(this.shellApi.checkEvent(_events.PLAYER_ESCAPED_WLAMP))
			{
				var masterThief:Entity = this.getEntityById("master_thief");
				CharUtils.setDirection(this.player, false);
				SceneUtil.setCameraTarget(this, masterThief);
				
				var dialog:Dialog = masterThief.get(Dialog);
				dialog.complete.addOnce(throwBomb);
				dialog.sayById("myself");
				
				TweenUtils.entityTo(masterThief, Spatial, 2, {x:870, ease:Linear.easeNone, onComplete:stopWalking});
				CharUtils.setAnim(masterThief, Walk);
			}
		}
		
		private function stopWalking():void
		{
			CharUtils.setAnim(this.getEntityById("master_thief"), Stand);
		}
		
		private function throwBomb(dialogData:DialogData):void
		{
			SceneUtil.setCameraTarget(this, this.player);
			CharUtils.setAnim(this.player, Tremble);
			var masterThief:Entity = this.getEntityById("master_thief");
			CharUtils.triggerSpecialAbility(masterThief);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.4, 1, bombExploded));
		}
		
		private function bombExploded():void
		{
			CharUtils.setAnim(this.player, Dizzy);
			SkinUtils.setEyeStates(this.player, EyeSystem.CLOSED);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, loadTreasureKeep));
		}
		
		private function loadTreasureKeep():void
		{
			this.shellApi.completeEvent(_events.PLAYER_CAUGHT_WLAMP);
			this.shellApi.loadScene(TreasureKeep);
		}
		
		private function checkForThiefOutfit():void
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
			
			this.changeBoraxItem(wearingThiefOutfit);
			this.changeThiefHazards(wearingThiefOutfit);
		}
		
		private function changeBoraxItem(wearingThiefOutfit:Boolean):void
		{
			var borax:Entity = this.getEntityById("borax");
			if(borax)
			{
				wearingThiefOutfit ? borax.add(new Item()) : borax.remove(Item);
			}
		}
		
		private function setupMagicSand():void
		{
			this._magicSandGroup = getGroupById(MagicSandGroup.GROUP_ID) as MagicSandGroup;
			if(!this._magicSandGroup)
			{
				this._magicSandGroup = MagicSandGroup(this.addChildGroup(new MagicSandGroup(_hitContainer)));
			}
			this._magicSandGroup.setupPlatforms();
		}
		
		private function setupFlames():void
		{	
			this._flameCreator.setup(this, this._hitContainer["fire1"], null, createFlames);
		}
		
		private function createFlames():void
		{
			this._postFlame = this._flameCreator.createFlame(this, this._hitContainer["fire1"], true);
			this._flameCreator.createFlame(this, this._hitContainer["fire2"], true);
		}
		
		private function setupBarrelRolling():void
		{
			var thief:Entity = this.getEntityById("thief1");
			
			var barrelRoller:BarrelRoller = new BarrelRoller();
			barrelRoller.barrelDisplay = this._hitContainer["barrelArt1"];
			barrelRoller.barrelBitmapData = BitmapUtils.createBitmapData(barrelRoller.barrelDisplay);
			thief.add(barrelRoller);
			
			thief.remove(Sleep);
			thief.sleeping = false;
			
			CharacterGroup(this.getGroupById(CharacterGroup.GROUP_ID)).addFSM(thief);
			thief.remove(HazardCollider);
		}
		
		private function setupThiefHazards():void
		{
			this.player.add(new ThiefAttackTarget());
			var thief:Entity;
			
			if(this.shellApi.checkEvent(_events.PLAYER_ESCAPED_WLAMP))
			{
				thief = this.getEntityById("thief1");
				this.addThiefHazard(thief);
				
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM)
				{
					this.removeEntity(this.getEntityById("thief2"));
					this.removeEntity(this.getEntityById("thief3"));
				}
				else
				{
					thief = this.getEntityById("thief2");
					this.addThiefHazard(thief);
					thief.add(new ThiefAttack(300));
					
					thief = this.getEntityById("thief3");
					this.addThiefHazard(thief);
					thief.add(new ThiefAttack(300));
				}
			}
			else
			{
				for(var index:int = 1; index <= 4; ++index)
				{
					thief = this.getEntityById("thief" + index);
					this.addThiefHazard(thief);
					
					if(index != 4)
					{
						thief.add(new ThiefAttack(300));
					}
				}
			}
		}
		
		private function addThiefHazard(thief:Entity):void
		{
			var hitCreator:HitCreator = new HitCreator();
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			
			var characterMotionControl:CharacterMotionControl = new CharacterMotionControl();
			characterMotionControl.maxAirVelocityX = 200;
			thief.add(characterMotionControl);
			
			var hitData:HazardHitData = new HazardHitData();
			hitData.type = "thief";
			hitData.knockBackCoolDown = 0.75;
			hitData.knockBackVelocity = new Point(1800, 500);
			hitData.velocityByHitAngle = false;
			
			hitCreator.makeHit(thief, HitType.HAZARD, hitData, this);
			hitCreator.addHitSoundsToEntity(thief, audioGroup.audioData, this.shellApi);
			
			var validHit:ValidHit = new ValidHit("barrelRoll");
			validHit.inverse = true;
			thief.add(validHit);
		}
		
		private function changeThiefHazards(wearingThiefOutfit:Boolean):void
		{
			for(var index:int = 1; index <= 4; ++index)
			{
				var thief:Entity = this.getEntityById("thief" + index);
				if(thief)
				{
					var hazard:Hazard = thief.get(Hazard);
					if(hazard)
					{
						hazard.active = !wearingThiefOutfit;
					}
					
					var sceneInteraction:SceneInteraction = thief.get(SceneInteraction);
					sceneInteraction.reached.removeAll();
					
					if(wearingThiefOutfit)
					{
						sceneInteraction.reached.add(sayThiefDialog);
					}
				}
			}
			
			if(wearingThiefOutfit)
			{
				this.player.remove(ThiefAttackTarget);
			}
			else
			{
				this.player.add(new ThiefAttackTarget());
			}
		}
		
		private function sayThiefDialog(player:Entity, thief:Entity):void
		{
			Dialog(thief.get(Dialog)).sayById("hello");
		}
		
		private function setupThiefFallZones():void
		{
			for(var index:int = 1; index <= 3; ++index)
			{
				var fallZone:Entity = this.getEntityById("fallZone" + index);
				var zone:Zone = fallZone.get(Zone);
				zone.entered.add(this.onFallZoneEntered);
				
				fallZone.remove(Sleep);
				fallZone.sleeping = false;
			}
		}
		
		private function onFallZoneEntered(zoneID:String, colliderID:String):void
		{
			if(colliderID.indexOf("thief") == -1) return;
			
			var thief:Entity = this.getEntityById(colliderID);
			thief.remove(ThiefAttack);
			thief.remove(BarrelRoller);
			thief.remove(Hazard);
			Motion(thief.get(Motion)).zeroMotion("x");
			CharUtils.setAnim(thief, Dizzy);
			SkinUtils.setSkinPart(thief, SkinUtils.EYES, "hypnotized");
		}
		
		private function setupBarrelZones():void
		{
			for(var index:int = 1; index <= 5; ++index)
			{
				var barrelZone:Entity = this.getEntityById("barrelZone" + index);
				var zone:Zone = barrelZone.get(Zone);
				zone.entered.add(this.onBarrelZoneEntered);
				
				if(index == 5)
				{
					zone.shapeHit = false;
				}
				
				barrelZone.remove(Sleep);
				barrelZone.sleeping = false;
			}
		}
		
		private function onBarrelZoneEntered(zoneID:String, colliderID:String):void
		{
			if(colliderID.indexOf("barrel") == -1) return;
			
			const barrel:Entity = this.getEntityById(colliderID);
			if(!barrel) return;
			const motion:Motion = barrel.get(Motion);
			
			if(zoneID == "barrelZone1" || zoneID == "barrelZone3")
			{
				motion.velocity.x = 150;
			}
			else if(zoneID == "barrelZone2")
			{
				motion.velocity.x = -150;
			}
			else if(zoneID == "barrelZone4")
			{
				/*
				Needs to be -200 'cause for some reason, the barrels get hung up on the last
				platform if their velocities are too slow...
				*/
				motion.velocity.x = -200;
			}
			else if(zoneID == "barrelZone5")
			{
				barrel.group.removeEntity(barrel);
			}
		}
		
		private function setupIntro():void
		{
			if(!shellApi.checkEvent(_events.INTRO_COMPLETE))
			{
				shellApi.completeEvent(_events.INTRO_COMPLETE);
				showIntroPopup();
			}
		}
		
		private function showIntroPopup():void
		{
			var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			introPopup.updateText("Find the Sultan's lamp!", "Start");
			introPopup.configData("introPopup.swf", "scenes/arab2/shared/");
			addChildGroup(introPopup);
		}
	}
}