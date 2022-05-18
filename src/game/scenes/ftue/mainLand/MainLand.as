package game.scenes.ftue.mainLand
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Back;
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.transitions.easing.None;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.Skin;
	import game.components.entity.character.Talk;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.Item;
	import game.components.hit.ValidHit;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Crank;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Excited;
	import game.data.animation.entity.character.Fall;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.PointPistol;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.SleepingOnBack;
	import game.data.animation.entity.character.Stand;
	import game.data.scene.characterDialog.DialogData;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.data.ui.GestureData;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.ftue.FtueScene;
	import game.scenes.ftue.mainLand.popups.BlimpDrawing;
	import game.scenes.ftue.mainLand.popups.BlimpSchematic;
	import game.scenes.ftue.outro.Outro;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.EventAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.ShowPopupAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TweenEntityAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.SceneObjectHitCircleSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.MotionThresholdSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.ui.hud.Hud;
	import game.ui.settings.SettingsPopup;
	import game.ui.tutorial.TutorialGroup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class MainLand extends FtueScene
	{		
		public function MainLand()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/ftue/mainLand/";
			
			super.init(container);
		}
		
		override protected function addCharacters():void
		{
			super.addCharacters();
			
			// preload animations used throughout the scene
			var characterGroup:CharacterGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			characterGroup.preloadAnimations(new <Class>[PointPistol, Crank, Dizzy, Pull, Hurt, SleepingOnBack], this );
			characterGroup.preloadAnimations(new <Class>[Excited], this, "ape");
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
			
			itemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			addSystem(new ThresholdSystem());
			addSystem(new TimelineVariableSystem());
			
			amelia = getEntityById("amelia");
			monkey = getEntityById("monkey");
			crusoe = getEntityById("crusoe");
			
			amelia.get(Dialog).replaceKeyword("[Player Name]", shellApi.profileManager.active.avatarName);
			
			var validHits:ValidHit = new ValidHit("behind_desk");
			validHits.inverse = true;
			player.add(validHits);
			
			blimp = EntityUtils.createSpatialEntity(this, _hitContainer["blimp"]);
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(blimp));
			EntityUtils.visible(blimp,false);
			
			EntityUtils.lockSceneInteraction(getEntityById("blimpInteraction"));			
			_hitContainer["hammockBack"].visible = false;
			_hitContainer["hammockFront"].visible = false;
			
			setupMonkeys();
			setupCrank();
			setupFruitCanvas();
			setUpFruit();
			setupFruitMachine()
			setupDesk();
			setupSlide();						
			
			if(shellApi.checkEvent(ftue.MADE_BLIMP))
			{
				atBlimp();
			}
			else if(!shellApi.checkEvent(ftue.THREE_INGREDIENTS))
			{
				//start intro
				miniIntro();		
			}
			else
			{				
				if(shellApi.checkEvent(ftue.GAVE_EVERYTHING))
				{
					if(shellApi.checkEvent(ftue.SAW_CRUSOE_PLANS))
					{
						secondSleep();
					}
					else
					{
						sleepInHammock();
					}
				}
			}
			
			if(crusoe && crusoe.has(Skin))
			{
				var facialPart:Entity = SkinUtils.getSkinPartEntity(crusoe, SkinUtils.FACIAL);
				facialPart.get(Timeline).handleLabel("pop", crusoeBubblePop, false);
				facialPart.get(Timeline).handleLabel("pop2", crusoeBubblePop, false);
			}
		}
		
		override public function onEventTriggered(event:String=null, makeCurrent:Boolean=false, init:Boolean=false, removeEvent:String=null):void
		{
			var playerSpatial:Spatial;
			
			if (event == "shutup")
			{
				shutupCrusoe();
			}
			else if(event == "heard_ingredients")
			{
				shellApi.triggerEvent(ftue.THREE_INGREDIENTS, true);
				shellApi.track(ftue.THREE_INGREDIENTS);
				SceneUtil.lockInput(this, false);
				CharUtils.lockControls(player, false, false);
				CharUtils.moveToTarget(amelia, 1010, 1440, false, null, new Point(20, 50));
				EntityUtils.position(monkey, -50, 1650);
				EntityUtils.lockSceneInteraction(getEntityById("deskInteraction"), false);
			}
			else if(event == "show_dialog_speed_tutorial")
			{
				dialogSpeedTutorial();
			}
			else if(event == "skip_speed_tutorial")
			{
				shutupCrusoe();
			}
			else if(event == "give_items")
			{
				SceneUtil.lockInput(this, true);
				var items:Array = new Array();
				
				if(shellApi.checkHasItem(ftue.ROPE))
				{
					items.push(ftue.ROPE);
				}				
				if(shellApi.checkHasItem(ftue.CANVAS))
				{				
					items.push(ftue.CANVAS);
				}				
				if(shellApi.checkHasItem(ftue.DRINK))
				{
					items.push(ftue.DRINK);
				}
				
				giveCrusoeItems(items);
			}
			else if(event.indexOf("use_") == 0) 
			{
				// use item events
				EntityUtils.removeAllWordBalloons(this);
				if(event.indexOf(ftue.ROPE) != -1 || event.indexOf(ftue.DRINK) != -1 || event.indexOf(ftue.CANVAS) != -1)
				{			
					playerSpatial = player.get(Spatial);
					if(playerSpatial.x < 1300 && playerSpatial.y > 1280)
					{
						CharUtils.moveToTarget(player, 720, 1650, true, Command.create(giveCrusoeOneItem, event.slice(4)),new Point(20, 60)).setDirectionOnReached(CharUtils.DIRECTION_RIGHT);
					}
					else
					{
						player.get(Dialog).sayById("not_close_to_crusoe");
					}
				}
			}
			else if(event == "no_use_wrench")
			{
				playerSpatial = player.get(Spatial);
				if(playerSpatial.x > 1900 && playerSpatial.x < 2380 && playerSpatial.y < 710)
				{
					player.get(Dialog).sayById("no_use_wrench_crank");
				}
			}
			else if (event == "monkey_seq")
			{
				monkeyPlansSeq();
			}
			
			super.onEventTriggered(event, makeCurrent, init, removeEvent);
		}			
		
		private function setupFruitCanvas():void
		{	
			convertContainer(_hitContainer["fruitCanvas"], PerformanceUtils.defaultBitmapQuality + 1);
			fruitCanvas = EntityUtils.createSpatialEntity(this, _hitContainer["fruitCanvas"]);
			InteractionCreator.addToEntity(fruitCanvas, [InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity(fruitCanvas, "click", null, new Point(0, 80));
			fruitCanvas.get(Interaction).click.add(clickedFruitCanvas);
			
			ropeSnap = TimelineUtils.convertClip(_hitContainer["ropeSnap"], this, null, null, false);
			if(shellApi.checkItemEvent(ftue.ROPE))
			{
				removeEntity(fruitCanvas);
				_hitContainer.removeChild(_hitContainer["extraRope"]);
				ropeSnap.get(Timeline).gotoAndStop("broken");
			}
			
			var canvas:Entity = getEntityById("canvas");
			if(canvas)
			{
				if(!shellApi.checkItemEvent(ftue.ROPE))
				{
					canvas.remove(Item);
					EntityUtils.visible(canvas, false);
					ToolTipCreator.removeFromEntity(canvas);
				}
			}
			
			convertContainer(_hitContainer["treeBranch"], PerformanceUtils.defaultBitmapQuality + 1);
		}
		
		private function setUpFruit():void
		{			
			addSystem(new SceneObjectHitRectSystem());
			addSystem(new SceneObjectHitCircleSystem());
			
			player.add(new SceneObjectCollider());	// allows entity to collide with entities owning SceneObjectHit
			player.add(new RectangularCollider());	// specifies that collider is rectangular
			player.add( new Mass(50) );
			
			var clip:MovieClip;			
			hitCreator = new SceneObjectCreator();
			
			for(var i:int = 1; i <= NUM_FRUIT; i++)
			{
				clip = _hitContainer["fruit"+i];
				if(shellApi.checkItemEvent(ftue.ROPE))
				{
					if(shellApi.checkItemEvent(ftue.DRINK))
					{
						_hitContainer.removeChild(clip);
						continue;
					}
					enableFruit(clip);
				}
				else
				{
					clip.visible = false;
				}
			}
		}
		
		private function setupFruitMachine():void
		{
			var entity:Entity;
			spikes = new Vector.<Entity>();
			var spikeSequence:BitmapSequence = BitmapTimelineCreator.createSequence(_hitContainer["spike0"]);
			for(var i:int = 0; i < NUM_SPIKES; i++)
			{
				entity = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["spike" + i], true, spikeSequence, PerformanceUtils.defaultBitmapQuality, 24);
				this.addEntity(entity);
				spikes.push(entity);
			}
			
			var spikeSideSequence:BitmapSequence = BitmapTimelineCreator.createSequence(_hitContainer["spikeSide0"]);
			for(var j:int = 0; j < 4; j++)
			{
				entity = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["spikeSide" + j], true, spikeSideSequence, PerformanceUtils.defaultBitmapQuality, 24);
				this.addEntity(entity);
				spikes.push(entity);
			}
			
			smashingHands = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["smashingHands"], true, null, PerformanceUtils.defaultBitmapQuality + 1, 24);
			this.addEntity(smashingHands);
			
			wheel1 = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["drinkWheel1"], true, null, PerformanceUtils.defaultBitmapQuality + 1);
			wheel2 = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["drinkWheel2"], true, null, PerformanceUtils.defaultBitmapQuality + 1);
			this.addEntity(wheel1);
			this.addEntity(wheel2);
			
			chute = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["drinkChute"], true, null, PerformanceUtils.defaultBitmapQuality + 1);
			this.addEntity(chute);
			
			fruitBar = EntityUtils.createSpatialEntity(this, _hitContainer["fruitBar"]);
			
			drinkLever = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["drinkLever"], true, null, PerformanceUtils.defaultBitmapQuality + 1);	
			this.addEntity(drinkLever);
			if(!shellApi.checkItemEvent(ftue.DRINK))
			{
				InteractionCreator.addToEntity(drinkLever, [InteractionCreator.CLICK]);
				var sceneInt:SceneInteraction = new SceneInteraction();
				sceneInt.minTargetDelta = new Point(20, 50);
				sceneInt.reached.add(reachedDrinkLever);
				drinkLever.add(sceneInt);
				ToolTipCreator.addToEntity(drinkLever, "click", null, new Point(35, 0));
				
				fallingFruit = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["fallingFruit"], true, null, PerformanceUtils.defaultBitmapQuality + 1, 24);
				this.addEntity(fallingFruit);
				sludge = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["sludge"], true, null, PerformanceUtils.defaultBitmapQuality + 1, 24);
				this.addEntity(sludge);
				leftSplash = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["splashLeft"], true, null, PerformanceUtils.defaultBitmapQuality + 1, 24);
				this.addEntity(leftSplash);
				rightSplash = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["splashRight"], true, null, PerformanceUtils.defaultBitmapQuality + 1, 24);
				this.addEntity(rightSplash);
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["fallingFruit"]);
				_hitContainer.removeChild(_hitContainer["sludge"]);
				_hitContainer.removeChild(_hitContainer["splashLeft"]);
				_hitContainer.removeChild(_hitContainer["splashRight"]);
			}
		}
		
		private function setupDesk():void
		{	
			var ripple:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["ripple"]);
			BitmapTimelineCreator.convertToBitmapTimeline(ripple);
			ripple.get(Timeline).play();
			
			var desk:Entity = getEntityById("deskInteraction");
			var sceneInt:SceneInteraction = desk.get(SceneInteraction);
			sceneInt.minTargetDelta = new Point(20, 50);
			sceneInt.offsetX = -60;
			sceneInt.offsetY = 75;
			sceneInt.autoSwitchOffsets = false;
			sceneInt.reached.add(reachedDesk);
			
			if(!shellApi.checkEvent(ftue.THREE_INGREDIENTS))
			{				
				EntityUtils.lockSceneInteraction(desk);
			}
			else if(shellApi.checkEvent(ftue.MADE_BLIMP))
			{
				removeEntity(desk);
			}
			
			DisplayUtils.moveToTop(_hitContainer["desk"]);
			DisplayUtils.moveToTop(amelia.get(Display).displayObject);				
			DisplayUtils.moveToTop(monkey.get(Display).displayObject);
			DisplayUtils.moveToTop(player.get(Display).displayObject);
		}	
		
		private function setupCrank():void
		{
			if(!shellApi.checkItemEvent(ftue.ROPE))
			{
				var crank:Entity = getEntityById("crankInteraction");
				var sceneInt:SceneInteraction = crank.get(SceneInteraction);
				sceneInt.minTargetDelta = new Point(20, 60);
				sceneInt.reached.add(reachedCrank);
			}
			else
			{
				removeEntity(getEntityById("crankInteraction"));
			}
		}
		
		private function setupSlide():void
		{
			var sceneInt:SceneInteraction = getEntityById("slideInteraction").get(SceneInteraction);
			sceneInt.minTargetDelta = new Point(20, 50);
			sceneInt.reached.add(reachedSlide);
			
			// sleep z's for when crusoe is asleep
			sleepZs = EntityUtils.createSpatialEntity(this, _hitContainer["sleepZs"]);
			sleepZs = BitmapTimelineCreator.convertToBitmapTimeline(sleepZs);
		}
		
		private function setupMonkeys():void
		{
			var monkey2:Entity = getEntityById("monkey2"); // pushing canvas of fruit monkey
			var monkey3:Entity = getEntityById("monkey3"); // crank monkey
			
			if(!shellApi.checkItemEvent(ftue.ROPE))
			{
				var sceneInt:SceneInteraction = monkey2.get(SceneInteraction);
				sceneInt.reached.removeAll();
				sceneInt.reached.add(reachedPushMonkey);
				
				monkey3.remove(SceneInteraction);
				var sceneInt3:SceneInteraction = new SceneInteraction();
				sceneInt3.targetX = 2100;
				sceneInt3.reached.add(reachedCrankMonkey);
				monkey3.add(sceneInt3);
			}
			else
			{
				CharUtils.setAnim(monkey2, Stand);
				CharUtils.setAnim(monkey3, Stand);
				
				Dialog(monkey3.get(Dialog)).faceSpeaker = true;
			}
		}
		
		private function reachedSlide(...args):void
		{
			SceneUtil.lockInput(this, true);
			DisplayUtils.moveToTop(_hitContainer["slideTop"]);
			DisplayUtils.moveToTop(_hitContainer["slideEnd"]);
			CharUtils.setAnim(player, Hurt);
			var motion:Motion = player.get(Motion);
			motion.velocity.x = 200;
			motion.velocity.y = -200;
			motion.acceleration.y = 800;
			
			var threshold:Threshold = new Threshold("y", ">");
			threshold.threshold = 660;
			threshold.entered.addOnce(hidePlayerSlide);
			player.add(threshold);
		}
		
		private function reachedDesk(...args):void
		{			
			SceneUtil.lockInput(this, true);
			CharUtils.setDirection(player, true);
			CharUtils.setAnim(player, PointPistol);
			CharUtils.getTimeline(player).handleLabel("trigger", ringBell); 		
		}
		
		private function reachedCrank(...args):void
		{
			var crankPlayer:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["crankPlayer"]);
			var crank:Entity = EntityUtils.createMovingEntity(this, _hitContainer["crankPlayer"]["crank"]);
			var treeBranch:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["treeBranch"]);
			
			EntityUtils.position(player, 2295, 640);
			
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.lockInput = true;
			actionChain.autoUnlock = false;
			actionChain.addAction(new SetDirectionAction(player, false));
			actionChain.addAction(new AnimationAction(player, Crank, "turnCrank", 0, false));
			actionChain.addAction(new CallFunctionAction(rotateCrank, crankPlayer.get(Spatial)));
			actionChain.addAction(new WaitAction(2));			
			actionChain.addAction(new PanAction(fruitCanvas));		
			actionChain.addAction(new CallFunctionAction(positionPlayerToFall, crank));
			actionChain.addAction(new TweenEntityAction(getEntityById("monkey2"), Spatial, 2, {x:370, ease:Quad.easeIn})).noWait = true;
			actionChain.addAction(new AudioAction(fruitCanvas, SoundManager.EFFECTS_PATH + "wire_strain_01.mp3", 450, 0, 1, null, true));
			actionChain.addAction(new TweenEntityAction(fruitCanvas, Spatial, 2, {x:446, y:894, ease:Quad.easeIn}));
			actionChain.addAction(new AnimationAction(getEntityById("monkey2"), Stand)).noWait = true;
			actionChain.addAction(new TweenEntityAction(fruitCanvas, Spatial, 2, {x:945, y:437, ease:Quad.easeOut}));
			actionChain.addAction(new TweenEntityAction(fruitCanvas, Spatial, 1, {x:1205, y:437, ease:None.easeNone}));
			actionChain.addAction(new TweenEntityAction(treeBranch, Spatial, .45, {rotation:-5, ease:Bounce.easeInOut, yoyo:true, repeat:1})).noWait = true;
			actionChain.addAction(new CallFunctionAction(stopMovingCanvas));
			actionChain.addAction(new TweenEntityAction(fruitCanvas, Spatial, .3, {rotation:-20, ease:Quad.easeOut}));
			actionChain.addAction(new TweenEntityAction(fruitCanvas, Spatial, .6, {rotation:15, ease:Quad.easeInOut}));
			actionChain.addAction(new TweenEntityAction(fruitCanvas, Spatial, .5, {rotation:-10, ease:Quad.easeInOut}));
			actionChain.addAction(new TweenEntityAction(fruitCanvas, Spatial, .4, {rotation:5, ease:Quad.easeIn}));
			actionChain.addAction(new PanAction(player));
			actionChain.addAction(new TalkAction(player, "just_need", false, "pull_harder"));
			actionChain.addAction(new CallFunctionAction(breakCrank, crank));
			actionChain.execute();
		}
		
		private function reachedDrinkLever(...args):void
		{
			if(fruitsCollected >= NUM_FRUIT)
			{
				SceneUtil.lockInput(this, true);
				CharUtils.setDirection(player, true);				
				pullLeverDown();
				
				// remove drink lever interaction
				drinkLever.get(SceneInteraction).reached.removeAll();
				ToolTipCreator.removeFromEntity(drinkLever);
				drinkLever.remove(SceneInteraction);
				drinkLever.remove(Interaction);
			}
			else
			{		
				EntityUtils.removeAllWordBalloons(this);
				var actionChain:ActionChain = new ActionChain(this);
				
				if(fruitsCollected > 0 || shellApi.checkItemEvent(ftue.ROPE))
				{
					actionChain.addAction(new TalkAction(player, "no_fruit_dropped"));
					actionChain.addAction(new PanAction(getEntityById("fruit3"), .1));
				}
				else
				{ 					
					actionChain.addAction(new TalkAction(player, "no_fruit"));
					actionChain.addAction(new PanAction(getEntityById("monkey2"), .05));
					
				}
				
				actionChain.addAction(new WaitAction(2));
				actionChain.addAction(new PanAction(player, .05));
				actionChain.execute();
			}
		}
		
		private function reachedPushMonkey(...args):void
		{
			if(!shellApi.checkItemEvent(ftue.ROPE))
			{
				EntityUtils.removeAllWordBalloons(this, player);
				player.get(Dialog).sayById("pushing");
			}
			else
			{
				getEntityById("monkey2").get(Dialog).sayCurrent();
			}
		}
		
		private function reachedCrankMonkey(...args):void
		{
			if(!shellApi.checkItemEvent(ftue.ROPE))
			{
				player.get(Dialog).sayById("cranking");
			}
			else
			{
				getEntityById("monkey3").get(Dialog).sayCurrent();
			}
		}
		
		private function cameraBackOnPlayer():void
		{
			shellApi.camera.camera.scaleTarget = 1;
			SceneUtil.setCameraTarget(this, player);
		}
		
		private function giveCrusoeOneItem(entity:Entity, item:String):void
		{
			giveCrusoeItems([item]);
		}
		
		private function giveCrusoeItems(items:Array):void
		{
			for(var i:int = 0; i < items.length; i++)
			{
				var handler:Function = i + 1 == items.length ? checkCrusoeItems : null;
				itemGroup.takeItem(items[i], "crusoe", "", null, handler);				
				shellApi.removeItem(items[i]);
				
				shellApi.completeEvent(ftue.GAVE_CRUSOE_ITEM + items[i]);
				shellApi.track(ftue.GAVE_CRUSOE_ITEM + items[i]);
			}
		}
		
		private function checkCrusoeItems():void
		{
			var dialog:Dialog = crusoe.get(Dialog);
			
			if(shellApi.checkItemUsedUp(ftue.ROPE) && shellApi.checkItemUsedUp(ftue.CANVAS) && shellApi.checkItemUsedUp(ftue.DRINK))
			{
				SceneUtil.lockInput(this, true);				
				dialog.sayById("gave_all");
				dialog.complete.add(crusoeLeaveToMakeHammock);
				return;
			}
			
			var dialogId:String = "gave";
			if(shellApi.checkItemUsedUp(ftue.ROPE)) dialogId += "_rope";
			if(shellApi.checkItemUsedUp(ftue.CANVAS)) dialogId += "_canvas";
			if(shellApi.checkItemUsedUp(ftue.DRINK)) dialogId += "_drink";
			dialog.sayById(dialogId);
			SceneUtil.lockInput(this, false);
		}
		
		private function pullLeverDown(...args):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ratchet_crank_short_01.mp3");
			CharUtils.setAnim(player, PointPistol);
			var timeline:Timeline = drinkLever.get(Timeline);
			timeline.play();
			timeline.handleLabel("down", startFruitMachine);
			SceneUtil.setCameraPoint(this, 1280, 1240, false, .015); 
		}
		
		private function clickedFruitCanvas(...args):void
		{
			EntityUtils.removeAllWordBalloons(this, player);
			
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.addAction(new TalkAction(player, "fruit_canvas"));
			actionChain.addAction(new PanAction(getEntityById("monkey3"), .025));
			actionChain.addAction(new WaitAction(2.25));
			actionChain.addAction(new PanAction(player, .025));
			actionChain.execute();
		}
		
		private function hidePlayerSlide(...args):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "tumbling_down_pipe_01.mp3");
			EntityUtils.visible(player, false);			
			MotionUtils.zeroMotion(player);
			
			var panEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["slidePan"]);
			var chain:ActionChain = new ActionChain(this);
			chain.addAction(new PanAction(panEntity, .022, 20));
			chain.addAction(new SetSpatialAction(player, new Point(2573, 1748)));
			chain.addAction(new SetDirectionAction(player, false));
			chain.addAction(new PanAction(player));
			chain.addAction(new CallFunctionAction(exitSlide));
			chain.execute();
		}
		
		private function exitSlide():void
		{
			CharUtils.setAnim(player, Fall);
			EntityUtils.visible(player, true);
			TweenUtils.entityTo(player, Spatial, .5, {x:2220, y:1850, onComplete:waterHit, ease:Sine.easeOut});
		}
		
		private function waterHit(...args):void
		{
			CharUtils.stateDrivenOn(player);
			DisplayUtils.moveToBack(_hitContainer["slideTop"]);
			DisplayUtils.moveToBack(_hitContainer["slideEnd"]);
			
			if(slideAfterBreak)
			{
				_hitContainer.removeChild(_hitContainer["extraRope"]);				
				slideAfterBreak = false;
				var dialog:Dialog = player.get(Dialog);
				dialog.sayById("strong");
				dialog.complete.addOnce(spokeAboutStrong);				
				return;
			}			
			
			removeSystemByClass(MotionThresholdSystem);
			SceneUtil.lockInput(this, false, false);
		}
		
		private function spokeAboutStrong(...args):void
		{
			_hitContainer["outSlideRope"].alpha = 1;
			var rope:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["outSlideRope"]);
			DisplayUtils.moveToBack(rope.get(Display).displayObject);				
			var playerSpatial:Spatial = player.get(Spatial);
			
			var whack:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["whack"]);
			whack.get(Display).alpha = 0;
			EntityUtils.position(whack, playerSpatial.x + 30, playerSpatial.y - 100);
			
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.lockInput = true;
			actionChain.autoUnlock = true;
			actionChain.addAction(new TweenEntityAction(rope, Spatial, .85, {x:playerSpatial.x + 50, y:playerSpatial.y-20, ease:Back.easeOut})).noWait = true;
			actionChain.addAction(new WaitAction(.6));
			actionChain.addAction(new AnimationAction(player, Hurt)).noWait = true;				
			actionChain.addAction(new TweenEntityAction(whack, Display, .5, {alpha:1}));
			actionChain.addAction(new TweenEntityAction(whack, Display, .5, {alpha:0}));
			actionChain.addAction(new CallFunctionAction(removeEntity, rope));
			actionChain.addAction(new GetItemAction(ftue.ROPE));
			actionChain.addAction(new AnimationAction(player, Stand)).noWait = true;
			actionChain.addAction(new PanAction(getEntityById("fruit3"), .1));
			actionChain.addAction(new WaitAction(2));
			actionChain.addAction(new PanAction(player));
			actionChain.addAction(new TalkAction(player, "need_fruit"));
			actionChain.addAction(new CallFunctionAction(CharUtils.stateDrivenOn, player));
			actionChain.execute();
		}
		
		private function startFruitMachine(...args):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "contraption_machine_01_loop.mp3", 1, true);
			
			wheel1.get(Timeline).play();
			wheel2.get(Timeline).play();
			
			for each(var entity:Entity in spikes)
			{
				entity.get(Timeline).gotoAndPlay("start");
			}
			
			smashingHands.get(Timeline).gotoAndPlay("smash");
			
			var fallingTimeline:Timeline = fallingFruit.get(Timeline);
			SceneUtil.delay(this, 1.5, Command.create(fallingTimeline.gotoAndPlay, "fall"));
			fallingTimeline.handleLabel("still", fruitDown);
			
			TweenUtils.entityTo(fruitBar, Spatial, 3, {y:METER_BOTTOM_Y});
		}
		
		private function fruitDown():void
		{
			removeEntity(fallingFruit, true);
			
			var timeline:Timeline = sludge.get(Timeline);
			SceneUtil.delay(this, .25, Command.create(timeline.gotoAndPlay, "slideDown"));
			timeline.handleLabel("reachedSlide", Command.create(SceneUtil.delay, this, 1, sludgeDone));
		}
		
		private function sludgeDone():void
		{
			removeEntity(sludge);
			var smashTimeline:Timeline = smashingHands.get(Timeline);
			smashTimeline.handleLabel("smashRight", Command.create(smashSplash, true), false);
			smashTimeline.handleLabel("smashLeft", Command.create(smashSplash, false), false);
			SceneUtil.delay(this, 3, stopFruitMachine);
		}
		
		private function smashSplash(right:Boolean):void
		{
			if(rightSplash && leftSplash && rightSplash.has(Timeline) && leftSplash.has(Timeline))
			{
				if(right)
				{
					rightSplash.get(Timeline).gotoAndPlay("splash");
				}
				else
				{
					leftSplash.get(Timeline).gotoAndPlay("splash");
				}
			}
		}
		
		private function stopFruitMachine():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "contraption_machine_01_loop.mp3");
			wheel1.get(Timeline).stop();
			wheel2.get(Timeline).stop();
			
			var smashTimeline:Timeline = smashingHands.get(Timeline);
			smashTimeline.stop();
			removeEntity(rightSplash, true);
			removeEntity(leftSplash, true);
			
			for each(var entity:Entity in spikes)
			{
				entity.get(Timeline).gotoAndPlay("slow");
			}
			
			var dialog:Dialog = player.get(Dialog);
			dialog.complete.addOnce(getDrink);
			var timeline:Timeline = chute.get(Timeline);
			timeline.gotoAndPlay("releaseDrink");
			timeline.handleLabel("complete", Command.create(SceneUtil.delay, this, 1, Command.create(dialog.sayById, "get_drink")));
		}
		
		private function getDrink(...args):void
		{			
			chute.get(Timeline).gotoAndStop("noDrink");
			shellApi.getItem(ftue.DRINK, null, true, null);
			SceneUtil.setCameraTarget(this, player);
			SceneUtil.lockInput(this, false, false);
		}
		
		private function rotateCrank(spatial:Spatial):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "creaky_metal_04.mp3");
			currentTween = TweenUtils.globalTo(this, spatial, .38, {rotation:spatial.rotation - 180, ease:Linear.easeNone, onComplete:rotateCrank, onCompleteParams:[spatial]});
		}
		
		private function positionPlayerToFall(crank:Entity):void
		{
			shellApi.completeEvent(ftue.CRANKED_WHEEL);
			shellApi.track(ftue.CRANKED_WHEEL);			
			
			currentTween.kill();
			CharUtils.setAnim(player, Pull);
			crank.get(Spatial).rotation = 110;
		}
		
		private function stopMovingCanvas():void
		{
			var audio:Audio = fruitCanvas.get(Audio);
			audio.stop(SoundManager.EFFECTS_PATH + "wire_strain_01.mp3");
			AudioUtils.playSoundFromEntity(fruitCanvas, SoundManager.EFFECTS_PATH + "rope_strain_01.mp3");
		}
		
		private function breakCrank(crank:Entity):void
		{
			// Fix Monkeys
			CharUtils.setAnim(getEntityById("monkey3"), Stand);
			EntityUtils.position(getEntityById("monkey2"), 150, 1110); 
			
			slideAfterBreak = true;
			removeEntity(getEntityById("crankInteraction"));			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "rope_snap_01.mp3");
			
			var timeline:Timeline = ropeSnap.get(Timeline);
			timeline.gotoAndPlay("snap");
			
			DisplayUtils.moveToTop(_hitContainer["slideTop"]);
			DisplayUtils.moveToTop(_hitContainer["slideEnd"]);		
			
			SceneUtil.delay(this, .35, ropeSnapped);
			
			// We are also back at the crank so we can position the fruit and canvas
			removeEntity(fruitCanvas);
			var canvas:Entity = getEntityById("canvas");
			canvas.add(new Item());
			EntityUtils.visible(canvas, true);
			ToolTipCreator.addToEntity(canvas);			
			
			for(var i:int = 1; i <= NUM_FRUIT; i++)
			{
				enableFruit(_hitContainer["fruit" + i]);
			}
		}
		
		private function ropeSnapped():void
		{
			CharUtils.setAnim(player, Hurt);
			TweenUtils.entityTo(player, Spatial, .4, {x:2380, y:545, ease:Quad.easeOut, onComplete:playerTweenDownSlide})
		}
		
		private function playerTweenDownSlide():void
		{
			TweenUtils.entityTo(player, Spatial, .4, {x:2460, y:610, ease:Quad.easeIn, onComplete:hidePlayerSlide});
		}
		
		private function ringBell():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "desk_bell_01.mp3");
			
			// Show crusoe cut scene
			if(!shellApi.checkEvent(ftue.THREE_INGREDIENTS))
			{
				crusoe.get(Display).visible = true;
				monkey.get(Display).visible = true;
				
				if (crusoe.has(SceneInteraction))
				{
					EntityUtils.lockSceneInteraction(crusoe);
				}
				EntityUtils.lockSceneInteraction(getEntityById("monkey1"));
				EntityUtils.lockSceneInteraction(getEntityById("deskInteraction"), true);
				
				var actionChain:ActionChain = new ActionChain(this);
				actionChain.addAction(new MoveAction(amelia, new Point(610, 1640), new Point(20, 50))).noWait = true;
				actionChain.addAction(new MoveAction(player, new Point(680, 1630), new Point(20, 50)));
				actionChain.addAction(new SetDirectionAction(player, true));	
				actionChain.addAction(new MoveAction(crusoe, new Point(770, 1610), new Point(20, 60)));
				actionChain.addAction(new TalkAction(crusoe, "look"));
				actionChain.addAction(new SetDirectionAction(crusoe, true));
				actionChain.addAction(new TalkAction(crusoe, "scat"));
				actionChain.addAction(new MoveAction(getEntityById("monkey1"), new Point(940, 1650))).noWait = true;
				actionChain.addAction(new MoveAction(monkey, new Point(1800, 1625))).noWait = true;				
				actionChain.addAction(new SetDirectionAction(crusoe, false));
				actionChain.addAction(new TalkAction(amelia, "guests"));
				actionChain.addAction(new TalkAction(crusoe, "memories")).noWait = true;
				actionChain.addAction(new WaitAction(5));
				actionChain.addAction(new MoveAction(amelia, new Point(320, 1640), new Point(20, 50))).noWait = true;
				actionChain.addAction(new MoveAction(player, new Point(420, 1640), new Point(20, 50)));
				actionChain.addAction(new SetDirectionAction(amelia, true));
				actionChain.addAction(new SetDirectionAction(player, false));
				actionChain.addAction(new TalkAction(amelia, "dialog_speed"));				
				actionChain.addAction(new CallFunctionAction(unlockForDialogSpeedTutorial));
				actionChain.execute();
			}
			else if(!shellApi.checkEvent(ftue.GAVE_EVERYTHING))
			{
				SceneUtil.lockInput(this, false);
				crusoe.get(Dialog).sayById("stop_bell");
			}
			else
			{
				SceneUtil.lockInput(this, false);
				player.get(Dialog).sayById("hes_not_here");
			}
		}
		
		private function unlockForDialogSpeedTutorial():void
		{
			EntityUtils.lockSceneInteraction(amelia);
			SceneUtil.lockInput(this, false, false);
			CharUtils.lockControls(player);
		}
		
		private function shutupCrusoe():void
		{
			SceneUtil.lockInput(this, true);
			EntityUtils.removeAllWordBalloons(this, crusoe);
			
			CharUtils.moveToTarget(player, 670, 1630, false, null, new Point(20, 60));
			CharUtils.moveToTarget(amelia, 580, 1630, false, null, new Point(20, 60));			
			
			SceneUtil.delay(this, 1, longStoryShort);			
			
			EntityUtils.lockSceneInteraction(crusoe, false);
			EntityUtils.lockSceneInteraction(getEntityById("monkey1"), false);
			EntityUtils.lockSceneInteraction(amelia, false);
		}
		
		private function longStoryShort():void
		{
			EntityUtils.removeAllWordBalloons(this, crusoe);
			var dialog:Dialog = crusoe.get(Dialog);
			dialog.sayById("long_story_short");
		}	
		
		private function enableFruit(clip:MovieClip):void
		{
			var entity:Entity;			
			if(clip.name == "fruit3")entity = hitCreator.createBox(clip, 0, _hitContainer, NaN, NaN, null, null, new Rectangle(850, 900, 650, 300), this, null, null, 100);
			else entity = hitCreator.createCircle(clip, 0,_hitContainer, NaN, NaN, null, null, new Rectangle(850,900,650,300), this, null,null, 100);
			
			var validHits:ValidHit = new ValidHit("hole");
			validHits.inverse = true;
			entity.add(validHits).add(new PlatformCollider()).add(new Id(clip.name));
			
			EntityUtils.visible(entity);
			entity.add(new Id(clip.name));
			entity.add(new SceneObjectCollider());
			entity.add(new RectangularCollider());
			
			var threshold:Threshold = new Threshold("y",">");
			threshold.threshold = 1050;
			threshold.entered.addOnce(Command.create(updateFruitMeter, entity));
			entity.add(threshold);
			
			if(clip.name == "fruit2" || clip.name == "fruit5")
			{
				var edge:Edge = entity.get(Edge);
				edge.unscaled.top = edge.unscaled.left;
				edge.unscaled.bottom = edge.unscaled.right;
			}
		}
		
		private function updateFruitMeter(fruit:Entity):void
		{
			removeEntity(fruit);
			fruitsCollected++;
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "chute_02.mp3");
			
			if(fruitsCollected >= NUM_FRUIT)
			{
				var actionChain:ActionChain = new ActionChain(this);				
				actionChain.addAction(new TalkAction(player, "last_fruit"));
				actionChain.addAction(new PanAction(drinkLever, .08));
				actionChain.addAction(new WaitAction(2));
				actionChain.addAction(new PanAction(player, .08));
				actionChain.execute();
			}
			
			shellApi.completeEvent(ftue.DROPPED_IN_FRUIT + fruitsCollected);
			shellApi.track(ftue.DROPPED_IN_FRUIT + fruitsCollected);
			
			if(currentTween) currentTween.kill();			
			var spatial:Spatial = fruitBar.get(Spatial);
			var dist:Number = METER_BOTTOM_Y - (((METER_BOTTOM_Y - METER_TOP_Y) / NUM_FRUIT) * fruitsCollected);			
			currentTween = TweenUtils.entityTo(fruitBar, Spatial, .25, {y:dist});
		}
		
		private function crusoeLeaveToMakeHammock(data:DialogData):void
		{
			if(data.id == "wait")
			{
				var actionChain:ActionChain = new ActionChain(this);
				actionChain.autoUnlock = false;
				actionChain.addAction(new MoveAction(crusoe, new Point(1530, 1420), new Point(20, 50)));
				actionChain.addAction(new CallFunctionAction(fadeOutHammock));
				actionChain.execute();
			}
		}
		
		private function fadeOutHammock():void
		{
			screenEffects.fadeToBlack(2, sleepInHammock, [true]);
		}
		
		private function sleepInHammock(fadeIn:Boolean = false):void
		{
			SkinUtils.setSkinPart(crusoe, SkinUtils.ITEM, "ftue_drink");
			SkinUtils.emptySkinPart(crusoe, SkinUtils.FACIAL);
			EntityUtils.position(monkey, 2260, 1220);
			CharUtils.setDirection(monkey, false);
			EntityUtils.position(amelia, 1900, 1217);
			CharUtils.setDirection(crusoe, false);
			CharUtils.setAnim(crusoe, SleepingOnBack);
			var spatial:Spatial = crusoe.get(Spatial);
			CharUtils.stateDrivenOff(crusoe);
			
			sleepZs.get(Timeline).gotoAndPlay(0);
			AudioUtils.playSoundFromEntity(crusoe, SoundManager.EFFECTS_PATH + "sleeping_01_loop.mp3", 800, 0, 1.5, Quad.easeIn, true);
			
			_hitContainer["hammockBack"].visible = true;
			_hitContainer["hammockFront"].visible = true;		
			DisplayUtils.moveToOverUnder(_hitContainer["hammockFront"], EntityUtils.getDisplayObject(crusoe), true);
			
			spatial.rotation = 0;
			spatial.x = 2075;
			spatial.y = 1185;
			
			if(crusoe.has(Motion))
			{
				MotionUtils.zeroMotion(crusoe);
				Motion(crusoe.get(Motion)).rotationVelocity = 0;
			}
			
			if(!shellApi.checkEvent(ftue.SAW_CRUSOE_PLANS))
			{				
				EntityUtils.position(amelia, 975, 1620);				
				var sceneInt:SceneInteraction = crusoe.get(SceneInteraction);
				sceneInt.reached.removeAll();
				sceneInt.reached.add(clickedSleepingCrusoe);
			}
			
			if(fadeIn) 
			{
				screenEffects.fadeFromBlack(2, crusoeSleeping);
			}
		}
		
		private function crusoeSleeping(...args):void
		{
			var dialog:Dialog = amelia.get(Dialog);
			dialog.sayById("so_long");
			dialog.complete.add(ameliaComplains);
		}
		
		private function ameliaComplains(data:DialogData):void
		{
			if(data.event == ftue.GAVE_EVERYTHING)
			{
				amelia.get(Dialog).complete.remove(ameliaComplains);
				SceneUtil.lockInput(this, false);
			}
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
		
		private function clickedSleepingCrusoe(...args):void
		{		
			if(!shellApi.checkEvent(ftue.SAW_CRUSOE_PLANS))
			{
				var crusoeSpatial:Spatial = crusoe.get(Spatial);				
				sleepZs.get(Timeline).gotoAndStop(0);
				crusoe.get(Audio).stop(SoundManager.EFFECTS_PATH + "sleeping_01_loop.mp3");
				
				var actionChain:ActionChain = new ActionChain(this);
				actionChain.lockInput = true;
				actionChain.autoUnlock = false;
				actionChain.addAction(new AnimationAction(crusoe, Dizzy)).noWait = true;
				actionChain.addAction(new SetSpatialAction(crusoe, new Point(crusoeSpatial.x, crusoeSpatial.y - 20)));
				actionChain.addAction(new MoveAction(amelia, new Point(1535, 1450)));
				actionChain.addAction(new MoveAction(amelia, new Point(1900, 1200))).noWait = true;
				actionChain.addAction(new TalkAction(crusoe, "hammock"));
				actionChain.addAction(new TalkAction(amelia, "well_rested"));
				actionChain.addAction(new TalkAction(crusoe, "rested"));
				actionChain.addAction(new TalkAction(crusoe, "plans"));
				actionChain.addAction(new ShowPopupAction(new BlimpDrawing(overlayContainer)));
				actionChain.addAction(new EventAction(shellApi, ftue.SAW_CRUSOE_PLANS, null, true));
				actionChain.addAction(new TalkAction(player, "plan"));
				actionChain.addAction(new TalkAction(crusoe, "built"));			
				actionChain.addAction(new CallFunctionAction(secondSleep));
				actionChain.execute();
			}
			else
			{
				crusoe.get(Dialog).sayCurrent();
			}
		}
		
		private function secondSleep():void
		{
			SceneUtil.lockInput(this, false);
			jumpUpAndDown(CharacterState.LAND, monkey, new Point(2260, 1115));
			SkinUtils.setSkinPart(monkey, SkinUtils.ITEM, "paper");
			crusoe.get(Talk).adjustEyes = false;
			SkinUtils.getSkinPart(crusoe, SkinUtils.MOUTH).lock = true;
			
			var monkeyInt:SceneInteraction = monkey.get(SceneInteraction);
			monkeyInt.reached.removeAll();
			monkeyInt.reached.addOnce(monkeyPlans);			
			monkeyEek = SceneUtil.addTimedEvent(this, new TimedEvent(Math.random() * 5 + 2, 0, Command.create(monkey.get(Dialog).sayById, "plans")));
			
			shellApi.track(ftue.SAW_CRUSOE_PLANS);			
			sleepInHammock();
		}
		
		private function monkeyPlansSeq():void
		{
			SceneUtil.lockInput(this, true);
			shellApi.track(ftue.SAW_CRUSOE_PLANS);			
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.autoUnlock = false;
			actionChain.addAction(new ShowPopupAction(new BlimpSchematic(overlayContainer)));
			actionChain.addAction(new TalkAction(player, "monkey_plans"));
			actionChain.addAction(new SetSkinAction(getEntityById("monkey1"), SkinUtils.MOUTH, "1")).noWait = true;
			actionChain.addAction(new CallFunctionAction(finalFadeOut));
			actionChain.execute();
		}
		
		private function monkeyPlans(...args):void
		{
			monkeyEek.stop();
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.autoUnlock = false;
			actionChain.addAction(new CallFunctionAction(stopJumping, monkey));
			actionChain.addAction(new SetSkinAction(monkey, SkinUtils.ITEM, "empty"));
			actionChain.addAction(new ShowPopupAction(new BlimpSchematic(overlayContainer)));
			actionChain.addAction(new TalkAction(player, "monkey_plans"));
			actionChain.addAction(new SetSkinAction(monkey, SkinUtils.MOUTH, "1")).noWait = true;
			actionChain.addAction(new TalkAction(amelia, "masterminds"));
			actionChain.addAction(new CallFunctionAction(finalFadeOut));
			actionChain.execute();
		}
		
		private function finalFadeOut():void
		{
			shellApi.triggerEvent(ftue.MADE_BLIMP, true);
			shellApi.track(ftue.MADE_BLIMP);
			screenEffects.fadeToBlack(2, atBlimp, [true]);
		}
		
		private function atBlimp(fadeIn:Boolean = false):void
		{
			// hide Crusoe
			crusoe.get(Display).visible = false;
			
			EntityUtils.visible(blimp, true);
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(blimp));
						
			if(amelia.has(Motion))
			{
				CharacterGroup(getGroupById(CharacterGroup.GROUP_ID)).removeFSM(amelia);
				MotionUtils.zeroMotion(amelia);
				amelia.remove(Motion);	
				amelia.remove(MotionControl);
				amelia.remove(MotionTarget);
			}
			
			CharUtils.setAnim(amelia, Stand);
			CharUtils.setDirection(amelia, false);
			EntityUtils.getDisplay(amelia).setContainer(DisplayObjectContainer(EntityUtils.getDisplayObject(blimp).getChildByName("npcContainer")));
			EntityUtils.position(amelia, -40, -50);
			EntityUtils.turnOffSleep(amelia);
			
			CharUtils.setDirection(player, true);
			MotionUtils.zeroMotion(player);
			EntityUtils.position(player, 1100, 1440);			
			EntityUtils.position(monkey, 1480, 1420);
			var sceneInt:SceneInteraction = monkey.get(SceneInteraction);
			sceneInt.reached.removeAll();
			
			jumpUpAndDown(CharacterState.LAND, monkey, new Point(1480, 1400));
			SceneUtil.addTimedEvent(this, new TimedEvent(Math.random() * 5 + 1, 0, monkey.get(Dialog).sayCurrent));
			
			_hitContainer["hammockFront"].visible = false;
			_hitContainer["hammockBack"].visible = false;
			
			for(var i:int = 1; i <= 3; i++)
			{
				var newMonkey:Entity = getEntityById("monkey" + i);
				SkinUtils.emptySkinPart(newMonkey, SkinUtils.OVERSHIRT);
				SkinUtils.emptySkinPart(newMonkey, SkinUtils.OVERPANTS);
				SkinUtils.setSkinPart(newMonkey, SkinUtils.MOUTH, "1");
				EntityUtils.position(newMonkey, 900 + (i*100), 1460);
				CharUtils.setAnim(newMonkey, Excited);
				EntityUtils.lockSceneInteraction(newMonkey);
				SceneUtil.addTimedEvent(this, new TimedEvent(Math.random() * 4 + i, 0, newMonkey.get(Dialog).sayCurrent));
			}
			
			var blimpIntEntity:Entity = getEntityById("blimpInteraction");
			EntityUtils.lockSceneInteraction(blimpIntEntity, false);
			var blimpInt:SceneInteraction = blimpIntEntity.get(SceneInteraction);
			blimpInt.reached.addOnce(putPlayerInBlimp);
			
			var waveMotion:WaveMotion = new WaveMotion();
			waveMotion.data.push(new WaveMotionData("y", 5, .05, "cos"));
			blimp.add(waveMotion);
			blimp.add(new SpatialAddition());
			addSystem(new WaveMotionSystem());
			
			if(fadeIn)
			{
				screenEffects.fadeFromBlack(2);
				SceneUtil.lockInput(this, false);
				amelia.get(Dialog).sayById("great");
			}
		}
		
		private function reachedMonkeyAtBlimp(...args):void
		{
			player.get(Dialog).sayById("thanks_mongo");
		}
		
		private function putPlayerInBlimp(...args):void
		{
			blimp.remove(WaveMotion);
			
			SceneUtil.lockInput(this, true);
			SceneUtil.setCameraTarget(this, blimp);
			player.remove(MotionBounds);
			MotionUtils.zeroMotion(player);
			EntityUtils.position(player, 20, -50);
			player.remove(Motion);
			player.get(Spatial).rotation = 0;
			CharUtils.setAnim(player, Stand);
			EntityUtils.getDisplay(player).setContainer(DisplayObjectContainer(EntityUtils.getDisplayObject(blimp).getChildByName("npcContainer")));
			//player.get(Dialog).container = EntityUtils.getDisplayObject(blimp).getChildByName("dialogContainer") as DisplayObjectContainer;
			
			player.get(Dialog).sayById("where_crusoe");			
			TweenUtils.entityTo(blimp, Spatial, 14, {x:2600, y:-200, ease:Quad.easeIn, onComplete:moveOnOutro});
		}
		
		private function moveOnOutro():void
		{
			EntityUtils.removeAllWordBalloons(this);
			shellApi.loadScene(Outro);
		}
		
		private function miniIntro():void
		{		
			crusoe.get(Display).visible = false;
			EntityUtils.position(monkey, 500, 1690);
			EntityUtils.position(getEntityById("monkey1"), 1640, 1650);
			EntityUtils.position(crusoe, 1462, 1600);
			EntityUtils.position(amelia, 400, 1675);
			
			var threshold:Threshold = new Threshold("x", ">");
			threshold.threshold = 600;
			threshold.entered.addOnce(mentionBell);
			player.add(threshold);
			
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.lockInput = true;
			actionChain.addAction(new TalkAction(monkey, "hello"));
			actionChain.addAction(new MoveAction(monkey, new Point(960, 1650)));
			actionChain.addAction(new SetDirectionAction(monkey, false));
			actionChain.addAction(new TalkAction(amelia, "strange"));
			actionChain.execute();
		}
		
		private function mentionBell():void
		{
			EntityUtils.removeAllWordBalloons(this);
			SceneUtil.lockInput(this, true);
			var dialog:Dialog = amelia.get(Dialog);
			dialog.sayById("ring_bell");
			dialog.complete.addOnce(showInteractiveTutorial);
		}
		
		private function showInteractiveTutorial(...args):void
		{
			var deskInteraction:Entity = getEntityById("deskInteraction");
			EntityUtils.lockSceneInteraction(deskInteraction, false);
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			var gestures:Vector.<GestureData> = new Vector.<GestureData>();
			
			var platformInput:String = PlatformUtils.isMobileOS?"tap ":"click ";
			var bellLocation:Point = DisplayUtils.localToLocal(EntityUtils.getDisplayObject(deskInteraction), overlayContainer);
			
			gestures.push(new GestureData(GestureData.MOVE_THEN_CLICK, bellLocation, null, -1, 2));
			shapes.push(new ShapeData(ShapeData.CIRCLE, bellLocation, 70, 70, null, null, null, null, null));
			texts.push(new TextData(platformInput + "the bell.", "tutorialwhite", new Point(bellLocation.x - 120, bellLocation.y - 150)));
			texts.push(new TextData("Look for items throughout the island that can be clicked on.", "tutorialwhite", new Point(50, 50), 500));
			
			var clickStep:StepData = new StepData("interaction", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts, null, gestures);
			tutorial.addStep(clickStep);
			tutorial.start();
			tutorial.complete.addOnce(tutFinished);
		}
		
		private function tutFinished(group:DisplayGroup):void
		{
			shellApi.completeEvent(ftue.INTERACTIVE_TUTORIAL);
			shellApi.track(ftue.INTERACTIVE_TUTORIAL);
			SceneUtil.lockInput(this, true);
			SceneInteraction(getEntityById("deskInteraction").get(SceneInteraction)).activated = true;
		}
		
		private function dialogSpeedTutorial():void
		{
			// show tut on changing dialog speed settings
			shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
			var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;			
			
			var stepDatas:Vector.<StepData> = new Vector.<StepData>();
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			
			var hudButton:Entity = hud.getButtonById(Hud.HUD);
			var hudButtonSpatial:Spatial = hudButton.get(Spatial);
			
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(hudButtonSpatial.x, hudButtonSpatial.y), 60, 60, "gear", null, null, hudButton.get(Interaction)));
			texts.push(new TextData("First, open your menu.", "tutorialwhite", new Point(shellApi.viewportWidth - 350, 10),240));
			var clickHud:StepData = new StepData("hud", TUTORIAL_ALPHA, 0x000000, 1.5, true, shapes, texts);
			stepDatas.push(clickHud);	
			
			shapes = new Vector.<ShapeData>();
			texts = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(45, 45), 40, 40, "slider", null, settingsOpened, null,hud.openingHudElement));
			texts.push(new TextData("Press here to open your settings.", "tutorialwhite", new Point(10, 100*shellApi.viewportHeight/640)));
			var clickInventory:StepData = new StepData("gear", TUTORIAL_ALPHA, 0x000000, 1, true, shapes, texts);
			stepDatas.push(clickInventory);
			
			tutorialGroup = new TutorialGroup(overlayContainer, stepDatas);
			tutorialGroup.complete.addOnce(dialogTutFinished);
			this.addChildGroup(tutorialGroup);
			tutorialGroup.start();
		}
		
		private function settingsOpened():void
		{
			var settings:SettingsPopup = getGroupById(SettingsPopup.GROUP_ID,getGroupById(Hud.GROUP_ID)) as SettingsPopup;
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.RECTANGLE, new Point(shellApi.viewportWidth / 2 - 230,shellApi.viewportHeight / 2 - 150), 200, 210, null, null, null,null,new Signal()));
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(shellApi.viewportWidth / 2 + 250, shellApi.viewportHeight / 2 - 200), 40, 30, null,  null, null, null, settings.removed));
			texts.push(new TextData("On this screen, you can adjust how your game looks and sounds.", "tutorialwhite", new Point(shellApi.viewportWidth/2 - 300, shellApi.viewportHeight/2 - 300), 450));
			texts.push(new TextData("Click to save.", "tutorialwhite", new Point(shellApi.viewportWidth / 2 + 215, shellApi.viewportHeight / 2 - 290), 200));
			var adjustSettings:StepData = new StepData("slider", .85, 0x000000, .5, true, shapes, texts);
			tutorialGroup.addStep(adjustSettings);
		}
		
		private function dialogTutFinished(group:DisplayGroup):void
		{
			shellApi.completeEvent(ftue.DIALOG_TUTORIAL);
			shellApi.track(ftue.DIALOG_TUTORIAL);
			
			this.removeGroup(tutorialGroup);
			
			var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
			hud.openHud(false);
			
			shutupCrusoe();
		}
		
		private function crusoeBubblePop(...args):void
		{
			var randInt:int = GeomUtils.randomInt(4,5);
			AudioUtils.playSoundFromEntity(crusoe, SoundManager.EFFECTS_PATH + "pop_0" + randInt + ".mp3", 500, 0, 1, Linear.easeInOut);	
		}
		
		private const NUM_FRUIT:Number = 5;
		private const NUM_SPIKES:Number = 16;
		private const METER_BOTTOM_Y:Number = 1138;
		private const METER_TOP_Y:Number = 1090;
		
		private var itemGroup:ItemGroup;
		private var justGaveItem:Boolean = false;
		
		private var ropeSnap:Entity;
		private var monkey:Entity;
		private var amelia:Entity;
		private var crusoe:Entity;
		private var fruitCanvas:Entity;
		private var tutorialGroup:TutorialGroup;
		private var hitCreator:SceneObjectCreator;
		private var blimp:Entity;
		private var monkeyEek:TimedEvent;
		private var slideAfterBreak:Boolean = false;
		
		private var fruitsCollected:uint = 0;
		private var spikes:Vector.<Entity>;
		private var smashingHands:Entity;
		private var wheel1:Entity;
		private var wheel2:Entity;
		private var chute:Entity;
		private var drinkLever:Entity;
		private var fruitBar:Entity;
		private var fallingFruit:Entity;
		private var sludge:Entity;
		private var leftSplash:Entity;
		private var rightSplash:Entity;
		private var currentTween:TweenMax;
		private var sleepZs:Entity;
	}
}