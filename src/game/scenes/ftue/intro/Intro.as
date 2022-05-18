package game.scenes.ftue.intro
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Linear;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.FollowTarget;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Fall;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Throw;
	import game.data.animation.entity.character.Tremble;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.data.ui.GestureData;
	import game.data.ui.ToolTipType;
	import game.scenes.ftue.AceRaceScene;
	import game.scenes.ftue.beach.Beach;
	import game.scenes.hub.town.Town;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.costumizer.Costumizer;
	import game.ui.hud.Hud;
	import game.ui.tutorial.TutorialGroup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	import game.systems.actionChain.actions.TweenAction;
	
	public class Intro extends AceRaceScene
	{
		private var timedEvent:TimedEvent;
		
		public function Intro()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/ftue/intro/";
			
			super.init(container);
		}
		
		override public function destroy():void
		{
			timedEvent = null;
			super.destroy();
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
			_charGroup.removeFSM(player);
			_charGroup.removeCollliders(player);
			
			// hide menu only for CMG
			if (shellApi.cmg_iframe)
			{
				var hud:Hud = Hud(this.getGroupById(Hud.GROUP_ID));
				hud.showHudButton(false);
			}
			
			if(shellApi.checkEvent(ftue.RACE_ENTERED))
			{
				gotoRace();
			}
			else
			{
				intro();
			}
		}
		
		override protected function setupEntities():void
		{
			super.setupEntities();
			
			_airplane = EntityUtils.createMovingEntity(this, _hitContainer["airplane_p"], _hitContainer);
			MotionUtils.addWaveMotion(_airplane, new WaveMotionData("y", 15, 0.02, "sin", 1), this);
			MotionUtils.addWaveMotion(_airplane, new WaveMotionData("x", 14, 0.008, "sin", 1), this);
			TimelineUtils.convertClip(_hitContainer["airplane_p"]["prop"], this, null, null, true, 60);
			
			_airplane6 = EntityUtils.createMovingEntity(this, _hitContainer["airplane_6"], _hitContainer);
			MotionUtils.addWaveMotion(_airplane6, new WaveMotionData("y", 15, 0.02, "sin", Math.random()), this);
			MotionUtils.addWaveMotion(_airplane6, new WaveMotionData("x", 25, 0.014, "sin", Math.random()), this);
			_carpet = TimelineUtils.convertClip(_hitContainer["airplane_6"]["carpet"], this);
			
			// optimize
			convertContainer(Display(_airplane.get(Display)).displayObject);
			convertContainer(Display(_airplane6.get(Display)).displayObject);
			
			_pilot = characterInPlane(this.getEntityById("pilot"), _airplane, "pilot", "right", new Spatial(-188, 0));
			
			characterInPlane(this.player, _airplane, "player", "right", new Spatial(40, 0));
			
			_medallion = TimelineUtils.convertClip(_hitContainer["balloon"]["medallion"], this);
			_flags = TimelineUtils.convertClip(_hitContainer["balloon"]["flags"], this);
			
			// hide other aircraft
			Display(_airplane1.get(Display)).visible = false;
			Display(_airplane2.get(Display)).visible = false;
			Display(_airplane3.get(Display)).visible = false;
			Display(_airplane4.get(Display)).visible = false;
			Display(_airplane5.get(Display)).visible = false;
			Display(_airplane6.get(Display)).visible = false;
			
			// other pilots
			_pirate = characterInBGPlane(this.getEntityById("pirate"), _airplane2, true, new Spatial(268, 240));
			_stylishGirl = characterInBGPlane(this.getEntityById("stylishGirl"), _airplane3, true, new Spatial(-10, 350));
			//_cat = characterInBGPlane(this.getEntityById("cat"), _airplane3, true, new Spatial(15, 355), 0.25);
			_carpetRider = characterInBGPlane(this.getEntityById("carpetRider"), _airplane6, true, new Spatial(0, -34), 0.30);
			//MotionUtils.addWaveMotion(_carpetRider, new WaveMotionData("y", 9, 0.4, "sin", 0.5), this);
			
			// change cursor to target
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;  // change default cursor
			
			EntityUtils.removeInteraction(_pilot);
			
			// freeze player controls
			shellApi.player.remove(CharacterMovement);
			
			_pilot.get(Dialog).replaceKeyword("[Player Name]", shellApi.profileManager.active.avatarName);
		}
		
		override protected function initAnimations():void{
			_charGroup.preloadAnimations(new <Class>[
				Grief,
				Laugh,
				Sit,
				Stand,
				Throw,
				Tremble
			], this);
		}
		
		override protected function initSounds():void
		{
			AudioUtils.play(this, PROP_SOUND, 1, true);
		}
		
		override public function onEventTriggered(event:String=null, makeCurrent:Boolean=false, init:Boolean=false, removeEvent:String=null):void
		{
			switch(event){
				case "intro2":
					Dialog(shellApi.player.get(Dialog)).sayById("intro2");
					break;
				case "intro3":
					Dialog(_pilot.get(Dialog)).sayById("intro3");
					break;
				case "intro4":
					Dialog(shellApi.player.get(Dialog)).sayById("intro4");
					break;
				case "intro5":
					Dialog(_officiate.get(Dialog)).sayById("intro5");
					break;
				
				case "enterRace":
					enterRace();
					break;
				case "ask_where_are_we":
					Dialog(_pilot.get(Dialog)).sayById("question");
					break;
				case "showCostumize":
					Dialog(_pilot.get(Dialog)).sayById("costumize");
					break;
				case "showHowToCostumize":
					showHowToCostumize();
					break;
				case "costumized":
					Dialog(_officiate.get(Dialog)).sayById("raceReady");
					break;
				case "race_enter":
					var saveBtn:Entity = (super.getGroupById( Hud.GROUP_ID ) as Hud).getButtonById( Hud.SAVE );
					gotoRace();
					break;
				case ftue.LEAVE_TUTORIAL_CANCEL:
					Dialog(_officiate.get(Dialog)).sayById("raceReady");
					break;
				case "race_start":
					startRace();
					break;
				case "leave_tutorial":
					skipTutorial();
					break;
				
				case ftue.SHOW_SAVE_TUTORIAL:
					showSaveTutorial();
					break;
				case ftue.SKIPPED_SAVE_TUTORIAL:
					gotoRace();
					break;
			}
		}
		
		private function showSaveTutorial():void
		{
			tutorial = new TutorialGroup(overlayContainer);
			this.addChildGroup(tutorial);
			
			var saveBtn:Entity = (super.getGroupById( Hud.GROUP_ID ) as Hud).getButtonById( Hud.SAVE );	
			var saveBtnSpatial:Spatial = saveBtn.get(Spatial);
			var stepDatas:Vector.<StepData> = new Vector.<StepData>();
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(saveBtnSpatial.x, saveBtnSpatial.y+super.shellApi.viewportHeight-20), 70, 70, null, null, null, saveBtn.get(Interaction), null));
			texts.push(new TextData("Click the save button to create a username and password.", "tutorialwhite", new Point(shellApi.viewportWidth - 500, saveBtnSpatial.y + super.shellApi.viewportHeight - 80),350));
			var clickHud:StepData = new StepData("save", TUTORIAL_ALPHA, 0x000000, 1.5, true, shapes, texts, null, null);
			tutorial.addStep(clickHud);	
			tutorial.complete.addOnce(saveTutorialCanceled);
			tutorial.start();
		}
		
		private function saveTutorialCanceled(group:DisplayGroup):void
		{
			gotoRace();
		}
		
		public function skipTutorial():void
		{
			var introPopup:TutorialPopup = new TutorialPopup(overlayContainer);
			introPopup.buttonClicked.addOnce(gotoMap);
			addChildGroup(introPopup);
		}
		
		private function gotoMap(confirm:Boolean):void
		{
			if(confirm)
			{
				// load map
				shellApi.completeEvent(ftue.LEAVE_TUTORIAL_CONFIRM);
				shellApi.track(ftue.LEAVE_TUTORIAL_CONFIRM);
				shellApi.loadScene(Town);
			} 
			else 
			{
				Dialog(player.get(Dialog)).sayById("changeMind");
			}
		}
		
		private function dontShowTutorial(...args):void
		{
			timedEvent.stop();
			timedEvent.signal.removeAll();
		}
		
		private function showHowToUseDialog():void
		{
			var stepDatas:Vector.<StepData> = new Vector.<StepData>();
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			var gestures:Vector.<GestureData> = new Vector.<GestureData>();
			
			var bubbles:Vector.<Entity> = Children(player.get(Children)).children;			
			var bubble:Entity = bubbles[bubbles.length -1];			
			var spatial:Spatial = bubble.get(Spatial);
			var offset:SpatialOffset = bubble.get(SpatialOffset);			
			
			var rect:Rectangle = EntityUtils.getDisplayObject(bubble).getRect(overlayContainer);
			rect.bottom -= 25;
			
			gestures.push(new GestureData(GestureData.MOVE_THEN_CLICK,rect.topLeft.add(new Point(rect.width/2, rect.height/2)),null,-1,2));
			shapes.push(new ShapeData(ShapeData.RECTANGLE, rect.topLeft, rect.width, rect.height));
			texts.push(new TextData("Press on a bubble to respond.", "tutorialwhite", new Point(rect.right + 10, rect.top),shellApi.viewportWidth / 4));
			var clickHud:StepData = new StepData("dialog", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts,null,gestures);
			
			tutorial.addStep(clickHud);
			tutorial.complete.addOnce(Command.create(tutorialFinished, bubble));
			tutorial.start();
		}
		
		private function showHowToCostumize():void
		{
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;
			var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
			
			var stepDatas:Vector.<StepData> = new Vector.<StepData>();
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			
			var hudButton:Entity = hud.getButtonById(Hud.HUD);
			var hudButtonSpatial:Spatial = hudButton.get(Spatial);
			
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(hudButtonSpatial.x, hudButtonSpatial.y), 60, 60, "backpack", null, null, hudButton.get(Interaction)));
			texts.push(new TextData("First, open your menu.", "tutorialwhite", new Point(shellApi.viewportWidth - 350, 10),240));
			var clickHud:StepData = new StepData("hud", TUTORIAL_ALPHA, 0x000000, 1.5, true, shapes, texts);
			tutorial.addStep(clickHud);
			
			shapes = new Vector.<ShapeData>();
			texts = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(shellApi.viewportWidth - 196, 45), 36, 36, "npc", null, costumizeOpened, null, hud.openingHudElement));
			texts.push(new TextData("Now, click on the shirt.", "tutorialwhite", new Point(shellApi.viewportWidth - 310, 100),240));
			var clickInventory:StepData = new StepData("backpack", TUTORIAL_ALPHA, 0x000000, 2, true, shapes, texts);
			tutorial.addStep(clickInventory);
			tutorial.start();			
		}
		
		private function costumizeOpened():void{
			var costumizer:Costumizer = getGroupById(Costumizer.GROUP_ID) as Costumizer;
			var costumeNPC:Entity = getEntityById("pilot");
			var costumeUILoc:Point = DisplayUtils.localToLocal(costumeNPC.get(Display).displayObject, overlayContainer);
			costumeUILoc.x -= 52;
			costumeUILoc.y -= 105;
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.RECTANGLE, costumeUILoc, 115, 155, "accept", null, null, null, costumizer.onNPCSelected));
			texts.push(new TextData("Click on me to copy part of my outfit.", "tutorialwhite", new Point(200*shellApi.viewportWidth/960, 420*shellApi.viewportHeight/640)));
			var clickLady:StepData = new StepData("npc", TUTORIAL_ALPHA, 0x000000, 3, true, shapes, texts);
			tutorial.addStep(clickLady);
			
			costumizer.ready.addOnce(costumizerReady);
		}
		
		private function costumizerReady(group:Group):void
		{	
			var costumizer:Costumizer = group as Costumizer;
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.RECTANGLE, new Point(120, 120), shellApi.viewportWidth - 240, shellApi.viewportHeight - 240, "accept", "partTray",null/* Command.create(partClicked, costumizer)*/,null,new Signal()));//,costumizer.onNPCPartSelected));
			texts.push(new TextData("Click on the parts you want to try.", "tutorialwhite", new Point(shellApi.viewportWidth*.5 -325, shellApi.viewportHeight - 100)));
			
			var acceptSpatial:Spatial = costumizer.acceptButton.get(Spatial);
			var cancelSpatial:Spatial = costumizer.cancelButton.get(Spatial);
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(acceptSpatial.x, acceptSpatial.y), 50, 50, null,  null, null, costumizer.acceptButton.get(Interaction)));
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(cancelSpatial.x, cancelSpatial.y), 50, 50, null,  null, null, costumizer.cancelButton.get(Interaction)));
			texts.push(new TextData("Click check to keep changes.", "tutorialwhite", new Point(acceptSpatial.x - 300, 25),250));
			texts.push(new TextData("Click X to cancel changes.", "tutorialwhite", new Point(cancelSpatial.x -300, 25),250));
			var accept:StepData = new StepData("accept", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts);
			tutorial.addStep(accept);
			
			tutorial.complete.addOnce(tutorialFinished);
		}
		
		private function tutorialFinished(group:DisplayGroup, dialogBubble:Entity = null):void
		{
			if(dialogBubble)
			{
				dialogBubble.sleeping = false;
				dialogBubble.sleeping = false;
				Interaction(dialogBubble.get(Interaction)).downHandler(null);
			} 
			else 
			{
				shellApi.completeEvent(ftue.COMPLETE_COSTUMIZE_TUT);
				shellApi.track(ftue.COMPLETE_COSTUMIZE_TUT);
				
				if(SkinUtils.getSkinPart(player, SkinUtils.SHIRT).value == "home_crash")
				{
					Dialog(_pilot.get(Dialog)).sayById("costumized");
				} 
				else 
				{
					Dialog(_officiate.get(Dialog)).sayById("raceReady");
				}
			}
		}
		
		private function intro():void
		{
			SceneUtil.lockInput(this);
			
			shellApi.completeEvent(ftue.ARRIVED_IN_PLANE);
			shellApi.track(ftue.ARRIVED_IN_PLANE);
			
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new CallFunctionAction( playerInPlane) );
			actChain.addAction( new CallFunctionAction( enterAmelia ) );
			if (super.titleClip != null)
			{
				actChain.addAction( new WaitAction(0.5) );
				var tween:TweenMax = new TweenMax(super.titleClip, 0.5, {alpha:1});
				actChain.addAction( new TweenAction(tween));
			}
			actChain.addAction( new WaitAction(2) );
			if (super.titleClip != null)
			{
				tween = new TweenMax(super.titleClip, 0.25, {alpha:0});
				actChain.addAction( new TweenAction(tween));
			}
			actChain.addAction( new TalkAction(_pilot, "intro1") );
			actChain.addAction( new CallFunctionAction( askQuestion ) );
			
			actChain.execute();
		}
		
		private function enterAmelia():void
		{
			TweenUtils.entityTo(_airplane, Spatial, 3, {x:shellApi.viewportWidth / 2 + 110, y:shellApi.viewportHeight / 2, ease:Cubic.easeOut});	
		}
		
		private function enterPlayer():void
		{
			// player falls into plane from above
			CharUtils.setDirection(player, true);
			CharUtils.setAnim(player, Fall);
			
			var pSpatial:Spatial = player.get(Spatial);
			var tSpatial:Spatial = _airplane.get(Spatial);
			
			pSpatial.x = tSpatial.x - 110;
			pSpatial.y = -100;
			
			TweenUtils.entityTo(player, Spatial, 1.4, {y:tSpatial.y, onComplete:playerInPlane, ease:Cubic.easeIn});
		}
		
		private function playerInPlane():void
		{
			characterInPlane(player, _airplane, "player", "right", new Spatial(-122, 0));
			
			CharUtils.setAnim(player, Stand);
			CharUtils.setDirection(player, true);
			
			MotionUtils.zeroMotion(player);
		}
		
		private function askQuestion():void
		{
			SceneUtil.lockInput(this, false);
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;  // change default cursor
			
			Dialog(player.get(Dialog)).start.addOnce(dontShowTutorial);
			if(timedEvent == null)
				timedEvent = SceneUtil.delay(this, 5, showHowToUseDialog);
			
			Dialog(_pilot.get(Dialog)).start.add(speedUp);
			Dialog(_pilot.get(Dialog)).sayById("question");
		}
		
		private function showHUD():void
		{
			_hud.show();
		}
		
		private function askHow():void
		{
			SceneUtil.lockInput(this, false);
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;  // change default cursor
			Dialog(_pilot.get(Dialog)).start.add(speedUp);
			Dialog(_pilot.get(Dialog)).sayById("showHow");
		}
		
		private function gotoRace():void
		{
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new CallFunctionAction( playerInPlane ) );
			actChain.addAction( new CallFunctionAction( enterAmelia ) );
			actChain.addAction( new CallFunctionAction( enterRace ) );
			actChain.addAction( new WaitAction(3) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new CallFunctionAction( enterOfficiate ) );			
			actChain.execute();
		}
		
		private function speedUp(data:DialogData):void
		{
			if(data.id == "letsgo")
			{
				AudioUtils.play(this, SPEED_UP);
				SceneUtil.lockInput(this);
				TweenUtils.entityTo(_airplane, Spatial, 3, {x:Spatial(_airplane.get(Spatial)).x + 150, ease:Cubic.easeInOut});
				Dialog(_pilot.get(Dialog)).start.remove(speedUp);
			}
		}
		
		public function enterRace():void
		{
			Display(_airplane1.get(Display)).visible = true;
			Display(_airplane2.get(Display)).visible = true;
			Display(_airplane3.get(Display)).visible = true;
			Display(_airplane4.get(Display)).visible = true;
			Display(_airplane5.get(Display)).visible = true;
			Display(_airplane6.get(Display)).visible = true;
			
			TweenUtils.entityTo(_airplane6, Spatial, 11, {x:Spatial(_airplane6.get(Spatial)).x - 2000, ease:Cubic.easeOut});
			TweenUtils.entityTo(_airplane1, Spatial, 11, {x:Spatial(_airplane1.get(Spatial)).x - 2000, ease:Cubic.easeOut});
			TweenUtils.entityTo(_airplane2, Spatial, 11, {x:Spatial(_airplane2.get(Spatial)).x - 2100, ease:Cubic.easeOut});
			TweenUtils.entityTo(_airplane3, Spatial, 11, {x:Spatial(_airplane3.get(Spatial)).x - 2100, ease:Cubic.easeOut});
			TweenUtils.entityTo(_airplane4, Spatial, 11, {x:Spatial(_airplane4.get(Spatial)).x - 2000, ease:Cubic.easeOut});
			TweenUtils.entityTo(_airplane5, Spatial, 11, {x:Spatial(_airplane5.get(Spatial)).x - 2000, ease:Cubic.easeOut});
		}
		
		private function enterOfficiate():void
		{
			// remove airplanes/pilots not visible
			this.removeEntity(_airplane1);
			this.removeEntity(_airplane4);
			this.removeEntity(_airplane5);
			
			Display(_balloon.get(Display)).visible = true;
			Display(_officiate.get(Display)).visible = true;
			TweenUtils.entityTo(_airplane, Spatial, 5, {x:shellApi.camera.viewportWidth / 2, ease:Cubic.easeInOut});
			TweenUtils.entityTo(_balloon, Spatial, 6, {x:shellApi.camera.viewportWidth / 2 + 300, y:shellApi.camera.viewportHeight * 0.6, ease:Cubic.easeOut, onComplete:readyRace});
		}
		
		private function readyRace():void
		{
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new TalkAction(_officiate, "race1") );
			actChain.addAction( new TalkAction(_officiate, "race2") );
			actChain.addAction( new CallFunctionAction( showMedallion ) );
			actChain.addAction( new WaitAction(2) );
			actChain.addAction( new TalkAction(_officiate, "race3") );
			actChain.addAction( new CallFunctionAction( readyPlayer) );
			
			actChain.execute();
		}
		
		private function showMedallion():void
		{
			AudioUtils.play(this, REVEAL_MEDAL);
			Timeline(_medallion.get(Timeline)).play();
		}
		
		private function readyPlayer():void
		{
			SceneUtil.lockInput(this, false);
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;  // change default cursor
			Dialog(_officiate.get(Dialog)).sayById("raceReady");
		}
		
		private function startRace():void
		{
			shellApi.triggerEvent("raceMusic");
			SceneUtil.lockInput(this);
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new CallFunctionAction( readyPilots ) );
			actChain.addAction( new WaitAction(0.5) );
			actChain.addAction( new TalkAction(_officiate, "start1") );
			actChain.addAction( new WaitAction(0.5) );
			actChain.addAction( new CallFunctionAction( takeOff ) );
			actChain.addAction( new WaitAction(2) );
			actChain.addAction( new TalkAction(player, "exciting") );
			actChain.addAction( new CallFunctionAction( enterbaron ) );
			actChain.addAction( new WaitAction(2) );
			actChain.addAction( new TalkAction(_pilot, "baron1") );
			actChain.addAction( new CallFunctionAction( frown ));
			actChain.addAction( new AnimationAction(baron, Throw) );
			actChain.addAction( new CallFunctionAction( throwWrench ) );
			actChain.addAction( new WaitAction(4) );
			actChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, baron, true ) ));
			actChain.addAction( new TalkAction(_pilot, "goingDown") );
			actChain.addAction( new CallFunctionAction( goingDown ) );
			actChain.addAction( new WaitAction(3.5) );
			actChain.addAction( new CallFunctionAction( _smokeParticles.stopStream ) );
			
			actChain.execute();
		}
		
		private function readyPilots():void
		{
			CharUtils.setAnim(player, Sit);
			CharUtils.setAnim(_pilot, Sit);
			CharUtils.setAnim(_pirate, Sit);
			CharUtils.setAnim(_stylishGirl, Sit);
			if(_cat)
				CharUtils.setAnim(_cat, Sit);
			CharUtils.setAnim(_carpetRider, Sit);
		}
		
		private function takeOff():void
		{
			shellApi.completeEvent(ftue.RACE_BEGUN);
			shellApi.track(ftue.RACE_BEGUN);
			AudioUtils.play(this, START_RACE_HORN);
			
			TweenUtils.entityTo(_airplane2, Spatial, 5, {x:Spatial(_airplane2.get(Spatial)).x - 1200, ease:Cubic.easeInOut});
			TweenUtils.entityTo(_airplane3, Spatial, 5, {x:Spatial(_airplane3.get(Spatial)).x - 1200, ease:Cubic.easeInOut});
			TweenUtils.entityTo(_airplane6, Spatial, 5, {x:Spatial(_airplane6.get(Spatial)).x - 1200, ease:Cubic.easeInOut});
			
			TweenUtils.entityTo(_airplane, Spatial, 5, {x:Spatial(_airplane3.get(Spatial)).x + 200, ease:Cubic.easeInOut});
			
			TweenUtils.entityTo(_balloon, Spatial, 2, {x:-300, ease:Cubic.easeIn});
			
			Timeline(_flags.get(Timeline)).play();
			
			Dialog(_officiate.get(Dialog)).sayById("start2");
		}
		
		private function frown():void
		{
			SkinUtils.setSkinPart(_pilot, SkinUtils.MOUTH, 14);
		}
		
		private function enterbaron():void
		{
			shellApi.completeEvent(ftue.ENCOUNTERED_BARON);
			shellApi.track(ftue.ENCOUNTERED_BARON);
			AudioUtils.playSoundFromEntity(_airplaneB, PROP_SOUND, 500, 0, 1, null, true);
			
			// remove other airplanes not visible
			this.removeEntity(_airplane2);
			this.removeEntity(_airplane3);
			this.removeEntity(_airplane6);
			this.removeEntity(_pirate);
			this.removeEntity(_carpetRider);
			this.removeEntity(_carpet);
			this.removeEntity(_stylishGirl);
			if(_cat)
				this.removeEntity(_cat);
			this.removeEntity(_balloon);
			this.removeEntity(_officiate);
			
			Display(baron.get(Display)).visible = true;
			Display(_airplaneB.get(Display)).visible = true;
			TweenUtils.entityTo(_airplaneB, Spatial, 5, {x:shellApi.camera.viewportWidth / 2+110, y:240, ease:Cubic.easeOut});
			TweenUtils.entityTo(_airplane, Spatial, 5, {x:shellApi.camera.viewportWidth / 2-50, ease:Cubic.easeInOut});
			
			var followTarget:FollowTarget = new FollowTarget(_airplane.get(Spatial));
			followTarget.offset = new Point(58,29);
			_explosion.add(followTarget);
		}
		
		private function throwWrench():void
		{
			AudioUtils.play(this, THROW);
			//CharUtils.setAnim(_baron, Throw);
			var wSpatial:Spatial = _wrench.get(Spatial);
			var bSpatial:Spatial = baron.get(Spatial);
			var bPlane:Spatial = _airplaneB.get(Spatial);
			var aSpatial:Spatial = _airplane.get(Spatial);
			
			wSpatial.x = bSpatial.x + bPlane.x;
			wSpatial.y = bSpatial.y + bPlane.y;
			
			Display(_wrench.get(Display)).visible = true;
			
			TweenUtils.entityTo(_wrench, Spatial, 0.5, {x:aSpatial.x + 40, y:aSpatial.y, rotation:360, onComplete:impactPlane, ease:Linear.easeNone});
		}
		
		private function impactPlane():void
		{
			
			Display(_wrench.get(Display)).visible = false;
			
			SkinUtils.setSkinPart(baron, SkinUtils.MOUTH, 5);
			
			CharUtils.setAnim(baron, Laugh, false);
			CharUtils.setAnim(_pilot, Grief);
			CharUtils.setAnim(player, Tremble);
			
			AudioUtils.play(this, WRENCH_IMPACT);
			AudioUtils.play(this, ENGINE_DOWN);
			
			AudioUtils.stop(this, PROP_SOUND);
			AudioUtils.play(this, PROP_SOUND_BROKE, 1, true);
			
			TweenUtils.entityTo(_airplaneB, Spatial, 8, {x:Spatial(_airplaneB.get(Spatial)).x + 3100, ease:Cubic.easeIn});
			TweenUtils.entityTo(_airplane, Spatial, 7, {x:shellApi.camera.viewportWidth / 2+110, ease:Cubic.easeInOut});
			
			Timeline(_explosion.get(Timeline)).play();
			
			_smokeParticles.stream();
			
			cameraShake();
		}
		
		private function goingDown():void
		{
			shellApi.completeEvent(ftue.GOING_DOWN);
			shellApi.track(ftue.GOING_DOWN);
			TweenUtils.entityTo(_airplane, Spatial, 5, {x:shellApi.camera.viewportWidth / 2 - 50, y:shellApi.camera.viewportHeight + 200, ease:Cubic.easeInOut, onComplete:endScene});
		}
		
		private function endScene():void
		{
			shellApi.loadScene(Beach);
		}
		
		private function characterInBGPlane(char:Entity, plane:Entity, under:Boolean = true, offset:Spatial = null, scale:Number = 0.36):Entity
		{
			// remove FSMControl
			_charGroup.removeFSM(char);
			_charGroup.removeCollliders(char);
			
			// remove sleep
			Sleep(char.get(Sleep)).sleeping = false;
			Sleep(char.get(Sleep)).ignoreOffscreenSleep = true;
			
			// scale if necessary
			var spatial:Spatial = char.get(Spatial);
			spatial.scale = scale;
			spatial.x = offset.x;
			spatial.y = offset.y;
			var display:Display = char.get(Display);
			display.setContainer(EntityUtils.getDisplayObject(plane));
			display.moveToBack();
			
			return char;
		}
		
		private function cameraShake():Boolean
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion= cameraEntity.get(WaveMotion);
			
			if(waveMotion != null)
			{
				cameraEntity.remove(WaveMotion);
				var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
				spatialAddition.y = 0;
				return(false);
			} 
			else 
			{
				waveMotion = new WaveMotion();
			}
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 1;
			waveMotionData.rate = 1;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			if(!super.hasSystem(WaveMotionSystem))
			{
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
			
			return(true);
		}
		
		/*private function showHowToMap():void
		{
		Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;
		//shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
		
		var stepDatas:Vector.<StepData> = new Vector.<StepData>();
		var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
		var texts:Vector.<TextData> = new Vector.<TextData>();
		
		var hudButton:Entity = hud.getButtonById(Hud.HUD);
		var hudButtonSpatial:Spatial = hudButton.get(Spatial);
		
		shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(hudButtonSpatial.x, hudButtonSpatial.y), 60, 60, "backpack", null, null, hudButton.get(Interaction)));
		texts.push(new TextData("First, open your menu.", "tutorialwhite", new Point(shellApi.viewportWidth - 350, 10),240));
		var clickHud:StepData = new StepData("hud", TUTORIAL_ALPHA, 0x000000, 1.5, true, shapes, texts);
		tutorial.addStep(clickHud);
		
		shapes = new Vector.<ShapeData>();
		texts = new Vector.<TextData>();
		shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(shellApi.viewportWidth - 280, 45), 36, 36));
		texts.push(new TextData("The map is here!", "tutorialwhite", new Point(shellApi.viewportWidth - 400, 100),240));
		texts.push(new TextData("There are tons of islands to explore, but let's finish this one first.", "tutorialwhite", new Point(shellApi.viewportWidth - 424, 200),300));
		var clickInventory:StepData = new StepData("backpack", TUTORIAL_ALPHA, 0x000000, 1, true, shapes, texts);
		tutorial.addStep(clickInventory);
		
		//tutorial = new TutorialGroup(overlayContainer, stepDatas);
		tutorial.complete.addOnce(shownMap);
		//this.addChildGroup(tutorial);
		tutorial.start();
		
		}
		
		private function shownMap(group:Group):void{
		var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
		hud.openHud(false);
		Dialog(_officiate.get(Dialog)).sayById("raceReady");
		}*/
		
		private const LAND_SOUND:String = SoundManager.EFFECTS_PATH + "ls_car_hood_02.mp3";
		private const THROW:String = SoundManager.EFFECTS_PATH + "whoosh_08.mp3";
		private const WRENCH_IMPACT:String = SoundManager.EFFECTS_PATH + "small_explosion_04.mp3";
		private const ENGINE_DOWN:String = SoundManager.EFFECTS_PATH + "turn_engine_off_01.mp3";
		private const REVEAL_MEDAL:String = SoundManager.EFFECTS_PATH + "points_ping_03d.mp3";
		private const START_RACE_HORN:String = SoundManager.EFFECTS_PATH + "victoryFanfare.mp3";
		private const SPEED_UP:String = SoundManager.EFFECTS_PATH + "engine_speedup.mp3";
		
		private var _airplane:Entity;
		
		private var _medallion:Entity;
		private var _flags:Entity;
		private var _hud:Hud;
		
		private var _airplane6:Entity;
		private var _carpet:Entity;
		private var _pirate:Entity;
		private var _stylishGirl:Entity;
		private var _cat:Entity;
		private var _carpetRider:Entity;
	}
}