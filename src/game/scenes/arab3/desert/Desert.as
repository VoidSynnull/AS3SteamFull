package game.scenes.arab3.desert
{
	import com.greensock.easing.Back;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterWander;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Door;
	import game.components.hit.Zone;
	import game.components.motion.Proximity;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.AnimationData;
	import game.data.animation.AnimationSequence;
	import game.data.animation.entity.character.BigStomp;
	import game.data.animation.entity.character.Cough;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Read;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Sleep;
	import game.data.animation.entity.character.Soar;
	import game.data.animation.entity.character.Stand;
	import game.data.specialAbility.islands.arab.MagicCarpet;
	import game.scene.template.ItemGroup;
	import game.scenes.arab1.desert.components.Awning;
	import game.scenes.arab1.desert.particles.SandFall;
	import game.scenes.arab1.desert.systems.AwningSystem;
	import game.scenes.arab1.shared.groups.SmokeBombGroup;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.arab3.bazaar.Bazaar;
	import game.scenes.arab3.shared.DivinationTarget;
	import game.scenes.custom.AdMiniBillboard;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ProximitySystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.hud.Hud;
	import game.ui.inventory.Inventory;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.initializers.ColorInit;
	import org.osflash.signals.Signal;
	
	public class Desert extends Arab3Scene
	{
		private const SHATTER_SOUND:String = SoundManager.EFFECTS_PATH + "glass_break_03.mp3";
		private const FADE_SOUND:String = SoundManager.EFFECTS_PATH + "event_02.mp3";	
		private const COMPASS_DROP:String = SoundManager.EFFECTS_PATH + "sand_hard_01.mp3";		
		private const POOF_SOUND:String = SoundManager.EFFECTS_PATH + "poof_02.mp3";
		private const FOUND:String = SoundManager.MUSIC_PATH + "genie_found.mp3";
		
		private var oldman:Entity;
		private var enforcer:Entity;
		private var turban:Entity;
		private var genie:Entity;
		private var compass:Entity;
		private var cliffZone:Entity;
		private var sultan:Entity;
		private var genieHuman:Entity;
		private var genieThief:Entity;	
		private var lamp:Entity;
		
		// positions for genie
		private var genieLocId:int;
		private var genieFleePoints:Vector.<Point>;
		
		private var _smokeBombGroup:SmokeBombGroup;
		private var griefTimer:TimedEvent;
		private var _sandParticles:SandFall;
		private var _sandEmitter:Entity;
		private var pickedDrawing:String = "nothing"; // states: drawing, other, nothing
		private var gaveDrawing:Boolean;
		
		public function Desert()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer=null ):void 
		{
			super.groupPrefix = "scenes/arab3/desert/";
			_numSpellTargets = 6;
			_numThiefSpellTargets = 6;
			super.init( container );
		}
		override public function loaded():void
		{
			super.loaded();
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(535, 1125),"minibillboard/minibillboardSmallLegs.swf");	
		}
		private function handleEventTriggered(event:String, ...junk):void
		{
			if(event == _events.USE_DRAWING){
				if( shellApi.checkEvent( _events.SKY_CHASE_COMPLETE ))
				{
					if(sultan && genieHuman){
						pickedDrawing = "drawing";
					}
				}
				else
				{
					Dialog( player.get( Dialog )).sayById( "drawn" );
				}
			}
			else if(event.indexOf("use") != -1){
				// reject during sultan wiating
				if(sultan && genieHuman){
					pickedDrawing = "other";
				}
				else if(event == _events.USE_LAMP)
				{
					usedLamp();
				}
				else{
					checkSmashItem(event);
				}
			}
			else if(event == "wish_robots")
			{
				this.shellApi.takePhoto("13501", wishPhotoTaken);
			}
			else if(event == "wish_animals")
			{
				this.shellApi.takePhoto("13502", wishPhotoTaken);
			}
			else if(event == "wish_banjo")
			{
				this.shellApi.takePhoto("13503", wishPhotoTaken);
			}
			else if(event == "make_wish")
			{
				finalPoof();
			}
		}		
		
		private function wishPhotoTaken():void
		{
			Dialog(sultan.get(Dialog)).sayById("fine");
			Dialog(sultan.get(Dialog)).complete.addOnce(turn);
		}
		
		private function turn(...p):void
		{
			CharUtils.setDirection(sultan, true);
		}
		
		override public function smokeReady():void
		{						
			_smokeBombGroup = addChildGroup(new SmokeBombGroup(this,_hitContainer)) as SmokeBombGroup;
			
			shellApi.eventTriggered.add(handleEventTriggered);
			
			setupIntro();
			
			setupSceneEntities();
			
			setupGenieHiding();
		}
		
		private function setupSceneEntities():void
		{
			var flag:Entity = EntityUtils.createMovingTimelineEntity(this, _hitContainer["flag0"], null, true);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				flag = BitmapTimelineCreator.convertToBitmapTimeline(flag, null, true, null, PerformanceUtils.defaultBitmapQuality);
			}
			flag = EntityUtils.createMovingTimelineEntity(this, _hitContainer["flag1"], null, true);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				flag = BitmapTimelineCreator.convertToBitmapTimeline(flag, null, true, null, PerformanceUtils.defaultBitmapQuality);
			}
			cliffZone = getEntityById("cliffZone");
			Zone(cliffZone.get(Zone)).entered.add(talkCliff);
			
			lamp = EntityUtils.createSpatialEntity(this, _hitContainer["lamp"]);
			lamp.get(Display).visible =  false;
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				DisplayUtils.bitmapDisplayComponent(lamp,true, PerformanceUtils.defaultBitmapQuality);
				Spatial(lamp.get(Spatial)).scaleY *= -1;
			}
			setupParticles();
			setupAwning(); 
		}
		
		private function talkCliff(...p):void
		{
			var targ:Point = new Point(player.get(Spatial).x-200,1438);
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			actions.addAction(new MoveAction(player,targ));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,true)));
			actions.addAction(new TalkAction(player,"cliff"));
			actions.execute();
		}
		
		private function setupAwning():void
		{
			this.getEntityById("awning").add(new Awning());
			this.addSystem(new AwningSystem(this, _sandParticles), SystemPriorities.checkCollisions);
		}
		
		private function setupParticles():void
		{
			_sandParticles = new SandFall();
			_sandEmitter = EmitterCreator.create(this, this._hitContainer, _sandParticles, 0, 0, null, null, new Spatial(206,1268));
			_sandParticles.init(this);
			_sandParticles.addInitializer(new ColorInit(0x8BA184, 0xA2BA98));
		}
		
		private function setupGenieHiding():void
		{
			turban = getEntityById("turban");
			genie = getEntityById("genie");
			genie.get(Display).visible = false;
			ToolTipCreator.removeFromEntity(genie);
			genie.remove(Interaction);
			genie.remove(SceneInteraction);
			genie.add(new game.components.entity.Sleep(false,true));
			_smokePuffGroup.addJinnTailSmoke(genie);
			
			var turbanHat:Timeline = SkinUtils.getSkinPartEntity(turban,SkinUtils.HAIR).get(Timeline);
			var compassItem:Timeline = SkinUtils.getSkinPartEntity(turban, SkinUtils.ITEM).get(Timeline);
			
			this.compass = EntityUtils.createMovingEntity(this, _hitContainer["compass"]);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				DisplayUtils.bitmapDisplayComponent(compass,true, PerformanceUtils.defaultBitmapQuality);
			}
			if(shellApi.checkEvent(_events.GENIE_IN_DESERT_SKY) && !shellApi.checkItemEvent(_events.COMPASS)){
				this.compass.get(Display).visible = true;
				addSystem(new ProximitySystem());
				var prox:Proximity = new Proximity(60, player.get(Spatial));
				prox.entered.addOnce(getCompass);
				compass.add(prox);
				ToolTipCreator.addToEntity(compass);
			}else{
				this.compass.get(Display).visible = false;
				compass.get(Spatial).y -= 120;
			}
			if(shellApi.checkEvent(_events.SKY_CHASE_COMPLETE)){
				// ending stuff
				removeEntity(oldman);
				removeEntity(turban);
				removeEntity(genie);
				startEndSequence();
			}
			else if(shellApi.checkEvent(_events.GENIE_IN_ATRIUM)){
				// gone to atrium for minigame
				removeEntity(turban);
				removeEntity(oldman);
				removeEntity(genie);
			}
			else if(shellApi.checkEvent(_events.GENIE_IN_DESERT_SKY)){
				// hiding here in sky
				removeEntity(turban);
				idleGenie();
			}
			else if(shellApi.checkEvent(_events.GENIE_IN_DESERT)){
				// hiding here in hat
				turbanHat.gotoAndPlay("start");
				compassItem.gotoAndPlay("start");
				turbanHat.handleLabel("hide",hidePuff, false);
				Dialog(turban.get(Dialog)).complete.add(peakGenie);				
				var divination:DivinationTarget = new DivinationTarget();
				divination.response.addOnce(turbanHit);
				turban.add(divination);
				// hide genie
				EntityUtils.positionByEntity(genie, turban);
			}
			else if(shellApi.checkEvent(_events.GENIE_IN_BAZAAR) || shellApi.checkEvent(_events.GENIE_IN_PALACE)){
				//genie around but not here
				removeEntity(genie);
				turbanHat.gotoAndStop("start");
				compassItem.gotoAndStop("start");
			}
			else{
				// pre-hasItem_drawing state, no genie anywhere
				turbanHat.gotoAndStop("start");
				compassItem.gotoAndStop("start");
			}
			
		}
		
		private function getCompass(...p):void
		{
			ToolTipCreator.removeFromEntity(compass);
			removeEntity(compass);
			
			shellApi.getItem(_events.COMPASS,null, true);
		}
		
		private function hidePuff():void
		{
			//_smokePuffGroup.poofAt(turban, 0.2);
		}
		
		private function startEndSequence():void
		{	
			if(!shellApi.checkHasItem(_events.DRAWING)){
				shellApi.getItem(_events.DRAWING);
			}
			if(shellApi.checkHasItem(_events.MAGIC_CARPET)){
				shellApi.removeItem(_events.MAGIC_CARPET);
			}
			if(shellApi.checkHasItem(_events.SKELETON_KEY)){
				shellApi.removeItem(_events.SKELETON_KEY);
			}
			if(shellApi.checkHasItem(_events.MAGIC_BOOK)){
				shellApi.removeItem(_events.MAGIC_BOOK);
			}
			if(shellApi.checkHasItem(_events.DIVINATION_DUST)){
				shellApi.removeItem(_events.DIVINATION_DUST);
			}
			SceneUtil.lockInput(this,true,true);
			sultan = getEntityById("sultan");
			DisplayUtils.moveToTop( EntityUtils.getDisplayObject(sultan) );
			sultan.add(new game.components.entity.Sleep(false,true));
			genieHuman = getEntityById("genieHuman");
			genieHuman.add(new game.components.entity.Sleep(false,true));
			genieThief = getEntityById("genieThief");
			genieThief.add(new game.components.entity.Sleep(false,true));
			super.addGenieWaveMotion(genieThief, true);
			//		_smokePuffGroup.addJinnTailSmoke(genieThief, true);
			
			
			// player falls from top
			EntityUtils.position(player, 1450, -100);
			player.add(new game.components.entity.Sleep(false, true));
			FSMControl(player.get(FSMControl)).setState(CharacterState.HURT);
			FSMControl(player.get(FSMControl)).stateChange = new Signal();
			FSMControl(player.get(FSMControl)).stateChange.add(knockDown);
			MotionUtils.zeroMotion(player,"y");
			CharUtils.removeSpecialAbilityByClass(player, MagicCarpet, true);
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM, true);
			
			Dialog(sultan.get(Dialog)).replaceKeyword("[PLAYER_NAME]", shellApi.profileManager.active.avatarName);
			
			EntityUtils.position(genieThief, 1700, -100);
			
			genieThief.remove(Interaction);
			genieThief.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity(genieThief);
			
			var interaction:Interaction = sultan.get(Interaction);
			interaction.click.removeAll();
			//interaction.click.add(sultanComment);
			
			interaction = genieHuman.get(Interaction);
			interaction.click.removeAll();
			//interaction.click.add(genieComment);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2.2,1,genieDescends));
		}
		
		private function knockDown(s:String, ent:Entity):void
		{
			if(s != CharacterState.HURT && s != CharacterState.FALL){
				CharUtils.setAnim(player, game.data.animation.entity.character.Sleep,false,0,0,true);
				CharacterMotionControl(player.get(CharacterMotionControl)).spinEnd = true;
				Motion(player.get(Motion)).rotation = 0
				Motion(player.get(Motion)).zeroMotion("rotation");
				FSMControl(player.get(FSMControl)).stateChange.removeAll();
			}
		}
		
		private function genieDescends():void
		{
			CharUtils.setAnim(genieThief, Soar);
			TweenUtils.entityTo(genieThief, Spatial, 3.0, {y:1200, ease:Back.easeOut, onComplete:startEndDialog});
		}
		
		private function startEndDialog(...p):void
		{
			SceneUtil.lockInput(this, true);
			
			var actions:ActionChain = new ActionChain(this);
			
			//actions.lockInput = true;
			
			actions.addAction(new TalkAction(genieThief,"souls"));
			actions.addAction(new CallFunctionAction(Command.create(_smokePuffGroup.startSpellCasting,genieThief, true)));
			MoveAction(actions.addAction(new MoveAction(sultan, new Point(1600, 1300),new Point(50, 100)))).restoreControl = false;
			actions.addAction(new WaitAction(0.64));
			actions.addAction(new CallFunctionAction(sultanUseLamp));
			actions.addAction(new CallFunctionAction(Command.create(_smokePuffGroup.stopSpellCasting,genieThief)));
			actions.addAction(new WaitAction(1.50));		
			actions.addAction(new CallFunctionAction(lockDoor));
			actions.addAction(new AnimationAction(genieThief, Grief,"trigger",0,true));
			actions.addAction(new TalkAction(genieThief, "please"));
			actions.addAction(new TalkAction(player, "father"));
			actions.addAction(new TalkAction(sultan, "treasure"));
			actions.addAction(new TalkAction(genieThief, "everything"));
			actions.addAction(new TalkAction(sultan, "riches"));
			MoveAction(actions.addAction(new MoveAction(genieHuman, new Point(1350, 1483),new Point(50, 100)))).restoreControl = false;
			actions.addAction(new TalkAction(genieHuman, "again"));
			actions.addAction(new CallFunctionAction(openInventory));
			
			actions.execute();
		}
		
		private function openInventory(...p):void
		{
			// force open inventory, respond to used_'wrong'item with sultan rejecting it and then reopen inventory
			var hud:Hud = super.getGroupById( Hud.GROUP_ID ) as Hud;
			var inventory:Inventory = hud.openInventory();
			inventory.removed.addOnce(inventoryClosed);
			inventory.pauseParent = true;
			inventory.ready.addOnce(unlock);
			pickedDrawing = "nothing";
		}
		
		private function inventoryClosed(...p):void
		{
			var sultanDial:Dialog = sultan.get(Dialog);
			CharUtils.setDirection(sultan, false);
			SceneUtil.lockInput(this, true);
			if(pickedDrawing == "other"){
				sultanDial.sayById("what");
				sultanDial.complete.removeAll();
				sultanDial.complete.addOnce(wrongEndingItem);
			}
			else if(pickedDrawing == "nothing"){
				sultanDial.sayById("nothing");
				sultanDial.complete.removeAll();
				sultanDial.complete.addOnce(wrongEndingItem);
			}
			else{
				SceneUtil.addTimedEvent(this, new TimedEvent(0.6,1,giveDrawing));
			}
		}
		private function wrongEndingItem(...p):void
		{
			var genieDial:Dialog = genieHuman.get(Dialog);
			genieDial.sayById("again");
			genieDial.complete.removeAll();
			genieDial.complete.addOnce(openInventory);
		}
		
		private function unlock(popup:Inventory):void
		{
			SceneUtil.lockInput(popup, false);
		}
		
		private function genieComment(...p):void
		{
			SceneUtil.lockInput(this, true);
			
			Dialog(genieHuman.get(Dialog)).sayById("back");
			Dialog(genieHuman.get(Dialog)).complete.removeAll();
			Dialog(genieHuman.get(Dialog)).complete.addOnce(openInventory);
		}
		
		private function sultanComment(...p):void
		{
			Dialog(sultan.get(Dialog)).sayById("understand");
		}
		
		private function sultanUseLamp():void
		{
			_smokePuffGroup.trapJinn(genieThief, sultan, placeLamp, null, "stop");
		}
		
		private function placeLamp(...p):void
		{
			var actions:ActionChain = new ActionChain(this);
			
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new AnimationAction(sultan, Place, "trigger2"));
			actions.addAction(new SetSkinAction(sultan, SkinUtils.ITEM, "empty", true)).noWait = true;
			actions.addAction(new AnimationAction(genieThief, Stand)).noWait = true;
			actions.addAction(new CallFunctionAction(showLamp));
			actions.execute();
		}
		
		private function giveDrawing():void
		{
			if(!gaveDrawing){
				gaveDrawing = true;
				CharUtils.stateDrivenOff(player);
				
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				var target:Point = EntityUtils.getPosition(sultan);
				target.x -= 100;
				actions.addAction(new MoveAction(player ,target, new Point(50,100)));
				actions.addAction(new SetSkinAction(player, SkinUtils.ITEM,"an_drawing",false,true));
				actions.addAction(new AnimationAction(player, Read,"",0,false)).noWait = true;
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player, true)));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,sultan, false)));
				actions.addAction(new WaitAction(1.4));
				actions.addAction(new SetSkinAction(player, SkinUtils.ITEM, "empty", true)).noWait = true;
				actions.addAction(new AnimationAction(player, Stand,"",0,false)).noWait = true;
				actions.addAction(new RemoveItemAction(_events.DRAWING,"sultan",true));
				actions.addAction(new TalkAction(sultan, "drawing"));
				actions.addAction(new SetSkinAction(sultan, SkinUtils.ITEM,"an_drawing2",false,true));
				actions.addAction(new AnimationAction(sultan, Read,"",0,false)).noWait = true;
				actions.addAction(new CallFunctionAction(stopRage));
				actions.addAction(new WaitAction(1.5));
				actions.addAction(new AnimationAction(sultan, Cry));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection, sultan, true)));
				actions.addAction(new TalkAction(sultan, "blind"));
				actions.addAction(new TalkAction(genieThief, "princess"));
				actions.addAction(new TalkAction(genieThief, "life"));
				actions.addAction(new TalkAction(sultan, "sorry"));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection, sultan, false)));
				actions.addAction(new TalkAction(sultan, "thank"));
				
				actions.execute();
			}
		}
		
		private function showLamp():void
		{
			Display(lamp.get(Display)).visible = true;
			// genie girl rages about being trpped
			//SkinUtils.setSkinPart(genieThief, SkinUtils.MOUTH, "teethgrin2");
			SkinUtils.setEyeStates( genieThief, EyeSystem.OPEN_CASUAL);
			griefTimer = SceneUtil.addTimedEvent(this, new TimedEvent(3,1, rage));
		}
		
		private function rage(...p):void
		{
			CharUtils.setAnim(genieThief, Grief);
			
			CharUtils.getTimeline(genieThief).handleLabel("end", rageDelay);
		}
		
		private function rageDelay(...p):void
		{
			//SkinUtils.setSkinPart(genieThief, SkinUtils.MOUTH, "teethgrin2");
			
			griefTimer = SceneUtil.addTimedEvent(this, new TimedEvent(3,1, rage));
		}
		
		private function stopRage(...p):void
		{
			CharUtils.setAnim(genieThief, Stand, true,0,0,true);
			griefTimer.stop();
		}
		
		private function finalPoof():void
		{
			SceneUtil.lockInput(this, true);
			var actions:ActionChain = new ActionChain(this);
			
			actions.addAction(new SetSkinAction(genieThief, SkinUtils.MOUTH, "teethgrin2",true,true));
			actions.addAction(new TalkAction(genieThief,"command"));
			actions.addAction(new CallFunctionAction(Command.create(_smokePuffGroup.startSpellCasting,genieThief, true)));
			actions.addAction(new WaitAction(0.4));
			actions.addAction(new CallFunctionAction(Command.create(_smokePuffGroup.castSpell,genieThief,new <Entity>[sultan, genieHuman, genieThief, player],null,null,true,false,true)));
			actions.addAction(new WaitAction(0.7));
			// SOUND
			actions.addAction(new AudioAction(genie, FADE_SOUND, 500, 1));
			actions.addAction(new CallFunctionAction(moveToBazaar));
			
			actions.execute();
		}
		private function moveToBazaar(...p):void
		{
			//ending continued in bazaar
			shellApi.completeEvent(_events.SULTAN_MADE_WISH);
			shellApi.loadScene(Bazaar);
		}
		
		private function lockDoor():void
		{
			CharUtils.setAnim(player, Stand,false, 0,0,true);
			FSMControl(player.get(FSMControl)).setState(CharacterState.STAND);
			CharUtils.stateDrivenOn(player);
			
			var door:Entity = getEntityById("doorBazaar");
			door.remove(Door);
			var inter:Interaction = door.get(Interaction);
			var sceneInt:SceneInteraction = door.get(SceneInteraction);
			//inter.removeAll();
			sceneInt.reached.removeAll();
			sceneInt.reached.add(doorComment);
			
			//var lampZone:Entity = getEntityById("lampZone");
			//var zone:Zone = lampZone.get(Zone);
			//zone.exitted.add(goBackToDais);
		}
		
		private function goBackToDais(z:String, id:String):void
		{
			if(id == "player"){
				SceneUtil.lockInput(this, true, true);
				var actions:ActionChain = new ActionChain(this);
				actions.addAction(new PanAction(genieHuman));
				actions.addAction(new TalkAction(genieHuman,"back"));
				actions.addAction(new PanAction(player));
				actions.addAction(new MoveAction(player, new Point(1450,1300),new Point(50,50)));
				actions.execute(Command.create(SceneUtil.lockInput,this, true, true));
			}
		}
		
		private function doorComment(...p):void
		{
			Dialog(player.get(Dialog)).sayById("right");
		}
		
		private function peakGenie(...p):void
		{
			var turbanHat:Timeline = SkinUtils.getSkinPartEntity(turban,SkinUtils.HAIR).get(Timeline);
			turbanHat.gotoAndPlay("start");
		}
		
		private function turbanHit(bomb:Entity):void
		{
			var turbanHat:Timeline = SkinUtils.getSkinPartEntity(turban,SkinUtils.HAIR).get(Timeline);
			var compassItem:Timeline = SkinUtils.getSkinPartEntity(turban, SkinUtils.ITEM).get(Timeline);
			// grief the poor guy and release the genie
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			var targ:Point = EntityUtils.getPosition(turban);
			targ.x += 100;	
			actions.addAction(new CallFunctionAction(killWander));
			actions.addAction(new AnimationAction(turban, Stand)).noWait = true;
			actions.addAction(new PanAction(turban));
			actions.addAction(new CallFunctionAction(Command.create(turbanHat.gotoAndStop,"end")));
			actions.addAction(new CallFunctionAction(Command.create(compassItem.gotoAndStop,"end")));
			actions.addAction(new AnimationAction(turban, Grief));
			actions.addAction(new CallFunctionAction(showGenie));
			actions.addAction(new AnimationAction(genie, Cough, "", 50, true));
			actions.addAction(new TalkAction(genie, "rage"));
			actions.addAction(new CallFunctionAction(genieFlysAway));
			actions.addAction(new WaitAction(3.5));
			actions.addAction(new PanAction(player));
			actions.addAction(new TalkAction(player,"time"));
			actions.addAction(new PanAction(turban));
			actions.addAction(new TalkAction(turban,"waste"));
			actions.addAction(new AnimationAction(turban, Grief, "trigger"));
			actions.addAction(new CallFunctionAction(dropCompass));
			actions.addAction(new PanAction(compass));
			actions.addAction(new MoveAction(turban, new Point(-100, targ.y)));
			actions.addAction(new CallFunctionAction(Command.create(removeEntity, turban)));
			actions.addAction(new TalkAction(player, "need"));
			actions.addAction(new MoveAction(player, compass, new Point(50,100)));
			actions.addAction(new AnimationAction(player, Place));
			actions.addAction(new CallFunctionAction(Command.create(removeEntity, compass)));
			actions.addAction(new GetItemAction(_events.COMPASS));
			actions.addAction(new PanAction(player));
			actions.addAction(new TriggerEventAction(_events.GENIE_IN_DESERT_SKY, true));
			
			actions.execute();
		}		
		
		private function dropCompass():void
		{
			// drop it fool!
			EntityUtils.positionByEntity(compass, turban, false,true);
			compass.get(Spatial).y += -50;
			SkinUtils.emptySkinPart(turban, SkinUtils.ITEM);
			compass.get(Display).visible = true;
			var motion:Motion = new Motion();
			motion.velocity = new Point(10,-MotionUtils.GRAVITY/4);
			motion.acceleration = new Point(0, MotionUtils.GRAVITY/1.2);
			compass.add(motion);
			var thresh:Threshold = new Threshold("y",">");
			thresh.threshold = turban.get(Spatial).y + 16;
			thresh.entered.addOnce(landCompass);
			compass.add(thresh);
			addSystem(new ThresholdSystem());
		}
		
		private function landCompass(...p):void
		{
			MotionUtils.zeroMotion(compass);
			shellApi.completeEvent(_events.GENIE_IN_DESERT_SKY);
			AudioUtils.playSoundFromEntity(compass,COMPASS_DROP,500);
		}
		
		private function killWander():void
		{
			Dialog(turban.get(Dialog)).complete.remove(peakGenie);
			turban.get(Motion).zeroMotion();
			turban.remove(CharacterWander);
		}
		private function showGenie():void
		{
			AudioUtils.play(this, FOUND,1.2,false,null,null,1.2);
			AudioUtils.playSoundFromEntity(genie, POOF_SOUND, 600, 0.2);
			EntityUtils.positionByEntity(genie,turban);
			genie.get(Spatial).y -= 120;
			_smokePuffGroup.poofAt(genie,0.6);
			genie.get(Display).visible = true;
			genie.get(Display).moveToFront();
			super.addGenieWaveMotion(genie);
		}
		
		private function genieFlysAway():void
		{
			TweenUtils.entityTo(genie, Spatial, 3.0, {x:1790, y:700, ease:Back.easeIn, onComplete:idleGenie});
			CharUtils.setAnim(genie, Soar);
		}
		
		private function idleGenie():void
		{
			genieFleePoints = new Vector.<Point>();
			genieFleePoints.push(new Point(360, 500), new Point(1790,700) ,new Point(3568, 880));
			genieLocId = 0;
			
			if(shellApi.checkEvent(_events.USED_SPYGLASS)){
				genie.get(Display).visible = true;
				ToolTipCreator.addToEntity(genie);
				var inter:Interaction = InteractionCreator.addToEntity(genie,[InteractionCreator.CLICK]);
				var sceneInter:SceneInteraction = new SceneInteraction();
				sceneInter.reached.add(genieTaunt);
				genie.add(sceneInter);
				
				EntityUtils.position(genie, 1790, 700);
				CharUtils.setDirection(genie, false);
				var anims:Vector.<Class> = new Vector.<Class>();
				var delays:Vector.<Number> = new Vector.<Number>();
				anims.push(Laugh, Stand);
				delays.push(0, 50);
				setAnimSequence(genie, anims, delays, true);
			}
			if(!shellApi.checkEvent(_events.GENIE_IN_DESERT_SKY)){
				//_smokePuffGroup.poofAt(genie);
				genie.get(Display).visible = false;
			}
		}
		
		// gettig close to the genie makes him dodge
		private function genieTaunt(...p):void
		{
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new PanAction(genie));
			actions.addAction(new TalkAction(genie,"taunt"));
			actions.addAction(new PanAction(player));
			actions.addAction(new CallFunctionAction(genieDodge));
			if(!shellApi.checkHasItem(_events.GOLDEN_LAMP) && !shellApi.checkEvent(_events.LEARNED_JINNS_NAME)){
				actions.addAction(new TalkAction(player,"need_both"));
			}
			else if(shellApi.checkHasItem(_events.GOLDEN_LAMP) && !shellApi.checkEvent(_events.LEARNED_JINNS_NAME)){
				actions.addAction(new TalkAction(player,"need_name"));
			}
			else if(!shellApi.checkHasItem(_events.GOLDEN_LAMP) && shellApi.checkEvent(_events.LEARNED_JINNS_NAME)){
				actions.addAction(new TalkAction(player,"need_lamp"));
			}
			else if(shellApi.checkHasItem(_events.GOLDEN_LAMP) && shellApi.checkEvent(_events.LEARNED_JINNS_NAME)){
				actions.addAction(new TalkAction(player,"have_lamp_name"));
				actions.addAction(new CallFunctionAction(usedLamp));
			}
			actions.addAction(new PanAction(player));
			actions.execute();
		}
		
		private function usedLamp():void
		{
			// 	genieFleePoints.push(new Point(360, 500), new Point(1790,700) ,new Point(3568, 880));
			// make sure player has all genie trapping components
			if(shellApi.checkEvent(_events.GENIE_IN_DESERT_SKY) && shellApi.checkEvent(_events.USED_SPYGLASS))
			{
				if(shellApi.checkEvent(_events.LEARNED_JINNS_NAME))
				{
					if(CharUtils.hasSpecialAbility(player, MagicCarpet))
					{
						var target:Point = EntityUtils.getPosition(genie);
						if(0 == genieLocId){
							target.x += 130;
						}else if(1 == genieLocId){
							target.x -= 130;
						}else{
							target.x -= 130;
						}
						var actions:ActionChain = new ActionChain(this);
						
						actions.lockInput = true;
						
						actions.addAction(new SetSkinAction(player, SkinUtils.ITEM, "an3_lamp1"));
						actions.addAction(new MoveAction(player, target, new Point(110,110)));
						actions.addAction(new CallFunctionAction(Command.create(EntityUtils.position,player,target.x, target.y)));
						actions.addAction(new PanAction(genie));
						if(target){
							actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,true)));
						}else{
							actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,false)));
						}
						actions.addAction(new TalkAction(player,"ready"));
						actions.addAction(new TalkAction(genie,"wish"));
						actions.addAction(new CallFunctionAction(genieLeavesForAtrium));
						actions.addAction(new PanAction(player));
						actions.addAction(new WaitAction(2.0));
						
						actions.execute();
					}
					else{
						Dialog(player.get(Dialog)).sayById("up");	
					}
				}else{
					Dialog(player.get(Dialog)).sayById("need_name");
				}
			}
		}
		
		private function genieDodge():void
		{
			var speed:Number = 600;
			var target:Point;
			if(genieLocId >= genieFleePoints.length){
				genieLocId = 0;
				target = genieFleePoints[genieLocId];
			}else{	
				target = genieFleePoints[genieLocId];
				genieLocId++;
			}
			var spatial:Spatial = genie.get(Spatial);
			var time:Number = GeomUtils.dist(target.x,target.y, spatial.x, spatial.y) / speed;
			TweenUtils.entityTo( genie, Spatial, time, {x:target.x, y:target.y, ease:Back.easeIn});
			if(target.x < spatial.x){
				CharUtils.setDirection(genie, false);
			}else{
				CharUtils.setDirection(genie, true);
			}
		}
		
		private function genieLeavesForAtrium(...p):void
		{
			var speed:Number = 800;
			var target:Point = new Point(-100, 500);
			var spatial:Spatial = genie.get(Spatial);
			var time:Number = GeomUtils.dist(target.x,target.y, spatial.x, spatial.y) / speed;
			TweenUtils.entityTo( genie, Spatial, time, {x:target.x, y:target.y, ease:Back.easeIn, onComplete:Command.create(removeEntity,genie)});
			genie.add(new game.components.entity.Sleep(false, true));
			
			shellApi.completeEvent(_events.GENIE_IN_ATRIUM);
		}
		
		public static function setAnimSequence(entity:Entity, animations:Vector.<Class>, delays:Vector.<Number>, loop:Boolean = false):void
		{
			var animControl:AnimationControl = entity.get(AnimationControl);
			var animEntity:Entity = animControl.getEntityAt();
			var animSequencer:AnimationSequencer = animEntity.get(AnimationSequencer);
			
			if(!animSequencer)
			{
				animSequencer = new AnimationSequencer();
				animEntity.add(animSequencer);
			}
			var sequence:AnimationSequence = new AnimationSequence();
			for (var i:int = 0; i < animations.length; i++) 
			{
				sequence.add(new AnimationData(animations[i], delays[i]));
			}
			sequence.loop = loop;
			animSequencer.currentSequence = sequence;
			animSequencer.start = true;
		}
		
		private function setupIntro():void
		{
			oldman = getEntityById("old");
			enforcer = getEntityById("enforcer");
			
			if(!shellApi.checkEvent(_events.INTRO_COMPLETE)){
				setupIntroConv();
				SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,super.smokeReady));
				SceneUtil.addTimedEvent(this, new TimedEvent(2.0,1,showIntroPopup));
			}else{
				super.smokeReady();
			}
		}
		
		private function setupIntroConv():void
		{
			// sleep player
			CharUtils.setAnim(player,game.data.animation.entity.character.Sleep);
			CharUtils.setDirection(player, false);
			SceneUtil.lockInput(this, true);
			EntityUtils.position(player, 3630, 1400);
		}
		
		private function showIntroPopup():void
		{
			var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			introPopup.updateText("Capture the Genie!", "Start");
			introPopup.configData("introPopup.swf", "scenes/arab3/shared/");
			addChildGroup(introPopup);
			introPopup.removed.addOnce(introGo);
		}
		
		private function introGo(...p):void
		{
			SceneUtil.lockInput(this, true);
			
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			actions.addAction(new AnimationAction(player, Stand, "", 30));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player, false)));
			actions.addAction(new TalkAction(player, "what"));
			actions.addAction(new TalkAction(oldman, "goner"));
			actions.addAction(new TalkAction(player, "where"));
			actions.addAction(new TalkAction(oldman, "scattered"));
			actions.addAction(new TalkAction(player, "genie"));
			actions.addAction(new TalkAction(oldman, "sultan"));
			actions.addAction( new CallFunctionAction(Command.create(shellApi.completeEvent,_events.INTRO_COMPLETE)));
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,actions.execute));
		}
		
		
		private function checkSmashItem(itemEvent:String):void
		{
			var target:Point = EntityUtils.getPosition(enforcer);
			target.x += 100;
			var item:String;
			var product:String;
			switch(itemEvent)
			{
				case _events.USE_GEODE:
				{
					item = _events.GEODE;
					product = _events.CRYSTALS;
					break;
				}
				case _events.USE_MOONSTONE:
				{
					item = _events.MOONSTONE;
					product = _events.MOON_DUST;
					break;
				}
				case _events.USE_WISHBONE:
				{
					item = _events.WISHBONE;
					product = _events.BONE_MEAL;
					break;
				}
				default:
				{
					return;
				}
			}
			
			CharUtils.moveToTarget(player, target.x, target.y,false,Command.create(smashItem,item, product));
		}
		
		private function smashItem(junk:*, smashedID:String, recievedID:String):void
		{
			EntityUtils.removeAllWordBalloons(this, enforcer);
			EntityUtils.removeAllWordBalloons(this, player);
			SceneUtil.lockInput(this, true);
			CharUtils.setDirection(player, false);
			var actions:ActionChain = new ActionChain(this);
			actions.addAction(new TalkAction(player, "break"));
			actions.addAction(new TalkAction(enforcer, "useful"));
			actions.addAction(new WaitAction(0.4));
			actions.addAction(new CallFunctionAction(Command.create(take,smashedID,recievedID)));
			actions.execute();
		}	
		
		private function take(smashedID:String, recievedID:String):void
		{
			var itemGroup:ItemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			itemGroup.takeItem(smashedID, "enforcer","",null,Command.create(holdAndBreakItem,smashedID,recievedID));
			shellApi.removeItem(smashedID);
		}		
		
		private function holdAndBreakItem(hold:String, recieve:String):void
		{
			var actions:ActionChain = new ActionChain(this);
			actions.addAction(new SetSkinAction(enforcer,SkinUtils.ITEM,"an_"+hold,true,true));
			//actions.addAction(new AnimationAction(enforcer, Read)).noWait = true;
			//actions.addAction(new WaitAction(0.6));
			actions.addAction(new CallFunctionAction(Command.create(readStomp)));
			actions.addAction(new WaitAction(1.6));
			actions.addAction(new CallFunctionAction(Command.create(_smokeBombGroup.thiefAt,enforcer.get(Spatial), false, true)));
			actions.addAction(new AudioAction(enforcer, SHATTER_SOUND,600,1,1));		
			actions.addAction(new SetSkinAction(enforcer,SkinUtils.ITEM,"empty",true,true));
			actions.addAction(new WaitAction(0.9));	
			actions.addAction(new CallFunctionAction(Command.create(sitAgain)));
			actions.addAction(new WaitAction(1.0));
			if(shellApi.checkHasItem(recieve))
				actions.addAction(new CallFunctionAction(enforcerComment));
			else
				actions.addAction(new CallFunctionAction(Command.create(give,recieve)));
			actions.execute();
		}
		
		private function sitAgain():void
		{
			CharUtils.setAnim(enforcer, Sit);
			var rigAnim:RigAnimation = CharUtils.getRigAnim(enforcer, 1);
			if (rigAnim == null)
			{
				var slot:Entity = AnimationSlotCreator.create(enforcer);
				rigAnim = slot.get( RigAnimation ) as RigAnimation;
			}
			rigAnim.next = Sit;
			rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK);
		}
		
		private function readStomp(...p):void
		{
			CharUtils.setAnim(enforcer, Read);
			var rigAnim:RigAnimation = CharUtils.getRigAnim(enforcer, 1);
			if (rigAnim == null)
			{
				var slot:Entity = AnimationSlotCreator.create(enforcer);
				rigAnim = slot.get( RigAnimation ) as RigAnimation;
			}
			rigAnim.next = BigStomp;
			rigAnim.addParts( 	CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.FOOT_FRONT, CharUtils.FOOT_BACK,	CharUtils.BODY_JOINT, CharUtils.NECK_JOINT, CharUtils.LEG_BACK, CharUtils.LEG_FRONT );
		}
		
		private function give(recievedID:String):void
		{
			shellApi.getItem(recievedID,null,true,enforcerComment);
		}		
		
		private function enforcerComment(...p):void
		{
			Dialog(enforcer.get(Dialog)).sayById("else");
			SceneUtil.lockInput(this, false);
		}
	}
}