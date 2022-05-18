package game.scenes.ftue.forest
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.transitions.Tween;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.FollowClipInTimeline;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Skin;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.HitTest;
	import game.components.hit.Platform;
	import game.components.input.Input;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionTarget;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.CardItem;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Think;
	import game.data.display.SpatialData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.data.ui.GestureData;
	import game.data.ui.ToolTipType;
	import game.data.ui.card.CardButtonData;
	import game.particles.emitter.PoofBlast;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ui.CardGroup;
	import game.scenes.carrot.engine.Sparks;
	import game.scenes.ftue.FtueScene;
	import game.scenes.ftue.shared.TapCheckGroup;
	import game.systems.SystemPriorities;
	import game.systems.entity.FollowClipInTimelineSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.HitTestSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.hud.Hud;
	import game.ui.inventory.Inventory;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Pulse;
	import org.flintparticles.common.initializers.Initializer;
	import org.flintparticles.common.initializers.Lifetime;
	import org.osflash.signals.Signal;
	
	public class Forest extends FtueScene
	{
		private var monkey:Entity;
		private var amelia:Entity;
		private var plane:Entity;
		
		private var timedEvent:TimedEvent;
		
		private var shipDropped:SpatialData;
		private var shipWrecked:SpatialData;
		
		private const SHAKE_VELOCITY:Number = 2;
		
		private var smoke:Entity;
		private var spark:Sparks;
		private var sparkTimer:TimedEvent;
		
		private const MONKEY_JUMP_ON_PLANE:String	= "garbage_bins_rattle_01.mp3";// monkey jump
		private const PLANE_RATTLES:String			= "metal_impact_05.mp3";//plane rattle
		private const PLAYER_JUMP_ON_PLANE:String	= "metal_crash_impact_02.mp3";//player jump
		private const PLANE_BREAKS_FREE:String		= "metal_crash_impact_01.mp3";//plane break
		
		private const PLANE_LAND:String		= "heavy_metal_crash_rattle_01.mp3";
		private const FIX_PLANE:String		= "ratchet_crank_short_01.mp3";
		private const PLANE_CHOKE:String	= "tractor_start_01.mp3";
		private const PLANE_START:String	= "Plane_H_loop_01_loop.mp3";
		private const PLANE_MOVE:String		= "Plane_L_loop_01_loop.mp3";
		private const PLANE_CRASH:String	= "explosion_02.mp3";
		private const BLOW_ENGINE:String	= "explosion_04.mp3";
		private const PLANE_SMOKING:String	= "gas_leak_01_loop.mp3";
		
		public function Forest()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/ftue/forest/";
			
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
			
			monkey = getEntityById("monkey");
			amelia = getEntityById("amelia");
			
			setUpPlane();
			
			var dialog:Dialog = amelia.get(Dialog);
			dialog.faceSpeaker = false;
			
			var talkers:Array = ["monkey","amelia","player"];
			
			var fsm:FSMControl = player.get(FSMControl);
			fsm.stateChange = new Signal();
			fsm.stateChange.add(checkState);
			
			var propeller:Entity = getEntityById("propellerInteraction");
			var interaction:SceneInteraction = propeller.get(SceneInteraction);
			interaction.reached.add(reachedPropeller);
			ToolTipCreator.removeFromEntity(propeller);// tool tip was being stupid so i am remaking it
			ToolTipCreator.addToEntity(propeller);
			interaction.offsetY = 180;
			
			if(shellApi.checkEvent(ftue.SAVED_AMELIA))
			{
				removeEntity(getEntityById("branch3"));
				shipDropped.positionSpatial(plane.get(Spatial));
				
				if(shellApi.checkEvent(ftue.FIX_BROKE_PLANE))
				{
					removeEntity(propeller);
					removeEntity(getEntityById("plane1"));
					removeEntity(monkey);
					removeEntity(amelia);
					Timeline(plane.get(Timeline)).gotoAndStop("rekt");
					EntityUtils.getChildById(plane,"smokeAnimation").get(Timeline).play();
					addSmoke();
				}
				else
				{
					addSpark();
					getEntityById("plane2").remove(Platform);
					Timeline(plane.get(Timeline)).gotoAndStop("propellar_broke");
					
					if(shellApi.checkHasItem(ftue.WRENCH))
					{
						dialog.setCurrentById("fix");
						dialog.sayById("fix");
						dialog.complete.add(checkToStartTutotial);
						Dialog(monkey.get(Dialog)).faceSpeaker = false;
						monkey.remove(WallCollider);
						amelia.remove(WallCollider);
					}
					else
					{
						removeEntity(monkey);
					}
				}
			}
			else
			{
				var follow:FollowTarget = new FollowTarget(plane.get(Spatial),1, false, true);
				follow.offset = new Point(-60,-45);
				amelia.add(follow);
				Display(amelia.get(Display)).moveToBack();
				CharUtils.setAnim(amelia, Sit);
				
				addSystem(new HitTestSystem(), SystemPriorities.resolveCollisions);
				addSystem(new ThresholdSystem());
				
				getEntityById("plane1").remove(Platform);
				getEntityById("plane2").remove(Platform);
				
				for(var i:int = 1; i <= 3; i++)
				{
					getEntityById("branch"+i).add(new HitTest(Command.create(jumpToBranch,i)));
				}
				
				for each (var talker:String in talkers)
				{
					dialog = getEntityById(talker).get(Dialog);
					dialog.start.add(lookAtMe);
					dialog.faceSpeaker = false;
				}
				
				SceneInteraction(amelia.get(SceneInteraction)).disabled = true;
				
				Interaction(amelia.get(Interaction)).click.add(talkToMe);
				
				monkey.remove(Sleep);
				SceneInteraction(monkey.get(SceneInteraction)).disabled = true;
				Interaction(monkey.get(Interaction)).click.add(talkToMe);
				dialog = monkey.get(Dialog);
				dialog.complete.add(checkToSeeIfYouShouldFollowMe);
				dialog.sayById("look_up_here");
				
				monkey.add(new Audio()).add(new AudioRange(1000));
				
				var path:Vector.<Point> = new Vector.<Point>();
				path.push(new Point(500, 600), new Point(600,900), new Point(500,600), new Point(400,900));
				CharUtils.followPath(monkey, path);
				SceneUtil.lockInput(this);
				
				if(!shellApi.checkEvent(ftue.FOUND_AMELIA))
				{
					shellApi.track(ftue.FOUND_AMELIA);
					shellApi.completeEvent(ftue.FOUND_AMELIA);
				}
				
				shellApi.removeEvent(ftue.CLIMBED_ROPE);
				
				EntityUtils.lockSceneInteraction(propeller);
				// making sure you start at starting point when tuturial is restarted mid way through
				var spatial:Spatial = player.get(Spatial);
				spatial.x = 100;
				spatial.y = 950;
				CharUtils.setDirection(player, true);
			}
		}
		
		private function reachedPropeller(...args):void
		{
			SceneInteraction(amelia.get(SceneInteraction)).activated = true;
		}
		
		private function talkToMe(entity:Entity):void
		{
			Dialog(entity.get(Dialog)).sayCurrent();
			SceneUtil.lockInput(this);
		}
		
		private function setUpPlane():void
		{
			var clip:MovieClip = _hitContainer["ship_dropped"];
			shipDropped = new SpatialData();
			shipDropped.rotation = clip.rotation;
			shipDropped.x = clip.x;
			shipDropped.y = clip.y;
			
			_hitContainer.removeChild(clip);
			
			clip = _hitContainer["ship"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			plane = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertAllClips(clip,null,this,false,32,plane);
			
			addSystem(new WaveMotionSystem());
			
			var wave:WaveMotion = new WaveMotion();
			wave.data.push(new WaveMotionData("y",0,.5));
			plane.add(wave).add(new SpatialAddition());
			
			spark = new Sparks();
			spark.init();
			for each (var initializer:Initializer in spark.initializers)
			{
				if(initializer is Lifetime)
				{
					spark.removeInitializer(initializer);
					break;
				}
			}
			spark.addInitializer(new Lifetime(1));
			spark.addAction(new Fade());
		}
		
		private function addSpark():void
		{
			EmitterCreator.create(this, _hitContainer, spark, 175, -75, plane, "spark", plane.get(Spatial));
			createSparks();
		}
		
		private function createSparks():void
		{
			var rate:Number = 1 + Math.random() * 2;
			spark.counter = new Pulse(rate - .1,5 + Math.random() * 10);
			
			sparkTimer = SceneUtil.delay(this, rate, createSparks);
		}
		
		private function addSmoke():void
		{
			var sprite:Sprite = new Sprite();
			sprite.x = 2400;
			sprite.y = 700;
			smoke = EntityUtils.createSpatialEntity(this, sprite, _hitContainer);
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH+PLANE_SMOKING, true, SoundModifier.POSITION, .5);
			smoke.add(audio).add(new AudioRange(1000, 0, .5));
		}
		
		private function checkToStartTutotial(dialogData:DialogData):void
		{
			if((dialogData.id == "tut") || (dialogData.id == "need_help"))
			{
				// force island inventory
				shellApi.profileManager.inventoryType = Inventory.ISLAND;

				shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
				var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
				
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
				shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(shellApi.viewportWidth - 120, 45), 40, 40, "item", null, inventoryClicked, null, hud.openingHudElement));
				texts.push(new TextData("Now, look in your backpack.", "tutorialwhite", new Point(shellApi.viewportWidth - 250, 100),240));
				var clickInventory:StepData = new StepData("backpack", TUTORIAL_ALPHA, 0x000000, 2.5, true, shapes, texts);
				tutorial.addStep(clickInventory);
				
				tutorial.complete.addOnce(tutorialFinished);
				tutorial.start();
			}
		}
		
		private function inventoryClicked():void
		{
			var inventory:Inventory = getGroupById("inventory") as Inventory;
			inventory.autoOpen = false;
			inventory.ready.addOnce(inventoryReady);
		}
		
		private function inventoryReady(inventory:Inventory):void
		{
			inventory.open(Command.create(inventoryOpened, inventory));
		}
		
		private function inventoryOpened(inventory:Inventory):void
		{
			var card:CardItem;
			inventory.changePage(Inventory.ISLAND);
			for(var i:int = 0; i < inventory.activePage.cards.length; i++)
			{
				card = inventory.activePage.cards[i];
				if(card.itemId == ftue.WRENCH)
					break;
			}
			
			if(!card.displayLoaded)
			{
				card.cardReady.addOnce(Command.create(cardLoaded, inventory, card));
			}
			else
			{
				cardLoaded(inventory, card);
			}
		}
		
		private function cardLoaded(inventory:Inventory, card:CardItem):void
		{
			var cardRect:Rectangle = card.spriteHolder.parent.parent.getRect(overlayContainer);
			var cardButtonRect:Rectangle = CardButtonData(card.cardData.buttonData[0]).entity.get(Display).displayObject.getRect(overlayContainer);
			
			cardRect.bottom = cardButtonRect.top - 10;
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			
			shapes.push(new ShapeData(ShapeData.RECTANGLE, cardRect.topLeft, cardRect.width, cardRect.height,"itemButton",null, null, null,inventory.itemClicked));
			
			texts.push(new TextData("Click on the item card for a better look.", "tutorialwhite", new Point(cardRect.left + cardRect.width / 2 - 150, cardRect.top - 100)));
			var clickItem:StepData = new StepData("item", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts);
			tutorial.addStep(clickItem);
			
			var cardItemBounds:Rectangle = CardGroup.CARD_BOUNDS.clone();
			var inventoryTopBorder:Number = 134;
			var inventoryBottomBorder:Number = 37;
			var inventoryHeight:Number = shellApi.viewportHeight - inventoryTopBorder - inventoryBottomBorder;
			cardItemBounds.offset(shellApi.viewportWidth / 2, inventoryTopBorder + inventoryHeight / 2);
			
			shapes = new Vector.<ShapeData>();
			texts = new Vector.<TextData>();
			
			var topOfCardButton:Number = shellApi.viewportHeight / 2 + cardItemBounds.height * inventory.CARD_DISPLAY_SCALE * .33;
			shapes.push(new ShapeData(ShapeData.RECTANGLE, new Point(shellApi.viewportWidth / 2 - 150,topOfCardButton), 300, 80,null, null, null, null,inventory.removed));
			texts.push(new TextData("Press the ''use'' button to fix the plane.", "tutorialwhite", new Point(shellApi.viewportWidth / 2 - 150, topOfCardButton - 100)));
			var useItem:StepData = new StepData("itemButton", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts);
			tutorial.addStep(useItem);
		}
		
		private function tutorialFinished(group:DisplayGroup):void
		{
			trace("andandandnanddn ddadaddadaa thats all folks!");
			this.removeGroup(tutorial);
		}
		
		override public function onEventTriggered(event:String=null, makeCurrent:Boolean=false, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == ftue.USE+ftue.WRENCH)
			{
				if(!shellApi.checkEvent(ftue.FIX_BROKE_PLANE))
				{
					if(!shellApi.checkEvent(ftue.USED_ITEM_TUTORIAL))
					{
						shellApi.completeEvent(ftue.SKIPPED_ITEM_TUTORIAL);
						shellApi.track(ftue.SKIPPED_ITEM_TUTORIAL);
						shellApi.triggerEvent(ftue.AMELIA_SEES_YOU_FOUND_WRENCH);
					}
					var destination:Destination = CharUtils.moveToTarget(player, 650,800,true,workOnPlane);
					destination.setDirectionOnReached("right");
					destination.validCharStates = new Vector.<String>();
					destination.validCharStates.push(CharacterState.STAND);
					CharUtils.setAnim(amelia, Score);
					Timeline(amelia.get(Timeline)).handleLabel("ending", standStill);
				}
				else
					Dialog(player.get(Dialog)).sayById("no_use_now");
			}
			if(event == ftue.AMELIA_SEES_YOU_FOUND_WRENCH)
			{
				CharUtils.setAnim(amelia, Score);
				Timeline(amelia.get(Timeline)).handleLabel("ending", standStill);
			}
			if(event == ftue.SAVED_AMELIA)
			{
				shellApi.track(ftue.SAVED_AMELIA);
			}
			if(event == ftue.USED_ITEM_TUTORIAL)
			{
				shellApi.track(ftue.USED_ITEM_TUTORIAL);
			}
			if(event == "monkey_to_beach")
			{
				CharUtils.moveToTarget(monkey, 0, sceneData.bounds.bottom, false, goBackToBeach);
			}
			super.onEventTriggered(event, makeCurrent, init, removeEvent);
		}
		
		private function standStill():void
		{
			CharUtils.setAnim(amelia, Stand, false,0,0,true, true);
		}
		
		private function workOnPlane(entity:Entity):void
		{
			SceneUtil.lockInput(this);
			MotionUtils.zeroMotion(player);
			CharUtils.setDirection(player, true);
			CharUtils.setAnimSequence(player, new <Class>[Place, Place,Proud]);
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "wrench", false);
			SceneUtil.delay(this, 3, fixedPlane);
			var time:Timeline = player.get(Timeline);
			time.handleLabel("trigger", Command.create(AudioUtils.play,this, SoundManager.EFFECTS_PATH+FIX_PLANE,1,true));
			time.handleLabel("stand", Command.create(AudioUtils.stop,this, SoundManager.EFFECTS_PATH+FIX_PLANE));
			removeEntity(getEntityById("propellerInteraction"));
		}
		
		private function fixedPlane():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH+FIX_PLANE);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLANE_CHOKE,1,true);
			sparkTimer.stop();
			removeEntity(getEntityById("spark"));
			Skin(player.get(Skin)).revertAll();
			Dialog(amelia.get(Dialog)).sayById("fly");
			getEntityById("plane2").add(new Platform());
			SceneUtil.setCameraTarget(this, amelia, false, CAMERA_PAN_SPEED);
			EntityUtils.getChildById(plane,"propelstart").get(Timeline).play(); 
			Timeline(plane.get(Timeline)).gotoAndStop("planeStart");
			CharUtils.setAnim(amelia, Stand, false, 0,0,true, true);
			var dialog:Dialog = amelia.get(Dialog);
			dialog.sayById("thats_it");
			dialog.complete.addOnce(congrats);
		}
		
		private function congrats(...args):void
		{
			CharUtils.setAnim(amelia, Celebrate);
			Timeline(amelia.get(Timeline)).handleLabel("ending", ameliaGetInPlane);
		}
		
		private function ameliaGetInPlane():void
		{
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(shipDropped.x - 50, sceneData.bounds.bottom ), new Point(shipDropped.x - 50, shipDropped.y - 200));
			CharUtils.followPath(amelia, path,ameliaInPlane).setDirectionOnReached("right");
		}
		
		private function ameliaInPlane(entity:Entity):void
		{
			addSystem(new FollowClipInTimelineSystem(),SystemPriorities.animate);
			var planeClip:DisplayObjectContainer = EntityUtils.getDisplayObject(plane);
			var follow:FollowClipInTimeline = new FollowClipInTimeline(planeClip["rider2"],null,plane.get(Spatial));
			amelia.add(follow);
			CharUtils.setAnim(amelia, Sit);
			MotionUtils.zeroMotion(amelia);
			CharacterMotionControl(amelia.get(CharacterMotionControl)).spinEnd = true;
			Spatial(amelia.get(Spatial)).rotation = 0;
			Display(amelia.get(Display)).moveToBack();
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(shipDropped.x, shipDropped.y - 100));
			CharUtils.followPath(player, path,playerInPlane).setDirectionOnReached("right");
		}
		
		private function playerInPlane(entity:Entity):void
		{
			removeEntity(getEntityById("plane1"));
			
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH+PLANE_CHOKE);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLANE_START,1,true);
			
			var planeSpatial:Spatial = plane.get(Spatial);
			var planeClip:DisplayObjectContainer = EntityUtils.getDisplayObject(plane);
			var follow:FollowClipInTimeline = new FollowClipInTimeline(planeClip["rider1"],null,planeSpatial);
			player.add(follow);
			
			CharUtils.setAnim(player, Sit);
			MotionUtils.zeroMotion(player);
			CharacterMotionControl(player.get(CharacterMotionControl)).spinEnd = true;
			//CharUtils.stateDrivenOff(player);
			Spatial(player.get(Spatial)).rotation = 0;
			Display(player.get(Display)).moveToBack();
			
			var spatial:Spatial = monkey.get(Spatial);
			var offset:Point = new Point(spatial.x - planeSpatial.x + 62, spatial.y - planeSpatial.y + 50);
			
			follow = new FollowClipInTimeline(planeClip["rider2"],offset, planeSpatial);
			
			monkey.add(follow);
			
			// probably based on handling a label
			SceneUtil.delay(this, 2, startMoving);
		}
		
		private function startMoving():void
		{
			var timeline:Timeline = plane.get(Timeline);
			timeline.play();
			timeline.handleLabel("revUp", speedUpEngine);
			timeline.handleLabel("planeGo", upUpAndAway);
			timeline.handleLabel("slowDown", slowDown);
			timeline.handleLabel("crash", crash);
			timeline.handleLabel("stallEngine", stallEngine);
			timeline.handleLabel("blowEngine", blowEngine);
			timeline.handleLabel("rekt", maybeNot);
		}
		
		private function upUpAndAway():void
		{
			Dialog(amelia.get(Dialog)).sayById("up_and_away");
		}
		
		private function speedUpEngine():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH+PLANE_START);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLANE_MOVE,1,true);
			panCamera();
		}
		
		private function panCamera():void
		{
			var sprite:Sprite = new Sprite();
			sprite.x = shipDropped.x;
			sprite.y = shipDropped.y;
			var entity:Entity = EntityUtils.createSpatialEntity(this, sprite, _hitContainer);
			TweenUtils.entityTo(entity, Spatial,4.0, {x:2200, ease:Quad.easeIn});
			SceneUtil.setCameraTarget(this, entity);
		}
		
		private function slowDown():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH+PLANE_MOVE);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLANE_START);
		}
		
		private function crash():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLANE_CRASH);
		}
		
		private function stallEngine():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH+PLANE_START);
		}
		
		private function blowEngine():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+BLOW_ENGINE);
		}
		
		private function maybeNot():void
		{
			shellApi.completeEvent(ftue.FIX_BROKE_PLANE);
			shellApi.track(ftue.FIX_BROKE_PLANE);
			addSmoke();
			
			var dialog:Dialog = amelia.get(Dialog);
			dialog.sayById("grounded");
			dialog.complete.add(followMonkey);
			
			amelia.remove(FollowClipInTimeline);
			CharUtils.setAnim(amelia, Stand);
			Display(amelia.get(Display)).moveToFront();
			
			player.remove(FollowClipInTimeline);
			CharUtils.setAnim(player, Stand);
			Display(player.get(Display)).moveToFront();
			
			monkey.remove(FollowClipInTimeline);
			Display(monkey.get(Display)).moveToFront();
		}
		
		private function letsGo(entity:Entity):void
		{
			var dialog:Dialog = monkey.get(Dialog);
			dialog.sayById("come_on");
			dialog.complete.addOnce(moveOn);
			var spatial:Spatial = monkey.get(Spatial);
			CharUtils.moveToTarget(monkey, spatial.x -10, spatial.y - 100);
		}
		
		private function moveOn(...args):void
		{
			Dialog(amelia.get(Dialog)).sayById("follow_monkey");
			CharUtils.moveToTarget(monkey, 2800, 525,false, removeEntity);
		}
		
		private function followMonkey(dialogData:DialogData):void
		{
			var path:Vector.<Point> = new Vector.<Point>();
			if(dialogData.id == "grounded")
			{
				path.push(new Point(2200, 800), new Point(2450, 600));
				var destination:Destination = CharUtils.followPath(monkey, path, letsGo);
				destination.setDirectionOnReached("left");
				destination.validCharStates = new Vector.<String>();
				destination.validCharStates.push(CharacterState.STAND);
			}
			if(dialogData.id == "follow_monkey")
			{
				Dialog(amelia.get(Dialog)).sayById("follow_me2");
			}
			if(dialogData.id == "follow_me2")
			{
				path.push(new Point(2450, 550), new Point(2800, 600));
				CharUtils.followPath(amelia,path, removeEntity);
				SceneUtil.delay(this, 1, returnControls);
			}
		}
		
		private var bounces:Number = 0;
		
		private function jumpToBranch(branch:Entity, hitId:String, branchNumber:int):void
		{
			var wave:WaveMotion = plane.get(WaveMotion);
			if(wave == null)
				return;
			var data:WaveMotionData = wave.data[0];
			var tween:Tween;
			
			if(hitId != "player")
			{
				if(branchNumber == 3)
				{
					tween = new Tween(data, "magnitude", Linear.easeNone, SHAKE_VELOCITY / 2, 0, 1, true);
					tween.start();
					Audio(monkey.get(Audio)).play(SoundManager.EFFECTS_PATH+MONKEY_JUMP_ON_PLANE,false, SoundModifier.POSITION);
				}
				return;
			}
			
			switch(branchNumber)
			{
				case 1:
				{
					branch.remove(HitTest);
					sendMonkeyOnPath(3,4,immaLetChuFinishBut);
					shellApi.completeEvent(ftue.CLIMBED_ROPE);
					shellApi.track(ftue.CLIMBED_ROPE);
					break;
				}
				case 2:
				{
					branch.remove(HitTest);
					//monkeyJumpOnPlane();
					break;
				}
				case 3:
				{
					tween = new Tween(data, "magnitude", Linear.easeNone, SHAKE_VELOCITY + bounces, 0, 1, true);
					tween.start();
					AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLAYER_JUMP_ON_PLANE);
					
					if(++bounces >= 3)
					{
						removeEntity(branch);
						breakBranch();
					}
					else
						jumpAgain();
					break;
				}
			}
		}
		
		private function jumpAgain():void
		{
			var dialog:Dialog = amelia.get(Dialog);
			switch(bounces)
			{
				case 1:
				{
					dialog.start.removeAll();
					dialog.sayById("almost");
					break;
				}
				case 2:
				{
					dialog.sayById("one_more");
					break;
				}
			}
		}
		
		private function monkeyJumpOnPlane(...args):void
		{
			MotionUtils.zeroMotion(player, "x");
			CharUtils.lockControls(player);
			
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this, monkey, false, CAMERA_PAN_SPEED);
			
			Dialog(monkey.get(Dialog)).sayById("try_this");
			
			var path:Vector.<Point> = new Vector.<Point>();
			var spatial:Spatial = monkey.get(Spatial);
			path.push(new Point(spatial.x, spatial.y - 300), new Point(spatial.x,spatial.y), new Point(spatial.x,spatial.y - 300), new Point(spatial.x, spatial.y));
			CharUtils.followPath(monkey, path,heIsOnToSomething);
		}
		
		private function heIsOnToSomething(entity:Entity):void
		{
			var dialog:Dialog = amelia.get(Dialog);
			dialog.sayById("onto_something");
			dialog.complete.addOnce(getReadyToJump);
			jumpUpAndDown(CharacterState.LAND, monkey, new Point(400, 300));
		}
		
		private function jumpUpAndDown(state:String, entity:Entity, target:Point):void
		{
			if(state == CharacterState.LAND)
			{		
				var fsmControl:FSMControl = entity.get(FSMControl);
				if(!fsmControl)
				{
					var charGroup:CharacterGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
					fsmControl = charGroup.addFSM(entity);
				}
				
				SceneUtil.delay(this, 2, Command.create(jumpUp, entity, target));								
				
				if(!fsmControl.stateChange)
				{
					fsmControl.stateChange = new Signal();
					fsmControl.stateChange.add(Command.create(jumpUpAndDown, target));
				}
			}
		}
		
		private function jumpUp(entity:Entity, target:Point):void
		{
			var motionTarget:MotionTarget = entity.get(MotionTarget);
			motionTarget.targetX = target.x;
			motionTarget.targetY = target.y;
			CharUtils.setState(entity, CharacterState.JUMP);
		}
		
		private function stopJumping(entity:Entity):void
		{
			var fsmControl:FSMControl = entity.get(FSMControl);
			fsmControl.stateChange.removeAll();
			fsmControl.stateChange = null;
		}
		
		private function immaLetChuFinishBut(...args):void
		{
			sendMonkeyOnPath(5,5,monkeyJumpOnPlane,null);
		}
		
		private function getReadyToJump(...args):void
		{
			var target:MovieClip = _hitContainer["target2"];
			CharUtils.moveToTarget(player, target.x, target.y,true, showHowToTargetJump).validCharStates = new <String>[CharacterState.STAND];
		}
		
		private function showHowToTargetJump(...args):void
		{
			// TODO Auto Generated method stub
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			var gestures:Vector.<GestureData> = new Vector.<GestureData>();
			
			var location:Point = DisplayUtils.localToLocal(_hitContainer["tapToJump"],overlayContainer);
			
			var phrase:String = "and release quickly to target jump.";
			
			var prefix:String = PlatformUtils.isMobileOS?"tap ":"click ";
			
			gestures.push(new GestureData(GestureData.MOVE_THEN_CLICK,location,null,-1,2));
			
			var tapCheck:TapCheckGroup = new TapCheckGroup();
			tutorial.addChildGroup(tapCheck);
			
			shapes.push(new ShapeData(ShapeData.CIRCLE, location,50, 50,null,null,null,null,tapCheck.tappedCorrectly));
			
			texts.push(new TextData(prefix + phrase, "tutorialwhite", location.add(new Point(-100, 150))));
			
			var moveStep:StepData = new StepData("move", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts,null,gestures);
			tutorial.addStep(moveStep);
			tutorial.complete.addOnce(tapToJumpTutorialFinished);
			tutorial.start();
		}
		
		private function tapToJumpTutorialFinished(group:DisplayGroup):void
		{
			group.removeGroup(getGroupById(TapCheckGroup.GROUP_ID));
			
			CharacterMotionControl(player.get(CharacterMotionControl)).jumpTargetTrigger = true;	// makes CharacterJumpAssistSystem active
			FSMControl(player.get(FSMControl)).setState( CharacterState.JUMP ); 
		}
		
		private function sendMonkeyOnPath(start:int, end:int, onComplete:Function = null, endingPhrase:String = "you_can_do_it"):void
		{
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this, monkey, false, CAMERA_PAN_SPEED);
			var path:Vector.<Point> = new Vector.<Point>();
			for(var i:int = start; i <= end; i++)
			{
				var point:MovieClip = _hitContainer["target"+i];
				path.push(new Point(point.x, point.y));
			}
			CharUtils.followPath(monkey, path,Command.create(youCanDoIt, onComplete, endingPhrase));
		}
		
		private function checkToSeeIfYouShouldFollowMe(dialogData:DialogData):void
		{
			if(dialogData.id == "come_on")
			{
				sendMonkeyOnPath(0,0, checkToClimb);
				var dialog:Dialog = amelia.get(Dialog);
				dialog.setCurrentById("any_day_now");
				dialog.complete.add(returnControls);
			}
			else if(dialogData.id == "you_can_do_it" || dialogData.id == null)
			{
				returnControls();
			}
			else if(dialogData.id == "follow_me")
			{
				CharUtils.moveToTarget(monkey, 0, sceneData.bounds.bottom, false, goBackToBeach);
			}
		}
		
		private function checkToClimb(...args):void
		{
			var threshold:Threshold = new Threshold("x",">",monkey, - 200);
			threshold.entered.addOnce(checkIfOnRope);
			player.add(threshold);
		}
		
		private function checkIfOnRope(...args):void
		{
			MotionUtils.zeroMotion(player, "x");
			CharUtils.lockControls(player);
			sendMonkeyOnPath(1, 2,jumpOnRope);
		}
		
		private function jumpOnRope(...args):void
		{
			SceneUtil.setCameraTarget(this, player);
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(1450, 900), new Point(1525, 700));
			CharUtils.followPath(player, path);
		}
		
		private function checkState( state:String, entity:Entity):void
		{
			if(state == CharacterState.CLIMB && !shellApi.checkEvent(ftue.CLIMBED_ROPE))
			{
				SceneUtil.delay(this, 1, startClimbingTutorial);
			}
			
			if(state == CharacterState.LAND)
			{
				var spatial:Spatial = player.get(Spatial);
				var dialog:Dialog = player.get(Dialog);
				if(spatial.x > 2300 && !shellApi.checkEvent(ftue.FIX_BROKE_PLANE))
					dialog.sayById("too_high");
				if(spatial.x < 900 && !shellApi.checkEvent(ftue.CLIMBED_ROPE))
					dialog.sayById("another_way");
			}
		}
		
		private function startClimbingTutorial():void
		{
			// TODO Auto Generated method stub
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			var gestures:Vector.<GestureData> = new Vector.<GestureData>();
			
			var phrase:String = "and hold directly over your avatar to climb up ropes.";
			
			var prefix:String = PlatformUtils.isMobileOS?"tap ":"click ";
			
			var location:Point = new Point(shellApi.viewportWidth / 2, shellApi.viewportHeight / 8)
			
			gestures.push(new GestureData(GestureData.CLICK_AND_DRAG,location,null,-1,2));
			
			var tapCheck:TapCheckGroup = new TapCheckGroup();
			tutorial.addChildGroup(tapCheck);
			
			shapes.push(new ShapeData(ShapeData.CIRCLE, location,50, 50,null,null,null,null,Input(shellApi.inputEntity.get(Input)).inputDown));
			
			texts.push(new TextData(prefix + phrase, "tutorialwhite", new Point(100, shellApi.viewportHeight / 4)));
			
			var moveStep:StepData = new StepData("move", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts,null,gestures);
			tutorial.addStep(moveStep);
			tutorial.complete.addOnce(climbingRopeTutorialFinished);
			tutorial.start();
		}
		
		private function climbingRopeTutorialFinished(group:DisplayGroup):void
		{
			//turorial group unlocks controls, but this deactivates input
			var input:Input = shellApi.inputEntity.get(Input);
			input.inputActive = input.inputStateDown = true;
			CharUtils.lockControls(player, false, false);
			// reactivate input so player actually moves when they click
		}
		
		private function youCanDoIt(entity:Entity, onComplete:Function = null, endingPhrase:String = "you_can_do_it"):void
		{
			var dialog:Dialog = monkey.get(Dialog);
			CharUtils.setDirection(monkey, false);
			returnControls();
			endingPhrase = null;
			if(endingPhrase != null)
			{
				dialog.sayById(endingPhrase);
				dialog.faceSpeaker = true;
				if(onComplete)
					dialog.complete.addOnce(onComplete);
			}
			else if(onComplete)
				onComplete();
		}
		
		private function goBackToBeach(entity:Entity = null):void
		{
			removeEntity(monkey);
			returnControls();
			Dialog(amelia.get(Dialog)).setCurrentById("saved_amelia");
		}
		
		private function lookAtMe(dialogData:DialogData):void
		{
			SceneUtil.setCameraTarget(this, getEntityById(dialogData.entityID),false, CAMERA_PAN_SPEED);
		}
		
		private function breakBranch():void
		{
			//set up plane falling
			
			var threshold:Threshold = new Threshold();
			
			threshold.property = "y";
			threshold.operator = ">";
			threshold.threshold = shipDropped.y;
			threshold.entered.addOnce(fellFromBranch);
			
			var motion:Motion = new Motion();
			motion.acceleration.y = MotionUtils.GRAVITY;
			plane.add(motion).add(threshold);
			
			plane.remove(SpatialAddition);
			plane.remove(WaveMotion);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLANE_BREAKS_FREE);
			
			getEntityById("plane1").add(new Platform());
			
			SceneUtil.lockInput(this);
			
			stopJumping(monkey);
			
			// change amelia interaction
			
			Interaction(amelia.get(Interaction)).click.remove(talkToMe);
			var dialog:Dialog = amelia.get(Dialog);
			dialog.start.remove(lookAtMe);
			dialog.complete.remove(returnControls);
			EntityUtils.removeAllWordBalloons(this, amelia);
			
			//player falls
			MotionUtils.zeroMotion(player);
			CharUtils.stateDrivenOn(player);
		}
		
		private function fellFromBranch():void
		{
			addSpark();
			
			shipDropped.positionSpatial(plane.get(Spatial));
			
			Timeline(plane.get(Timeline)).gotoAndStop("propellar_broke");
			
			var motion:Motion = plane.get(Motion);
			motion.velocity.y = -500;
			
			var poofBlast:PoofBlast = new PoofBlast();
			poofBlast.init(10, 50, 0xC1BB97, .4, .5);
			EmitterCreator.create(this, _hitContainer, poofBlast, shipDropped.x, shipDropped.y + 50);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLANE_LAND);
			
			Threshold(plane.get(Threshold)).entered.addOnce(bouncedFromFall);
			
			CharUtils.setAnim(amelia, Hurt);
			
			amelia.remove(FollowTarget);
			motion = new Motion();
			motion.velocity.y = -900;
			motion.velocity.x = (800 - Spatial(amelia.get(Spatial)).x) * .75;
			motion.acceleration.y = MotionUtils.GRAVITY;
			motion.rotationVelocity = 270;
			
			var threshold:Threshold = new Threshold("y",">");
			threshold.threshold = 970;
			threshold.entered.addOnce(landed);
			amelia.add(threshold).add(motion);
			
		}
		
		private const UP_TIME:Number = .5;
		private const DOWN_TIME:Number = .8;
		
		private function bouncedFromFall():void
		{
			plane.remove(Threshold);
			plane.remove(Motion);
			
			shipDropped.positionSpatial(plane.get(Spatial));
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+PLANE_LAND);
		}
		private function landed():void
		{
			amelia.remove(Motion);
			amelia.remove(Threshold);
			var spatial:Spatial = amelia.get(Spatial);
			spatial.rotation = 0;
			spatial.x = 800;
			spatial.y = 920;
			
			var interaction:SceneInteraction = amelia.get(SceneInteraction);
			interaction.disabled = false;
			
			var dialog:Dialog = amelia.get(Dialog);
			dialog.sayById("thanks");
			dialog.setCurrentById("whats_next");
			CharUtils.setAnim(amelia, Think);
			
			Dialog(player.get(Dialog)).start.remove(lookAtMe);
			Dialog(monkey.get(Dialog)).start.remove(lookAtMe);
			
			CharUtils.setAnim(amelia, Stand);
			CharUtils.setDirection(amelia, false);
			
			EntityUtils.lockSceneInteraction(getEntityById("propellerInteraction"), false);
		}
	}
}