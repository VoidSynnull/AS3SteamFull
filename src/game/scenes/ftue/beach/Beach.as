package game.scenes.ftue.beach
{
	import com.greensock.easing.Quad;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.SeeSaw;
	import game.components.hit.ValidHit;
	import game.components.input.Input;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Dizzy;
	import game.data.character.LookData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.data.ui.GestureData;
	import game.data.ui.ToolTipType;
	import game.particles.emitter.PoofBlast;
	import game.scene.template.CharacterGroup;
	import game.scenes.ftue.FtueScene;
	import game.scenes.ftue.beach.components.Crab;
	import game.scenes.ftue.beach.crabStates.CrabGrabWrenchState;
	import game.scenes.ftue.beach.crabStates.CrabHideState;
	import game.scenes.ftue.beach.crabStates.CrabIdleState;
	import game.scenes.ftue.beach.crabStates.CrabStartleState;
	import game.scenes.ftue.beach.crabStates.CrabSurrenderState;
	import game.scenes.ftue.beach.crabStates.CrabWalkState;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.systems.animation.FSMState;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.touch.JumpState;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.ItemHitSystem;
	import game.systems.hit.SeeSawSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class Beach extends FtueScene
	{
		private var monkey:Entity;
		
		private var crab:Entity;
		
		private var goForCrab:Boolean = false;
		
		private var currentStep:int = WALK;
		
		private const MASS1:Number 			= 40;
		private const MASS2:Number 			= 120;
		private const MASS_PLAYER:Number	= 80;
		
		private const LAND:String			= "sand_hard_01.mp3";
		
		private const SEE:String			= "grinding_stone_03.mp3";
		private const SAW:String			= "grinding_stone_02.mp3";
		
		private const SCURRY:String 		= "insect_scurry_01.mp3";
		private const GRAB_WRENCH:String	= "metal_impact_12.mp3";
		private const THROW_WRENCH:String	= "sand_bag_01.mp3";
		
		private var rockData:BitmapData;
		private var saidFollow:Boolean = false;
		private var monkeyCanMove:Boolean = false;
		
		public function Beach()
		{
			super();
		}
		
		override public function destroy():void
		{
			if(rockData)
				rockData.dispose();
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/ftue/beach/";
			
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
			
			addSystem(new ThresholdSystem());
			addSystem(new HitTestSystem());
			addSystem(new SeeSawSystem());
			
			setUpMonkey();
			setupCrab();
			setUpPlayer();
			
			setUpTilt("tiltPlatformLeft", MASS1,MASS2,-30,20);
			setUpTilt("tiltPlatformRight",MASS2,MASS1,-20,30);
		}
		
		override public function onEventTriggered(event:String=null, makeCurrent:Boolean=false, init:Boolean=false, removeEvent:String=null):void
		{
			switch(event){
				case "beach1":
					if (monkeyCanMove)
					{
						moveMonkeyToRock();
					}
					break;
				case "beach2":
					if (!saidFollow)
					{
						saidFollow = true;
						var dialog:Dialog = player.get(Dialog);
						dialog.sayById("follow");
						SceneUtil.setCameraTarget(this, monkey,false,CAMERA_PAN_SPEED);
						dialog.complete.addOnce(getUp);
						dialog.start.addOnce(lookBackAtPlayer);
						Dialog(monkey.get(Dialog)).complete.remove(monkeyDoneTalking);
					}
					break;
			}
		}
		
		private function setUpTilt(tiltName:String, leftMass:Number, rightMass:Number, leftAngle:Number, rightAngle:Number):Entity
		{
			var entity:Entity = getEntityById(tiltName);
			
			var disp:DisplayObjectContainer;
			if(entity == null)
			{
				disp = _hitContainer[tiltName];
				if(disp != null)
					entity = EntityUtils.createSpatialEntity(this, disp).add(new Id(tiltName));
				else
					return null;
			}
			else
				disp = EntityUtils.getDisplayObject(entity);
			
			if(PlatformUtils.isMobileOS)
			{
				var rock:MovieClip = disp["rock"];
				if(rock == null)
				{
					rock = disp.getChildAt(0)["rock"];
				}
				if(rockData == null)
					rockData = BitmapUtils.createBitmapData(rock);
				rock.parent.addChild(BitmapUtils.createBitmapSprite(rock, 1, null, true, 0, rockData));
				rock.parent.removeChild(rock);
			}
			
			EntityUtils.getDisplay(entity).isStatic = false;
			EntityUtils.visible(entity);
			
			var edge:Edge = new Edge();
			edge.unscaled = disp.getBounds(disp);
			edge.unscaled.left *=.1;
			edge.unscaled.right *= .1;
			entity.add(edge);
			entity.add(new Motion());
			
			if(entity.get(Platform) == null)
			{
				entity.add(new Platform());
				entity.add(new EntityIdList());
			}
			entity.remove(Sleep);
			
			//Motion(entity.get(Motion)).rotationFriction = 100;
			
			var rightRock:Boolean = tiltName.indexOf("Right")>= 0;
			
			var seesaw:SeeSaw = new SeeSaw(leftMass, rightMass, leftAngle, rightAngle);
			seesaw.maxTiltReached.add(Command.create(tiltedRock, rightRock));
			seesaw.changedDirections.add(Command.create(changedRocksDirection, rightRock))
			entity.add(seesaw);
			
			return entity;
		}
		
		private function tiltedRock(entity:Entity, tiltedRight:Boolean, isRightRock:Boolean):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+LAND);
			
			var crabState:Crab = crab.get(Crab);
			if(crabState == null)
				return;
			
			if(tiltedRight == isRightRock)
			{
				if(isRightRock)
					crabState.rightBlocked = true;
				else
					crabState.leftBlocked = true;
				
				if(isRightRock == !crabState.hidingLeft)
				{
					FSMControl(crab.get(FSMControl)).setState(MovieclipState.JUMP);
				}
			}
			else
			{
				if(isRightRock)
					crabState.rightBlocked = false;
				else
					crabState.leftBlocked = false;
			}
		}
		
		private function changedRocksDirection(entity:Entity, tiltingRight:Boolean, isRightRock:Boolean):void
		{
			if(tiltingRight == isRightRock)
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+SEE);
			else
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+SAW);
			
			// if you are supposed to catch the crab
			if(goForCrab)
			{
				// if you are about to solve the puzzle
				if(!isRightRock && !tiltingRight)
				{
					SceneUtil.lockInput(this); // lock input
					// however if for some reason you start tilting the wrong way while input is locked
					SeeSaw(entity.get(SeeSaw)).maxTiltReached.addOnce(Command.create(checkReturnControls, isRightRock));//unlock input
				}
			}	
		}
		
		private function checkReturnControls(entity:Entity, tiltedRight:Boolean, isRightRock:Boolean):void
		{
			if(!isRightRock && tiltedRight)
			{
				SceneUtil.lockInput(this, false);
			}
		}
		
		private function setUpMonkey():void
		{
			monkey = getEntityById("monkey");
			monkey.add(new Mass(MASS_PLAYER));
			monkey.remove(Sleep);
			if(shellApi.checkItemEvent(ftue.WRENCH))
			{
				removeEntity(monkey);
				monkey = null;
			}
			else
			{
				if(shellApi.checkEvent(ftue.SAVED_AMELIA))
				{
					var spatial:Spatial = monkey.get(Spatial);
					spatial.x = 3250;
					spatial.y = 675;
					CharUtils.moveToTarget(monkey, EXIT + 200, 800,false, thereItIs);
					SceneUtil.setCameraTarget(this, monkey,false,CAMERA_PAN_SPEED);
					SceneUtil.lockInput(this);
					shellApi.completeEvent(ftue.FOLLOWED_MONKEY_TO_BEACH);
					shellApi.track(ftue.FOLLOWED_MONKEY_TO_BEACH);
				}
				else
				{
					if(shellApi.checkEvent(ftue.COMPLETED_TUTORIAL))
					{
						removeEntity(monkey);
						monkey = null;
					}
				}
			}
		}
		
		private function thereItIs(entity:Entity):void
		{
			jumpOnRock();
		}
		
		private function jumpOnRock(...args):void
		{
			goForCrab = true;
			CharUtils.moveToTarget(monkey, EXIT - 100, 900);
			Dialog(monkey.get(Dialog)).faceSpeaker = false;
		}
		
		private function lookAtCrab(...args):void
		{
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this, crab,false,CAMERA_PAN_SPEED);
		}
		
		private function setupCrab():void
		{
			var clip:MovieClip = _hitContainer["crab"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			crab = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertClip(clip, this,crab,null,true, 30);
			
			var interaction:SceneInteraction = new SceneInteraction();
			InteractionCreator.addToEntity(crab, ["click"]);
			interaction.reached.add(grabCrab);
			interaction.minTargetDelta.x = 150;
			interaction.ignorePlatformTarget = false;
			crab.add(interaction);
			ToolTipCreator.addToEntity(crab);
			
			var edge:Edge = new Edge();
			edge.unscaled = clip.getBounds(clip);
			crab.add(edge);
			
			var hideLeft:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["crabHideLeft"]);
			var hideRight:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["crabHideRight"]);
			var crabState:Crab = new Crab(hideLeft.get(Spatial), hideRight.get(Spatial),500, false);
			
			if(!shellApi.checkItemEvent(ftue.WRENCH))
			{
				var wrench:Entity = getEntityById("wrench");
				ToolTipCreator.removeFromEntity(wrench);
				wrench.remove(Item);
				
				crabState.hasWrench = shellApi.checkEvent(ftue.COMPLETED_TUTORIAL);
				
				EntityUtils.visible(wrench, !crabState.hasWrench);
				
				if(shellApi.checkEvent(ftue.SAVED_AMELIA))
				{
					crab.get(Spatial).x = hideRight.get(Spatial).x;
					crabState.hidingLeft = false;
					var itemSystem:ItemHitSystem = getSystem(ItemHitSystem) as ItemHitSystem;
					itemSystem.gotItem.addOnce(goodJob);
				}
				else
				{
					if(!crabState.hasWrench)
					{
						addSystem(new HitTheDeckSystem());
						var duck:HitTheDeck = new HitTheDeck(crab.get(Spatial),50, false);
						duck.duck.add(pickUpWrench);
						wrench.add(duck);
					}
				}
			}
			
			var validHits:ValidHit = new ValidHit("tiltPlatformLeft", "tiltPlatformRight", "sand");
			validHits.inverse = true;
			crab.add(validHits);
			
			crab.add(crabState);
			
			var charGroup:CharacterGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			charGroup.addTimelineFSM(crab, true,new <Class>[CrabIdleState, CrabWalkState, CrabStartleState, CrabGrabWrenchState, CrabHideState, CrabSurrenderState],MovieclipState.STAND);
			charGroup.addAudio(crab);
			crab.add(new AudioRange(1000, .1, 1, Quad.easeIn));
			
			var fsm:FSMControl = crab.get(FSMControl);
			fsm.stateChange = new Signal();
			fsm.stateChange.add(checkState);
			
			crab.remove(WallCollider);
			crab.remove(Sleep);
		}
		
		private function pickUpWrench(wrench:Entity):void
		{
			//shellApi.getItem(ftue.WRENCH, null, true,goodJob);
			FSMControl(crab.get(FSMControl)).setState("grab");
			goForCrab = false;
			var spatial:Spatial = crab.get(Spatial);
			spatial.x = 2647;
			var time:Timeline = crab.get(Timeline);
			time.handleLabel("grab",grabbedWrench);
			removeEntity(wrench,true);
		}
		
		private function grabbedWrench():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + GRAB_WRENCH);
		}
		
		private function centerOverCrab():void
		{
			shellApi.completeEvent(ftue.CORNERED_CRAB);
			shellApi.track(ftue.CORNERED_CRAB);
			SceneUtil.setCameraPoint(this, 2600,900);
		}
		
		private function checkState(state:String,crab:Entity):void
		{
			var audio:Audio = crab.get(Audio);
			if(state == MovieclipState.JUMP || state == MovieclipState.WALK)
			{
				if(!audio.isPlaying(SoundManager.EFFECTS_PATH+SCURRY))
					audio.play(SoundManager.EFFECTS_PATH+SCURRY, false, SoundModifier.POSITION);
			}
			
			if(!goForCrab)
				return;
			
			var crabState:Crab = crab.get(Crab);
			
			if(state == MovieclipState.WALK)
			{
				if(crabState.startScurrying)
					centerOverCrab();
				else
					lookAtCrab();
			}
			
			if(state == MovieclipState.STAND)// jump on the rock when it is hiding under monkey
			{
				SceneUtil.delay(this, 1, returnControls);
			}
			
			if(state == MovieclipState.RUN)
			{
				FSMControl(crab.get(FSMControl)).stateChange.remove(checkState);
				
				Timeline(crab.get(Timeline)).handleLabel("wrenchThrown", thrownWrench);
			}
		}
		
		private function thrownWrench():void
		{
			var wrench:Entity = getEntityById("wrench");
			wrench.add(new Item());
			ToolTipCreator.addToEntity(wrench);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + THROW_WRENCH);
			
			var spatial:Spatial = wrench.get(Spatial);
			
			var poofBlast:PoofBlast = new PoofBlast();
			poofBlast.init(5, 10, 0xC1BB97);
			EmitterCreator.create(this, _hitContainer, poofBlast, spatial.x, spatial.y + 50);
			
			EntityUtils.visible(wrench);
			TweenUtils.entityTo(crab, Spatial, 2,{y:sceneData.bounds.bottom + 50, onComplete:Command.create(removeEntity, crab)});
			returnControls();
			goForCrab = false;
		}
		
		private function grabCrab(player:Entity, crab:Entity):void
		{
			var dialog:Dialog = player.get(Dialog);
			
			if(shellApi.checkEvent(ftue.CORNERED_CRAB))
				dialog.sayById("got_wrench");
			else if(shellApi.checkEvent(ftue.FOLLOWED_MONKEY_TO_BEACH))
				dialog.sayById("crabs_hiding_monkey");
			else
				dialog.sayById("crabs_hiding");
		}
		
		private function goodJob(...args):void
		{
			nowBackToThePlane();
			SceneUtil.setCameraTarget(this, monkey,false,CAMERA_PAN_SPEED);
			SceneUtil.lockInput(this);
		}
		
		private function nowBackToThePlane(...args):void
		{
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(EXIT,800),new Point(sceneData.bounds.right,650));
			CharUtils.followPath(monkey, path, monkeyLeaveScene);
		}
		
		private function setUpPlayer():void
		{
			player.add(new Mass(MASS_PLAYER));
			if(!shellApi.checkEvent(ftue.COMPLETED_TUTORIAL))
			{
				shellApi.removeEvent(ftue.JUMPED_ON_ROCK);
				//making sure you start in your starting position if restarting a tutorial mid way through
				CharUtils.setDirection(player, true);
				var spatial:Spatial = player.get(Spatial);
				spatial.x = 1000;
				spatial.y = 925;
				
				CharUtils.setAnim(player, Dizzy);
				SceneUtil.delay(this, 2, enterMonkey);
				SceneUtil.lockInput(this);
				lockDoor(true);
				FSMControl(player.get(FSMControl)).removeState(CharacterState.JUMP);
			}
		}
		
		private function enterMonkey(...args):void
		{
			CharUtils.moveToTarget(monkey, sceneData.startPosition.x + 100, sceneData.startPosition.y, true, wakePlayer);
		}
		
		private function wakePlayer(entity:Entity):void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("where_am_i");
			dialog.complete.addOnce(openYourEyes);
		}
		
		private function monkeyDoneTalking(dialogData:DialogData):void
		{
			var dialog:Dialog = player.get(Dialog);
			if(dialogData.id == "r_u_ok")
			{
				dialog.complete.addOnce(openYourEyes);
			}
			if(dialogData.id == "she_is_over_there")
			{
				moveMonkeyToRock();
			}
		}
		
		private function lookBackAtPlayer(...args):void
		{
			SceneUtil.setCameraTarget(this, player, false, CAMERA_PLAYER_SPEED);
		}
		
		private function openYourEyes(...args):void
		{
			var look:LookData = SkinUtils.getPlayerLook(this);
			SkinUtils.setEyeStates(player,look.getValue(SkinUtils.EYE_STATE));
			monkeyCanMove = true;
		}
		
		private function getUp(...args):void
		{
			SceneUtil.delay(this, 1, showHowToMove);
			CharUtils.stateDrivenOn(player);
		}
		
		private function moveMonkeyToRock():void
		{
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(JUMP -75, 900), new Point( JUMP + 100, 650), new Point(JUMP + 275, 650));
			CharUtils.followPath(monkey, path,Command.create(nowYouTry));
			SceneUtil.setCameraTarget(this, monkey,false,CAMERA_PAN_SPEED);
			var threshold:Threshold = new Threshold("x",">");
			threshold.entered.add(Command.create(reachedThreshold, threshold));
			threshold.threshold = RUN;
			player.add(threshold);
		}
		
		private function reachedThreshold(threshold:Threshold):void
		{
			switch(threshold.threshold)
			{
				case RUN:
				{
					returnControls();
					threshold.threshold = JUMP;
					showHowToMove(RUN);
					break;
				}
				case JUMP:
				{
					if(shellApi.checkEvent(ftue.JUMPED_ON_ROCK))// not entirely sure how this gets activated again
						break;
					returnControls();
					var stateCreator:FSMStateCreator = new FSMStateCreator();
					var state:FSMState = stateCreator.createCharacterState(JumpState, player, CharacterState.JUMP);
					FSMControl(player.get(FSMControl)).addState(state, CharacterState.JUMP);
					threshold.threshold = PASSED_HURDLE;
					showHowToMove(JUMP);
					break;
				}
				case PASSED_HURDLE:
				{
					MotionUtils.zeroMotion(player, "x");// dont let them jump completely over rock
					CharUtils.lockControls(player);
					threshold.threshold = EXIT;
					shellApi.completeEvent(ftue.JUMPED_ON_ROCK);
					shellApi.track(ftue.JUMPED_ON_ROCK);
					jumpOffRock();
					break;
				}
				case EXIT:
				{
					goIntoJungle();
					threshold.entered.removeAll();
					break;
				}
			}
		}
		
		private function showHowToMove(movement:int = WALK):void
		{
			currentStep = movement;
			var spatial:Spatial = player.get(Spatial);
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			var gestures:Vector.<GestureData> = new Vector.<GestureData>();
			
			var location:Point =  DisplayUtils.localToLocal(EntityUtils.getDisplayObject(player),overlayContainer);
			
			if(movement == RUN)
				location.x += 300;
			else
				location.x += 100;
			
			if(movement == JUMP)
				location.y -= 300;
			
			var signal:Signal;
			var handler:Function;
			
			if(movement == EXIT)
			{
				location = DisplayUtils.localToLocal(EntityUtils.getDisplayObject(getEntityById("door1")),overlayContainer);
				location = location.subtract(new Point(100, 100));
				//signal = new Signal();
				//handler = Command.create(tappingDone, signal);
				gestures.push(new GestureData(GestureData.MOVE_THEN_CLICK, location, null,-1,1));
			}
			else
			{
				if(spatial.x > currentStep + 200)
				{
					// don't show tutorial if you already got it
					return;
				}
				gestures.push(new GestureData(GestureData.CLICK_AND_DRAG,location,null,-1,2));
				signal = Input(shellApi.inputEntity.get(Input)).inputDown;
			}
			
			
			var platformInput:String = PlatformUtils.isMobileOS?"tap ":"click ";
			
			var prefix:String = (movement == EXIT)?platformInput:platformInput+"and hold ";
			
			var yFactor:Number;
			var xFactor:Number;
			
			var phrase:String;
			switch(movement)
			{
				case WALK:
				{
					phrase = "in front of avatar to walk.";
					yFactor = .5;
					xFactor = .5;
					break;
				}
				case RUN:
				{
					phrase = "further away to run.";
					yFactor = .5;
					xFactor = .75;
					break;
				}
				case JUMP:
				{
					phrase = "above avatar to jump.";
					yFactor = .25;
					xFactor = .5;
					break;
				}
				case EXIT:
				{
					phrase = "the edge of a scene to exit.";
					yFactor = .33;
					xFactor = .66;
					break;
				}
			}
			
			shapes.push(new ShapeData(ShapeData.CIRCLE, location,50, 50,null,null,handler,null,signal));
			
			texts.push(new TextData(prefix + phrase, "tutorialwhite", new Point(shellApi.viewportWidth * xFactor - 150, shellApi.viewportHeight * yFactor - 75)));
			
			var moveStep:StepData = new StepData("move", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts,null,gestures);
			tutorial.addStep(moveStep);
			tutorial.start();
			tutorial.complete.addOnce(tutFinished);
		}
		
		private function tappingDone(signal:Signal):void
		{
			signal.dispatch();
		}
		
		private function tutFinished(group:DisplayGroup):void
		{			
			if(currentStep == EXIT)
			{
				SceneInteraction(getEntityById("door1").get(SceneInteraction)).activated = true;
				shellApi.completeEvent(ftue.COMPLETED_TUTORIAL);
				shellApi.track(ftue.COMPLETED_TUTORIAL);
				return;
			}
			//turorial group unlocks controls, but this deactivates input
			var input:Input = shellApi.inputEntity.get(Input);
			input.inputActive = input.inputStateDown = true;
			// reactivate input so player actually moves when they click
		}
		
		private function jumpOffRock():void
		{
			goForCrab = true;
			CharUtils.moveToTarget(monkey, EXIT - 85, 750).setDirectionOnReached("left");
			SeeSaw(getEntityById("tiltPlatformRight").get(SeeSaw)).maxTiltReached.addOnce(startleCrab);
			SceneUtil.setCameraTarget(this, monkey,false,CAMERA_PAN_SPEED);
			SceneUtil.lockInput(this);
		}
		
		private function startleCrab(...args):void
		{
			SceneUtil.delay(this, 5, jumpOnToSolidGround);
		}
		
		private function jumpOnToSolidGround():void
		{
			SceneUtil.setCameraTarget(this, monkey,false,CAMERA_PAN_SPEED);
			CharUtils.moveToTarget(monkey, EXIT + 200, 700,false,Command.create(nowYouTry, Command.create(showHowToMove, JUMP),returnControls));
		}
		
		private function goIntoJungle():void
		{
			CharUtils.moveToTarget(monkey, sceneData.bounds.right,650,true,monkeyLeaveScene);
			SceneUtil.lockInput(this);
		}
		
		private function monkeyLeaveScene(entity:Entity):void
		{
			removeEntity(monkey);
			monkey = null;
			
			if(!shellApi.checkEvent(ftue.COMPLETED_TUTORIAL))
			{
				showHowToMove(EXIT);
			}
			else
				Dialog(player.get(Dialog)).sayById("did_it");
			
			lockDoor(false);
			
			returnControls();
		}
		
		private function lockDoor(lock:Boolean):void
		{
			var door:Entity = getEntityById("door1");
			Interaction(door.get(Interaction)).lock = lock;
			if(lock)
				ToolTipCreator.removeFromEntity(door);
			else
				ToolTipCreator.addToEntity(door, ToolTipType.EXIT_RIGHT, "GO RIGHT", new Point(-100, -200));
		}
		
		private function nowYouTry(entity:Entity, gestureMethod:Function = null,onComplete:Function = null):void
		{
			CharUtils.setDirection(monkey, false);
			//I'd like to add a waving follow me animation
			var dialog:Dialog = monkey.get(Dialog);
			returnControls();
			shellApi.triggerEvent("beach2");
			if(gestureMethod)
				dialog.complete.addOnce(Command.create(showYouHow, gestureMethod, onComplete));
			else
			{
				if(onComplete)
					dialog.complete.addOnce(onComplete);
			}
		}
		
		private function showYouHow(dialogData:DialogData, gestureMethod:Function, onComplete:Function):void
		{
			if(onComplete);
			onComplete();
		}
		
		private const WALK:Number 			= 1000;
		private const RUN:Number 			= 1300;
		private const JUMP:Number 			= 1900;
		private const PASSED_HURDLE:Number 	= 2050;
		private const EXIT:Number 			= 3000;
	}
}