package game.scenes.prison.metalShop
{	
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.motion.ShakeMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.AnimationData;
	import game.data.animation.AnimationSequence;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Hammer;
	import game.data.animation.entity.character.PlacePitcher;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.scene.template.ItemGroup;
	import game.scenes.prison.PrisonScene;
	import game.scenes.prison.cellBlock.CellBlock;
	import game.scenes.prison.metalShop.particles.Cloud;
	import game.scenes.prison.metalShop.particles.Smoke;
	import game.scenes.prison.metalShop.popups.LicensePlateGame;
	import game.scenes.prison.shared.VentPuzzleGroup;
	import game.scenes.prison.shared.ventPuzzle.VentEnding;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.StopAudioAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MetalShop extends PrisonScene
	{
		private var finished_plates:int = 0; // one plate earns one gum, add as userfield?
		
		private var itemGroup:ItemGroup;
		
		private var pressMachine:Entity;
		private var grinder:Entity;
		private var drillBit:Entity;
		private var marion:Entity;
		private var guard:Entity;
		private var fakeDrillBit:Entity;
		private var machineEmitter:Entity;
		private var officeVent:Entity;
		private var ventSwitch:Entity;
		private var leak0:Entity;
		private var leak1:Entity;
		private var leak2:Entity;
		private var intakeVent:Entity;
		private var ventGroup:VentPuzzleGroup;
		private var desk:Entity;
		private var drillPress:Entity;
		
		private var used_plate_machine:Boolean; // at least one sucess happened	
		private var guard_distracted:Boolean; // guard distraction is overheated machine?
		private var grindingSpoon:Boolean;
		private var guard_blinded:Boolean;
		//private var inVentArea:Boolean; // player is in upper area, kill npcs and stuff from below
		private var used_bit:Boolean;
		
		public function MetalShop()
		{
			this.mergeFiles = true;
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/metalShop/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			switch(event)
			{
				case _events.SHOP_STEAM_REDIRECTED:
				{
					if(inVentArea()){
						ventsLinkedResponse();
					}
					break;
				}
				case "hasItem_" + _events.DRILL_BIT:
				{
					if(!inVentArea()){
						hideBitOnWall();
					}
					break;
				}
				case "use_" + _events.DRILL_BIT:
				{
					useDrillBit();
					break;
				}
				case "drill_plz":
				{
					if(shellApi.checkHasItem(_events.DRILL_BIT)){
						useDrillBit();
					}
					break;
				}
				case "use_" + _events.PAINTED_PASTA:
				{
					if(!inVentArea()){
						usePaintedPasta();
					}else{
						player.get(Dialog).sayById("cant_use_generic");
					}
					break;
				}
				case "use_" + _events.UNCOOKED_PASTA:
				{
					if(!inVentArea()){
						useUncookedPasta();
					}
					break;
				}
				case "use_" + _events.SPOON:
				{
					if(!inVentArea()){
						useSpoon();
					}else{
						player.get(Dialog).sayById("cant_use_generic");
					}
					break;
				}
				case "return_stuff":
				{
					turnInLicensePlates();
					break;
				}
				default:
				{
					super.eventTriggered(event,makeCurrent,init,removeEvent);
				}
			}
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			itemGroup  = getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			
			this.addSystem(new ShakeMotionSystem());
			
			used_plate_machine  = false;
			used_bit = false;
			
			setupVents();	
			
			setupFans();
			
			setupCharacters();
			
			setupIntro();
			
			setupMachines();
		}
		
		private function setupCharacters():void
		{
			if(!inVentArea()){
				marion = getEntityById("marion");
				if(shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE) && !shellApi.checkEvent(_events.DRILLED_PLATE)){
					startMarionDrilling();
				}else{
					Interaction(marion.get(Interaction)).click.add(clickMarion);
				}
				guard = getEntityById("guard");
				desk = EntityUtils.createSpatialEntity(this, _hitContainer["desk"]);
				putGuardInDesk();
				var sceneInter:SceneInteraction = guard.get(SceneInteraction);
				sceneInter.reached.removeAll();
				sceneInter.reached.add(talkToGuard);
				Display(desk.get(Display)).disableMouse();
			}else{
				removeEntity(getEntityById("marion"));
				removeEntity(getEntityById("guard"));
			}
		}
		
		private function clickMarion(...p):void
		{
			if(shellApi.checkHasItem(_events.DRILL_BIT) && !shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE)){
				SceneUtil.lockInput(this, true);
				Dialog(marion.get(Dialog)).complete.addOnce(unlock);
			}
		}
		
		private function talkToGuard(...p):void
		{
			// override dialog for guard, to manage weird event structure
			// pre day 1 states
			if(!shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE)){
				if(!shellApi.checkHasItem(_events.DRILL_BIT) && !shellApi.checkEvent(_events.BORROWED_TOOL)){
					// intro, first state
					Dialog(guard.get(Dialog)).sayById("guard_intro");
				}
				else{
					// intro, can't leave state
					Dialog(guard.get(Dialog)).sayById("guard_locked");
				}
			}
				// METAL_DAY_1_COMPLETE
			else {
				if(!shellApi.checkHasItem(_events.DRILL_BIT) && !used_bit){
					// get bit as normal
					Dialog(guard.get(Dialog)).sayById("guard_normal");
				}
				else{
					// allowed to leave
					Dialog(guard.get(Dialog)).sayById("guard_leave");
				}
			}
			
		}
		
		private function doDrill():void
		{
			// SOUND
			Command.callAfterDelay(Timeline(drillPress.get(Timeline)).gotoAndPlay,250,"loaded");
		}
		
		private function putGuardInDesk(...p):void
		{
			EntityUtils.position(guard, 2084, 1180);
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(guard),EntityUtils.getDisplayObject(desk),false);
			// hide legs
			SkinUtils.hideSkinParts(guard, [SkinUtils.FOOT1,SkinUtils.FOOT2, CharUtils.LEG_FRONT, CharUtils.LEG_BACK], true);
			CharUtils.stateDrivenOff(guard);
			guard.remove(Motion);
		}
		
		private function removeGuardFromDesk(...p):void
		{
			EntityUtils.position(guard, 2084, 1180);
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(guard),EntityUtils.getDisplayObject(desk),true);
			// hide legs
			SkinUtils.hideSkinParts(guard, [SkinUtils.FOOT1,SkinUtils.FOOT2, CharUtils.LEG_FRONT, CharUtils.LEG_BACK], false);
			CharUtils.stateDrivenOn(guard);
		}
		
		private function setupIntro():void
		{
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			var targ:Point;
			if(!inVentArea()){
				if(!shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE)){
					shellApi.removeItem(_events.DRILL_BIT);
					shellApi.removeEvent("gotItem_"+_events.DRILL_BIT);
					shellApi.removeEvent(_events.BORROWED_TOOL);
					
					targ = EntityUtils.getPosition(guard);
					targ.x += 120;
					
					actions.addAction(new MoveAction(player, targ, new Point(50,100)));
					actions.addAction(new SetDirectionAction(player,false));
					actions.addAction(new WaitAction(0.2));
					actions.addAction(new TalkAction(guard,"duty"));
					actions.addAction(new TalkAction(guard,"duty2"));
					actions.addAction(new WaitAction(0.3));
					targ = EntityUtils.getPosition(marion);
					targ.x += 120;
					actions.addAction(new MoveAction(player, targ, new Point(50,100)));
					actions.addAction(new SetDirectionAction(player,false));
					actions.addAction(new TalkAction(marion,"bad"));
					actions.addAction(new TalkAction(player,"bandit"));
					actions.addAction(new TalkAction(marion,"sure"));
					actions.addAction(new TalkAction(player,"proof"));
					actions.addAction(new TalkAction(marion,"files"));
					actions.addAction(new TalkAction(marion,"teach"));
				}
				else if(shellApi.checkEvent(_events.DRILLED_PLATE)){
					// last day, marion forces you to take prison files if you don't have them
					if(!shellApi.checkHasItem(_events.PRISON_FILES)){
						actions.addAction(new WaitAction(0.3));
						targ = EntityUtils.getPosition(marion);
						targ.x += 120;
						actions.addAction(new MoveAction(player, targ, new Point(50,100)));
						actions.addAction(new SetDirectionAction(player,false));
						actions.addAction(new SetDirectionAction(marion,true));
						actions.addAction(new TalkAction(marion,"escape"));
						actions.addAction(new TalkAction(player,"right"));
						actions.addAction(new TalkAction(marion,"help"));
						actions.addAction(new TalkAction(player,"all"));		
						actions.addAction(new CallFunctionAction(this.removePlayerGum,this.gumCount,"marion"));
						actions.addAction(new TalkAction(marion,"deal"));
						actions.addAction(new GetItemAction(_events.PRISON_FILES,true));
						actions.addAction(new TalkAction(marion,"luck"));
						actions.addAction(new CallFunctionAction(shellApi.loadScene,CellBlock));
					}
				}
			}
			actions.execute();
		}
		
		private function setupMachines():void
		{
			pressMachine = EntityUtils.createMovingTimelineEntity(this,_hitContainer["machine"]);
			grinder = EntityUtils.createMovingTimelineEntity(this, _hitContainer["grinder"]);
			drillPress = EntityUtils.createMovingTimelineEntity(this, _hitContainer["drillPress"]);
			
			
			// pressMachine: opens press popup
			var interation:Interaction = InteractionCreator.addToEntity(pressMachine, [InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.offsetY = 100;
			sceneInter.validCharStates = new <String>[CharacterState.STAND];
			sceneInter.reached.add(reachedLever);
			pressMachine.add(sceneInter);
			ToolTipCreator.addToEntity(pressMachine);
			
			// grinder
			interation = InteractionCreator.addToEntity(grinder, [InteractionCreator.CLICK]);
			sceneInter = new SceneInteraction();
			sceneInter.offsetY = 150;
			sceneInter.validCharStates = new <String>[CharacterState.STAND];
			sceneInter.reached.add(reachedGrinder);
			grinder.add(sceneInter);
			ToolTipCreator.addToEntity(grinder);
			
			// bit
			drillBit = EntityUtils.createSpatialEntity(this, _hitContainer["drillBit"]);
			fakeDrillBit = EntityUtils.createSpatialEntity(this, _hitContainer["fakeDrillBit"]);
			if(shellApi.checkHasItem(_events.DRILL_BIT)){
				hideBitOnWall();
			}
			
			if(shellApi.checkEvent(_events.SMUGGLED_DRILL_BIT)){
				interation = InteractionCreator.addToEntity(fakeDrillBit, [InteractionCreator.CLICK]);
				interation.click.add(reachedFakeDrillBit);
				ToolTipCreator.addToEntity(fakeDrillBit);
				hideBitOnWall();
				showFakeBitOnWall();
			}else{
				interation = InteractionCreator.addToEntity(drillBit, [InteractionCreator.CLICK]);
				interation.click.add(reachedDrillBit);
				ToolTipCreator.addToEntity(drillBit);
				hideFakeBitOnWall();
			}
			
			// steam vent stuff
			intakeVent = EntityUtils.createSpatialEntity(this, _hitContainer["intake"]);
			officeVent = EntityUtils.createSpatialEntity(this, _hitContainer["ventOffice"]);
			ventSwitch = EntityUtils.createMovingTimelineEntity(this, _hitContainer["ventSwitch"]);
			interation = InteractionCreator.addToEntity(ventSwitch, [InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity(ventSwitch);
			sceneInter = new SceneInteraction();
			sceneInter.validCharStates = new <String>[CharacterState.STAND];
			sceneInter.reached.add(buttonReached);
			ventSwitch.add(sceneInter);
			leak0 = EntityUtils.createSpatialEntity(this, _hitContainer["leak0"]);
			leak1 = EntityUtils.createSpatialEntity(this, _hitContainer["leak1"]);
			leak2 = EntityUtils.createSpatialEntity(this, _hitContainer["leak2"]);
		}
		
		private function buttonReached(...p):void
		{
			if(!guard_distracted){
				Dialog(guard.get(Dialog)).sayById("fan");
			}
		}
		
		private function reachedLever(...p):void
		{
			if(!used_plate_machine){
				if(shellApi.checkItemEvent(_events.DRILL_BIT) && shellApi.checkEvent(_events.BORROWED_TOOL)){
					var popup:LicensePlateGame = this.addChildGroup(new LicensePlateGame(overlayContainer, finished_plates)) as LicensePlateGame;
					popup.completeSignal.add(plateGameComplete);
				}else{
					Dialog(player.get(Dialog)).sayById("help_guy");
				}
			}else{
				Dialog(player.get(Dialog)).sayById("plates_finished");
			}
		}
		
		private function plateGameComplete(suceeded:Boolean = false, platesComplete:int = 0, endResult:String = null):void
		{
			this.finished_plates = platesComplete;
			if(platesComplete > 0){
				if(platesComplete >= 5){
					used_plate_machine = true;
				}
				shellApi.triggerEvent(_events.METAL_DAY_1_COMPLETE,true);
				if(endResult == "quotaMet"){
					Dialog(player.get(Dialog)).sayById("done_pressing");
				}
				else if(endResult == "timeOut"){
					Dialog(player.get(Dialog)).sayById("times_up");
				}
				else if(endResult == "overHeat"){
					// machine goes smokey, guard comes over
					overheatMachine();
				}
			}
			else if(!shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE)){
				Dialog(player.get(Dialog)).sayById("one_plate");
			}
		}
		
		private function overheatMachine():void
		{
			var actions:ActionChain = new ActionChain(this);
			
			actions.addAction(new CallFunctionAction(lock));
			actions.addAction(new MoveAction(player, new Point(400, 1200),new Point(50,150)));
			actions.addAction(new PanAction(pressMachine));
			actions.addAction(new CallFunctionAction(shakeAndSmoke));
			// SOUND
			actions.addAction(new AudioAction(pressMachine,SoundManager.EFFECTS_PATH+"gas_leak_01_loop.mp3",800, 0.0, 0.4, Linear.easeInOut,true));
			actions.addAction(new AudioAction(pressMachine,SoundManager.EFFECTS_PATH+"machinery_medium_shaking_01_loop.mp3",800, 0.1, 1.4, Linear.easeInOut, true));
			actions.addAction(new WaitAction(2.5));
			actions.addAction(new PanAction(guard));
			actions.addAction(new TalkAction(guard,"what"));
			actions.addAction(new CallFunctionAction(removeGuardFromDesk));
			actions.addAction(new MoveAction(guard,pressMachine));
			actions.addAction(new CallFunctionAction(Command.create(steamGuard)));
			actions.addAction(new AnimationAction(guard,Grief));
			actions.addAction(new WaitAction(0.3));
			actions.addAction(new TalkAction(guard,"junk"));
			actions.addAction(new WaitAction(0.3));
			actions.addAction(new CallFunctionAction(unlock));
			actions.addAction(new PanAction(player));
			// idles for a bit, is now distracted 
			actions.addAction(new SetDirectionAction(guard,false));
			actions.addAction(new AnimationAction(guard,Hammer)).noWait = true;
			// SOUND
			actions.addAction(new AudioAction(pressMachine,SoundManager.EFFECTS_PATH+"machine_impact_01.mp3",800, 0.4, 1.4, Linear.easeInOut,true));
			actions.addAction(new WaitAction(10.0));
			actions.addAction(new StopAudioAction(pressMachine, SoundManager.EFFECTS_PATH+"machinery_medium_shaking_01_loop.mp3"));
			actions.addAction(new StopAudioAction(pressMachine, SoundManager.EFFECTS_PATH+"machine_impact_01.mp3"));
			actions.addAction(new CallFunctionAction(guardReturns));
			
			actions.execute();
		}
		
		private function guardReturns(...p):void{
			if(!grindingSpoon){
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				
				actions.addAction(new PanAction(guard));
				actions.addAction(new CallFunctionAction(pressMachine.remove,ShakeMotion));
				actions.addAction(new SetSkinAction(guard,SkinUtils.ITEM,"empty")).noWait = true;
				actions.addAction(new SetSkinAction(guard,SkinUtils.ITEM2,"empty")).noWait = true;
				actions.addAction(new AnimationAction(guard,Stand)).noWait = true;
				actions.addAction(new TalkAction(guard,"steam"));
				actions.addAction(new MoveAction(guard,new Point(2084, 1180)));
				actions.addAction(new CallFunctionAction(putGuardInDesk));
				actions.addAction(new SetDirectionAction(guard,false));
				actions.addAction(new WaitAction(0.1));
				actions.addAction(new AnimationAction(guard,PointItem)).noWait = true;
				actions.addAction(new AudioAction(guard,SoundManager.EFFECTS_PATH +"switch_03.mp3",1000,1,1));
				actions.addAction(new SetSkinAction(guard,SkinUtils.MOUTH,"van"));
				actions.addAction(new WaitAction(0.9));
				actions.addAction(new CallFunctionAction(ventsOn));
				actions.addAction(new PanAction(pressMachine));
				actions.addAction(new WaitAction(0.2));
				actions.addAction(new CallFunctionAction(Command.create(activateVentSteam)));
				actions.addAction(new WaitAction(1.0));
				actions.addAction(new PanAction(guard));
				if(shellApi.checkEvent(_events.SHOP_STEAM_REDIRECTED)){	
					actions.addAction(new AudioAction(officeVent,SoundManager.EFFECTS_PATH+"gas_leak_01_loop.mp3",500, 0.0, 0.4, Linear.easeInOut,true));
					actions.addAction(new CallFunctionAction(steamGuard));
					actions.addAction(new AnimationAction(guard,Grief));
					actions.addAction(new TalkAction(guard,"see"));
				}else{
					actions.addAction(new AudioAction(leak1,SoundManager.EFFECTS_PATH+"gas_leak_01_loop.mp3",500, 0.0, 0.3, Linear.easeInOut,true));
					actions.addAction(new TalkAction(guard,"cool"));
					actions.addAction(new CallFunctionAction(unSteamGuard));
				}
				actions.addAction(new CallFunctionAction(putGuardInDesk));
				actions.addAction(new PanAction(player));
				actions.addAction(new CallFunctionAction(unDistractGuard));
				//SOUND
				actions.execute();
			}else{
				
			}
		}
		
		private function unDistractGuard():void
		{
			guard_distracted = false;
		}
		
		private function unSteamGuard():void
		{
			var glasses:Entity = SkinUtils.getSkinPartEntity(guard, SkinUtils.FACIAL);
			if(glasses){
				var tl:Timeline = glasses.get(Timeline);
				if(tl){
					tl.gotoAndStop("start");
				}
			}
		}
		
		private function steamGuard():void
		{
			guard_distracted = true;
			var glasses:Entity = SkinUtils.getSkinPartEntity(guard, SkinUtils.FACIAL);
			if(glasses){
				var tl:Timeline = glasses.get(Timeline);
				if(tl){
					tl.gotoAndPlay("fog");
				}
			}
		}
		
		private function shakeAndSmoke():void
		{
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-3, -3, 3, 3));
			shake.onInterval = 1.9;
			shake.offInterval = 1.75;
			shake.shaking = false;
			shake.active = true;
			pressMachine.add(shake);
			
			
			pressMachine.add(new SpatialAddition());
			
			// smoke particles
			var smokeEmitter:Smoke = new Smoke();
			smokeEmitter.init(16, 40, 0xE3E6E1);
			
			smokeEmitter.addInitializer( new Position( new DiscZone(new Point(0,0),60)));
			smokeEmitter.addInitializer( new Velocity( new LineZone( new Point( -100, -20), new Point( 100, -40 ) ) ) );
			
			//smokeEmitter.addAction( new DeathZone(new RectangleZone(332,890,474,1170),true));
			
			machineEmitter = EmitterCreator.create(this, hitContainer, smokeEmitter, 0, 0, pressMachine, "press", pressMachine.get(Spatial));
		}
		
		private function activateVentSteam():void
		{
			// pull steam into vent
			var machineSmoke:Smoke = Emitter(machineEmitter.get(Emitter)).emitter as Smoke;
			machineSmoke.addInitializer( new Velocity( new LineZone( new Point( -30, -130), new Point( 30, -150 ) ) ) );
			var ventSpatial:Spatial = intakeVent.get(Spatial);
			machineSmoke.addAction( new GravityWell(170,ventSpatial.x,ventSpatial.y,70));
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(intakeVent));
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(machineEmitter));
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(pressMachine));
			var outVent:Smoke;
			if(shellApi.checkEvent(_events.SHOP_STEAM_REDIRECTED)){
				// office vent blows steam
				outVent = new Smoke();
				outVent.init(18, 25, 0xE3E6E1);		
				outVent.addInitializer( new Velocity( new LineZone( new Point( -30, 130), new Point( 30, 150 ) ) ) );
				EmitterCreator.create(this, hitContainer, outVent, 0,0, officeVent, "v", officeVent.get(Spatial));
				var officeSteam:Cloud = new Cloud();
				officeSteam.init(20, 30, 0xE3E6E1, MovieClip(_hitContainer["officeaoe"]).getRect(_hitContainer));		
				EmitterCreator.create(this, hitContainer, officeSteam, 0, 0);
				guard_blinded = true;
				var glasses:Entity = SkinUtils.getSkinPartEntity(guard, SkinUtils.FACIAL);
				if(glasses){
					var tl:Timeline = glasses.get(Timeline);
					if(tl){
						tl.gotoAndPlay("fog");
					}
				}			
			}
			else{		
				// small leaks on other vent
				outVent = new Smoke();
				outVent.init(12, 6, 0xE3E6E1);		
				outVent.addInitializer( new Velocity( new LineZone( new Point( 40, -30), new Point( 60, 30 ) ) ) );
				EmitterCreator.create(this, hitContainer, outVent, 0, 0, leak0, "leak",leak0.get(Spatial));
				outVent = new Smoke();
				outVent.init(12, 6, 0xE3E6E1);		
				outVent.addInitializer( new Velocity( new LineZone( new Point( -60, 60), new Point( -40, 40 ) ) ) );
				EmitterCreator.create(this, hitContainer, outVent, 0, 0, leak1, "leak",leak1.get(Spatial));
				outVent = new Smoke();
				outVent.init(12, 6, 0xE3E6E1);		
				outVent.addInitializer( new Velocity( new LineZone( new Point( -40, -30), new Point( -60, 30 ) ) ) );
				EmitterCreator.create(this, hitContainer, outVent, 0, 0, leak2, "leak",leak2.get(Spatial));
			}
		}
		
		private function reachedGrinder(...p):void
		{
			trace("USE_GRINDER");
			// check for distraction
			if(guard_distracted){
				if(shellApi.checkHasItem(_events.SPOON) && !shellApi.checkItemEvent(_events.SHARPENED_SPOON)){
					grindSpoon();
				}
				else{
					Dialog(player.get(Dialog)).sayById("nothing_grind");	
				}
			}else{
				if(shellApi.checkHasItem(_events.SPOON)){
					guardBlockGrinder();
				}
				else{
					Dialog(player.get(Dialog)).sayById("nothing_grind");
				}
			}
		}
		
		private function useSpoon():void
		{
			// check for distraction
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new MoveAction(player,grinder,new Point(50, 100)));
			actions.addAction(new WaitAction(0.4));
			if(guard_distracted){
				actions.addAction(new CallFunctionAction(grindSpoon));
			}
			else{
				actions.addAction(new CallFunctionAction(guardBlockGrinder));
			}
			
			actions.execute();
		}
		
		private function guardBlockGrinder():void
		{
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new PanAction(guard));
			actions.addAction(new TalkAction(guard,"block_grinder"));
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new PanAction(player));
			actions.addAction(new TalkAction(player,"need_distraction"));
			
			actions.execute();
		}
		
		private function grindSpoon():void
		{							
			grindingSpoon = true;
			
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new RemoveItemAction(_events.SPOON,"grinder",true));
			actions.addAction(new WaitAction(0.4));
			actions.addAction(new SetSkinAction(player,"item", "pr_spoon"));
			actions.addAction(new AnimationAction(player,PlacePitcher,"trigger2",0,false));
			//actions.addAction(new AnimationAction(player, Salute, "raised", 0, false));
			actions.addAction(new CallFunctionAction(lockPlayerArms));
			actions.addAction(new AudioAction(grinder, SoundManager.EFFECTS_PATH +"grinder_loop_01.mp3",1000,1,1,null,true));
			actions.addAction(new TimelineAction(grinder,"still","ending",false)).noWait = true;
			actions.addAction(new WaitAction(4.0));
			actions.addAction(new AnimationAction(player,Stand,"",20)).noWait = true;
			actions.addAction(new CallFunctionAction(killGrindSound));
			actions.addAction(new WaitAction(0.1));
			actions.addAction(new GetItemAction(_events.SHARPENED_SPOON,true));
			actions.addAction(new SetSkinAction(player,"item","empty"));
			actions.addAction(new CallFunctionAction(doneGrind));
			
			actions.execute();
		}
		
		private function killGrindSound():void
		{
			Audio(grinder.get(Audio)).stopAll();
			Timeline(grinder.get(Timeline)).gotoAndStop("still");
			//add slowdown SOUND
		}
		
		private function doneGrind(...p):void
		{
			grindingSpoon = false
			if(guard_distracted){
				guardReturns();
			}
		}
		
		private function lockPlayerArms():void
		{
			Timeline(player.get(Timeline)).gotoAndStop("trigger2");
		}
		
		private function getSharpSpoon(...p):void
		{
			itemGroup.showAndGetItem(_events.SHARPENED_SPOON, null, unlock);
		}
		
		private function hideBitOnWall(...p):void
		{
			drillBit.get(Display).visible = false;
			ToolTipCreator.removeFromEntity(drillBit);
		}
		
		private function showBitOnWall(...p):void
		{
			drillBit.get(Display).visible = true;
			ToolTipCreator.addToEntity(drillBit);
		}
		
		private function hideFakeBitOnWall(...p):void
		{
			fakeDrillBit.get(Display).visible = false;
			ToolTipCreator.removeFromEntity(fakeDrillBit);
		}		
		
		private function showFakeBitOnWall(...p):void
		{
			// TODO: get fake bit art
			fakeDrillBit.get(Display).visible = true;
			ToolTipCreator.addToEntity(fakeDrillBit);
		}
		
		private function reachedDrillBit(...p):void
		{
			lock();
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("need_bit");
			dialog.complete.add(unlock);
		}
		
		private function reachedFakeDrillBit(...p):void
		{
			lock();
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("pasta");
			dialog.complete.add(unlock);
		}
		
		
		private function useDrillBit(...p):void
		{
			if(!inVentArea()){
				if(!guard_distracted && 300 > GeomUtils.spatialDistance(guard.get(Spatial),player.get(Spatial))){
					CharUtils.moveToTarget(player, guard.get(Spatial).x-110, guard.get(Spatial).y+70, false, Command.create(giveGuardItem, _events.DRILL_BIT),new Point(50,100));
				}
				else if(!shellApi.checkEvent(_events.METAL_DAY_1_COMPLETE)){
					var targ:Point = EntityUtils.getPosition(marion);
					targ.x += 120;
					var actions:ActionChain =  new ActionChain(this);
					actions.lockInput = true;
					actions.addAction(new MoveAction(player,targ,new Point(40,100),NaN,true));
					actions.addAction(new SetDirectionAction(player, false));
					actions.addAction(new RemoveItemAction(_events.DRILL_BIT,"marion",true));
					actions.addAction(new TalkAction(marion,"thanks"));		
					actions.addAction(new SetDirectionAction(marion,false));
					actions.addAction(new AnimationAction(marion, Score));
					actions.addAction(new TimelineAction(drillPress,"loaded","loaded"));
					actions.addAction(new SetDirectionAction(marion,true));
					actions.addAction(new TalkAction(marion,"pay"));
					actions.addAction(new WaitAction(0.8));
					actions.addAction(new SetDirectionAction(marion,false));
					actions.addAction(new CallFunctionAction(startMarionDrilling));
					actions.addAction(new WaitAction(0.5));
					actions.addAction(new MoveAction(player,pressMachine,new Point(50,100),NaN,true));
					actions.addAction(new CallFunctionAction(reachedLever));
					
					actions.execute();
					used_bit = true;
				}
				else if(shellApi.checkEvent(_events.SMUGGLED_DRILL_BIT)){
					Dialog(player.get(Dialog)).sayById("has_bit");
				}
				else{
					Dialog(player.get(Dialog)).sayById("need_bit");
				}
			}
		}
		
		private function usePaintedPasta(...p):void
		{
			if(!guard_distracted){
				if(shellApi.checkHasItem(_events.DRILL_BIT)){
					CharUtils.moveToTarget(player, guard.get(Spatial).x-110, guard.get(Spatial).y+70, false, Command.create(giveGuardItem, _events.PAINTED_PASTA),new Point(50,100));
				}
				else{
					Dialog(player.get(Dialog)).sayById("paint");
				}
			}
		}
		
		private function useUncookedPasta(...p):void
		{
			if(!guard_distracted){
				if(shellApi.checkHasItem(_events.DRILL_BIT)){	
					CharUtils.moveToTarget(player, guard.get(Spatial).x-110, guard.get(Spatial).y+70, false, Command.create(giveGuardItem, _events.UNCOOKED_PASTA),new Point(50,100));
				}
				else{
					Dialog(player.get(Dialog)).sayById("paint");
				}
			}
		}
		
		private function giveGuardItem(junkmail:*, item:String):void
		{
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new SetSpatialAction(player, new Point(guard.get(Spatial).x-105, guard.get(Spatial).y+70)));
			actions.addAction(new SetDirectionAction(player,true));
			actions.addAction(new TalkAction(guard,"bit2"));
			switch(item)
			{
				case _events.DRILL_BIT:
				{
					actions.addAction(new RemoveItemAction(_events.DRILL_BIT,"guard",true,true));
					if(guard_blinded){
						actions.addAction(new TalkAction(guard,"bit_sneak"));
					}
					actions.addAction(new CallFunctionAction(showBitOnWall));
					break;
				}
				case _events.PAINTED_PASTA:
				{
					if(guard_blinded){
						actions.addAction(new RemoveItemAction(_events.PAINTED_PASTA,"guard",true,true));
						actions.addAction(new TalkAction(guard,"bit_sneak"));
						actions.addAction(new TriggerEventAction(_events.SMUGGLED_DRILL_BIT,true));
						actions.addAction(new CallFunctionAction(showFakeBitOnWall));
					}
					else{	
						actions.addAction(new RemoveItemAction(_events.PAINTED_PASTA,"guard",true,false));
						actions.addAction(new TalkAction(guard,"crude_bit"));
						actions.addAction(new RemoveItemAction(_events.DRILL_BIT,"guard",true,true));
						actions.addAction(new CallFunctionAction(showBitOnWall));
					}
					break;
				}
				case _events.UNCOOKED_PASTA:
				{
					actions.addAction(new RemoveItemAction(_events.UNCOOKED_PASTA,"guard",true,false));
					actions.addAction(new TalkAction(guard,"raw_bit"));
					actions.addAction(new RemoveItemAction(_events.DRILL_BIT,"guard",true,true));
					actions.addAction(new CallFunctionAction(showBitOnWall));
					break;
				}
			}
			
			actions.execute();
		}
		
		private function startMarionDrilling():void
		{
			CharUtils.setDirection(marion,false);
			// animaiton sequence
			var sequence:AnimationSequence = new AnimationSequence();
			sequence.add( new AnimationData( Score) );
			sequence.add( new AnimationData( Stand, 110 ) );
			sequence.loop = true;
			sequence.random = false;
			
			var animControl:AnimationControl = marion.get(AnimationControl);
			var animEntity:Entity = animControl.getEntityAt();
			var animSequencer:AnimationSequencer = animEntity.get(AnimationSequencer);
			
			if(animSequencer == null)
			{
				animSequencer = new AnimationSequencer();
				animEntity.add(animSequencer);
			}
			
			animSequencer.currentSequence = sequence;
			animSequencer.start = true;
			
			Timeline(marion.get(Timeline)).handleLabel("score",doDrill,false);
		}
		
		// give back plates and bit
		private function turnInLicensePlates():void
		{
			var actions:ActionChain =  new ActionChain(this);
			actions.lockInput = true;
			actions.addAction(new CallFunctionAction(correctGumDialog));
			// check drill bit
			if(shellApi.checkHasItem(_events.DRILL_BIT) && !shellApi.checkEvent(_events.SMUGGLED_DRILL_BIT)){
				actions.addAction(new TalkAction(guard,"bit"));
				actions.addAction(new RemoveItemAction(_events.DRILL_BIT,"guard",true,true));
				if(guard_blinded){
					actions.addAction(new TalkAction(guard,"bit_sneak"));
				}
			}
			if(finished_plates > 0){
				actions.addAction(new WaitAction(0.3));
				actions.addAction(new TalkAction(guard,"gum"));
				actions.addAction(new CallFunctionAction(this.givePlayerGum, finished_plates));
			}
			actions.addAction(new CallFunctionAction(clearLicensePlateField));
			actions.addAction(new WaitAction(0.2));
			//actions.addAction(new CallFunctionAction(shellApi.removeEvent,_events.BORROWED_TOOL));
			actions.addAction(new CallFunctionAction(super.openSchedule,this));
			
			actions.execute();
		}
		
		private function clearLicensePlateField():void
		{
			finished_plates = 0;
			correctGumDialog();
		}
		
		// insert plates produced number into dialog
		private function correctGumDialog():void
		{
			//TODO: create exchange rate for gum to plate count, display/save that instead
			var dialog:Dialog = guard.get(Dialog);
			var allDialog:Dictionary = dialog.allDialog;
			var newString:String = allDialog["gum"].dialog;
			allDialog["gum"].dialog = newString.replace("[x]",finished_plates.toString());
			newString = allDialog["gum2"].dialog;
			allDialog["gum2"].dialog = newString.replace("[x]",finished_plates.toString());
		}	
		
		private function inVentArea():Boolean
		{
			var result:Boolean = false;
			if(550 > EntityUtils.getPosition(player).y){
				result = true;
				shellApi.triggerEvent("in_the_roof");
			}
			else{
				result = false;
				shellApi.triggerEvent("in_the_hall");
			}
			return result;
		}
		
		
		private function setupVents():void
		{
			inVentArea();
			// init each vent's available connections
			var flapLinkMap:Array = [
				["flap6", null, "flap14", "flap1"],//flap0
				[ "flap13", "flap0", "flap7", null],//flap1
				["flap3", "flap13", "flap8", "end"],//flap2
				["flap4", "flap5", "flap2", null],//flap3
				["flap9", null, "flap3", "start"],//flap4
				["flap10", "flap11", "flap12", "flap3"],//flap5
				["flap11", null, "flap0", "flap12"],//flap6
				["flap1", "flap14", null, "flap8"],//flap7
				["flap2", "flap7", null, "end"],//flap8
				[null, "flap10", "flap4", null],//flap9
				[null, null, "flap5", "flap9"],//flap10
				[null, null, "flap6", "flap5"],//flap11
				["flap5", "flap6", null, null],//flap12
				[null, null, "flap1", "flap2"],//flap13
				["flap0", null, null, "flap7"]//flap014
			];
			//similar to pipe game from atlantis 2
			ventGroup = VentPuzzleGroup(this.addChildGroup(new VentPuzzleGroup(_hitContainer, flapLinkMap,"flap4",
				[new VentEnding("flap8",_events.SHOP_STEAM_REDIRECTED),
					new VentEnding("flap2",_events.SHOP_STEAM_REDIRECTED,true)],
				_events.VENTS_FIELD_METAL, new RectangleZone(144,108,2100,580))));
			ventGroup.ventsReady.addOnce(ventsLoaded);
		}
		
		private function ventsLoaded():void
		{
			if(shellApi.checkEvent(_events.SHOP_STEAM_REDIRECTED)){
				var outVent:Smoke = new Smoke();
				outVent.init(7, 1, 0xffffff);		
				outVent.addInitializer( new Velocity( new LineZone( new Point( -30, 130), new Point( 30, 150 ) ) ) );
				EmitterCreator.create(this, hitContainer, outVent, 0,0, officeVent, "v1", officeVent.get(Spatial));
			}
		}
		
		private function ventsLinkedResponse():void
		{
			Dialog(player.get(Dialog)).sayById("vents");
			var outVent:Smoke = new Smoke();
			outVent.init(7, 1, 0xffffff);		
			outVent.addInitializer( new Velocity( new LineZone( new Point( -30, 130), new Point( 30, 150 ) ) ) );
			EmitterCreator.create(this, hitContainer, outVent, 0,0, officeVent, "v1", officeVent.get(Spatial));
		}
		
		private function setupFans():void
		{
			for(var i:int = 0; i < 5; i++)
			{
				var clip:MovieClip = this._hitContainer.getChildByName("fan" + i) as MovieClip;
				
				clip = clip.getChildByName("fan_blades") as MovieClip;
				
				var entity:Entity = EntityUtils.createMovingEntity(this, clip);
				entity.add(new Id("fan"+i));
				
				var motion:Motion = entity.get(Motion);
				motion.rotationFriction = 50;
				motion.rotationMaxVelocity = 400;
				trace("FAN"+i)
			}
		}
		
		private function ventsOn(...p):void
		{
			Timeline(ventSwitch.get(Timeline)).gotoAndStop("on");
			for(var i:int = 0; i < 5; i++)
			{
				var fan:Entity = this.getEntityById("fan" + i);
				var motion:Motion = fan.get(Motion);
				motion.rotationAcceleration = 200;
			}
			AudioUtils.playSoundFromEntity(intakeVent, SoundManager.EFFECTS_PATH+"vent_fan_01_loop.mp3",500,0,1.0,null,true);
		}
		
		private function lock(...p):void
		{
			SceneUtil.lockInput(this, true);
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false);
		}
		
	}
}
