package game.scenes.backlot.soundStage2
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Zone;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.KissStart;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Wave;
	import game.data.character.LookData;
	import game.data.game.GameEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.shared.emitters.RainEmitter;
	import game.scenes.backlot.shared.popups.Clapboard;
	import game.components.entity.FollowClipInTimeline;
	import game.systems.entity.FollowClipInTimelineSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.ZoneHitSystem;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.Steady;
	
	public class SoundStage2 extends PlatformerGameScene
	{
		public function SoundStage2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/soundStage2/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var backlot:BacklotEvents;
		
		private var rainLevel:int = 0;
		
		private var rainEmitter:RainEmitter;
		private var dripEmitter:RainEmitter;
		
		private var sophia:Entity;
		private var carson:Entity;
		private var gracie:Entity;
		private var cameraMan:Entity;
		
		private var originalLook:LookData;
		private var originalBalloonPosition:Point;
		private var originalGraciePosition:Point;
		private var started:Boolean;
		
		private var makeUpStation:MakeUpStation;
		
		private var takes:int = 0;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			backlot = super.events as BacklotEvents;
			super.shellApi.eventTriggered.add( onEventTriggered );
			
			addSystem( new ZoneHitSystem(), SystemPriorities.checkCollisions);
			addSystem( new FollowClipInTimelineSystem(), SystemPriorities.animate);
			
			started = false;
			
			setUpGulls();
			setUpBalloons();
			setUpHairDryer();
			setUpLevers();
			setUpRain();
			setUpDressingRoom();
			setUpMakeupStation();
			setUpNPCs();
			setUpStage();
			
			if(shellApi.profileManager.active.userFields[shellApi.island] != null)
			{
				if(shellApi.profileManager.active.userFields[shellApi.island]["stage2"] != null)
					takes = shellApi.getUserField("stage2",shellApi.island);
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
			shellApi.setUserField("stage2",takes,shellApi.island,true);
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			trace(event);
			
			if(event == backlot.GET_THE_SCRIPT)
			{
				SceneUtil.lockInput(this, false);
			}
			
			if(event == backlot.ORDERED_QUESTION)
			{
				var sophiaDialog:Dialog = sophia.get(Dialog);
				if(shellApi.checkEvent(backlot.ORDERED_PAGES))
					sophiaDialog.sayById("right order");
				else
					sophiaDialog.sayById("not in order");
			}
			
			if(event == backlot.FINISHED_TALKING || event == GameEvent.GOT_ITEM + backlot.HEAD_SHOT)
			{
				SceneUtil.lockInput(this, false);
			}
			
			if(event == backlot.ACTION)
			{
				getReady();
			}
			
			if(event == backlot.DIALOG_OPTION )
			{
				SceneUtil.lockInput(this, false);
			}
			
			if(event == backlot.AGAIN)
			{
				SceneUtil.lockInput(this);
				setUpFade(true);
			}
			
			if(event == backlot.STOP)
			{
				takeFive();
			}
			
			if(event == backlot.PRINT)
			{
				setUpRain(0);
				SceneUtil.lockInput(this);
				SceneUtil.setCameraTarget(this, carson);
			}
			if(event == backlot.WRAP_IT_UP)
			{
				completStage();
			}
			
			if(event == backlot.CONTINUE_SCENE)
			{
				SceneUtil.lockInput(this);
			}
			
			if(event == backlot.EXCLAIM)
			{
				CharUtils.setAnim(player, Grief);
			}
			
			if(event == backlot.START_RAIN)
			{
				SceneUtil.lockInput(this, false);
				Dialog(gracie.get(Dialog)).setCurrentById("options2");
				Dialog(gracie.get(Dialog)).sayById("options2");
				setUpRain(.5);
			}
			
			if(event == backlot.OFFER_COMPASS)
			{
				CharUtils.setAnim(player, Salute);
				performAction(backlot.OFFER_COMPASS, 2);
			}
			if(event == backlot.OFFER_KISS)
			{
				CharUtils.setAnim(player, KissStart);
				performAction(backlot.OFFER_KISS, 2);
			}
			if(event == backlot.OFFER_FLOWER)
			{
				CharUtils.setAnim(player, Place);
				performAction(backlot.OFFER_FLOWER, 2);
			}
			
			if(event == backlot.BALLOON_ARRIVES)
			{
				balloonArrives();
			}
			if(event == backlot.ENTER_BALLOON)
			{
				getInBalloon();
			}		
			if(event == backlot.FLY_AWAY)
			{
				SceneUtil.lockInput(this);
				takeOff();
			}
			
			if(event == backlot.DARN_IT)
			{
				CharUtils.setAnim(player, Grief);
				Dialog(player.get(Dialog)).sayById("darn it");
				performAction(backlot.DARN_IT, 4);
			}
			if(event == backlot.GOTCHA)
			{
				CharUtils.setAnim(player, Score);
				Dialog(player.get(Dialog)).sayById("gotcha");
				performAction(backlot.GOTCHA, 4);
			}
			if(event == backlot.NOOOOOO)
			{
				CharUtils.setAnim(player, Grief);
				Dialog(player.get(Dialog)).sayById("no");
				performAction(backlot.NOOOOOO, 4);
			}
		}
		
		private function takeFive():void
		{
			started = false;
			SceneUtil.lockInput(this);
			setUpFade(false);
			SceneInteraction(gracie.get(SceneInteraction)).reached.add(stopAndListen);
			Dialog(gracie.get(Dialog)).setCurrentById("dont worry");
			Dialog(sophia.get(Dialog)).setCurrentById("back to dressing room");
			Dialog(carson.get(Dialog)).setCurrentById("back to dressing room");
		}
		
		private function completStage():void
		{
			started = false;
			removeDressingRoom();
			setUpFade(false);
			shellApi.triggerEvent(backlot.COMPLETE_STAGE_2, true);
			Dialog(sophia.get(Dialog)).setCurrentById("nice work");
			Dialog(carson.get(Dialog)).setCurrentById("sublime");
			Dialog(gracie.get(Dialog)).setCurrentById("thrill");
			SceneInteraction(carson.get(SceneInteraction)).reached.remove(stopAndListen);
			SceneInteraction(sophia.get(SceneInteraction)).reached.remove(stopAndListen);
		}
		
		private function performAction(event:String, optionNumber:int):void
		{
			SceneUtil.lockInput(this);
			SceneUtil.addTimedEvent(super, new TimedEvent(3,1,Command.create(checkAction, event, optionNumber)));
		}
		
		private function checkAction(event:String, optionNumber:int):void//, event:String, timeline:Timeline):void
		{
			switch(optionNumber)
			{
				case 2:
				{
					if(event == backlot.OFFER_COMPASS)
						Dialog(gracie.get(Dialog)).sayById("what is it");
					else
						wrongAction();
					break;
				}
				case 4:
				{
					if(event == backlot.NOOOOOO)
						Dialog(player.get(Dialog)).sayById("guess");
					else
						wrongLine();
					break;
				}
			}
		}
		
		private function wrongLine():void
		{
			setUpRain(0);
			Dialog(carson.get(Dialog)).sayById("cut line");
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this, carson);
		}
		
		private function wrongAction():void
		{
			setUpRain(0);
			Dialog(carson.get(Dialog)).sayById("cut action");
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this, carson);
		}
		
		private function setUpStage():void
		{
			var stage:Entity = EntityUtils.createSpatialEntity(this, new MovieClip(), _hitContainer);
			stage.add(new Id("stageZone"));
			var stageDisplay:Display = stage.get(Display);
			var display:MovieClip = stageDisplay.displayObject as MovieClip;
			display.graphics.lineTo(450, 0);
			display.graphics.lineTo(450, 500);
			display.graphics.lineTo( 0, 500);
			var spatial:Spatial = stage.get(Spatial);
			spatial.x = 800;
			spatial.y = 300;
			stage.add(new Zone());
			
			var zone:Zone = stage.get(Zone);
			zone.exitted.add(leftStage);
		}
		
		private function leftStage(zone:String, actor:String):void
		{
			if(actor == "player" && started)
			{
				SceneUtil.lockInput(this);
				SceneUtil.setCameraTarget(this, carson);
				Dialog(carson.get(Dialog)).sayById("cut leave");
			}
		}
		
		private function setUpNPCs():void
		{
			originalLook = SkinUtils.getLook(player);
			
			sophia = getEntityById("char1");
			gracie = getEntityById("char2");
			cameraMan = getEntityById("char3");
			carson = getEntityById("char4");
			
			CharUtils.setDirection(sophia, true);
			CharUtils.setDirection(gracie, true);
			CharUtils.setDirection(cameraMan, true);
			CharUtils.setDirection(carson, true);
			
			originalGraciePosition = new Point(gracie.get(Spatial).x, gracie.get(Spatial).y);
			
			if(shellApi.checkEvent(backlot.COMPLETE_STAGE_2))
			{
				Dialog(sophia.get(Dialog)).setCurrentById("nice work");
				Dialog(carson.get(Dialog)).setCurrentById("sublime");
				Dialog(gracie.get(Dialog)).setCurrentById("thrill");
			}
			else
			{
				if(!super.shellApi.checkEvent(backlot.COLLECTED_SCRIPT))
				{
					Dialog(sophia.get(Dialog)).setCurrentById("where is goldie");
					SceneInteraction(sophia.get(SceneInteraction)).reached.add(stopAndListen);
					
					removeEntity(gracie);
					removeEntity(cameraMan);
					removeEntity(carson);
				}
				else
				{
					Dialog(sophia.get(Dialog)).setCurrentById("found pages");
					SceneInteraction(sophia.get(SceneInteraction)).reached.add(stopAndListen);
					if(super.shellApi.checkEvent(backlot.ORDERED_PAGES))
					{
						if(super.shellApi.checkEvent(backlot.FOUND_GRACIE))
						{
							Dialog(sophia.get(Dialog)).setCurrentById("act the navigator");
							
							Dialog(carson.get(Dialog)).setCurrentById("dont got all day");
							SceneInteraction(carson.get(SceneInteraction)).reached.add(stopAndListen);
							
							Dialog(gracie.get(Dialog)).setCurrentById("your my support");
							SceneInteraction(gracie.get(SceneInteraction)).reached.add(stopAndListen);
						}
						else
						{
							removeEntity(gracie);
							removeEntity(cameraMan);
							removeEntity(carson);
						}
					}
				}
			}
		}
		
		private function stopAndListen(player:Entity, me:Entity):void
		{
			SceneUtil.lockInput(this);
		}
		
		private function setUpMakeupStation():void
		{
			var mirror:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["mirror"], _hitContainer);
			mirror.add(new Id("makeUpStation"));
			Display(mirror.get(Display)).moveToBack();
			
			//if(SkinUtils.getSkinPart(player, SkinUtils.GENDER).value == SkinUtils.GENDER_FEMALE)
			//	return;
			
			mirror.add(new SceneInteraction());
			InteractionCreator.addToEntity(mirror, [InteractionCreator.CLICK],this._hitContainer["mirror"]);
			var interaction:SceneInteraction = mirror.get(SceneInteraction);
			interaction.reached.add(putOnMakeUp);
			ToolTipCreator.addToEntity(mirror);
		}
		
		private function putOnMakeUp(player:Entity, entity:Entity):void
		{
			makeUpStation = super.addChildGroup( new MakeUpStation( super.overlayContainer )) as MakeUpStation;
		}
		
		private function setUpDressingRoom():void
		{
			var dressingRoom:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["dressingRoom"], _hitContainer);
			dressingRoom.add(new Id("dressingRoom"));
			var display:Display = dressingRoom.get(Display);
			display.moveToBack();
			
			if(shellApi.checkEvent(backlot.COMPLETE_STAGE_2))//if commented it is only for testing purposes
				return;
			
			dressingRoom.add(new SceneInteraction());
			InteractionCreator.addToEntity(dressingRoom,[InteractionCreator.CLICK],this._hitContainer["dressingRoom"]);
			var interaction:SceneInteraction = dressingRoom.get(SceneInteraction);
			interaction.reached.add(getDressed);
			ToolTipCreator.addToEntity(dressingRoom);
		}
		
		private function removeDressingRoom():void
		{
			var dressingRoom:Entity = getEntityById("dressingRoom");
			dressingRoom.remove(SceneInteraction);
			dressingRoom.remove(Interaction);
			ToolTipCreator.addToEntity(dressingRoom, ToolTipType.NAVIGATION_ARROW);
		}
		
		private function getDressed(player:Entity, dressingRoom:Entity):void
		{
			var posY:Number = player.get(Spatial).y;
			
			var minY:Number = 450
			
			if(posY > minY)
				player.get(Spatial).y -= (posY - minY)// making sure player gets on top of platform
			
			player.get(Display).visible = false;
			SceneUtil.lockInput(this);
			setUpFade(true);
		}
		
		private function setUpFade(start:Boolean):void// start determines if you should start the acting sequence(true) or go back to the dressing room (false)
		{
			var darkFade:Entity = EntityUtils.createSpatialEntity(this, new MovieClip(),this.overlayContainer);
			darkFade.add(new Id("darkFade"));
			var darkFadeDisplay:Display = darkFade.get(Display);
			darkFadeDisplay.moveToBack();
			var left:Number = -super.shellApi.camera.camera.viewport.width /2 - 100;
			var width:Number = super.shellApi.camera.camera.viewport.width + 200;
			var top:Number = -super.shellApi.camera.camera.viewport.height /2 - 300;
			var height:Number = super.shellApi.camera.camera.viewport.height + 200;
			var display:MovieClip = darkFadeDisplay.displayObject as MovieClip;
			display.graphics.beginFill(0);
			display.graphics.moveTo( left, top);
			display.graphics.lineTo(width, top);
			display.graphics.lineTo(width, height);
			display.graphics.lineTo( left, height);
			display.graphics.endFill();
			display.alpha =0;
			darkFadeDisplay.alpha = 0;
			var position:Spatial = darkFade.get(Spatial);
			position.x = 0;
			position.y = 0;
			
			SceneUtil.addTimedEvent(super, new TimedEvent(.1,21,Command.create(fade, start)));
		}
		
		private function fade(start:Boolean):void
		{
			var darkFade:Display = getEntityById("darkFade").get(Display);
			
			if(darkFade.alpha >= 1)// this is when the screen goes black
			{
				resetGracieAndBalloon();
				setUpRain(0);
				if(start)
					startSceneSequence();
				else
					goBackToDressingRoom();
				return;
			}
			darkFade.alpha += .05;
		}
		
		private function goBackToDressingRoom():void
		{
			SceneUtil.setCameraTarget(this, player);
			player.get(Spatial).x = getEntityById("dressingRoom").get(Spatial).x;
			player.get(Spatial).y = getEntityById("dressingRoom").get(Spatial).y;
			
			FSMControl(player.get(FSMControl)).active = true;
			
			SkinUtils.applyLook(player, originalLook);
			player.get(Display).visible = true;
			
			SceneUtil.addTimedEvent(super, new TimedEvent(.1,21,Command.create(fadeIn, false)));
		}
		
		private function startSceneSequence():void
		{
			SceneUtil.setCameraTarget(this, player);
			player.get(Spatial).x = gracie.get(Spatial).x + 100;
			player.get(Spatial).y = gracie.get(Spatial).y;
			
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "scroll", false);
			SkinUtils.setSkinPart(player, SkinUtils.FACIAL, "oldpilot2", false);
			SkinUtils.setSkinPart(player, SkinUtils.OVERSHIRT, "frankenstein", false);
			SkinUtils.emptySkinPart(player, SkinUtils.OVERPANTS, false);
			SkinUtils.setSkinPart(player, SkinUtils.SHIRT, "oldpilot", false);
			SkinUtils.setSkinPart(player, SkinUtils.HAIR, "sponsorfarmmom", false);
			
			CharUtils.setDirection(player, false);
			player.get(Display).visible = true;
			
			SceneUtil.addTimedEvent(super, new TimedEvent(.1,21,Command.create(fadeIn, true)));
		}
		
		private function fadeIn(start:Boolean):void
		{
			var darkFade:Display = getEntityById("darkFade").get(Display);
			
			if(darkFade.alpha <= 0)// this is when the screen is back to normal
			{
				if(start)
				{
					if(started)
						getReady();
					else
						quietOnSet();
				}
				else
					reset();
				return;
			}
			darkFade.alpha -= .05;
		}
		
		private function resetGracieAndBalloon():void
		{
			gracie.get(Spatial).x = originalGraciePosition.x;
			gracie.get(Spatial).y = originalGraciePosition.y;
			CharUtils.setDirection(gracie, true);
			
			var motion:CharacterMotionControl = gracie.get(CharacterMotionControl);
			if(motion)
			{
				motion.gravity = 1700;
				gracie.remove(CharacterMotionControl);
			}
			
			var balloon:Entity = getEntityById("balloonCover");
			balloon.get(Spatial).x = originalBalloonPosition.x;
			balloon.get(Spatial).y = originalBalloonPosition.y;
			balloon.get(Display).visible = false;
		}
		
		private function reset():void
		{
			SceneUtil.lockInput(this, false);
			removeEntity(getEntityById("darkFade"));
		}
		
		private function quietOnSet():void
		{
			SceneUtil.setCameraTarget(this, carson);
			Dialog(carson.get(Dialog)).say("quiet");
		}
		
		private function getReady():void
		{
			takes++;
			saveTakesToServer();
			
			started = true;
			removeEntity(getEntityById("darkFade"));
			SceneUtil.setCameraTarget(this, player);
			var clapboard:Clapboard = new Clapboard(this.overlayContainer, 2, takes);
			clapboard.removed.addOnce(action);
			this.addChildGroup(clapboard);
		}
		
		private function action(popup:Group):void
		{
			Dialog(gracie.get(Dialog)).say("start");
			SceneInteraction(gracie.get(SceneInteraction)).reached.remove(stopAndListen);
			Dialog(gracie.get(Dialog)).setCurrentById("options1");
		}
		
		private function setUpRain(rainSpeed:Number = 0):void
		{
			trace(rainSpeed);
			// if rain has already been set up
			if(super.getEntityById("rain"))
			{
				// just change its rate
				rainEmitter.counter = new Steady(rainSpeed * 50);
				dripEmitter.counter = new Steady(5 + rainSpeed * 5);
			}
			else
			{
				//otherwise you need to instantiate it
				rainEmitter = new RainEmitter();
				rainEmitter.init(rainSpeed * 50);
				var entity:Entity = EmitterCreator.create(this, _hitContainer, rainEmitter, 0, 0, null, "rain", null, false);
				
				//var audioRange:AudioRange = new AudioRange(1500, .1, 1, Quad.easeIn);
				entity.add(new Audio());//.add(audioRange);
				
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = 700;
				spatial.y = 295;
				
				dripEmitter = new RainEmitter();
				
				dripEmitter.init(5 + rainSpeed * 5, .5, 0);
				
				var drips:Entity = EmitterCreator.create(this, this._hitContainer, dripEmitter, 0, 0, null, "drips", null, false);
				
				spatial = drips.get(Spatial);
				spatial.x = 700;
				spatial.y = 875;
				
				var dripper:Emitter = drips.get(Emitter);
				dripper.start = true;
				dripper.emitter.counter.resume();
			}
			var emitter:Emitter = super.getEntityById("rain").get(Emitter);
			var rainAudio:Audio = getEntityById("rain").get(Audio);
			var bublerAudio:Audio = getEntityById("bubbles").get(Audio);
			var leverAudio:Audio = getEntityById("lever").get(Audio);
			
			var waterHoseTimeline:Timeline = Timeline(getEntityById("hose").get(Timeline));
			var waterBubblesTimeline:Timeline = Timeline(getEntityById("bubbles").get(Timeline));
			
			if(rainSpeed > 0)
			{
				emitter.start = true;
				emitter.emitter.counter.resume()
				waterHoseTimeline.gotoAndPlay(0);
				waterBubblesTimeline.gotoAndPlay(0);
				bublerAudio.play("ambient/fish_tank_filter.mp3",true,SoundModifier.POSITION);
				leverAudio.play("effects/bus_engine_idle_01_L.mp3",true,SoundModifier.POSITION);
				if(rainSpeed <=1)
				{
					rainAudio.play("ambient/rain_light.mp3",true, SoundModifier.POSITION,.5);
				}
				else
				{
					rainAudio.stop("ambient/rain_light.mp3", "effects");
					rainAudio.play("ambient/rain_heavy_01.mp3",true, SoundModifier.POSITION,.5);
				}
			}
			else
			{
				rainAudio.fade("ambient/rain_heavy_01.mp3",0,.01,.5,"effects");
				bublerAudio.fade("ambient/fish_tank_filter.mp3",0,.01,1,"effects");
				leverAudio.fade("effects/bus_engine_idle_01_L.mp3",0,.01,1,"effects");
				emitter.emitter.counter.stop();
				waterHoseTimeline.gotoAndStop(0);
				waterBubblesTimeline.gotoAndStop(0);
			}
		}
		
		private function setUpLevers():void
		{
			MovieClip(_hitContainer["console"]).mask = _hitContainer["consoleMask"];
			// levers are used to change water flow on the scene
			var lever:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["lever"], _hitContainer);
			Display(lever.get(Display)).moveToBack();
			
			var audioRange:AudioRange = new AudioRange(1500, .1, 1, Quad.easeIn);
			lever.add(new Audio()).add(audioRange);
			
			//Display(lever.get(Display)).displayObject.mask = _hitContainer["doorMask"];
			TimelineUtils.convertClip(_hitContainer["lever"], this, lever, null, false);
			lever.add(new Id("lever"));
			lever.add(new SceneInteraction());
			InteractionCreator.addToEntity(lever,[InteractionCreator.CLICK],this._hitContainer["lever"]);
			var interaction:SceneInteraction = lever.get(SceneInteraction);
			interaction.reached.add(clickLever);
			ToolTipCreator.addToEntity(lever);
			
			var waterHose:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["hose"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["hose"], this, waterHose, null, false);
			waterHose.add(new Id("hose"));
			Display(waterHose.get(Display)).displayObject.mask = _hitContainer["hoseMask"];
			
			var waterBubbles:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["bubbles"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["bubbles"], this, waterBubbles, null, false);
			waterBubbles.add(new Id("bubbles"));
			Display(waterBubbles.get(Display)).displayObject.mask = _hitContainer["bubblerMask"];
			Display(waterBubbles.get(Display)).moveToBack();
			waterBubbles.add(new Audio()).add(audioRange);
			
		}
		
		private function clickLever(player:Entity, lever:Entity):void
		{
			var timeLine:Timeline = lever.get(Timeline);
			timeLine.gotoAndPlay(1);
			timeLine.labelReached.removeAll();
			timeLine.labelReached.add(Command.create(stopLever, timeLine));
		}
		
		private function stopLever(label:String, timeline:Timeline):void
		{
			if(label == "beginning")
			{
				timeline.gotoAndStop(1);
				
				rainLevel++;
				
				if(rainLevel > 2)
					rainLevel = 0;
				else
					upSetGracie();
				
				setUpRain(rainLevel);
			}
		}
		
		private function upSetGracie():void
		{
			if(rainLevel == 1)
				Dialog(gracie.get(Dialog)).sayById("not yet");
			if(rainLevel == 2)
				Dialog(gracie.get(Dialog)).sayById("turn it off");
			
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this, gracie);
			CharUtils.setAnim(gracie, Grief,false,0,0,true);
			CharUtils.setAnim(cameraMan, Laugh);
			SceneUtil.addTimedEvent(super, new TimedEvent(3.5,1,Command.create(turnOffWaterPlz)));
		}
		
		private function turnOffWaterPlz():void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
			CharUtils.setDirection(gracie, true);
			CharUtils.setAnim(gracie, Stand);
			//still having issues where animation doesnt reset and replays grief animation after every dialog she says
			trace(RigAnimation( gracie.get(RigAnimation)).current.data.name);
		}
		
		private function setUpHairDryer():void
		{
			var hairDrier:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["hairDrier"], _hitContainer);
			var display:Display = hairDrier.get(Display);
			display.moveToBack();
			TimelineUtils.convertClip(_hitContainer["hairDrier"], this, hairDrier, null, false);
			var hairTime:Timeline = hairDrier.get(Timeline);
			hairTime.handleLabel("loop",Command.create(loop, hairTime),false);
			hairTime.paused = true;
			hairDrier.add(new Audio()).add(new Id("hairDrier"));
			var interaction:Interaction = InteractionCreator.addToEntity(hairDrier,[InteractionCreator.CLICK],this._hitContainer["hairDrier"]);
			interaction.click.add(clickHairDrier);
			ToolTipCreator.addToEntity(hairDrier);
		}
		
		private function loop(timeline:Timeline):void
		{
			trace("loop");
			timeline.gotoAndPlay("on");
		}
		
		private function clickHairDrier(hairDrier:Entity):void
		{
			Audio(hairDrier.get(Audio)).play("effects/switch_02.mp3");
			var timeline:Timeline = hairDrier.get(Timeline);
			timeline.paused = !timeline.paused;
			if(timeline.paused)
				timeline.gotoAndStop("off");
			else
				timeline.gotoAndPlay("on");
		}
		
		private function setUpBalloons():void
		{
			// balloon that drops in
			var balloon:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["balloon"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["balloon"], this, balloon, null, false);
			balloon.add( new Audio()).add( new Id("balloon"));
			balloon.remove(Sleep);
			Display(balloon.get(Display)).moveToBack();
			var balloonTimeline:Timeline = balloon.get(Timeline);
			balloonTimeline.handleLabel("ending",Command.create(balloonLanded, balloonTimeline));
			
			// balloon that gets struck by lightning
			var balloonSmall:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["balloonSmall"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["balloonSmall"], this, balloonSmall, null, false);
			balloonSmall.add(new Audio()).add( new Id("balloonSmall"));
			balloonSmall.remove(Sleep);
			var balloonSmallTimeline:Timeline = balloonSmall.get(Timeline);
			balloonSmallTimeline.labelReached.add(Command.create(balloonSmallLabelReached, balloonSmallTimeline));
			
			// there is a movieclip with in the smallballoon's timeline that needs to get set
			var b:MovieClip = balloonSmall.get(Display).displayObject as MovieClip;
			
			var mask:MovieClip = b.balloon.cover;
			var maskBalloon:Entity = EntityUtils.createSpatialEntity(this, mask,_hitContainer);
			maskBalloon.add(new FollowClipInTimeline(b.balloon, new Point(-278, -4), balloonSmall.get(Spatial)));
			maskBalloon.remove(Sleep);
			//Display(maskBalloon.get(Display)).displayObject.mas
			
			var balloonGraphic:MovieClip = b.balloon.graphic;
			var danglingBallon:Entity = EntityUtils.createSpatialEntity(this,balloonGraphic,_hitContainer);
			danglingBallon.add(new Id("danglingBalloon"));
			TimelineUtils.convertClip(balloonGraphic, this, danglingBallon,null,false);
			Timeline(danglingBallon.get(Timeline)).labelReached.add(Command.create(danglingLabelHandler,danglingBallon.get(Timeline)));
			Display(danglingBallon.get(Display)).visible = false;
			Display(danglingBallon.get(Display)).displayObject.mask = Display(maskBalloon.get(Display)).displayObject;
			danglingBallon.add(new FollowClipInTimeline(b.balloon, new Point(-183, -112.5), balloonSmall.get(Spatial)));
			//balloonGraphic.visible = false;
			danglingBallon.remove(Sleep);
				
			// balloonCover
			var balloonCover:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["balloonCover"],_hitContainer);
			var display:Display = balloonCover.get(Display);
			display.visible = false;
			display.moveToFront();
			balloonCover.add(new Id("balloonCover"));
			originalBalloonPosition = new Point(balloonCover.get(Spatial).x, balloonCover.get(Spatial).y);
		}
		
		
		
		private function balloonArrives():void
		{
			Audio(getEntityById("balloon").get(Audio)).play("effects/rope_strain_01.mp3");
			Timeline(getEntityById("balloon").get(Timeline)).gotoAndPlay(0);
		}
		
		private function getInBalloon():void
		{
			CharUtils.moveToTarget(gracie, gracie.get(Spatial).x - 50, gracie.get(Spatial).y - 100,false,inBalloon);
		}
		
		private function inBalloon(entity:Entity):void
		{
			// making it look like she is in the balloon and making her not continue to fall after jumping
			var balloonCover:Entity = getEntityById("balloonCover");
			balloonCover.get(Display).visible = true;
			CharUtils.setDirection(gracie,true);
			
			var motion:CharacterMotionControl = gracie.get(CharacterMotionControl);
			motion.gravity = 0;
			
			MotionUtils.zeroMotion(gracie, "x");
			MotionUtils.zeroMotion(gracie, "y");

			gracie.get(Spatial).y = balloonCover.get(Spatial).y;
			
			Timeline(getEntityById("balloon").get(Timeline)).gotoAndStop(0);
			
			SceneUtil.lockInput(this, false);
			Dialog(gracie.get(Dialog)).setCurrentById("options3");
		}
		
		private function takeOff():void
		{
			var tweenTime:Number = 5;
			
			var riseHeight:Number = 500;
			
			var gracieTween:Tween = new Tween();
			gracieTween.to(gracie.get(Spatial),tweenTime,{y:gracie.get(Spatial).y - riseHeight, onComplete:rose, ease:Linear.easeOut});
			gracie.add(gracieTween);
			
			var balloonCover:Entity = getEntityById("balloonCover");
			
			var balloonTween:Tween = new Tween();
			balloonTween.to(balloonCover.get(Spatial),tweenTime,{y:balloonCover.get(Spatial).y - riseHeight, ease:Linear.easeOut});
			balloonCover.add(balloonTween);
			
			CharUtils.setAnim(player, Wave);
			setUpRain(2);
		}
		
		private function rose():void
		{
			CharUtils.setDirection(player, true);
			var balloonSmall:Entity = getEntityById("balloonSmall");
			Timeline(balloonSmall.get(Timeline)).gotoAndPlay(0);
			Audio(balloonSmall.get(Audio)).play("effects/squeaky_motor_01_L.mp3",true,null,.6);
		}
		
		private function balloonSmallLabelReached(label:String, timeline:Timeline):void
		{
			var danglineBalloon:Entity = getEntityById("danglingBalloon");
			
			if(label == "start")
			{
				Display(danglineBalloon.get(Display)).visible = true;
				Timeline(danglineBalloon.get(Timeline)).gotoAndPlay("dangle");
			}
			if(label == "ending")
			{
				timeline.gotoAndStop(timeline.currentIndex);
				Dialog(gracie.get(Dialog)).sayById("options4");
				SceneUtil.lockInput(this, false);
				Display(danglineBalloon.get(Display)).visible = false;
			}
			if(label == "fall")
			{
				Audio(getEntityById("balloonSmall").get(Audio)).stop("effects/squeaky_motor_01_L.mp3", "effects");
				Audio(getEntityById("balloonSmall").get(Audio)).play("effects/thunder_clap_01.mp3");
				Timeline(danglineBalloon.get(Timeline)).gotoAndPlay("falling");
			}
		}
		
		private function danglingLabelHandler(label:String, timeline:Timeline):void
		{
			if(label == "loop")
				timeline.gotoAndPlay("dangle");
			if(label == "ending")
				timeline.gotoAndStop(timeline.currentIndex);
		}
		
		private function balloonLanded( timeline:Timeline):void
		{
			timeline.gotoAndStop(timeline.currentIndex);
		}
		
		private function setUpGulls():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var gullName:String = "gull"+i;
				var gull:Entity = EntityUtils.createSpatialEntity(this, _hitContainer[gullName], _hitContainer);
				TimelineUtils.convertClip(_hitContainer[gullName], this, gull, null, false);
				gull.add(new Id(gullName));
				var interaction:Interaction = InteractionCreator.addToEntity(gull,[InteractionCreator.CLICK],this._hitContainer[gullName]);
				interaction.click.add(clickGull);
				ToolTipCreator.addToEntity(gull);
				var display:Display = gull.get(Display);
				display.moveToBack();
				var audioRange:AudioRange = new AudioRange(500, .5, 1, Quad.easeIn);
				gull.add(new Audio()).add(audioRange);
			}
		}
		
		private function clickGull(gull:Entity):void
		{
			Audio(gull.get(Audio)).play("effects/seagull_squawk_01.mp3");
			var timeLine:Timeline = gull.get(Timeline);
			timeLine.gotoAndPlay("gullSquawk");
			timeLine.labelReached.add(Command.create(stopYourSquawkin, timeLine));
		}
		
		private function stopYourSquawkin( label:String, gull:Timeline):void
		{
			trace(label);
			if(label == "stopWaiting")
			{
				gull.gotoAndPlay("gullIdle");
			}
			if(label == "gullWait")
			{
				var waitFrame:int = 70+ int(Math.random() * 60);
				trace(waitFrame);
				gull.gotoAndPlay(waitFrame);
			}
		}
	}
}