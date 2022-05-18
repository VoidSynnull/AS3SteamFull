package game.scenes.backlot.soundStage1
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
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.particles.Flame;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.HitReact2;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Think;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.WalkNinja;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.BacklotEvents;
	import game.scenes.backlot.backlotTopDown.BacklotTopDown;
	import game.scenes.backlot.shared.emitters.WindowSnow;
	import game.scenes.backlot.shared.popups.Camera;
	import game.scenes.backlot.shared.popups.Clapboard;
	import game.scenes.backlot.soundStage1.KeepWithInDistanceSystem.KeepWithInDistance;
	import game.scenes.backlot.soundStage1.KeepWithInDistanceSystem.KeepWithInDistanceSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.systems.particles.FlameSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class SoundStage1 extends PlatformerGameScene
	{
		public var backlot:BacklotEvents;
		
		private var motion:Motion;
		private var display:DisplayObjectContainer;
		private var target:DisplayObjectContainer;
		
		public var camera:Camera;
		public var carson:Entity;
		public var conrad:Entity;
		public var kirk:Entity;
		public var cat:Entity;
		private var flashLight:Entity;
		
		private var takes:int = 0;
		
		private var filmingBounds:Rectangle;
		private var originalBounds:Rectangle;
		
		public function SoundStage1()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/soundStage1/";
			
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
			
			originalBounds = super.shellApi.camera.camera.area;
			filmingBounds = new Rectangle(0,0,2100,1400);
			
			this.backlot = this.events as BacklotEvents;
			
			this.shellApi.eventTriggered.add(this.handleEventTriggered);
			
			super.addSystem(new ThresholdSystem(), SystemPriorities.update);
			addSystem(new KeepWithInDistanceSystem(),SystemPriorities.update);
			
			this.carson = this.getEntityById("carson");
			this.conrad = this.getEntityById("conrad");
			this.kirk = this.getEntityById("kirk");
			this.kirk.add( new Tween());
			this.cat = this.getEntityById("cat");
			
			if(shellApi.profileManager.active.userFields[shellApi.island] != null)
			{
				if(shellApi.profileManager.active.userFields[shellApi.island]["stage1"] != null)
					takes = shellApi.getUserField("stage1",shellApi.island);
				else
					saveTakesToServer();
			}
			else
			{
				saveTakesToServer();
			}
			
			this.setupAnimations();
			this.setupCat();
			this.setupSnow();
			setUpSpeechBubble();
			this.setupFire();
			
			if(this.shellApi.checkEvent(backlot.KIRK_RETURNS_STAGE_1))
			{
				if(!this.shellApi.checkEvent(backlot.COMPLETE_STAGE_1))
				{
					if(this.shellApi.checkEvent(backlot.CAMERA_CHAT))
					{
						this.removeEntity(this.conrad);
					}
					else if(this.shellApi.checkEvent(backlot.CONRAD_LEFT))
					{
						this.removeEntity(this.conrad);
					}
					else
					{
						SceneUtil.lockInput(this);
						this.shellApi.camera.target = this.carson.get(Spatial);
						var dialog:Dialog = this.carson.get(Dialog);
						dialog.sayById("unbelievable");
					}
					this.setupCamera(false);
					SkinUtils.setSkinPart(this.kirk, SkinUtils.ITEM, "flashlight");
				}
				else
				{
					if(shellApi.checkEvent(backlot.DAY_2_STARTED) && !shellApi.checkEvent(backlot.DAY_2_ESCAPED_LOT))
						this.setupCamera(true);
					else
						setupCamera(false,false);
					
					this.removeEntity(this.getEntityById("conrad"));
					this.removeEntity(this.getEntityById("carson"));
					this.removeEntity(this.getEntityById("kirk"));
				}
			}
			else if(!this.shellApi.checkEvent(backlot.DISRUPTED_KIRK))
			{
				setupCamera(false,false);
				this.conrad.get(Spatial).y = 990;
				this.conrad.get(Dialog).setCurrentById("shh");
				
				this.carson.get(Dialog).setCurrentById("filming");
				
				kirk.get(Spatial).x = 650;
				kirk.get(Spatial).y = 900;
				
				var threshold:Threshold = new Threshold("x", "<");
				threshold.threshold = 1450;
				threshold.entered.add( Command.create( interruptKirk, this.player));
				this.player.add(threshold);
			}
			else
			{
				setupCamera(false,false);
				this.removeEntity(this.getEntityById("carson"));
				this.removeEntity(this.getEntityById("kirk"));
			}
			
			if(!this.shellApi.checkEvent(backlot.DAY_2_STARTED) || shellApi.checkEvent(backlot.DAY_2_ESCAPED_LOT))
			{
				this.removeEntity(this.getEntityById("lauren"));
				this.removeEntity(this.getEntityById("erin"));
			}
			
		}
		
		private function setUpSpeechBubble():void
		{
			var speech:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["speech_mc"],_hitContainer);
			speech.add(new Id("speech"));
			Display(speech.get(Display)).visible = false;
		}
		
		private function interruptKirk(player:Entity):void
		{
			trace("disrupt Kirk");
			player.remove(Threshold);
			SceneUtil.lockInput(this);
			CharUtils.setDirection(kirk, true);
			
			CharUtils.setAnim(kirk, WalkNinja);
			var tween:Tween = kirk.get(Tween);
			tween.to(kirk.get(Spatial), 2, {x:930, y:1150, ease:Linear.easeNone, onComplete:ruinedLighting});
			SceneUtil.setCameraTarget(this, kirk);
		}
		
		private function newKirkTween():void
		{
			kirk.remove(Tween);
			kirk.add( new Tween());
		}
		
		private function ruinedLighting():void
		{
			CharUtils.setAnim( kirk, Stand );
			var dialog:Dialog = this.kirk.get(Dialog);
			dialog.sayById("light");
		}
		
		private function stormOff(label:String):void
		{
			trace(label);
			if(label == "end")
			{
				kirk.get(Timeline).labelReached.removeAll();
				CharUtils.moveToTarget(kirk, 2450,1235);
				CharacterMotionControl( kirk.get(CharacterMotionControl) ).maxVelocityX = 200;
				SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, waitKirk));
			}
		}
		
		private function waitKirk():void
		{
			SceneUtil.setCameraTarget(this, carson);
			var dialog:Dialog = carson.get(Dialog);
			dialog.sayById("need");
		}
		
		
		private function carsonFollowKirkOut():void
		{
			SceneUtil.setCameraTarget(this, super.player);
			CharUtils.moveToTarget(carson, 2450,1235, false, exitCarsonAndKirk);
			CharacterMotionControl( carson.get(CharacterMotionControl) ).maxVelocityX = 200;
		}
		
		private function exitCarsonAndKirk(entity:Entity):void
		{
			super.removeEntity(kirk);
			super.removeEntity(carson);
			super.shellApi.triggerEvent(backlot.DISRUPTED_KIRK,true);
			SceneUtil.lockInput(this, false);
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			//trace(event);
			
			if(event == "look_at_player")
			{
				this.shellApi.camera.target = this.player.get(Spatial);
			}
			
			if(event == "now_back_at_kirk")
			{
				this.shellApi.camera.target = this.kirk.get(Spatial);
			}
			
			if(event == "kirk_leaves")
			{
				CharUtils.setAnim(kirk, Stomp);
				kirk.get(Timeline).labelReached.add(stormOff);
			}
			
			if(event == "we_need_you")
			{
				carsonFollowKirkOut();
			}
			
			if(event == "sorry")
			{
				this.shellApi.camera.target = this.conrad.get(Spatial);
			}
			else if(event == "walk_out")
			{
				CharUtils.followPath(this.conrad, new <Point> [new Point(2450, 1235)], this.carsonPicksYou);
			}
			else if(event == "try")
			{
				this.shellApi.camera.target = this.player.get(Spatial);
				this.player.get(Dialog).sayById("try");
			}
			else if(event == "center")
			{
				this.shellApi.camera.target = this.carson.get(Spatial);
				var dialog:Dialog = this.carson.get(Dialog);
				dialog.sayById("center");
				
				function action(data:DialogData, scene:SoundStage1):void
				{
					SceneUtil.lockInput(scene, false);
					scene.shellApi.camera.target = scene.player.get(Spatial);
					scene.shellApi.triggerEvent(backlot.CAMERA_CHAT, true);
				};
				dialog.complete.addOnce(Command.create(action, this));
			}
			else if(event == "bad_filming" || event == "good_filming")
			{
				SceneUtil.lockInput(this, false);
				this.shellApi.camera.target = this.player.get(Spatial);
				CharUtils.stateDrivenOn(this.player);
				
				if(event == "good_filming")
					this.shellApi.completeEvent(this.backlot.COMPLETE_STAGE_1);
			}
			if(event == backlot.BEGIN_CHASE)
			{
				CharUtils.moveToTarget(player, getEntityById("door1").get(Spatial).x, getEntityById("door1").get(Spatial).y,false,leaveSoundStage1);
			}
		}
		
		private function leaveSoundStage1(entity:Entity):void
		{
			shellApi.loadScene(BacklotTopDown);
		}
		
		private function carsonPicksYou(conrad:Entity):void
		{
			this.removeEntity(conrad);
			this.shellApi.completeEvent(backlot.CONRAD_LEFT);
			this.shellApi.camera.target = this.carson.get(Spatial);
			this.carson.get(Dialog).sayById("you");
		}
		
		private function setupAnimations():void
		{
			TimelineUtils.convertClip(this._hitContainer["glow"], this);
			
			var animations:Array = ["table", "window", "door", "bear", "chest", "plates"];
			
			for(var i:int = 0; i < animations.length; i++)
			{
				var animation:String = animations[i];
				var entity:Entity = TimelineUtils.convertClip(this._hitContainer[animation], this, null, null, false);
				entity.add(new Id(animation));
				Timeline(entity.get(Timeline)).labelReached.add(Command.create(animationSignals, entity));
			}
		}
		
		private function animationSignals(label:String, entity:Entity):void
		{
			shellApi.triggerEvent(label);
		}
		
		private function setupCat():void
		{
			if(shellApi.checkEvent(backlot.COMPLETE_STAGE_1) || !shellApi.checkEvent(backlot.KIRK_RETURNS_STAGE_1))
			{
				removeEntity(cat);
				return;
			}
			var doorDisplay:DisplayObjectContainer = this._hitContainer["door"]
			var index:int = doorDisplay.parent.getChildIndex(doorDisplay);
			
			var catDisplay:DisplayObjectContainer = this.cat.get(Display).displayObject;
			catDisplay.parent.setChildIndex(catDisplay, index);
		}
		
		private function setupFire():void
		{
			this.addSystem(new FlameSystem());
			var x:int = 0;
			for(var i:int = 1; i <= 4; i++)
			{
				var clip:MovieClip = this._hitContainer["flame" + i];
				
				for(var j:int = 1; j <= 2; j++)
				{
					var flame:Entity = new Entity();
					flame.add(new Id("flame" + ++x));
					this.addEntity(flame);
					
					if(j == 1) flame.add(new Flame(clip["flame" + j], true));
					else flame.add(new Flame(clip["flame" + j], false));
				}
				
				clip.visible = false;
				
				var spark:Entity = TimelineUtils.convertClip(this._hitContainer["spark" + i], this, null, null, false);
				spark.add(new Id("spark" + i));
			}
			var grill:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["grill"],_hitContainer);
			var audioRange:AudioRange = new AudioRange(600, .01, 1, Quad.easeIn);
			grill.add(new Audio()).add(audioRange).add(new Id("grill"));
			Audio(grill.get(Audio)).play("effects/fire_01_L.mp3",true, SoundModifier.POSITION);
			DisplayUtils.moveToOverUnder(grill.get(Display).displayObject,_hitContainer["spark4"], false);
		}
		
		private function setupSnow():void
		{
			var snow:WindowSnow = new WindowSnow();
			snow.init();
			
			var entity:Entity = EmitterCreator.create(this, this._hitContainer, snow, 0, 0, null, "snow", null, false);
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = 1180;
			spatial.y = 690;
			
			var index:int = this._hitContainer.getChildIndex(this._hitContainer["window"]);
			
			var display:Display = entity.get(Display);
			this._hitContainer.setChildIndex(display.displayObject, index);
		}
		
		private function setupCamera(day2:Boolean = false, interactive = true):void
		{
			var cam:Entity = this.getEntityById("cameraInteraction");
			
			TimelineUtils.convertClip(this._hitContainer["cameraInteraction"], this, cam, null, false);
			if(!interactive)
			{
				cam.remove(Interaction);
				cam.remove(SceneInteraction);
				ToolTipCreator.addToEntity(cam,ToolTipType.NAVIGATION_ARROW);
				return;
			}
			
			var interaction:SceneInteraction = cam.get(SceneInteraction);
			if(day2)
				interaction.reached.add(pickUpCamera);
			else
				interaction.reached.add(this.holdCamera);
		}
		
		private function pickUpCamera(player:Entity, entity:Entity):void
		{
			shellApi.getItem(backlot.MOVIE_CAMERA,null,true);
			removeEntity(entity);
			SceneUtil.lockInput(this);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,holdIt));
		}
		
		private function holdIt():void
		{
			Display(getEntityById("speech").get(Display)).visible = true;
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,hideIt));
		}
		
		private function hideIt():void
		{
			Display(getEntityById("speech").get(Display)).visible = false;
			
			var erin:Entity = getEntityById("erin");
			
			CharUtils.moveToTarget(erin,1900,1200,false,dunDunDuh);
			CharacterMotionControl(erin.get(CharacterMotionControl)).maxVelocityX = 200;
			
			var lauren:Entity = getEntityById("lauren");
			
			CharUtils.moveToTarget(lauren,1800,1200);
			CharacterMotionControl(lauren.get(CharacterMotionControl)).maxVelocityX = 200;
			
			SceneUtil.setCameraTarget(this, erin);
		}
		
		private function dunDunDuh(entity:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("who");
		}
		
		private function holdCamera(player:Entity, camera:Entity):void
		{
			//Make sure the player is actually near the camera before starting. 
			var spatial:Spatial = this.player.get(Spatial);
			spatial.x = 2000;
			
			var timeline:Timeline;
			
			//Set the player's animation to Salute, but stop it at full salute to hold the camera.
			CharUtils.setDirection(this.player, false);
			CharUtils.setAnim(this.player, Salute);
			timeline = this.player.get(Timeline);
			timeline.handleLabel("stop", Command.create(this.showClapboard, timeline));
			
			//Play the camera's animation to move the lens down.
			timeline = camera.get(Timeline);
			timeline.playing = true;
		}
		
		private function showClapboard(timeline:Timeline):void
		{
			takes++;
			saveTakesToServer();
			
			//Stop the player at a full salute to hold camera.
			timeline.stop();
			
			//Do the Clapboard popup before doing the camera overlay.
			var clapboard:Clapboard = new Clapboard(this.overlayContainer,1,takes);
			clapboard.removed.addOnce(this.filmKirk);
			this.addChildGroup(clapboard);
		}
		
		private function filmKirk(popup:Group):void
		{
			//Add camera overlay.
			this.camera = new Camera(this.overlayContainer);
			this.addChildGroup(this.camera);
			
			//super.shellApi.sceneManager.currentScene.sceneData.bounds.setTo(-100,PICTURE_AREA_Y, _originalBounds.width + PICTURE_AREA_WIDTH, _originalBounds.height - 50);
			super.shellApi.camera.camera.area = filmingBounds;
			
			/**
			 * Had to make a dummy Entity to follow the Input Entity with a camera offset so I could properly set
			 * the camera's target to the dummy Entity's Spatial. Painful. The Camera should be an entity...
			 */
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			
			var spatial:Spatial = this.player.get(Spatial);
			sprite.x = spatial.x;
			sprite.y = spatial.y;
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, sprite);
			var target:FollowTarget = new FollowTarget(this.shellApi.inputEntity.get(Spatial), 0.05, true);
			entity.add(target);
			entity.add(new Id("dummyCamera"));
			entity.add(new KeepWithInDistance(new Point(150, 375),3,kirk.get(Spatial),false));
			KeepWithInDistance(entity.get(KeepWithInDistance)).loose.add(resetScene);
			
			this.shellApi.camera.target = entity.get(Spatial);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, this.sayAction));
		}
		
		private function sayAction():void
		{
			var dialog:Dialog = this.carson.get(Dialog);
			dialog.sayById("action");
			dialog.complete.addOnce(this.startScene);
		}
		
		private function startScene(data:DialogData):void
		{
			KeepWithInDistance(getEntityById("dummyCamera").get(KeepWithInDistance)).keepTrack = true;
			
			CharUtils.setDirection(this.kirk, false);
			CharUtils.setAnim(this.kirk, WalkNinja);
			flashLight = SkinUtils.getSkinPartEntity(kirk, SkinUtils.ITEM);
			var flashClip:MovieClip = Display(flashLight.get(Display)).displayObject as MovieClip;
			flashClip = flashClip.getChildAt(1) as MovieClip;
			TimelineUtils.convertClip(flashClip, this, flashLight, null, false);
			
			var tween:Tween = kirk.get(Tween);
			
			tween.to(this.kirk.get(Spatial), 2, {x:1460, ease:Linear.easeNone, onComplete:this.reachedSled});
			
			//Setting this label handler to false stops the animation for ALL instances where Kirk moves his flashlight.
			var timeline:Timeline = this.kirk.get(Timeline);
			timeline.handleLabel("pointing", Command.create(
				function(timeline:Timeline):void { timeline.stop(); }, timeline), false);
		}
		
		private function reachedSled():void
		{
			shellApi.triggerEvent("flashlight_on");
			Timeline(flashLight.get(Timeline)).gotoAndStop(2);
			
			CharUtils.setAnim(this.kirk, PointItem);
			SkinUtils.setSkinPart(this.kirk, SkinUtils.MOUTH, "ooh", false);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, this.moveToBear));
		}
		
		private function moveToBear():void
		{
			shellApi.triggerEvent("flashlight_off");
			Timeline(flashLight.get(Timeline)).gotoAndStop(1);
			
			CharUtils.setAnim(this.kirk, WalkNinja);
			var tween:Tween = kirk.get(Tween);
			tween.to(kirk.get(Spatial), 2, {x:1225, ease:Linear.easeNone, onComplete:this.reachedBear});
		}
		
		private function reachedBear():void
		{
			shellApi.triggerEvent("flashlight_on");
			Timeline(flashLight.get(Timeline)).gotoAndStop(2);
			CharUtils.setAnim(this.kirk, PointItem);
			SkinUtils.setSkinPart(this.kirk, SkinUtils.MOUTH, "distressedMom", false);
			
			var door:Entity = this.getEntityById("door");
			door.get(Timeline).playing = true;
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, this.moveToCloset));
		}
		
		private function moveToCloset():void
		{
			shellApi.triggerEvent("flashlight_off");
			Timeline(flashLight.get(Timeline)).gotoAndStop(1);
			
			CharUtils.setAnim(kirk, WalkNinja);
			var tween:Tween = kirk.get(Tween);
			tween.to(kirk.get(Spatial), 3, {x:785, ease:Linear.easeNone, onComplete:this.reachedCloset});
		}
		
		private function reachedCloset():void
		{
			CharUtils.setAnim(this.kirk, Tremble);
			
			var door:Entity = this.getEntityById("door");
			var timeline:Timeline = door.get(Timeline);
			timeline.gotoAndPlay("open");
			
			timeline.handleLabel("end", this.catRun);
		}
		
		private function catRun():void
		{
			shellApi.triggerEvent("cat_meow");
			var sleep:Sleep = this.cat.get(Sleep);
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			
			CharUtils.followPath(this.cat, new <Point> [new Point(1800, 1200)],goToSleep);
			
			this.addSystem(new ThresholdSystem());
			
			var threshold:Threshold = new Threshold("x", ">");
			threshold.threshold = 785;
			threshold.entered.addOnce(this.catHitsKirk);
			this.cat.add(threshold);
		}
		
		private function goToSleep(entity:Entity):void
		{
			Display(cat.get(Display)).visible = false;
		}
		
		private function catHitsKirk():void
		{
			CharUtils.setAnim(this.kirk, Hurt);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, this.goUpstairs));
		}
		
		private function goUpstairs():void
		{
			CharUtils.followPath(this.kirk, new <Point> [new Point(925, 1150), new Point(780, 980), new Point(615, 820), new Point(840, 700), new Point(970, 730)], this.reachedUpstairs);
		}
		
		private function reachedUpstairs(kirk:Entity):void
		{
			CharUtils.setAnim(this.kirk, Tremble);
			
			var window:Entity = this.getEntityById("window");
			var timeline:Timeline = window.get(Timeline);
			timeline.gotoAndPlay(0);
			
			function startSnow(snow:Entity):void
			{
				shellApi.triggerEvent("wind_blowing");
				var emitter:Emitter = snow.get(Emitter);
				emitter.start = true;
				emitter.emitter.counter.resume();
			};
			timeline.handleLabel("window_open", Command.create(startSnow, this.getEntityById("snow")));
			timeline.handleLabel("ending", this.goToFire);
		}
		
		private function goToFire():void
		{
			CharUtils.stateDrivenOn(this.kirk);
			CharUtils.followPath(this.kirk, new <Point> [new Point(1450, 730)], this.reachedFire);
		}
		
		private function reachedFire(kirk:Entity):void
		{
			CharUtils.setAnim(this.kirk, Grief);
			
			shellApi.triggerEvent("fire_flare");
			
			for(var i:int = 1; i <= 4; i++)
			{
				this._hitContainer["flame" + i].visible = true;
				var spark:Entity = this.getEntityById("spark" + i);
				spark.get(Timeline).playing = true;
			}
			
			var timeline:Timeline = this.kirk.get(Timeline);
			timeline.handleLabel("ending", this.goToPlates);
		}
		
		private function goToPlates():void
		{
			CharUtils.followPath(this.kirk, new <Point> [new Point(820, 730)], this.reachedPlates);
		}
		
		private function reachedPlates(kirk:Entity):void
		{
			var timeline:Timeline;
			
			CharUtils.setAnim(this.kirk, Proud);
			
			timeline = this.kirk.get(Timeline);
			
			function stand(timeline:Timeline):void { timeline.stop(); };
			timeline.handleLabel("stand", Command.create(stand, timeline));
			
			var plates:Entity = this.getEntityById("plates");
			timeline = plates.get(Timeline);
			timeline.playing = true;
			
			function duck(kirk:Entity):void
			{
				CharUtils.setAnim(kirk, DuckDown);
				timeline = kirk.get(Timeline);
				timeline.gotoAndStop(3);
				
				SkinUtils.setSkinPart(kirk, SkinUtils.MOUTH, "ooh");
				SkinUtils.setEyeStates(kirk, "open");
			};
			timeline.handleLabel("loop", Command.create(duck, this.kirk));
			timeline.handleLabel("loop", Command.create(SceneUtil.addTimedEvent, this, new TimedEvent(1, 1, this.goDownstairs)));
		}
		
		private function goDownstairs():void
		{
			CharUtils.stateDrivenOn(this.kirk);
			CharUtils.followPath(this.kirk, new <Point> [new Point(660, 860), new Point(925, 1150)], this.reachedDownstairs);
		}
		
		private function reachedDownstairs(kirk:Entity):void
		{
			CharUtils.setAnim(this.kirk, WalkNinja);
			
			var tween:Tween = this.kirk.get(Tween);
			tween.to(this.kirk.get(Spatial), 1, {x:1030, onComplete:this.moveToChest});
		}
		
		private function moveToChest():void
		{
			var bear:Entity = this.getEntityById("bear");
			bear.get(Timeline).playing = true;
			
			shellApi.triggerEvent("bear_roar");
			
			Timeline(this.kirk.get(Timeline)).reverse = true;
			
			var animation:RigAnimation = CharUtils.getRigAnim(this.kirk, 1);
			if (!animation)
			{
				var slot:Entity = AnimationSlotCreator.create(this.kirk);
				animation = slot.get(RigAnimation) as RigAnimation;
			}
			animation.next = Cry;
			animation.addParts(CharUtils.HAND_FRONT);
			
			var tween:Tween = this.kirk.get(Tween);
			tween.to(this.kirk.get(Spatial), 2.5, {x:785, onComplete:this.reachedChest});
		}
		
		private function reachedChest():void
		{
			CharUtils.setDirection(this.kirk, false);
			
			var chest:Entity = this.getEntityById("chest");
			chest.get(Timeline).playing = true;
			
			var animation:RigAnimation = CharUtils.getRigAnim(this.kirk, 1);
			if (!animation)
			{
				var slot:Entity = AnimationSlotCreator.create(this.kirk);
				animation = slot.get(RigAnimation) as RigAnimation;
			}
			animation.next = Cry;
			animation.addParts(CharUtils.HAND_FRONT);
			
			var tween:Tween = this.kirk.get(Tween);
			tween.to(this.kirk.get(Spatial), 2.5, {x:925, onComplete:this.reachedStairs});
		}
		
		private function reachedStairs():void
		{
			this.kirk.get(Timeline).reverse = false;
			
			CharUtils.setAnim(this.kirk, HitReact2);
			
			var dialog:Dialog = this.kirk.get(Dialog);
			dialog.sayById("ah");
			dialog.complete.addOnce(this.moveToDoor);
		}
		
		private function moveToDoor(data:DialogData):void
		{
			CharUtils.followPath(this.kirk, new <Point> [new Point(2450, 1235)], exitKirk);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.25,1,reachedDoor));
		}
		
		private function reachedDoor():void
		{
			getEntityById("dummyCamera").remove(KeepWithInDistance);
			
			removeEntity(cat);
			
			this.camera.remove();
			
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this,carson);
			
			this.carson.get(Dialog).sayById("print");
			super.shellApi.camera.camera.area = originalBounds;
			Dialog(carson.get(Dialog)).setCurrentById("take a spin");
		}
		
		private function exitKirk(kirk:Entity):void
		{
			removeEntity(kirk);
		}
		
		private function resetScene():void
		{
			this.camera.remove();
			
			SceneUtil.lockInput(this);
			SceneUtil.setCameraTarget(this,carson);
			this.carson.get(Dialog).sayById("cut");
			super.shellApi.camera.camera.area = originalBounds;
			
			var i:int = 0;
			var spatial:Spatial;
			
			//Animations
			var animations:Array = ["table", "window", "door", "bear", "chest", "plates", "cameraInteraction"];
			for(i = 0; i < animations.length; i++)
			{
				var animation:String = animations[i];
				
				var timeline:Timeline = this.getEntityById(animation).get(Timeline);
				timeline.gotoAndStop(0);
			}
			
			//Fire
			for(i = 1; i <= 4; i++)
			{
				this._hitContainer["flame" + i].visible = false;
				var spark:Entity = this.getEntityById("spark" + i);
				spark.get(Timeline).gotoAndStop(0);
			}
			
			//Snow
			var emitter:Emitter = this.getEntityById("snow").get(Emitter);
			emitter.emitter.counter.stop();
			
			//Kirk
			Timeline(flashLight.get(Timeline)).gotoAndStop(0);
			CharUtils.setAnim(this.kirk, Think);
			kirk.remove(Tween);
			kirk.add(new Tween());
			spatial = this.kirk.get(Spatial);
			spatial.x = 1700;
			spatial.y = 1140;
			kirk.remove(CharacterMotionControl);
			
			//Cat
			spatial = this.cat.get(Spatial);
			spatial.x = 500;
			spatial.y = 1170;
			cat.remove(CharacterMotionControl);
			
			this.cat.get(Sleep).sleeping = true;
		}
		
		private function saveTakesToServer():void
		{
			shellApi.setUserField("stage1",takes,shellApi.island,true);
		}
	}
}