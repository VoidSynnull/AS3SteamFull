package game.scenes.arab2.sanctum
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.Wall;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionTarget;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTipActive;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Read;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Throw;
	import game.particles.FlameCreator;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab2.Arab2Events;
	import game.scenes.arab2.cells.Cells;
	import game.scenes.arab2.shared.MagicSandGroup;
	import game.systems.motion.MaintainRotationSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class Sanctum extends PlatformerGameScene
	{
		private const CAUGHT_PLAYER:String = SoundManager.EFFECTS_PATH + "event_07.mp3";
		private const SMASH_LAB:String = SoundManager.EFFECTS_PATH + "ls_cave_pond_splash_02.mp3";
		private const CLOSE_DOOR:String = SoundManager.EFFECTS_PATH + "door_knob_turn_open_01.mp3";
		private const IGNITE:String = SoundManager.EFFECTS_PATH + "explosion_01.mp3";
		private const BURN:String = SoundManager.EFFECTS_PATH + "fire_burst_02.mp3";
		private const BURNOUT:String = SoundManager.EFFECTS_PATH + "burn_flesh_02.mp3";
		private const LAMP_LAND:String = SoundManager.EFFECTS_PATH + "fs_clay_tile_02.mp3";
		private const USE_OIL:String = SoundManager.EFFECTS_PATH + "pour_drink_01.mp3";
		private const EXPLOSION:String = SoundManager.EFFECTS_PATH + "small_explosion_03.mp3";
		
		private var _magicSandGroup:MagicSandGroup;
		private var _events:Arab2Events;
		
		private var masterThief:Entity;
		private var masterThiefDialog:Dialog;
		
		private var charGroup:CharacterGroup;
		
		private var _flameCreator:FlameCreator;
		
		private var flames:Array;
		
		private var storeRoom:Entity;
		private var storeRoomBurned:Entity;
		private var lamp:Entity;
		private var lampFire:Entity;
		private var patrol:Boolean;
		private var oilPot:Entity;
		private var rightZone:Entity;
		private var leftZone:Entity;
		
		private var _mtFacingRight:Boolean = true;
		private var usedRobe:Boolean = false;
		
		
		public function Sanctum()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab2/sanctum/";
			//showHits = true;
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
			charGroup = CharacterGroup( getGroupById(CharacterGroup.GROUP_ID) );
			
			addSystem(new ThresholdSystem());
			addSystem(new MaintainRotationSystem());
			
			setupMagicSand();
			setupChemLab();
			setupLamp();
			setupMasterThief();
			setupDoor();
			setupFire();
			setupOil();
			shellApi.eventTriggered.add(handleEvents);
			
			super.loaded();
		}
		
		private function setupLamp():void
		{
			var clip:MovieClip = _hitContainer["oilLamp"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			lamp = EntityUtils.createMovingEntity(this,clip);
			lamp.add(new Id("lamp"));
			lampFire = EntityUtils.createMovingEntity(this, clip["fire"]);
			lampFire.add(new Id("lampFire"));
		}
		
		private function setupDoor():void
		{
			var clip:MovieClip = _hitContainer["closetDoor"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			var door:Entity = EntityUtils.createMovingTimelineEntity(this,_hitContainer["closetDoor"],_hitContainer);
			door.add(new Id("closetDoor"));
			if(shellApi.checkEvent(_events.STORE_ROOM_BURNED)){
				Timeline(door.get(Timeline)).gotoAndStop("closed");
			}
			else{
				Timeline(door.get(Timeline)).gotoAndStop("open");
				getEntityById("closetGate").remove(Wall);
			}
		}
		
		private function setupOil():void
		{
			oilPot = getEntityById("oilPotInteraction");
			DisplayUtils.bitmapDisplayComponent(oilPot);
			SceneInteraction(oilPot.get(SceneInteraction)).reached.add(makeOilShirt);
		}
		
		private function makeOilShirt(...p):void
		{
			if(usedRobe && shellApi.checkHasItem(_events.WHITE_ROBE) && !shellApi.checkHasItem(_events.THIEVES_GARB)){
				AudioUtils.playSoundFromEntity(oilPot, USE_OIL, 800,0.8,1.4);
				CharUtils.setAnim(player,Salute);
				Timeline(player.get(Timeline)).handleLabel("stop",getGarb);
			}
			else{
				player.get(Dialog).sayById("oil");
			}
		}
		
		private function getGarb(...p):void
		{
			shellApi.removeItem(_events.WHITE_ROBE);
			shellApi.getItem(_events.THIEVES_GARB,null,true)
		}
		
		private function setupMasterThief():void
		{
			masterThief = getEntityById("master");
			
			if(this.shellApi.checkItemEvent(_events.MEDAL))
			{
				this.removeEntity(masterThief);
				return;
			}
			
			masterThief.add(new Sleep(false,true));
			charGroup.addFSM(masterThief);
			CharacterMotionControl(masterThief.get(CharacterMotionControl)).maxVelocityX = 300;
			
			// add player capture zone
			rightZone = getEntityById("zone0");
			Zone(rightZone.get(Zone)).inside.add(spotPlayer);
			//rightZone.add(new FollowTarget(masterThief.get(Spatial)));
			Display(rightZone.get(Display)).isStatic = false;
			rightZone.add(new Sleep(false,true));
			
			leftZone = getEntityById("zone1");
			Zone(leftZone.get(Zone)).inside.add(spotPlayer);
			leftZone.add(new FollowTarget(masterThief.get(Spatial)));
			Display(leftZone.get(Display)).isStatic = false;
			leftZone.add(new Sleep(false,true));
			
			masterThiefDialog = masterThief.get(Dialog);
			patrol = true;
			// starts lamp oil burning
			burnOil();			
		}
		
		// grap lamp, move to oil, gesture, go back
		private function startPatrol(...p):void
		{
			patrol = true;
			masterThiefDialog.sayById("burnedOut");
			masterThiefDialog.complete.addOnce(Command.create(grabLamp,false));
		}
		
		private function grabLamp(dialog:*, fireOn:Boolean):void
		{
			equipLamp(fireOn);
			CharUtils.setAnim(masterThief,Salute);
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,moveToOil));
			AudioUtils.play(this, LAMP_LAND, 1, false,null,null,1.0);
		}
		
		private function moveToOil(...p):void
		{
			if(patrol){
				_mtFacingRight = false;
				CharUtils.moveToTarget(masterThief,910,660,false,thiefUseOil);
			}
		}
		
		private function thiefUseOil(...p):void
		{
			AudioUtils.playSoundFromEntity(oilPot, USE_OIL, 800,0.5,1);
			CharUtils.setAnim(masterThief,Salute);
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,moveToTable));
		}
		
		private function moveToTable(...p):void
		{
			if(patrol){
				_mtFacingRight = true;
				CharUtils.moveToTarget(masterThief,1400,660,false,placeLamp);
			}
		}
		
		private function placeLamp(...p):void
		{
			removeLamp();
			CharUtils.setAnim(masterThief,Salute);
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,burnOil));
			AudioUtils.play(this, LAMP_LAND, 1, false,null,null,1.0);
			
		}
		
		private function burnOil(...p):void
		{
			CharUtils.setAnim(masterThief, Read);
			// reset lamp fire
			Spatial(lampFire.get(Spatial)).scale = 0.3;
			if(patrol){
				TweenUtils.entityTo(lampFire,Spatial,15,{scale:0.05, onComplete:fizzle},"lamp");
			}
		}
		
		private function fizzle(...p):void
		{
			// fizz sound
			AudioUtils.playSoundFromEntity(lamp,BURNOUT,800,0.5,1.0);
			Spatial(lampFire.get(Spatial)).scale = 0;
			if(patrol){
				startPatrol();
			}
		}
		
		// stop all patrol related stuff
		private function stopPatrol(...p):void
		{
			patrol = false;
			masterThief.remove(MotionTarget);
			masterThief.add(new Motion());
			masterThief.remove(FSMControl);
			Tween(lampFire.get(Tween)).killAll();
			// clear anim and word balloon
			EntityUtils.removeAllWordBalloons(this);
		}
		
		private function spotPlayer(z:String, id:String):void
		{
			if(id == "player"){
				if(!checkDisguise()){
					switch(z){
						case "zone0":
							if(_mtFacingRight){ 
								catchPlayer();
							}
							break;
						case "zone1":
							if(!_mtFacingRight){
								catchPlayer();
							}
							break;
					}
				}
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
		
		private function catchPlayer():void
		{
			leftZone.remove(Zone);
			rightZone.remove(Zone);
			SceneUtil.setCameraTarget(this,masterThief);
			facePlayer();
			masterThiefDialog.sayById("caught");
			stopPatrol();
			SceneUtil.lockInput(this,true);
			CharUtils.setAnim(masterThief, Stomp);
			AudioUtils.play(this, CAUGHT_PLAYER, 1, false,null,null,1.0);
		}
		
		private function handleEvents(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "get_caught"){
				failScene();
			}
			else if(event == "throwfire"){
				throwFire(masterThief);
			}
			else if(event == "use_robe"){
				usedRobe = true;
				var p:Spatial = oilPot.get(Spatial);
				CharUtils.moveToTarget(player,p.x,p.y,false,makeOilShirt);
			}
		}
		
		private function throwFire(char:Entity):void
		{
			removeLamp();
			lampFire.get(Spatial).scale = 0.15;
			CharUtils.setAnim(masterThief, Throw);
			var p:Point = EntityUtils.getPosition(masterThief);
			EntityUtils.positionByEntity(lamp,char);
			charGroup.addColliders(lamp); 
			lamp.remove(WallCollider);
			var motion:Motion = new Motion();
			motion.velocity = new Point(250, -400);
			motion.acceleration = new Point(0, 600);
			motion.friction = new Point(0.4, 0);
			motion.rotationAcceleration = 20;
			motion.rotationMaxVelocity = 100;
			lamp.add(motion);
			var threshold:Threshold = new Threshold("y",">");
			threshold.threshold = p.y + 15;
			threshold.entered.addOnce(Command.create(lampLand,lamp));
			lamp.add(threshold);
			SceneUtil.setCameraTarget(this,player);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.4,1,closeDoor));
		}
		
		private function lampLand(thrownlamp:Entity):void
		{
			thrownlamp.remove(Motion);
			AudioUtils.play(this, LAMP_LAND, 1, false, null, null, 1);
			// make fireball after comment
			crazyComment();
		}
		
		private function equipLamp(addFire:Boolean):void
		{
			lamp.add(new Sleep(true,true));
			if(addFire){
				SkinUtils.setSkinPart(masterThief, SkinUtils.ITEM, "oilLampLit");
			}else{
				SkinUtils.setSkinPart(masterThief, SkinUtils.ITEM, "oilLamp");
			}
		}
		
		private function removeLamp():void
		{
			lamp.add(new Sleep(false,false));
			SkinUtils.setSkinPart(masterThief, SkinUtils.ITEM, "empty");
		}
		
		private function crazyComment(...p):void{
			Dialog(player.get(Dialog)).sayById("crazy");
			Dialog(player.get(Dialog)).complete.addOnce(startfireBlast);
		}
		
		private function startfireBlast(...p):void
		{
			CharUtils.setAnim(masterThief, Laugh);
			Timeline(masterThief.get(Timeline)).handleLabel("end", Command.create(CharUtils.moveToTarget,masterThief,1400,660,false,facePlayer));
			CharUtils.setAnim(player, Grief);
			Timeline(player.get(Timeline)).handleLabel("trigger",burnClothing);
			//sound
			AudioUtils.play(this, BURN, 1, false, null, null, 1.1);
			AudioUtils.play(this, IGNITE, 1, false, null, null, 1.1);
			
			// expand flames
			var flame:Entity;
			for (var i:int = 0; i < flames.length; i++) 
			{
				flame = flames[i];
				flame.add(new Sleep());
				var last:Boolean = false;
				if(i == flames.length -1){
					last = true;	
				}
				TweenUtils.entityTo(flame,Spatial,2.5,{scale:1.0, onComplete:endfireBlast, onCompleteParams:[flame, last]},"burn1");
				if(flame.get(Id).id == "playerFire"){
					var follow:FollowTarget = new FollowTarget(player.get(Spatial));
					follow.offset = new Point(0,20)
					flame.add(follow);
					DisplayUtils.moveToTop(flame.get(Display).displayObject);
				}
			}			
			// fade in incinerated room
			SceneUtil.addTimedEvent(this,new TimedEvent(0.5,1,fadeOut));
		}
		
		private function fadeOut():void
		{
			screenEffects.fadeToBlack(2.5, fadeOutComplete);		
		}
		private function fadeOutComplete():void
		{
			// showBurned room art
			removeEntity(storeRoom);
			EntityUtils.visible(storeRoomBurned);
			shellApi.triggerEvent(_events.STORE_ROOM_BURNED, true);
			removeEntity(lampFire);
			AudioUtils.play(this, EXPLOSION, 1.4, false,null,null,1.4);
			SceneUtil.delay(this, .6, fadeIn);
		}
		
		private function fadeIn():void
		{
			screenEffects.fadeFromBlack(2.5, fadeInComplete);
		}
		
		private function fadeInComplete():void
		{
			var dialog:Dialog = player.get(Dialog);
			SceneUtil.delay(this, .6, Command.create(dialog.sayById, "burnedoutfit"));
			dialog.complete.addOnce(returnControl);
		}
		
		private function endfireBlast(flame:Entity, last:Boolean):void
		{
			clearFire(flame);
		}
		
		private function burnClothing(...p):void
		{
			SkinUtils.emptySkinPart(player, SkinUtils.FACIAL, true);
			SkinUtils.emptySkinPart(player, SkinUtils.OVERSHIRT, true);
			shellApi.removeItem(_events.THIEVES_GARB);
			shellApi.removeEvent(_events.PLAYER_DISGUISED);
		}
		
		private function clearFire(flame:Entity):void
		{
			flames.splice(flames.indexOf(flame),1);
			removeEntity(flame);
		}
		
		private function returnControl(...p):void
		{
			SceneUtil.setCameraTarget(this, player);
			SceneUtil.lockInput(this, false);
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
		
		private function setupChemLab():void
		{
			var clip:MovieClip = _hitContainer["bounds0"];
			var bounds:Rectangle = new Rectangle(clip.x,clip.y,clip.width,clip.height);
			_hitContainer.removeChild(clip);
			clip = _hitContainer["chem"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			var lab:Entity = (new SceneObjectCreator()).createBox(clip,0.01,super.hitContainer,clip.x, clip.y,null,null,bounds,this,null,null,600,false);
			if(!shellApi.checkEvent(_events.STORE_ROOM_BURNED)){
				lab.add(new Id("chemStation"));
				lab.add(new WallCollider());
				lab.add(new PlatformCollider());
				lab.add(new ZoneCollider());
				InteractionCreator.addToEntity(lab,[InteractionCreator.CLICK]);
				var sceneInter:SceneInteraction = new SceneInteraction();
				sceneInter.reached.add(Command.create(openChemLab,50,0));
				lab.add(sceneInter);
				lab.add(new Sleep(false,true));
				ToolTipCreator.addToEntity(lab);
			}else{
				// throw lab into pit if magic sand has been created 
				Spatial(lab.get(Spatial)).y += 300;
			}
		}
		
		private function openChemLab(...p):void
		{
			//	alchemy popup
			if(shellApi.checkEvent(_events.GOT_ALL_INGREDIENTS)){
				var popup:AlchemyTable = super.addChildGroup(new AlchemyTable(super.overlayContainer)) as AlchemyTable;
				popup.id = "alchemy_table";
				popup.completeSignal = new Signal();
				popup.completeSignal.addOnce(getMagicSand);
			}else if(shellApi.checkHasItem(_events.FORMULA)){
				Dialog(player.get(Dialog)).sayById("labmissingitems");
			}else{
				Dialog(player.get(Dialog)).sayById("labnoformula");
			}
			//SceneUtil.addTimedEvent(this, new TimedEvent(2,1,Command.create(shellApi.triggerEvent,"sinklab")));
		}
		
		private function getMagicSand(sucess:Boolean):void
		{
			if(sucess){
				//shellApi.triggerEvent("sinklab");
				shellApi.getItem(_events.MAGIC_SAND,null, true);
				SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,backUp));
			}else{
				Dialog(player.get(Dialog)).sayById("labretry");
				SceneUtil.lockInput(this, false, false);
			}
		}
		
		// move back from table
		private function backUp():void
		{
			CharUtils.moveToTarget(player,2100,620,false,sinkLab);
		}
		
		private function sinkLab(...p):void
		{
			SceneUtil.lockInput(this, true);
			CharUtils.setDirection(player,true);
			stopPatrol();
			var lab:Entity = getEntityById("chemStation");
			_magicSandGroup.explodeAt(lab.get(Spatial));
			// lil bit shorter sand effect, for timing.
			_magicSandGroup.applyMagicSandEffect(getEntityById("magicSandPlat0"),3);
			var threshold:Threshold = new Threshold("y",">");
			threshold.threshold = 1150;
			threshold.entered.addOnce(Command.create(smashLab,lab));
			lab.get(Spatial).y += 50;
			lab.add(threshold);
		}
		
		private function facePlayer(...p):void
		{
			if(masterThief.get(Spatial).x > player.get(Spatial).x){
				CharUtils.setDirection(masterThief,false);
			}else{
				CharUtils.setDirection(masterThief,true);
			}
		}
		
		private function smashLab(lab:Entity):void
		{
			// SMASH
			AudioUtils.play(this, SMASH_LAB, 1, false,null,null,0.8);
			// disable interaction
			lab.remove(Interaction);
			lab.remove(SceneInteraction);
			Children(lab.get(Children)).children[0].remove(ToolTipActive);
			var dialog:Dialog = Dialog(player.get(Dialog));
			dialog.sayById("useful");
			dialog.complete.addOnce(sandCommentDone);
		}
		
		private function sandCommentDone(...p):void
		{
			// reset sand duration
			_magicSandGroup.effectDuration = 5;
			// alert thief
			stopPatrol();
			SceneUtil.setCameraTarget(this, masterThief);
			masterThiefDialog.sayById("what");
			masterThiefDialog.complete.removeAll();
			masterThiefDialog.complete.addOnce(moveThiefToDoor);
		}
		
		private function moveThiefToDoor(...p):void
		{
			grabLamp(null,true);
			CharUtils.moveToTarget(masterThief,_hitContainer["nav2"].x,665,false,fireComment);
		}
		
		private function fireComment(...p):void
		{
			masterThiefDialog.sayById("throw");
			CharUtils.setDirection(player,false);
		}
		
		private function closeDoor():void
		{
			var door:Entity = getEntityById("closetDoor");
			getEntityById("closetGate").add(new Wall());
			var tl:Timeline = door.get(Timeline);
			tl.gotoAndPlay("close");
			AudioUtils.play(this, CLOSE_DOOR,1,false,null,null,1.0);
		}
		
		private function setupMagicSand():void
		{
			_magicSandGroup = getGroupById(MagicSandGroup.GROUP_ID) as MagicSandGroup;
			if(!_magicSandGroup){
				_magicSandGroup = MagicSandGroup(this.addChildGroup(new MagicSandGroup(_hitContainer)));
			}
			_magicSandGroup.setupPlatforms();
		}
		
		private function setupFire():void
		{
			// set burned-up room
			var disp:Sprite = createBitmapSprite(_hitContainer["storeRoom"]);
			storeRoom = EntityUtils.createSpatialEntity(this, disp,_hitContainer);
			disp = createBitmapSprite(_hitContainer["storeRoomBurned"]);
			storeRoomBurned = EntityUtils.createSpatialEntity(this, disp,_hitContainer);
			if(shellApi.checkEvent(_events.STORE_ROOM_BURNED)){
				removeEntity(storeRoom);
			}else{
				EntityUtils.visible(storeRoomBurned, false);
			}
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, _hitContainer[ "fire" + 0 ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			flames = [];
			var clip:MovieClip;
			var flame:Entity;
			for( var i:uint = 0; _hitContainer[ "fire" + i ] != null; i ++ )
			{
				clip = _hitContainer[ "fire" + i ];
				flame = _flameCreator.createFlame( this, clip, true );
				if(i > 1){
					// hide closet flames until fire is started
					flame.add(new Sleep(true,true));
					flames.push(flame);
					if(i == 8){
						flame.add(new Id("playerFire"));
					}
				}
			}
			// lamp fire
			var lamp:Entity = getEntityById("lamp");
			if(lamp){
				clip = _hitContainer["oilLamp"][ "fire" ];
				flame = _flameCreator.createFlame( this, clip, true );
			}
		}
	}
}