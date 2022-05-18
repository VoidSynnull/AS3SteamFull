package game.scenes.backlot.soundStage3Chase
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.entity.Dialog;
	import game.components.entity.FollowClipInTimeline;
	import game.components.entity.Sleep;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.TwirlPistol;
	import game.data.ui.ButtonSpec;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.BacklotEvents;
	import game.scenes.backlot.shared.popups.Clapboard;
	import game.scenes.backlot.soundStage3.SoundStage3;
	import game.systems.SystemPriorities;
	import game.systems.entity.FollowClipInTimelineSystem;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayPositionUtils;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class SoundStage3Chase extends PlatformerGameScene
	{
		public function SoundStage3Chase()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/soundStage3Chase/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var backlot:BacklotEvents;
		
		private var hero:Entity;
		private var villain:Entity;
		private var sophia:Entity;
		
		private const sceneActions:int = 8;
		private var actionNumber:int = 0;
		private const timeBetweenActions:int = 3;
		
		private const wrongActionsAllowed:int = 3;
		private var wrongActions:int = 0;
		private const actionReminderTime:int = 5;
		
		private var selectedAction:Boolean = false;
		
		private var obstacles:Array = ["buffalo", "tornado", "donkey"];
		private var currentAction:String;
		
		private var buffaloClip:MovieClip;
		private var tumbleWeeds:MovieClip;
		
		private var startPoint:Point;//for obstacles
		
		// for the hero
		private var landPoint:Point;
		private var jumpPoint:Point;
		private var movePoint:Point;
		
		private var takes:int = 0;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			backlot = events as BacklotEvents;
			shellApi.eventTriggered.add(onEventTriggered);
			
			setUpCloseButton()
			
			setUpNpcs();
			setUpBackGround();
			setUpObstacles();
			setUpButtons();
			removeEntity(player);
			Cursor(shellApi.inputEntity.get(Cursor)).defaultType = "arrow";
			reset();
			
			if(shellApi.profileManager.active.userFields[shellApi.island] != null)
			{
				if(shellApi.profileManager.active.userFields[shellApi.island]["stage3"] != null)
					takes = shellApi.getUserField("stage3",shellApi.island);
				else
					saveTakesToServer();
			}
			else
			{
				saveTakesToServer();
			}
		}
		
		private function saveTakesToServer():void
		{
			shellApi.setUserField("stage3",takes,shellApi.island,true);
		}
		
		private function setUpCloseButton():void
		{
			var buttonSpec:ButtonSpec = new ButtonSpec();
			var displayPosition:String = DisplayPositions.TOP_LEFT
			buttonSpec.position = DisplayPositionUtils.getPosition(displayPosition,shellApi.viewportWidth,shellApi.viewportHeight,50,50);
			buttonSpec.clickHandler = handleCloseClicked;
			buttonSpec.container = Hud(getGroupById("hud")).screen;
			ButtonCreator.loadStandardButton( ButtonCreator.CLOSE_BUTTON, getGroupById("hud"), buttonSpec );
		}
		
		protected function handleCloseClicked (e:Event = null): void 
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + SoundManager.STANDARD_CLOSE_CANCEL_FILE);
			
			shellApi.loadScene(SoundStage3, 1000, 800, "right");
		}
		
		private function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			trace(event);
			
			if(event == backlot.ACTION)
			{
				startScene()
			}
			
			if(event == backlot.WRONG_ACTION)
			{
				checkIfLoose();
			}
			
			if(event == backlot.AGAIN)
			{
				reset();
			}
			if(event == backlot.PRINT)
			{
				print();
			}
			
			if(event == backlot.END_OF_THE_LINE)
			{
				kickOffVillain();
			}
		}
		
		private function print():void
		{
			shellApi.triggerEvent(backlot.COMPLETE_STAGE_3, true);
			shellApi.loadScene(SoundStage3, 1000, 800, "right");
		}
		
		private function reset():void
		{
			SceneUtil.lockInput(this);
			stopBackGround();
			moveKeyObjectsToFront();
			CharUtils.setAnim(hero, Stand);
			actionNumber = 0;// if not 0 it is only for testing purposes
			wrongActions = 0;
			currentAction = "";
			selectedAction = false;
			showClapboard();
		}
		
		private function moveKeyObjectsToFront():void
		{
			Display(hero.get(Display)).moveToFront();
			Display(villain.get(Display)).moveToFront();
			Display(getEntityById("train").get(Display)).moveToFront();
			Display(getEntityById("stage").get(Display)).moveToFront();
			
			for(var i:int = 0; i < obstacles.length; i++)
			{
				Display(getEntityById(obstacles[i]).get(Display)).moveToFront();
			}
		}

		private function showClapboard():void
		{
			takes++;
			saveTakesToServer();
			
			var clapboard:Clapboard = new Clapboard(this.overlayContainer, 3, takes);
			clapboard.removed.addOnce(action);
			addChildGroup(clapboard);
		}
		
		private function action(popup:Group):void
		{
			Dialog(sophia.get(Dialog)).sayById("action");
		}
		
		private function startScene():void
		{
			SceneUtil.lockInput(this, false);
			startBackGround();
			CharUtils.setAnim(hero, Run);
			SceneUtil.addTimedEvent(this, new TimedEvent(timeBetweenActions, 1, cueAction));
		}
		
		private function cueAction():void
		{
			currentAction = obstacles[actionNumber % 3];
			
			Dialog(sophia.get(Dialog)).sayById(currentAction);
			trace("cue action");
			SceneUtil.addTimedEvent(this, new TimedEvent(actionReminderTime, 0, remindAction), "reminder");
		}
		
		private function remindAction():void
		{
			trace("need i remind you?");
			if(selectedAction)
				SceneUtil.getTimer(this, "reminder").timedEvents.pop();
			else
				Dialog(sophia.get(Dialog)).sayById("need " + currentAction);
		}
		
		private function selectOption(action:String):void
		{
			selectedAction = true;
			if(action == currentAction)
				startAction();
			else
				sayWrongAction();
		}
		
		private function sayWrongAction():void
		{
			shellApi.triggerEvent("wrong");
			selectedAction = false;
			wrongActions++;
			var randomPhraseNumber:Number = Math.random();
			if(randomPhraseNumber < .33)
				Dialog(sophia.get(Dialog)).sayById("all wrong");
			else
			{
				if(randomPhraseNumber > .66)
					Dialog(sophia.get(Dialog)).sayById("wrong cue");
				else
					Dialog(sophia.get(Dialog)).sayById("not in script");
			}
		}
		
		private function checkIfLoose():void
		{
			if(wrongActions >= wrongActionsAllowed)
				Dialog(sophia.get(Dialog)).sayById("disaster");
		}
		
		private function startAction():void
		{
			shellApi.triggerEvent("right");
			SceneUtil.lockInput(this);
			switch(currentAction)
			{
				case obstacles[0]:// buffalo
				{
					setUpBuffalo();
					break
				}
				case obstacles[1]:// tornado
				{
					setUpTornado();
					break;
				}
				case obstacles[2]:// villain
				{
					setUpVillain();
					break;
				}
			}
		}
		
		private function setUpVillain():void
		{
			if(actionNumber == sceneActions)// the third and final time the villain appears
			{
				villain.remove(FollowClipInTimeline);
				CharUtils.getPart(villain, CharUtils.LEG_BACK).get(Display).visible = true;
				CharUtils.getPart(villain, CharUtils.FOOT_BACK).get(Display).visible = true;
				
				Spatial(villain.get(Spatial)).x = startPoint.x;
				Spatial(villain.get(Spatial)).y = hero.get(Spatial).y;
				CharUtils.setAnim(villain, Run);
				var tween:Tween = new Tween();
				tween.to(villain.get(Spatial),5,{x:420, onComplete:endOfTheLine});
				villain.add(tween);
				
				var path:Vector.<Point> = new Vector.<Point>();
				path.push(jumpPoint,movePoint);
				SceneUtil.addTimedEvent(this, new TimedEvent(.75, 1, Command.create(jump, path)));
				
				var train:Entity = getEntityById("train");
				tween = new Tween();
				tween.to(train.get(Spatial),5,{x:-850, ease:Linear.easeNone, onComplete:stopTrain});
				train.add(tween);
				train.remove(Sleep);
				Audio(train.get(Audio)).play("effects/squeaky_motor_01_L.mp3",true);
			}
			else
			{
				var donkey:Entity = getEntityById(obstacles[2]+"Anim");
				Timeline(donkey.get(Timeline)).gotoAndPlay(0);
				CharUtils.getPart(villain, CharUtils.LEG_BACK).get(Display).visible = false;
				CharUtils.getPart(villain, CharUtils.FOOT_BACK).get(Display).visible = false;
			}
		}
		
		private function stopTrain():void
		{
			Audio(getEntityById("train").get(Audio)).stop("effects/squeaky_motor_01_L.mp3","effects");
			stopBackGround();
		}
		
		private function ridingDonkey(label:String, donkey:Entity):void
		{
			var timeline:Timeline = donkey.get(Timeline);
			trace(label);
			
			if(label =="drop"|| label == "rise")
				Audio(donkey.get(Audio)).play("effects/squeaky_motor_01_L.mp3");
			if(label =="hold")
				Audio(donkey.get(Audio)).play("effects/rope_strain_01.mp3");
			if(label == "twirlPistol")
				CharUtils.setAnim(villain, TwirlPistol);
			if(label == "ending")
			{
				timeline.gotoAndStop(timeline.currentIndex);
				completeAnimation();
				return;
			}
		}
		
		private function endOfTheLine():void
		{
			CharacterGroup( super.getGroupById("characterGroup")).addFSM(villain);
			CharacterGroup( super.getGroupById("characterGroup")).addFSM(hero);
			
			CharUtils.setAnim(villain, Stand);
			CharUtils.setAnim(hero, Stand);
			
			Dialog(hero.get(Dialog)).sayById("end of the line");
		}
		
		private function kickOffVillain():void
		{
			CharUtils.setAnim(hero, Attack);
			Timeline( hero.get(Timeline)).handleLabel("trigger",villainFalls);
		}
		
		private function villainFalls():void
		{
			Audio(hero.get(Audio)).play("effects/whack_01.mp3");
			CharUtils.setAnim(villain, Hurt);
			CharUtils.setAnim(hero, Proud);
			hero.remove(FSMControl);
			hero.remove(FSMMaster);
			FSMControl( villain.get(FSMControl)).setState("hurt");
			
			var motion:Motion = villain.get(Motion);
			motion.velocity = new Point(100, -250);
			motion.acceleration = new Point(0, 1700);
			villain.remove(MotionBounds);
			SceneUtil.addTimedEvent(this,new TimedEvent(1, 1, Command.create(printIt)));
		}
		
		private function printIt():void
		{
			Dialog( sophia.get(Dialog)).sayById("print it");
		}
		
		private function setUpTornado():void
		{
			var tornado:Entity = getEntityById(obstacles[1]+"Anim");
			Timeline(tornado.get(Timeline)).gotoAndPlay(0);
			
			
			var tumbleStartDistance:Number = 150;
			
			tumbleWeeds = new MovieClip();
			tumbleWeeds = getAsset("tumble_weeds.swf") as MovieClip;
			
			var tumble1:Entity = EntityUtils.createSpatialEntity(this, tumbleWeeds.tumbleWeed1, _hitContainer);
			tumble1.add(new Id("tumble1"));
			var tween:Tween = new Tween();
			tween.to(tumble1.get(Spatial), 3, {x:- tumbleWeeds.width, ease:Linear.easeNone, onComplete:removeTumbles});
			
			tumble1.add(tween);
			Spatial(tumble1.get(Spatial)).scaleX = - .5;
			Spatial(tumble1.get(Spatial)).scaleY = - .5;
			Spatial(tumble1.get(Spatial)).x = startPoint.x + tumbleStartDistance;
			Spatial(tumble1.get(Spatial)).y = startPoint.y;
			//Sleep(tumble1.get(Sleep)).ignoreOffscreenSleep = true;
			
			var tumble2:Entity = EntityUtils.createSpatialEntity(this, tumbleWeeds.tumbleWeed2, _hitContainer);
			tumble2.add(new Id("tumble2"));
			var tween2:Tween = new Tween();
			tween2.to(tumble2.get(Spatial), 3, {x:- tumbleWeeds.width - tumbleStartDistance, ease:Linear.easeNone});
			
			tumble2.add(tween2);
			Spatial(tumble2.get(Spatial)).scaleX = - .5;
			Spatial(tumble2.get(Spatial)).scaleY = - .5;
			Spatial(tumble2.get(Spatial)).x = startPoint.x;
			Spatial(tumble2.get(Spatial)).y = startPoint.y;
			//Sleep(tumble2.get(Sleep)).ignoreOffscreenSleep = true;
			
			var fan:Entity = getEntityById("fan");
			Audio(fan.get(Audio)).play("effects/fan_engine_01_L.mp3",true);
			tween = new Tween();
			tween.to(fan.get(Spatial), 1, {x:550});
			fan.add(tween);
			
			moveKeyObjectsToFront();
		}
		
		private function removeTumbles():void
		{
			removeEntity(getEntityById("tumble1"), true);
			removeEntity(getEntityById("tumble2"), true);
		}
		
		private function clipEnd(label:String, tornado:Entity):void
		{
			var timeline:Timeline = tornado.get(Timeline);
			trace(label);
			
			if(label == "drop" || label == "rise")
			{
				Audio(tornado.get(Audio)).play("effects/squeaky_motor_01_L.mp3");
			}
			
			if(label == "hold")
			{
				Audio(tornado.get(Audio)).play("effects/rope_strain_01.mp3");
			}
			
			if(label == "ending")
			{
				Audio(tornado.get(Audio)).stop("effects/squeaky_motor_01_L.mp3","effects");
				var fan:Entity = getEntityById("fan");
				Audio(fan.get(Audio)).fade("effects/fan_engine_01_L.mp3",0,.01,1,"effects");
				var tween:Tween = new Tween();
				tween.to(fan.get(Spatial), 1, {x:750});
				fan.add(tween);
				timeline.gotoAndStop(timeline.currentIndex);
				completeAnimation();
			}
		}
		
		private function setUpBuffalo():void
		{
			buffaloClip = getAsset("buffalo.swf") as MovieClip;
			var buffalo:Entity = EntityUtils.createSpatialEntity(this, buffaloClip, _hitContainer);
			buffalo.add(new Audio()).add(new Id(obstacles[0]+"Anim"));
			buffalo.remove(Sleep);
			
			Audio(buffalo.get(Audio)).play("effects/buffalo.mp3");
			
			Spatial(buffalo.get(Spatial)).x = startPoint.x;
			Spatial(buffalo.get(Spatial)).y = startPoint.y;
			var tween:Tween = new Tween();
			tween.to(buffalo.get(Spatial), 3, {x:-buffaloClip.width, ease:Linear.easeNone, onComplete:removeBuffalo});
			buffalo.add(tween);
			
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(jumpPoint,landPoint);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.75, 1, Command.create(jump, path)));
			
			moveKeyObjectsToFront();
		}
		
		private function jump(path:Vector.<Point>):void
		{
			Audio(hero.get(Audio)).play("effects/jump_from_gravel_01.mp3");
			if(hero.get(FSMControl))
			{
				FSMControl(hero.get(FSMControl)).active = true;
				FSMControl(hero.get(FSMControl)).setState("stand");
			}
			CharUtils.followPath(hero,path,run,false,false,new Point(25,25));
		}
		
		private function run(entity:Entity):void
		{
			CharUtils.setAnim(hero, Run);
		}

		private function removeBuffalo():void
		{
			removeEntity(getEntityById("buffaloAnim"));
			completeAnimation();
		}
		
		private function completeAnimation():void
		{
			currentAction = "";
			selectedAction = false;
			actionNumber++;
			SceneUtil.lockInput(this, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(timeBetweenActions, 1, cueAction));
		}
		
		private function startBackGround():void
		{
			var backGround:Entity = getEntityById("backdropAnime");
			Audio(backGround.get(Audio)).play("effects/treadmill_servo_01_L.mp3",true,null,.6);
			Timeline(backGround.get(Timeline)).gotoAndPlay(0);
			for(var i:int = 1; i <= 5; i++)
			{
				var gear:Entity = getEntityById("gear"+i);
				Timeline(gear.get(Timeline)).gotoAndPlay(0);
			}
		}
		
		private function stopBackGround():void
		{
			var backGround:Entity = getEntityById("backdropAnime");
			Audio(backGround.get(Audio)).fade("effects/treadmill_servo_01_L.mp3",0,.01,.6,"effects");
			Timeline(backGround.get(Timeline)).gotoAndStop(0);
			for(var i:int = 1; i <= 5; i++)
			{
				var gear:Entity = getEntityById("gear"+i);
				Timeline(gear.get(Timeline)).gotoAndStop(0);
			}
		}
		
		private function setUpNpcs():void
		{
			hero = getEntityById("hero");
			hero.remove(Interaction);
			hero.remove(SceneInteraction);
			ToolTipCreator.addToEntity(hero, ToolTipType.ARROW);
			CharUtils.moveToTarget(hero,hero.get(Spatial).x, hero.get(Spatial).y);//just to get it so the npcs audio will work right away
			
			landPoint = new Point(hero.get(Spatial).x, hero.get(Spatial).y);
			jumpPoint = new Point(hero.get(Spatial).x, hero.get(Spatial).y - 200);
			movePoint = new Point(360, hero.get(Spatial).y);
			
			CharacterGroup(getGroupById("characterGroup")).addAudio(hero);
			
			villain = getEntityById("villain");
			villain.remove(Interaction);
			villain.remove(SceneInteraction);
			villain.remove(Sleep);
			ToolTipCreator.addToEntity(villain, ToolTipType.ARROW);
			
			CharacterGroup(getGroupById("characterGroup")).addAudio(villain);
			
			sophia = getEntityById("sophia");
			sophia.remove(Interaction);
			sophia.remove(SceneInteraction);
			sophia.remove(Sleep);
			sophia.get(Spatial).y = shellApi.camera.camera.areaHeight + 75;
			sophia.get(Spatial).x = shellApi.camera.camera.areaHeight * 9.0 / 10.0;
		}
		
		private function setUpBackGround():void
		{
			var backGround:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["backdropAnime"],_hitContainer);
			backGround.add(new Audio()).add( new Id("backdropAnime"));
			Audio(backGround.get(Audio)).play("effects/treadmill_servo_01_L.mp3",true);
			TimelineUtils.convertClip(_hitContainer["backdropAnime"],this, backGround, null, false);
			Display(backGround.get(Display)).moveToBack();
			for(var i:int = 1; i <= 5; i++)
			{
				var gear:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["g"+i],_hitContainer);
				gear.add(new Id("gear"+i));
				TimelineUtils.convertClip(_hitContainer["g"+i], this, gear, null, false);
			}
		}
		
		private function setUpObstacles():void
		{
			var train:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["trainClip"],_hitContainer);
			train.add(new Audio()).add( new Id("train"));
			
			startPoint = new Point(750, 260);
			
			//tornado will play anim and fan will blow tumble weeds accross stage
			
			var tornado:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["tornado"], _hitContainer);
			tornado.add(new Audio()).add(new Id("tornadoAnim"));
			TimelineUtils.convertClip(hitContainer["tornado"], this, tornado, null, false);
			Timeline(tornado.get(Timeline)).labelReached.add(Command.create(clipEnd, tornado));
			tornado.remove(Sleep);
			
			var fan:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["fan"], _hitContainer);
			fan.add(new Audio()).add(new Id("fan"));
			
			//villain riding a donkey
			var donkey:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["donkey"], _hitContainer);
			
			// weird parenting of animation made this extra setp necisary
			var donkeyAnim:Entity = TimelineUtils.convertClip(_hitContainer["donkey"].anim, this, donkeyAnim, donkey, false);
			donkeyAnim.add(new Audio()).add(new Id("donkeyAnim"));
			donkeyAnim.remove(Sleep);
			
			Timeline(donkeyAnim.get(Timeline)).labelReached.add(Command.create(ridingDonkey, donkeyAnim));
			
			var donkeyClip:MovieClip = _hitContainer["donkey"].anim;
			
			villain.add(new FollowClipInTimeline(donkeyClip.body, new Point( 5, - 35), donkeyAnim.get(Spatial)));
			
			var stage:Entity = EntityUtils.createDisplayEntity(this, _hitContainer["midVector"], _hitContainer);
			stage.add(new Audio()).add(new Id("stage"));
			Display(stage.get(Display)).moveToFront();
			
			addSystem( new FollowClipInTimelineSystem(), SystemPriorities.animate);
		}
		
		private function setUpButtons():void
		{
			for(var i:int = 0; i < obstacles.length; i++)
			{
				var buttonName:String = obstacles[i];
				var btn:String = "btn" + captializeFirstLetter(buttonName);//name of the button in the swf
				var button:Entity = EntityUtils.createSpatialEntity(this, _hitContainer[btn], _hitContainer);
				button.add(new Id(buttonName));
				TimelineUtils.convertClip(_hitContainer[btn], this, button, null, false);
				
				var interaction:Interaction = InteractionCreator.addToEntity(button, [InteractionCreator.DOWN, InteractionCreator.OVER, InteractionCreator.OUT], _hitContainer[btn])
				interaction.down.add(buttonDown);
				interaction.over.add(buttonOver);
				interaction.out.add(buttonOut);
				
				ToolTipCreator.addToEntity(button);
			}
		}
		
		private function captializeFirstLetter(word:String):String
		{
			var firstLetter:String = word.charAt();
			var restOfLetters:String = word.substr(1, word.length);
			var upperCaseName:String = firstLetter.toUpperCase() + restOfLetters;
			return upperCaseName;
		}
		
		private function buttonOut(button:Entity):void
		{
			Timeline(button.get(Timeline)).gotoAndStop("out");
		}
		
		private function buttonOver(button:Entity):void
		{
			Timeline(button.get(Timeline)).gotoAndStop("over");
		}
		
		private function buttonDown(button:Entity):void
		{
			selectOption(button.get(Id).id);
			Timeline(button.get(Timeline)).gotoAndStop("down");
		}
	}
}