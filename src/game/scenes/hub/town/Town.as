package game.scenes.hub.town
{
	import com.greensock.easing.Bounce;
	import com.poptropica.AppConfig;
	import com.poptropica.shells.browser.steps.BrowserStepGetStoreCards;
	import com.poptropica.shells.mobile.steps.MobileStepGetStoreCards;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.getQualifiedClassName;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.hit.HitTest;
	import game.components.motion.Mass;
	import game.components.motion.Proximity;
	import game.components.motion.PulleyConnecter;
	import game.components.motion.PulleyObject;
	import game.components.motion.PulleyRope;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.PlayerLocation;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.character.LookParser;
	import game.data.profile.ProfileData;
	import game.data.sound.SoundModifier;
	import game.data.specialAbility.store.AddSnow;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.data.ui.ToolTipType;
	import game.managers.HouseVideos;
	import game.managers.ProfileManager;
	import game.managers.SceneManager;
	import game.managers.ads.AdManager;
	import game.managers.interfaces.IIslandManager;
	import game.particles.emitter.specialAbility.Snow;
	import game.proxy.ITrackingManager;
	import game.proxy.TrackingManager;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scene.template.ads.AdVideoGroup;
	import game.scene.template.ui.CardGroup;
	import game.scenes.clubhouse.clubhouse.Clubhouse;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.hub.HubEvents;
	import game.scenes.hub.petBarn.PetBarn;
	import game.scenes.hub.race.Race;
	import game.scenes.hub.starcade.Starcade;
	import game.scenes.hub.store.Store;
	import game.scenes.hub.town.wheelPopup.WheelPopup;
	import game.scenes.map.map.Map;
	import game.scenes.map.map.MapIslandLoader;
	import game.scenes.start.login.popups.WarningPopup;
	import game.scenes.tutorial.tutorial.Tutorial;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.CharacterDialogSystem;
	import game.systems.hit.HitTestSystem;
	import game.systems.motion.ProximitySystem;
	import game.systems.motion.PulleySystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.hud.Hud;
	import game.ui.hud.HudPopBrowser;
	import game.ui.saveGame.RealmsRedirectPopup;
	import game.ui.saveGame.SaveGamePopup;
	import game.ui.tutorial.TutorialGroup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.ColorUtil;
	import game.util.DataUtils;
	import game.util.DisplayPositions;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	import game.utils.AdUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.flintparticles.twoD.zones.Zone2D;
	import org.osflash.signals.Signal;
	
	public class Town extends PlatformerGameScene
	{
		private var _events:HubEvents;
		private var _pilot:Entity;
		private var _blimp:Entity;
		private var _platformFilesLoaded:Boolean = false;
		private var _charGroup:CharacterGroup;
		private var _videoGroup:AdVideoGroup;
		
		// carousel
		public const CAROUSEL_WIDTH:int = 501;
		public const CAROUSEL_HEIGHT:int = 263;
		public const CAROUSEL_DELAY:int = 10;
		private var _carouselLoadCounter:int;
		private var _hasBillboard:Boolean = false;
		private var _currentSlot:int = 0; // zero is used for default billboard
		private var _slots:Array = [true, false, false, false, false, false, false, false, false, false, false];
		private var _slotData:Array = [null, null, null, null, null, null];
		private var _carouselHasTimer:Boolean = false;
		
		// how to save tutorial
		public var tutorial:TutorialGroup;
		public const TUTORIAL_ALPHA:Number = .65;
		
		// wheel
		private const LAST_SPIN_DATE:String	= "lastSpinDate";	
		private const DAYS_PER_MONTH:Array = [31,28,31,30,31,30,31,31,30,31,30,31];
		private const DAYS_PER_MONTH_LEAP_YEAR:Array = [31,29,31,30,31,30,31,31,30,31,30,31];
		private var daysSinceLastSpin:int = -1;
		private var testingWheel:Boolean = false;
		private var spunAlready:Boolean = false;
		private const TEST_WHEEL:String = "test_wheel";
		
		// blimp takeover
		private var hasBlimpTakeover:Boolean = false;
		private var blimpVideoY:Number;
		
		public function Town()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{				
			this.groupPrefix = "scenes/hub/town/";
			super.init(container);
			
			// if not mobile, then check for member gifts when scene is done loading
			//super.shellApi.sceneManager.sceneLoaded.addOnce(checkMemberGifts);
		}
		
		override protected function addGroups():void
		{
			trace("town add groups");
			if( !_platformFilesLoaded )
			{
				var filePrefix:String = ( PlatformUtils.isMobileOS ) ? "mobile/" : "browser/";
				super.sceneDataManager.loadSceneConfiguration(GameScene.SCENE_FILE_NAME, super.groupPrefix + filePrefix, loadPlatformSpecificMerge);
			}
			else
			{
				// possible for this to get called again based on how PlatformerGameScene.addGroups works, need to maintain flag so this does loop - bard
				super.addGroups();
			}
		}
		
		private function loadPlatformSpecificMerge(files:Array):void
		{
			trace("town merge");
			_platformFilesLoaded = true;
			var filePrefix:String = ( PlatformUtils.isMobileOS ) ? "mobile/" : "browser/";
			// merge all the scene files from the appropriate folder using the default merge process 
			super.sceneDataManager.mergeSceneFiles(files, super.groupPrefix + filePrefix, super.groupPrefix);
			super.addGroups();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			trace("town load");
			super.load();
			
			if (PlatformUtils.inBrowser) {
				var islandManager:IIslandManager = shellApi.islandManager;
				if (getQualifiedClassName(islandManager.hudGroupClass) != getQualifiedClassName(HudPopBrowser)) {
					islandManager.hudGroupClass = HudPopBrowser;
				}
			}
		}
		
		// all assets ready
		override public function loaded():void
		{
			trace("town loaded");
			//addSnow();
			setupPulley();
			setupAnimations();
			setupWheelOfLoot();
			setupClubhouseDoor();
			setupPetbarnDoor();
			setupStarcadeDoor();
			setupStoreDoor();
			// always remove airplane for now
			removeAirplane();

			shellApi.profileManager.active.RefreshMembershipStatus(shellApi);
			//this.setupPlayerBridgePosition();
			
			_events = (super.events as HubEvents);
			
			// suppress realms, pet barn, and clubhouse on mobile
			if (AppConfig.mobile)
			{
				// remove realms portal and door
				super.hitContainer.removeChild(super.hitContainer["realms"]);
				super.hitContainer.removeChild(super.hitContainer["doorRealms"]);
				// remove clubhouse door
				super.hitContainer.removeChild(super.hitContainer["doorClubhouse"]);
			}
			else
			{
				// if not mobile
				setUpRealmsDoor();
				// remove sign on clubhouse door
				super.hitContainer.removeChild(super.hitContainer["clubhouseSign"]);
			}
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(-800,140), "minibillboard/minibillboardSmallLegs.swf");			

			super.loaded();
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);
			
			// check for blimp takeover
			hasBlimpTakeover = (shellApi.adManager.getAdData(shellApi.adManager.blimpType) != null);
			
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new ProximitySystem());	
			
			this.setupRocks();
			this.setupBarberPole();
			// carousel content will vary across mobile & web (ultimately should be driven by CMS)
			//this.setupCarousel();
			this._hitContainer["carousel"].visible = false;
			_hitContainer.removeChild(_hitContainer["playVideosButton"]);
			this.setupChimney();
			this.setupStore();
			// NOTE :: For now don't implement island on browser, will work on later... bard
			this.setupIsland();
			this.setupBlimp();			
			this.setupTailor();
			this.setupBundleNPCWithRandomBundleLook();
			//this.setupSnow(); //Seasonal code to make it snow
			
			//add setSize here since some users will bypass login now
			super.shellApi.screenManager.setSize();
			
			_charGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			
			shellApi.eventTriggered.add(onEventTriggered);
			// do this every time now that FTUE is removed
			this.setupForTutorial();
			
			isPLayerByMiniGame();
			
			// play videos (suppress on mobile)
			
			removeEntity(getEntityById("doorTheater"));
			
			
			// ITEM 3496 (purple racing sneakers) wasn't added to the CMS when the campaign was put live
			// this is a manual add to the person's inventory if they should have it
			if(shellApi.checkEvent("racer_next_con1") && !shellApi.checkHasItem("3496", "store"))
			{
				shellApi.getItem("3496", "store");
			}
			trace("town load oomplete");
		}
		
		private function addSnow():void
		{
			var emitter:Snow = new Snow(super.shellApi.sceneManager.currentScene.sceneData.bounds.width, super.shellApi.sceneManager.currentScene.sceneData.bounds.height);
			emitter.init();
			emitter.rate = 100;
			EmitterCreator.create( this, overlayContainer, emitter as Emitter2D, 0, 0);
		}
		
		private function removeAirplane():void
		{
			var clip:MovieClip = _hitContainer["airplane_p"];
			if(clip && clip.parent == _hitContainer)
			{
				_hitContainer.removeChild(clip);
			}
		}

		// REALMS /////////////////////////////
		
		private function setUpRealmsDoor():void
		{
			if(shellApi.profileManager.active.isGuest)
			{
				var realms:Entity = getEntityById("doorRealms");
				var door:SceneInteraction = realms.get(SceneInteraction);
				door.reached.removeAll();
				door.reached.add(approachRealmsAsNonMember);
			}
		}
		
		private function approachRealmsAsNonMember(entity:Entity, target:Entity):void
		{
			// TODO Auto Generated method stub
			if(shellApi.profileManager.active.isGuest)
			{
				var popup:RealmsRedirectPopup = addChildGroup(new RealmsRedirectPopup(overlayContainer)) as RealmsRedirectPopup;
				popup.removed.addOnce(checkSaveForRealms);
			}
			else
			{
				var door:Door = target.get(Door);
				door.open = true;
			}
		}
		
		private function checkSaveForRealms(popup:RealmsRedirectPopup):void
		{
			if(popup.save)
				addChildGroup(new SaveGamePopup(overlayContainer));
		}
		
		// WHEEL OF LOOT //////////////////////////////////////////
		
		private function setupWheelOfLoot():void
		{
			trace("set up wheel of loot");
			var soundManager:SoundManager = shellApi.getManager(SoundManager) as SoundManager;
			soundManager.cache(SoundManager.EFFECTS_PATH+"coins_large_rustle_01.mp3");
			soundManager.cache(SoundManager.EFFECTS_PATH+"CrowdCheer_01.mp3");
			soundManager.cache(SoundManager.EFFECTS_PATH+"mini_game_win.mp3");
			// cahche coin sounds
			for(var i:int = 1; i<= 4; i++)
			{
				soundManager.cache(SoundManager.EFFECTS_PATH+"coin_toss_0"+i+".mp3");
			}
			checkLastSpinData();
			createWheelInteraction();
		}
		
		private function createWheelInteraction():void
		{
			var wheelGuy:Entity = getEntityById("wheelGuy");
			var clip:MovieClip = new MovieClip();
			var pos:Point = EntityUtils.getPosition(wheelGuy);
			clip.x = pos.x - 125;
			clip.y = pos.y + 25;
			clip.graphics.beginFill(0,0);
			clip.graphics.drawRect(100, -200, 150, 200);
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			InteractionCreator.addToEntity(entity, ["click"]);
			var interaction:SceneInteraction = new SceneInteraction();
			interaction.reached.add(talkToWheelGuy);
			entity.add(interaction);
			ToolTipCreator.addToEntity(entity);
			interaction = wheelGuy.get(SceneInteraction);
			interaction.reached.add(stopTalking);
		}
		
		private function stopTalking(player:Entity, wheelGuy:Entity):void
		{
			EntityUtils.removeAllWordBalloons(this, player);
		}
		
		private function talkToWheelGuy(...args):void
		{
			SceneInteraction(getEntityById("wheelGuy").get(SceneInteraction)).activated = true;
		}
		
		private function setWheelGuyDialog():void
		{
			var dialog:Dialog = getEntityById("wheelGuy").get(Dialog);
			var saveBtn:Entity = (super.getGroupById( Hud.GROUP_ID ) as Hud).getButtonById( Hud.SAVE );
						
			if(shellApi.profileManager.active.isGuest && saveBtn)
				dialog.setCurrentById("not_registered");
			else
			{
				if(!spunAlready || testingWheel)
					dialog.setCurrentById("spin");
				else
					dialog.setCurrentById("nospin");
			}
		}
		
		private function receivePrize(wheelPopup:WheelPopup):void
		{
			if(wheelPopup.prize == null)
			{
				trace("something ain't right");
				return;
			}
			shellApi.setUserField(LAST_SPIN_DATE, getDay(),null, true);
			if(!testingWheel)
				Dialog(getEntityById("wheelGuy").get(Dialog)).setCurrentById("nospin");
			if(wheelPopup.prize.id == "grandPrize")
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"mini_game_win.mp3");
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"CrowdCheer_01.mp3");
				CharUtils.setAnim(player, Proud);
				if(wheelPopup.prize.unique)
				{
					Timeline(player.get(Timeline)).handleLabel("ending", 
						Command.create(shellApi.showItem, wheelPopup.prize.prize, CardGroup.STORE));
				}
				else
					SceneUtil.getCoins(this,int(wheelPopup.prize.prize)/5, player);
			}
			else
			{
				if(wheelPopup.prize.unique)
					shellApi.showItem( wheelPopup.prize.prize, CardGroup.STORE);
				else
					SceneUtil.getCoins(this,int(wheelPopup.prize.prize)/5, player);
			}
		}
		
		private function getDay():int// returns a number 1-364 or 365 depending on the year
		{
			var date:Date = new Date();
			var day:int = date.date;
			var daysPerMonth:Array = date.fullYear % 4 == 0?DAYS_PER_MONTH_LEAP_YEAR:DAYS_PER_MONTH;
			for(var i:int = 0; i <date.month; i++)
			{
				day += daysPerMonth[i];
			}
			return day;
		}
		
		private function lastSpinDateWas(data:*):void
		{
			var day:int = getDay();
			var previousSpin:int = DataUtils.getNumber(data);
			
			// if day < previousSpin // assume its a new year and let them spin (first spin of the year could even give them a bonus spin)
			// if day - previousDay > 7 // possibly say its been a while
			// if day == previousDay // say come back tomorrow
			
			if(!isNaN(previousSpin))
			{
				daysSinceLastSpin = data - previousSpin;
				if(daysSinceLastSpin < 0)
					daysSinceLastSpin == 0;
			}
			
			spunAlready = day == previousSpin;
			
			trace("last spin number: " + previousSpin + " today's spin number: " + day);
			
			if(getEntityById("wheelGuy"))
				setWheelGuyDialog();
		}
		
		private function checkLastSpinData():void
		{
			shellApi.getUserField(LAST_SPIN_DATE, null, lastSpinDateWas, true);
		}
		
		// SCENE ANIMATIONS ////////////////////////////
		
		private function setupRocks():void
		{
			trace("set up rocks");
			var entity:Entity;
			var wave:WaveMotion;
			for(var index:int = 1; index <= 12; ++index)
			{
				var display:DisplayObject = this._hitContainer.getChildByName("rock" + index);
				if( display )
				{
					if( PlatformUtils.isMobileOS )	// if on mobile bitmap, otherwise OK to leave as vector
					{
						display = this.convertToBitmapSprite(display, null, true, PerformanceUtils.defaultBitmapQuality).sprite;
					}
					entity = EntityUtils.createSpatialEntity(this, display);
					entity.add(new SpatialAddition());
					
					wave = new WaveMotion();
					wave.data.push(new WaveMotionData("y", 5, Utils.randNumInRange(0.01, 0.025), "sin", Utils.randNumInRange(0, 1)));
					wave.data.push(new WaveMotionData("rotation", 10, Utils.randNumInRange(0.01, 0.025), "sin", Utils.randNumInRange(0, 1)));
					entity.add(wave);
				}
			}
		}
		
		private function setupBarberPole():void
		{
			trace("set up barber pole");
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["barberPole"]);
			BitmapTimelineCreator.convertToBitmapTimeline(entity);
			
			entity.get(Timeline).play();
		}
		
		private function setupChimney():void
		{
			trace("set up chimney");
			var emitter2D:Emitter2D = new Emitter2D();
			
			emitter2D.counter = new Random(4, 8);
			emitter2D.addInitializer(new ImageClass(Blob, [20]));
			emitter2D.addInitializer(new ScaleImageInit(0.7, 1.5));
			emitter2D.addInitializer(new Position(new LineZone(new Point(-20, 0), new Point(20, 0))));
			emitter2D.addInitializer(new Velocity(new LineZone(new Point(0, -40), new Point(0, -80))));
			emitter2D.addInitializer(new Lifetime(2, 3));
			emitter2D.addInitializer(new ColorsInit([0x444444, 0x555555, 0x666666, 0x777777]));
			
			emitter2D.addAction(new Age());
			emitter2D.addAction(new Move());
			emitter2D.addAction(new RandomDrift(50, 50));
			emitter2D.addAction(new ScaleImage(0.5, 1.5));
			emitter2D.addAction(new Fade(1, 0));
			emitter2D.addAction(new Accelerate(80, -40));
			
			var entity:Entity = EmitterCreator.create(this, this._hitContainer, emitter2D, 0, 0, null, "chimney");
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = 2425;
			spatial.y = 175;
			
			entity.add(new Sleep());
		}
		
		private function setupAnimations():void
		{
			setupBouncyAnimations();
			trace("set up interactive animations");
			//var clickable:Array = ["seagull", "ac", "thea", "cocoaStand", "shack", "candle", "imp", "bubbling_pot", "statue", "greenFire"];
			var clickable:Array = ["seagull"];
			
			/* var animations:Array = ["flag1","flag2", "sms", 
				"lw1", "lw2", "lw3", "lw4", //fall
				"flame1", "flame2", "flame3", "flame4", "flame5", //halloween
				"flame6", "flame7", "flame8", "flame9", "flame10", //halloween 
				"flame11", "fc1", "fc2", "fc3", "fc4", "fc5", //halloween
				"loop1", "loop2", "loop3", "loop4", "loop5", "loop6", "loop7", "loop8", //wizard
				"cc", "shock1", "shock2", "shock3"];//halloween */
			var animations:Array = ["flag1","flag2"];
			animations = animations.concat(clickable);
			var clip:MovieClip;
			var entity:Entity;
			var interaction:SceneInteraction;
			//pinwheels just spin for days
			var i:int = 1;
			clip = _hitContainer["pinWheel"+i];
			while(clip)
			{
				entity = EntityUtils.createMovingEntity(this, clip);
				Motion(entity.get(Motion)).rotationVelocity = 90;
				SceneUtil.delay(this, 10+i, Command.create(resetRotation, entity));// delay and offset so they don't all reset at the same time
				i++;
				
				clip = _hitContainer["pinWheel"+i];
			}
			
			for(i = 0; i < animations.length; i++)
			{
				clip = _hitContainer[animations[i]];
				if(!clip)
					continue;
				
				entity = EntityUtils.createSpatialEntity(this, clip);
				TimelineUtils.convertClip(clip, this, entity);
				//if meant to be interactive
				if(animations.length - i <= clickable.length)
				{
					InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
					interaction = new SceneInteraction();
					interaction.reached.add(playTimeline);
					entity.add(interaction);
					ToolTipCreator.addToEntity(entity);
					var time:Timeline = entity.get(Timeline);
					time.labelReached.add(shellApi.triggerEvent);
				}
			}
		}
		
		//rotations were getting so big it could not be stored if left alone for 15-20 mins
		private function resetRotation(entity:Entity):void
		{
			var spatial:Spatial = entity.get(Spatial);
			spatial.rotation = spatial.rotation%360;
			SceneUtil.delay(this, 10, Command.create(resetRotation, entity));
		}
		
		private function playTimeline(interactor:Entity, entity:Entity):void
		{
			// TODO Auto Generated method stub
			var time:Timeline = entity.get(Timeline);
			if(time.data.getLabelIndex("click")>-1)
			{
				time.gotoAndPlay("click");
			}
			else
			{
				time.play();
			}
			//play a sound by id
			shellApi.triggerEvent(entity.get(Id).id);
		}
		
		private function setupBouncyAnimations():void
		{
			trace("set up bounce animations");
			var bounceContainer:MovieClip = _hitContainer["bContainer"];
			if(bounceContainer)
			{
				addSystem(new HitTestSystem());
				var clip:MovieClip;
				for(var i:int = 0; i < bounceContainer.numChildren; i++)
				{
					clip = bounceContainer.getChildAt(i) as MovieClip;
					if(clip == null)// only objects that are movieclips are to be converted
						continue;
					var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
					entity.add(new Id(clip.name));
					var hit:Entity = getEntityById(clip.name+"_hit");
					//trace(clip.name);
					if(hit)
					{
						//trace("add hit test to " + clip.name);
						if(clip.name.indexOf("b_") >-1)
							hit.add(new HitTest(onBouncyHit));
						else if(clip.name.indexOf("t_") >-1)
						{
							TimelineUtils.convertClip(clip, this,entity, null, false);
							hit.add(new HitTest(onTimelineHit));
							var time:Timeline = entity.get(Timeline);
							time.labelReached.add(shellApi.triggerEvent);
						}
					}
				}
			}
		}
		
		private function onTimelineHit(entity:Entity, id:String):void
		{
			var hitId:String = entity.get(Id).id;
			var anim:Entity = getEntityById(hitId.substr(0,hitId.length-4));
			var time:Timeline = anim.get(Timeline);
			time.play();
			// if its a one off remove platform
			time.handleLabel("removePlatform", Command.create(removeEntity, entity));
		}
		
		private function onBouncyHit(entity:Entity, id:String):void
		{
			var hitId:String = entity.get(Id).id;
			var anim:Entity = getEntityById(hitId.substr(0,hitId.length-4));
			TweenUtils.entityFromTo(anim, Spatial, .5, {scaleY:.7},{scaleY:1, ease:Bounce.easeInOut});
		}
		
		// CLUBHOUSE ROPE PULLEY /////////////////////////
		
		private function setupPulley():void
		{
			trace("set up pulley");
			var leftPlatform:Entity = getEntityById("pulleyPlatform");
			if(leftPlatform == null)
				return;
			this.player.add(new Mass(-200));
			
			var pulleyConnector:PulleyConnecter = new PulleyConnecter();
			
			var sprite:Sprite = new Sprite();
			sprite.y = 600;
			sprite.x = 1800;
			var rightPlatform:Entity = EntityUtils.createMovingEntity(this, sprite, _hitContainer);
			rightPlatform.add(pulleyConnector);
			rightPlatform.add(new Mass(0));
			var rightPulleyObject:PulleyObject = new PulleyObject(leftPlatform, 700);
			rightPlatform.add(rightPulleyObject);
			
			var leftPulleyObject:PulleyObject = new PulleyObject(rightPlatform, 700);
			leftPulleyObject.startMoving.add(pulleyStartMoving);
			leftPulleyObject.stopMoving.add(pulleyStopMoving);
			leftPulleyObject.wheel = convertToBitmapSprite(_hitContainer["pulleyGear"], _hitContainer, true).sprite;
			leftPulleyObject.wheelSpeedMultiplier = -.1;
			leftPlatform.add(leftPulleyObject);
			leftPlatform.add(new Audio());
			leftPlatform.add(new AudioRange(600));
			leftPlatform.add(pulleyConnector);
			leftPlatform.add(new Mass(100));
			
			var displayEntity:Entity = getEntityById("pulleyFloor");
			var display:Display = displayEntity.get(Display);
			display.disableMouse();
			var leftSpatial:Spatial = displayEntity.get(Spatial);
			var rope1:Entity = EntityUtils.createSpatialEntity(this, convertToBitmapSprite(_hitContainer["pulleyRope"], _hitContainer, true).sprite);
			rope1.add(new PulleyRope(rope1.get(Spatial), leftSpatial, -95));
			
			this.addSystem(new PulleySystem(), SystemPriorities.checkCollisions);
		}
		
		private function pulleyStartMoving(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "wheel_squeak_04_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function pulleyStopMoving(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			audio.stop(SoundManager.EFFECTS_PATH + "wheel_squeak_04_loop.mp3");
		}
		
		// BLIMP /////////////////////////////////////
		
		private function setupBlimp():void
		{
			trace("set up blimp");
			var door:Door = getEntityById('exitToMap').get(Door) as Door;
			door.opening.addOnce(onGondolaEntered);
			
			_blimp = EntityUtils.createSpatialEntity(this, convertToBitmapSprite(_hitContainer["blimp"]).sprite);
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(_blimp));
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		private function onGondolaEntered(e:Entity):void
		{
			sendTrackingEvent(SceneUIGroup.UI_EVENT, 'Tutorial1', 'Click Blimp');
		}

		// MINI-GAME ///////////////////////////////
		
		private function isPLayerByMiniGame():void
		{
			trace("set up is player by mini game");
			var racer:Entity = getEntityById("racer");
			if(sceneData.data.indexOf("mini_game.xml") != -1 && racer)
			{
				var xml:XML = shellApi.getFile(shellApi.dataPrefix + this.groupPrefix + "mini_game.xml");
				for each(var layer:XML in xml.layers.layer)
				{
					if(layer.attribute("id") == "MiniGame")
					{
						var offsetX:Number = DataUtils.getNumber(layer.child("offsetX"));
						var offsetY:Number = DataUtils.getNumber(layer.child("offsetY"));
						
						var playerSpatial:Spatial = player.get(Spatial);
						var diffX:Number = playerSpatial.x - offsetX;
						if(diffX >= 0 && diffX <= 300 && Math.abs(playerSpatial.y - offsetY) < 100)
						{
							racer.get(Dialog).sayCurrent();
						}
						
						return;
					}
				}
			}
		}
		
		// SNOW EFFECT //////////////////////////////////////
		
		/**
		 * Used seasonally to add snow to home scene 
		 */
		private function setupSnow():void
		{
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0xFFFFFF, 0.5);
			shape.graphics.drawCircle(0, 0, 3);
			shape.graphics.endFill();
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(shape);
			
			var width:Number = this.shellApi.viewportWidth;
			var height:Number = this.shellApi.viewportHeight;
			var rectangle:Rectangle = new Rectangle(-50, 0, width + 100, height);
			
			//Makes it snow from the top of the screen
			this.createScreenSideSnow(bitmapData, rectangle, 20, new LineZone(new Point(0, 0), new Point(width, 0)));
			
			/*
			If the player is running, they end up running away from all of the particles since it only snows in an area about the size
			of the screen in the overlayContainer. To fix this, we could also have it snow along the edges of the screen, so running
			off moves side snowflakes back in the center. But too many particles/emitters may be to intense for mobile. Needs testing.
			
			*/
			this.createScreenSideSnow(bitmapData, rectangle, 20, new LineZone(new Point(0, 0), new Point(0, height)));
			this.createScreenSideSnow(bitmapData, rectangle, 20, new LineZone(new Point(width, 0), new Point(width, height)));
		}
		
		private function createScreenSideSnow(bitmapData:BitmapData, rectangle:Rectangle, rate:Number, positionZone:Zone2D):void
		{
			var emitter:Emitter2D = new Emitter2D();
			
			emitter.counter = new Steady(rate);
			
			emitter.addInitializer(new BitmapImage(bitmapData, true));
			emitter.addInitializer(new ScaleImageInit(0.5, 1.5));
			emitter.addInitializer(new Velocity(new RectangleZone(-100, 100, 100, 200)));
			emitter.addInitializer(new Position(positionZone));
			
			emitter.addAction(new Move());
			emitter.addAction(new DeathZone(new RectangleZone(rectangle.left, rectangle.top, rectangle.right, rectangle.bottom), true));
			emitter.addAction(new RandomDrift(100, 100));
			
			EmitterCreator.createSceneWide(this, emitter);
		}
		
		// PLAYER ON BRIDGE //////////////////////////////
		
		private function setupPlayerBridgePosition():void
		{
			trace("set up player bridge position");
			var sceneManager:SceneManager = this.shellApi.sceneManager;
			var prevScene:String = sceneManager.previousScene;
			if (prevScene) {
				var sceneContainsHub:Boolean = prevScene.indexOf('.hub.') > -1;
				var sceneContainsHubCommon:Boolean = prevScene.indexOf('HubCommon') > -1;
				var sceneContainsClubHouse:Boolean = prevScene.indexOf(".clubhouse.") >-1;
				if (!(sceneContainsHub || sceneContainsHubCommon  || sceneContainsClubHouse)) {
					// trace("Seeing as how prevScene is", prevScene, "you must drop in just so");
					var spatial:Spatial = player.get(Spatial) as Spatial;
					spatial.x = sceneData.startPosition.x;
					spatial.y = 400; //sceneData.startPosition.y;
				}
			}
		}
		
		// BUNDLE NPC //////////////////
		
		private function setupBundleNPCWithRandomBundleLook():void
		{
			if(PlatformUtils.isMobileOS)
			{
				//var bundleIndex:int = Utils.randInRange(1, 2); // use for randomizing between a couple bundles
				this.shellApi.loadFile(shellApi.dataPrefix + "bundles/beach1/bundle.xml", onBundleXMLLoaded);
			}
			else
			{
				//This is totally random, and picks from ALL bundles and looks.
				this.shellApi.loadFile(shellApi.dataPrefix + "dlc/bundles/bundles.xml", onBundlesXMLLoaded);
			}			
		}
		
		private function onBundlesXMLLoaded(xml:XML):void
		{
			if(xml)
			{
				var bundlesXML:XMLList = XML(xml.target).child("bundle");
				var bundleXML:XML;
				var activeBundles:Array = [];
				for each(bundleXML in bundlesXML)
				{
					if(bundleXML.attribute("active") == "true")
					{
						// quick hack so the Earth Knight isn't loaded on home island. 
						//if(bundleXML.attribute("id") != "knights")
						activeBundles.push(bundleXML);
					}
				}
				
				if(activeBundles.length > 0)
				{
					bundleXML = activeBundles[Utils.randInRange(0, activeBundles.length - 1)];
					var id:String = bundleXML.attribute("id");
					this.shellApi.loadFile(shellApi.dataPrefix + "bundles/" + id + "/bundle.xml", onBundleXMLLoaded);
				}
			}
		}
		
		private function onBundleXMLLoaded(bundleXML:XML):void
		{
			if(bundleXML)
			{
				var playerGender:String = this.shellApi.profileManager.active.gender;
				var cards:Array = [];
				var genders:Array = [];
				var cardSetsXML:XMLList = XML(bundleXML.cardSets).child("cardSet");
				for each(var cardSetXML:XML in cardSetsXML)
				{
					var cardSetGender:String = cardSetXML.attribute("id");
					if(playerGender == SkinUtils.GENDER_MALE && cardSetGender == SkinUtils.GENDER_FEMALE ||
						playerGender == SkinUtils.GENDER_FEMALE && cardSetGender == SkinUtils.GENDER_MALE)
					{
						continue;
					}
					var cardsXML:XMLList = cardSetXML.child("card");
					for each(var cardXML:XML in cardsXML)
					{
						cards.push(cardXML);
						genders.push(cardSetXML.attribute("id"));
					}
				}
				
				if(cards.length > 0)
				{
					var index:int = Utils.randInRange(0, cards.length - 1);
					var id:String = cards[index];
					this.shellApi.loadFile(shellApi.dataPrefix + "items/store/item" + id + ".xml", onCardXMLLoaded, genders[index], bundleXML);
				}
			}
		}
		
		private function onCardXMLLoaded(cardXML:XML, gender:String, bundleXML:XML):void
		{
			if(cardXML)
			{
				//The cardXML loaded doesn't have any looks. Might be a special ability card. Try finding another card to use.
				if(!cardXML.hasOwnProperty("looks"))
				{
					this.onBundleXMLLoaded(bundleXML);
				}
				else
				{
					var looksXML:XMLList = XML(cardXML.looks).child("look");
					var lookXML:XML = looksXML[Utils.randInRange(0, looksXML.length() - 1)];
					var lookData:LookData = LookParser.parseChar(lookXML);
					lookData.emptyAllFill();
					if(gender == SkinUtils.GENDER_MALE || gender == SkinUtils.GENDER_FEMALE)
					{
						lookData.applyAspect(new LookAspectData(SkinUtils.GENDER, gender));
					}
					SkinUtils.applyLook(this.getEntityById("bundleNpc"), lookData);
				}
			}
		}
		
		// TAILOR NPC ///////////////
		
		private function setupTailor():void
		{
			var tailor:Entity = this.getEntityById("tailor");
			tailor.get(Dialog).replaceKeyword("[Player Name]", shellApi.profileManager.active.avatarName);
			
			var proximity:Proximity = new Proximity(500, this.player.get(Spatial));
			proximity.entered.add(this.tailorTalkToPlayer);
			tailor.add(proximity);
		}
		
		private function tailorTalkToPlayer(tailor:Entity):void
		{
			Dialog(tailor.get(Dialog)).sayById("step_inside");
			// really only want her to interrupt you once per scene entry
			tailor.remove(Proximity);
		}
		

		// TUTORIAL ///////////////////////////
		
		/**
		 * Setup scene and dialog based on players stage in the tutorial process
		 */
		private function setupForTutorial():void
		{
			trace("set up tutorial");
			_pilot = super.getEntityById("amelia");
			_pilot.get(Dialog).replaceKeyword("[Player Name]", shellApi.profileManager.active.avatarName);
			
			if(super.shellApi.checkEvent(_events.TUTORIAL_COMPLETED))
			{
				return;
			}
			
			if(shellApi.profileManager.active.isGuest && !shellApi.checkEvent(_events.TUTORIAL_STARTED))
			{
				shellApi.triggerEvent("new_user");
			}
			
			if(shellApi.profileManager.active.isGuest)
			{
				if(!super.shellApi.checkEvent(_events.TUTORIAL_COMPLETED))
				{
					if(!shellApi.checkEvent(_events.TUTORIAL_STARTED) && !shellApi.checkEvent(_events.SPOKE_TO_AMELIA))
					{
						EntityUtils.position(player, 1650, 780);
						SceneUtil.delay( this, .5, _pilot.get(Dialog).sayCurrent );				
					}
				}
			}			
		}
		
		private function startNewTutorial():void
		{
			// disable during blimp takeover
			if (!hasBlimpTakeover)
			{
				SceneUtil.lockInput(this);
			}
			
			// if player hasn't started tutorial yet, then start it
			if( !shellApi.checkEvent( _events.TUTORIAL_STARTED ) )
			{
				shellApi.completeEvent( _events.TUTORIAL_STARTED );
				shellApi.track(_events.TUTORIAL_STARTED);
				shellApi.loadScene(Tutorial);
			}
			else
			{
				var profileManager:ProfileManager = shellApi.profileManager;
				// we actually want to relaod them to where they left off
				//If they've already started an island, we should return them to where they were.
				var sceneName:String;
				var loc:PlayerLocation = profileManager.active.lastScene["tutorial"];
				if (loc) {
					sceneName = loc.scene;
				}
				if(sceneName)
				{
					var sceneClass:Class = ClassUtils.getClassByName(sceneName);
					if(sceneClass)
					{
						this.shellApi.loadScene(sceneClass);
						return;
					}
				}
				
				shellApi.loadScene(Tutorial);
			}
		}
						
		private function showHowToSave():void
		{
			tutorial = new TutorialGroup(overlayContainer);
			this.addChildGroup(tutorial);
			
			var saveBtn:Entity = (super.getGroupById( Hud.GROUP_ID ) as Hud).getButtonById( Hud.SAVE );
			
			var stepDatas:Vector.<StepData> = new Vector.<StepData>();
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			
			var saveBtnSpatial:Spatial = saveBtn.get(Spatial);			
			
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(saveBtnSpatial.x, saveBtnSpatial.y+super.shellApi.viewportHeight), 60, 60, null, null, null, saveBtn.get(Interaction)));
			texts.push(new TextData("Click the save button to create a username and password.", "tutorialwhite", new Point(shellApi.viewportWidth - 450, saveBtnSpatial.y + super.shellApi.viewportHeight - 80),350));
			var clickHud:StepData = new StepData("save", TUTORIAL_ALPHA, 0x000000, 1.5, true, shapes, texts, null, null);
			tutorial.addStep(clickHud);
			
			tutorial.start();
		}

		/////////////////////////////// EVENT HANDLING ///////////////////////////////
		
		private function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			//trace(event);
			if(event == "open_wheel")
			{
				trace("open wheel");
				if(shellApi.networkAvailable())
				{
					addChildGroup(new WheelPopup(overlayContainer, testingWheel)).removed.addOnce(receivePrize);
					shellApi.track(event, daysSinceLastSpin);
				}else
				{
					shellApi.showNeedNetworkPopup();
				}
				
			}
			if(event == "decline_wheel")
			{
				shellApi.track(event);
			}
			if(event == "play_save_tutorial")
			{
				showHowToSave();
			}
			if(event == "no_has_questions")
			{
				CharUtils.lockControls(player, false, false);
				shellApi.completeEvent(_events.SPOKE_TO_AMELIA);
			}
			else if(event == "open_realms")
			{
				var hud:Hud = this.getGroupById(Hud.GROUP_ID) as Hud;
				//Might wanna check this in case we're not using a HudPopBrowser that doesn't have Realms.
				if(hud is HudPopBrowser)
				{
					hud.openHud();
					HudPopBrowser(hud).openRealms();
				}
			}
			else if(event == _events.START_RACE)
			{
				// if tutorial not completed, then start tutorial
				if (!shellApi.checkEvent(_events.TUTORIAL_COMPLETED))
				{
					shellApi.completeEvent(_events.SPOKE_TO_AMELIA);
					startNewTutorial();
				}
				// else load map
				else
				{
					shellApi.loadScene(Map);
				}
			}
			else if(event == _events.AGREED_RACE || event == _events.AGREED_RECORD_RACE || event == _events.AGREED_MORE_RACE)
			{
				shellApi.loadScene(Race);
			}
			else if(event == "saved_game")
			{
				setWheelGuyDialog();
			}
			else if(event.indexOf("racer_next") != -1)
			{
				var racer:Entity = getEntityById("racer");
				if(racer)
				{
					removeEntity(SkinUtils.getSkinPartEntity(racer, SkinUtils.ITEM2));
					CharUtils.setAnim(racer, Stand);
				}
			}
			//some generic logic effecting player via events
			if(event.indexOf("-") >= -1)
			{
				var params:Array = event.split("-");
				switch(params[0])
				{
					case SET_PART:
					{
						if(params.length == 3)
							SkinUtils.setSkinPart(player, params[1], params[2], false);
						break;
					}
						
					case SET_COLOR:
					{
						if(params.length == 3)
							ColorUtil.tint(EntityUtils.getDisplayObject(player), params[1], params[2]);
						break;
					}
				}
			}
		}
		
		private const SET_PART:String = "setPart";
		private const SET_COLOR:String = "setColor";
				
		private function sendTrackingEvent(eventAKAActionName:String, clusterAKACategoryName:String, choiceAKALabelName:String):void {
			var trackingManager:TrackingManager = shellApi.getManager(ITrackingManager) as TrackingManager;
			if (trackingManager) {
				trackingManager.trackEvent(eventAKAActionName, {cluster:clusterAKACategoryName, choice:choiceAKALabelName});
			}
		}
		/////////////////////////////// STORE ///////////////////////////////
		
		private function setupStore():void
		{
			var doorShop:Entity = this.getEntityById("doorShop");
				
			SceneInteraction(doorShop.get(SceneInteraction)).reached = new Signal();
			SceneInteraction(doorShop.get(SceneInteraction)).reached.add(reachedDoorShop);
		}
		
		private function reachedDoorShop(...p):void
		{
			if( PlatformUtils.isMobileOS )
			{
				if(MobileStepGetStoreCards.failedToGetCards)
				{
					MobileStepGetStoreCards.getCards(shellApi, checkStoreStatus);
				}
				else
					shellApi.loadScene(Store);
			}
			else
			{
				
				if(shellApi.networkAvailable())
				{
					shellApi.loadScene(game.scenes.hub.store.Store);
				}else
				{
					shellApi.showNeedNetworkPopup();
				}
				
			}
		}
		
		private function checkStoreStatus():void
		{
			if(BrowserStepGetStoreCards.failedToGetCards)
			{
				var warning:WarningPopup = addChildGroup(new WarningPopup(overlayContainer)) as WarningPopup;
				warning.ConfigPopup("oops", "could not load store. check connection and try again.");
			}
			else
			{
				shellApi.loadScene(Store);
			}
		}
		
		// SETUP ISLAND UNDER BRIDGE //////////////////////////////////////////
		
		private function setupIsland():void
		{
			trace("set up island");
			var islandBanner:DisplayObject = this._hitContainer["islandBanner"];
			islandBanner.visible = false;
			var profile:ProfileData = shellApi.profileManager.active;
			
			var previousIsland:String = profile.previousIsland;
			
			var as2:Boolean = !DataUtils.validString(previousIsland)?false:previousIsland.indexOf('pop://') == 0;
			
			if(!as2)
			{
				var playerLocation:PlayerLocation = profile.lastScene[previousIsland];
				if(playerLocation && playerLocation.type == PlayerLocation.AS2_TYPE)
				{
					previousIsland = playerLocation.popURL;
					as2 = true;
				}
			}
			
			// skip if previous island is clubhouse (framework should not be saving clubhouse island as previous island)
			if (previousIsland == "clubhouse" || as2)
				return;
			
			trace("previous island: " + previousIsland);
			if(DataUtils.validString(previousIsland)) {
				if (previousIsland.indexOf('pop://') == 0) {
					var loc:PlayerLocation = PlayerLocation.instanceFromPopURL(previousIsland);
					var urlData:Object = ProxyUtils.parsePopURL(previousIsland);
					previousIsland = ProxyUtils.AS3IslandNameFromAS2IslandName(urlData.island);
					profile.lastScene[previousIsland] = loc;
					//					trace("Here's what we put into lastScene[] for", previousIsland, ":" + loc);
				}
				
				//NOTE :: We don't want an island showing up if your previous scene is the Map, another scene in Home, or the Start. This if() still looks kinda fugly though.
				if(!(previousIsland == "hub" || previousIsland == "map" || previousIsland == "start" /*|| previousIsland == "lands"*/))
				{
					var previousScene:String = profile.lastScene[previousIsland];
					if(!DataUtils.validString(previousScene))
					{
						for(var island:String in profile.lastScene)
						{
							trace( island + " : " + profile.lastScene[island]);
						}
						trace("\nTown::setupIsland() will show NO R2G icon because last scene is unknown for", previousIsland + "!");
						return;
					}
					/*
					If an island has a numberical suffix, it's assumed that it's an episodic island. If it is,
					we need to remove the number, as episodic islands use the same island.swf.
					Ex. deepDive1 and deepDive2 both use deepDive.swf.
					*/
					// don't need this now since we have broken out the episodic islands
					//previousIsland = previousIsland.replace(/[0-9]+$/, "Episodic");
					trace("load island under bridge: " + previousIsland);
					var mapIslandLoader:MapIslandLoader = new MapIslandLoader(this, previousIsland);
					mapIslandLoader.loaded.add(islandLoaded);
					mapIslandLoader.load();
				}
			}
		}
		
		private function islandLoaded(mapIslandLoader:MapIslandLoader):void
		{
			//(1450, 1050) Island
			//(1450, 900) Banner
			trace("island loaded");
			
			var islandBanner:DisplayObject = this._hitContainer["islandBanner"];
			
			if(mapIslandLoader.entity)
			{
				var entity:Entity = mapIslandLoader.entity;
				var display:DisplayObject = Display(entity.get(Display)).displayObject;
				var spatial:Spatial = entity.get(Spatial);
				islandBanner.visible = true;
				
				var scale:Number = 1;
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM)
				{
					var container:DisplayObjectContainer = this.getEntityById("backdrop").get(Display).displayObject;
					container.mouseChildren = true;
					
					scale = 1.2;
					
					spatial.x 		= 1500;
					spatial.y 		= 1100;
					spatial.scaleX = spatial.scaleY = scale;
					container.addChild(display);
					
					islandBanner.x = 1500;
					islandBanner.y = 930;
					container.addChild(islandBanner);
				}
				else
				{
					spatial.x = 1575;
					spatial.y = 1030;
					this._hitContainer.addChild(display);
					
					this._hitContainer.addChild(islandBanner);
				}
				
				var island:Entity = EntityUtils.getChildById(entity, "island");
				var button:Button = island.get(Button);
				button.value = mapIslandLoader.islandXML;
				var interaction:Interaction = island.get(Interaction);
				interaction.click.add(islandClicked);
				
				var banner:Entity = EntityUtils.createSpatialEntity(this, islandBanner);
				banner.add(new SpatialAddition());
				
				var wave:WaveMotion = new WaveMotion();
				wave.add(new WaveMotionData("y", 7, 1.6, "sin", 0, true));
				banner.add(wave);
			}
			else
			{
				islandBanner.parent.removeChild(islandBanner);
			}
		}
		
		private function islandClicked(entity:Entity):void
		{
			var profile:ProfileData = shellApi.profileManager.active;
			var destination:String = profile.previousIsland;
			 
			var as2:Boolean = destination.indexOf('pop://') == 0;
			if(!as2)
			{
				var playerLocation:PlayerLocation = profile.lastScene[destination];
				if(playerLocation.type == PlayerLocation.AS2_TYPE)
				{
					destination = playerLocation.popURL;
					as2 = true;
				}
			}
			if (as2)
			{
				// moved to prevent any as2 islands from loading but until we are sure it works will leave this here
				// don't do anything
				// it's possible that the AS2 island will appear because it was saved as the last island in the database
			}
			else
			{
				AS3IslandClicked(entity);
			}
		}
		
		private function AS3IslandClicked(entity:Entity):void
		{
			var profile:ProfileData = shellApi.profileManager.active;
			try {
				////				var previousScene:String = profile.lastScene[profile.previousIsland];
				var previousScene:String = (profile.lastScene[profile.previousIsland] as PlayerLocation).scene;
				trace("We're going to try to make something of", previousScene);
				if (DataUtils.validString(previousScene)) {
					var sceneClass:Class = ClassUtils.getClassByName(previousScene);
					this.shellApi.loadScene(sceneClass, NaN, NaN, null, NaN, NaN, onIslandLoadFailure );
				} else {
					onIslandLoadFailure();
				}
			} catch(error:Error) {
				/*
				We should never even make a button unless there is a scene in ProfileManager's active ProfileData.
				This is a precaution to avoid crashes, but there's no way we should ever get here unless the ProfileData's
				scene is corrupt.
				*/
				onIslandLoadFailure();
			}
		}
		
		/**
		 * Handler for failure during scene load, redirects to map as recovery method
		 */
		private function onIslandLoadFailure():void
		{
			// if there is an issue with loading the island redirect to map
			trace( this,":: ERROR :: onIslandLoadFailure : was an error trying to redirect to last scene, redirecting to map." );
			
			// redirect to map as method of handling failure to manage last scene
			var mapClass:Class = shellApi.islandManager.gameData.mapClass
			
			// NOTE :: Should we bother determining last island or just return to map regardless?
			// Something is already broken if we get here, maybe just returning to map is safest thing - bard
			this.shellApi.loadScene(mapClass);
		}
		
		// CAROUSEL FUNCTIONS ////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Setup carousel images
		 * Images should be swfs at 501x263
		 */
		private function setupCarousel():void
		{
			trace("set up carousel");
			var carouselContainer:DisplayObjectContainer 	= this._hitContainer["carousel"];
			carouselContainer.mouseChildren 				= false;
			carouselContainer.mouseEnabled 					= true;
			
			// get files from cms
			var hasSlots:Boolean = false;
			// check 10 slots
			for (var i:int = 1; i != 11; i++)
			{
				var adData:AdData = AdManager(shellApi.adManager).getCarouselSlot(i);
				// if found and has file data
				if ((adData) && ((adData.campaign_file1) || (adData.campaign_file2)))
				{
					// filter out haxe billboards
					if (adData.campaign_name.toLowerCase().indexOf("haxe") == 0) {
						continue;
					}
					var imagePath:String;
					var isVideo:Boolean = false;
					// if video path in file2
					if (adData.campaign_file2.indexOf("video/") == 0)
					{
						imagePath = adData.campaign_file1;
						isVideo = true;
					}
					else if ((adData.campaign_file2 != null) && (adData.campaign_file2 != ""))
					{
						imagePath = adData.campaign_file2;
					}
					else if ((adData.campaign_file1 != null) && (adData.campaign_file1 != ""))
					{
						imagePath = adData.campaign_file1;
					}
					else
					{
						continue;
					}
					
					hasSlots = true;
					
					var path:String
					// Note: make sure the swf is pushed live or this will fail on mobile
					// check if file2 starts with "images/"
					if (imagePath.substr(0,7) == "images/")
					{
						trace("Getting external billboard: " + imagePath);
						path = "https://" + super.shellApi.siteProxy.fileHost + "/" + imagePath;
						//trace("Town carousel image loading: " + path);
						var loader:Loader = new Loader();
						loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, Command.create(gotExternalBillboard, i, adData, isVideo));
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE, Command.create(gotExternalBillboard, i, adData, isVideo));
						var url:URLRequest = new URLRequest(path);
						var loaderContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
						loader.load(url, loaderContext);			
					}
					else
					{
						path = super.shellApi.assetPrefix + this.groupPrefix + "carousel/" + imagePath;
						trace("Town carousel image loading: " + path);
						// note that this will pull from the LIVE server if not found locally
						shellApi.loadFileWithServerFallback( path, carouselImageLoaded, i, adData, isVideo);
					}
					// increment laod counter
					_carouselLoadCounter++;
				}
			}
			// if carousel slots, then hide default billboard
			var defaultBillbaoard:DisplayObject = _hitContainer["defaultBillboard"];
			trace("is there a default billbaoard? " + defaultBillbaoard);
			if (hasSlots && defaultBillbaoard)
				defaultBillbaoard.visible = false;
		}
		
		private function gotExternalBillboard(event:Event, numSlot:int, adData:AdData, isVideo:Boolean):void
		{
			trace("got external billboard: " +  event.toString());
			trace("target: " + event.target);
			trace("content: " + event.target.content);
			carouselImageLoaded(event.target.content, numSlot, adData, isVideo);
		}
		
		/**
		 * When carousel jpeg or swf loaded 
		 * @param event
		 * @param numSlot
		 */
		private function carouselImageLoaded(asset:DisplayObject, numSlot:int, adData:AdData, isVideo:Boolean):void
		{
			_carouselLoadCounter--;
			if (asset == null)
			{
				// if the swf fails to load from the server, make sure it has been pushed live
				trace("Town carousel image is null for slot " + numSlot);
			}
			else
			{
				_hasBillboard = true;
				_slots[numSlot] = true;
				_slotData[numSlot] = adData;
				trace("Town carousel image loaded in slot " + numSlot);
				
				// add to movie clip
				var clip:MovieClip = new MovieClip();
				clip.addChild(asset);
				// add campaign name and clickURL
				clip.campaign_name = adData.campaign_name;
				clip.clickURL = adData.clickURL;
				// add to carousel
				var slot:MovieClip = MovieClip(this._hitContainer["carousel"].addChild(clip));
				this._hitContainer["carousel"]["slot" + numSlot] = slot;
				// position
				slot.x = 9;
				slot.y = 9;
				slot.visible = false;
				// ad impression (needed to change to every refresh)
				//shellApi.adManager.track(adData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, adData.campaign_type);
				// setup video
				if (isVideo)
				{
					// fixes problem with video buttons
					this._hitContainer["carousel"].mouseChildren = true;
					// setup video
					// if video group exists, then don't create new one
					_videoGroup = AdVideoGroup(this.groupManager.getGroupById("AdVideoGroup"));
					if (_videoGroup == null)
						_videoGroup = new AdVideoGroup();
					// get video path and duration
					var arr:Array = adData.campaign_file2.split(",");
					slot.duration = Number(arr[1]);
					var videoData:Object = {};
					videoData.width = CAROUSEL_WIDTH;
					videoData.height = CAROUSEL_HEIGHT;
					videoData.videoFile = arr[0];
					videoData.locked = (slot.duration <= 15 ? true : false);
					videoData.clickURL = adData.clickURL;
					//videoData.impressionURL = adData.impressionURL; // don't pass to video click impression (use campaign.xml instead for that)
					videoData.campaign_name = adData.campaign_name;
					_videoGroup.setupTownCarouselVideo(this, slot.getChildAt(0)["carouselVideoContainer"], this._hitContainer, videoData);
					slot.isVideo = true;
				}
			}
			
			// when all loaded
			if (_carouselLoadCounter == 0)
				carouselDoneLoading();
		}
		
		/**
		 * When carousel had loaded all slots 
		 */
		private function carouselDoneLoading():void
		{
			var carouselContainer:DisplayObjectContainer = this._hitContainer["carousel"];
			
			// if have billboard slots
			if (_hasBillboard)
			{
				// make into entity
				var carousel:Entity = EntityUtils.createSpatialEntity(this, carouselContainer, this._hitContainer);
				
				// add tooltip
				var offset:Point = new Point(250, 131);
				ToolTipCreator.addToEntity(carousel, ToolTipType.CLICK, null, offset);
				
				// create interaction for clicking on post
				var interaction:Interaction = InteractionCreator.addToEntity(carousel, [InteractionCreator.CLICK], carouselContainer);
				interaction.click.add(carouselClick);
				
				// disable default slot
				_slots[0] = false;
				
				// get next available slot
				getNextSlot(true);
				
				// check number of valid slots
				var count:int = 0;
				for (var i:int = _slots.length-1; i!= 0; i--)
				{
					if (_slots[i])
						count++;
				}
				trace("Town carousel count: " + count);
				// if more than one slot
				if (count > 1)
				{
					_carouselHasTimer = true;
					// setup rotation timer
					SceneUtil.addTimedEvent(this, new TimedEvent(AdManager(shellApi.adManager).carouselDelay, 1, getNextSlot), "carouselTimer");
					// setup dots for clicking
					setupDots(count);
				}
			}
			else
			{
				// if no slots loaded
				// show default billboard
				this._hitContainer["defaultBillboard"].visible = true;
			}
		}
		
		/**
		 * Setup dots on billboard frame for navigation 
		 * @param count
		 */	
		private function setupDots(count:int):void
		{
			trace("set up dots");
			var path:String = super.shellApi.assetPrefix + this.groupPrefix + "carousel/buttonSlide.swf";
			var pos:int = 0;
			for (var slot:int = 0; slot!= _slots.length; slot++)
			{
				// if slot filled
				if (_slots[slot])
				{
					// laod dot and increment position
					shellApi.loadFile(path, dotLoaded, pos, slot, count);
					pos++;
				}
			}
		}
		
		/**
		 * When dot loaded
		 * @param clip
		 * @param pos dot index starting at 0
		 * @param slot occupied billboard slot starting at 1
		 * @param count total dots/billboards
		 */
		private function dotLoaded(clip:MovieClip, pos:int, slot:int, count:int):void
		{
			var spacing:int = 47; // was 50
			
			// add dot to scene
			var dot:MovieClip = MovieClip(this._hitContainer.addChild(clip));
			
			// position and scale dot, carousel is 501x263
			var carousel:MovieClip = this._hitContainer["carousel"];
			dot.y = carousel.y + CAROUSEL_HEIGHT + 24;
			dot.x = carousel.x + (CAROUSEL_WIDTH - (count - 1) * spacing) / 2 + pos * spacing;
			dot.scaleX = dot.scaleY = 0.5;
			
			DisplayUtils.moveToOverUnder(dot, carousel);
			
			// make into button
			var entity:Entity = ButtonCreator.createButtonEntity(clip, this, dotClicked, null, null, null, true, true);
			entity.add(new Id("dot" + slot));
			var button:Button = entity.get(Button);
			// point to billboard slot (won't match pos)
			button.value = slot;
			
			// select first dot
			if (pos == 0)
				button.isSelected = true;
		}
		
		/**
		 * When dot clicked 
		 * @param entity
		 */
		private function dotClicked(entity:Entity):void
		{
			// get button
			var button:Button = entity.get(Button);
			
			// hide current slot and deselect dot if non-zero
			if (_currentSlot != 0)
			{
				this._hitContainer["carousel"]["slot" + _currentSlot].visible = false;
				this.getEntityById("dot" + _currentSlot).get(Button).isSelected = false;
			}
			
			// set current slot
			_currentSlot = button.value;
			// show billboard
			this._hitContainer["carousel"]["slot" + _currentSlot].visible = true;
			// select dot
			button.isSelected = true;
			// restart timer
			SceneUtil.getTimer(this, "carouselTimer").timedEvents[0].start();
		}
		
		/**
		 * Get next carousel slot and make visible
		 * Also called when more than one slot and slots rotate
		 */
		private function getNextSlot(firstTime:Boolean = false):void
		{
			// if timer then setup delay till next billboard
			if (_carouselHasTimer)
			{
				this.removeEntity(this.getEntityById("carouselTimer"));
				SceneUtil.addTimedEvent(this, new TimedEvent(AdManager(shellApi.adManager).carouselDelay, 1, getNextSlot), "carouselTimer");
			}
			
			// hide current slot and deselect dot if non-zero
			if (_currentSlot != 0)
			{
				this._hitContainer["carousel"]["slot" + _currentSlot].visible = false;
				this.getEntityById("dot" + _currentSlot).get(Button).isSelected = false;
			}
			
			while(true)
			{
				// increment slot
				_currentSlot++;
				// wrap to 1 if equals number of slots
				if (_currentSlot == _slots.length)
					_currentSlot = 1;
				// return if slot is filled
				if (_slots[_currentSlot])
					break;
			}
			// show slot
			// trace("Town carousel current slot: " + _currentSlot);
			// impression on every refresh
			var ad:AdData = _slotData[_currentSlot];
			if (ad != null)
			{
				shellApi.adManager.track(ad.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, ad.campaign_type);
			}
			this._hitContainer["carousel"]["slot" + _currentSlot].visible = true;
			// select dot if not first time
			if (!firstTime)
				this.getEntityById("dot" + _currentSlot).get(Button).isSelected = true;
		}
		
		/**
		 * When click on carousel 
		 * @param entity
		 */
		private function carouselClick(entity:Entity):void
		{
			var clip:MovieClip = this._hitContainer["carousel"]["slot" + _currentSlot];
			
			if (clip.isVideo == true)
			{
				// if timer active, then delete old timer and create new one based on duration plus delay
				if (_carouselHasTimer)
				{
					this.removeEntity(this.getEntityById("carouselTimer"));
					SceneUtil.addTimedEvent(this, new TimedEvent(AdManager(shellApi.adManager).carouselDelay + clip.duration, 1, getNextSlot), "carouselTimer");
				}
				return;
			}
			
			if ((clip.clickURL) && (clip.clickURL != ""))
			{
				// if pop url, don't show bumper
				if (clip.clickURL.substr(0,3) == "pop")
				{
					triggerSponsorSite();
				}
				else
				{
					// else go through normal processing
					AdManager.visitSponsorSite(shellApi, clip.campaign_name, triggerSponsorSite);
				}
			}
		}
		
		/**
		 * Open sponsor site (called after delay on mobile) 
		 */
		private function triggerSponsorSite():void
		{
			// tracking
			var clip:MovieClip = this._hitContainer["carousel"]["slot" + _currentSlot];
			AdManager(shellApi.adManager.track(clip.campaign_name, AdTrackingConstants.TRACKING_CLICK_CAROUSEL, "Carousel", "slot " + _currentSlot));
			// open sponsor URL
			AdUtils.openSponsorURL(shellApi, clip.clickURL, clip.campaign_name, "Carousel", "");
		}
				
		// MEMBER GIFTS //////////////////////////////////////
		
		// check for member gifts on web
		private function checkMemberGifts(scene:Group):void
		{
			// get data from memberGifts user field
			super.shellApi.getUserField("memberGifts", "", gotMemberGifts, true);
			// remove listener for sceneLoaded
			super.shellApi.sceneManager.sceneLoaded.remove(checkMemberGifts);
		}
		
		// check data from memberGifts user field
		private function gotMemberGifts(gifts:Object = null):void
		{
			trace("Membergifts: " + gifts);
			// if gifts data is not null
			if (gifts != null)
			{
				// check if array
				var isArray:Boolean = (gifts is Array);
				trace("array: " + isArray)
				// if gifts object is array and contains items
				if ((isArray) && (gifts.length != 0))
				{
					// add cards to inventory
					for each (var item:String in gifts)
					{
						super.shellApi.getItem(item, CardGroup.STORE);
					}
					// remember number of gifts
					_numGifts = String(gifts.length);
					// trigger animation after delay
					SceneUtil.delay(this, 1, triggerMemberAnim);
					return;
				}
			}
			// if no member gifts, then load home popup if any
			//loadHomePopup();
		}
		
		// trigger member gifts animation
		private function triggerMemberAnim():void
		{
			// lock input
			//SceneUtil.lockInput(this, true);
			// load animation
			//super.shellApi.loadFile(super.shellApi.assetPrefix + "ui/popups/memberGifts.swf", memberAnimLoaded);
		}
		
		// when member gifts animation loaded
		private function memberAnimLoaded(clip:MovieClip):void
		{
			// remember clip
			_popupClip = clip;
			
			// disable interaction
			clip.mouseChildren = clip.mouseEnabled = false;
			
			// Add the movieClip to scene
			this.container.addChild(clip);
			
			// Create the new entity and set the display and spatial
			_popupClipEntity = new Entity();
			_popupClipEntity.add(new Display(clip, this.container));
			
			// add to scene
			this.addEntity(_popupClipEntity);
			
			// convert to timeline entity
			var timeline:Entity = TimelineUtils.convertClip(clip.content, this);
			// listener for when animation is done
			TimelineUtils.onLabel( timeline, Animation.LABEL_ENDING, memberAnimDone );
		}
		
		// when member gifts animation is done
		private function memberAnimDone():void
		{
			// clear member gifts field
			super.shellApi.setUserField("memberGifts", [], "", true);
			
			// tracking
			super.shellApi.track("AwardMemberGifts", _numGifts);
			
			// remove popup
			this.container.removeChild(_popupClip);
			this.removeEntity(_popupClipEntity);
			_popupClip = null;
			_popupClipEntity = null;
			
			// unlock input
			SceneUtil.lockInput(this, false);
		}
		
		// HOME POPUP FUNCTIONS /////////////////////////////////////
		
		// load home popup from server if any
		private function loadHomePopup():void
		{
			// check if CMS data
			var adData:AdData = AdManager(shellApi.adManager).getHomePopup();
			// if found and has file data
			if ((adData != null) && ((adData.campaign_file1 != null) || (adData.campaign_file2 != null)))
			{
				// get filename
				var fileName:String;
				// file1 shows for everyone
				if ((adData.campaign_file1 != null) && (adData.campaign_file1 != ""))
				{
					fileName = adData.campaign_file1;
				}
				// file2 shows for members only
				/*if ((adData.campaign_file2 != null) && (adData.campaign_file2 != "") && (!shellApi.profileManager.active.isGuest))
				{
					fileName = adData.campaign_file2;
				}
				*/
				// if filename given
				if ((fileName != null) && (fileName != ""))
				{
					// Note: make sure the image is pushed live or this will fail on mobile
					trace("Getting home popup image: " + fileName);	
					var cardsArr:Array = adData.campaign_file2.split(',');
					if(shellApi.itemManager.checkHas(cardsArr[0],"custom") == false) 
					{
					shellApi.loadFile(fileName, popupImageLoaded, adData);
					}
				}
			}
		}
		
		// when popup image loaded
		private function popupImageLoaded(asset:DisplayObject, adData:AdData):void
	  	{
			if (asset == null)
			{
				// if the image fails to load from the server, make sure it has been pushed live
				trace("Town popup image is null");
			}
			else
			{
				trace("Town popup image loaded");
				
				// add to movie clip and center
				_homePopupClip = new MovieClip();
				var popup:MovieClip = new MovieClip();
				asset = popup.addChild(asset);
				asset.x = shellApi.viewportWidth/2 - asset.width/2;
				asset.y = shellApi.viewportHeight/2 - asset.height/2;
				_homePopupClip.addChild(popup);
				this.overlayContainer.addChild(_homePopupClip);
				
				// add campaign name and clickURL
				_homePopupClip.campaign_name = adData.campaign_name;
				_homePopupClip.clickURL = adData.clickURL;
				
				//track
				AdManager(shellApi.adManager.track(adData.campaign_name, "HomePopup", "Seen"));

				// make popup into entity and make clickable if clickURL given
				if ((adData.clickURL != null) && (adData.clickURL != ""))
				{
					var popupEntity:Entity = EntityUtils.createSpatialEntity(this, popup, _homePopupClip);
					popupEntity.add(new Id("homePopup"));
					ToolTipCreator.addToEntity(popupEntity, ToolTipType.CLICK);
					var interaction:Interaction = InteractionCreator.addToEntity(popupEntity, [InteractionCreator.CLICK], popup);
					interaction.click.add(onClickPopup);
				}
				
				// add close button
				var closeContainer:Sprite = new Sprite()
				_homePopupClip.addChild(closeContainer);
				var buttonEntity:Entity = ButtonCreator.loadCloseButton( this, closeContainer, Command.create(closeHomePopup,adData), DisplayPositions.TOP_RIGHT, 40 + asset.x, 40 + asset.y);
				buttonEntity.add(new Id("closeHomePopup"));

				// add darkened background
				var screenEffects:ScreenEffects = new ScreenEffects();
				var darken:Sprite = screenEffects.createBox(shellApi.viewportWidth, shellApi.viewportHeight, 0x000000);
				darken.alpha = 0.4;
				_homePopupClip.addChildAt(darken, 0);
				
				// pause dialog
				var dialogSystem:CharacterDialogSystem = CharacterDialogSystem(this.getSystem(CharacterDialogSystem));
				dialogSystem.paused = true;
			}
		}
		
		// when clicking on popup that has URL
		private function onClickPopup(button:Entity):void
		{
			// if pop url, don't show bumper
			if (_homePopupClip.clickURL.substr(0,3) == "pop")
			{
				triggerSponsorSitePopup();
			}
			else
			{
				// else go through normal processing
				AdManager.visitSponsorSite(shellApi, _homePopupClip.campaign_name, triggerSponsorSitePopup);
			}
		}
		
		// when clicking out to sponsor site
		private function triggerSponsorSitePopup():void
		{
			// tracking
			AdManager(shellApi.adManager.track(_homePopupClip.campaign_name, AdTrackingConstants.TRACKING_CLICK_CAROUSEL, "Carousel", "slot " + _currentSlot));
			// open sponsor URL
			AdUtils.openSponsorURL(shellApi, _homePopupClip.clickURL, _homePopupClip.campaign_name, "Carousel", "");
		}

		// close home popup
		private function closeHomePopup(button:Entity, adData:AdData):void
		{
			// remove popup
			this.overlayContainer.removeChild(_homePopupClip);
			_homePopupClip = null;
			// remove entities
			this.removeEntity(this.getEntityById("closeHomePopup"));
			this.removeEntity(this.getEntityById("homePopup"));
			// resume dialog
			var dialogSystem:CharacterDialogSystem = CharacterDialogSystem(this.getSystem(CharacterDialogSystem));
			dialogSystem.paused = false;
			if(adData.campaign_file2 != null) {
				// parse multiples
				var cardsArr:Array = adData.campaign_file2.split(',');
				//var campaigns:Array = AdUtils.parseURLs(adData.campaign_name);
				var numCards:int = cardsArr.length;
				// for each card
				for (var i:int=0; i!=numCards; i++)
				{
					// don't trigger tracking if already have card
					// if don't have card yet, then track
					if (!shellApi.checkHasItem(cardsArr[i], CardGroup.CUSTOM))
						super.shellApi.adManager.track(adData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, AdCampaignType.AUTOCARD);
					// get card and animate
					shellApi.getItem(cardsArr[i], CardGroup.CUSTOM, true);
				}
			}
		}
		
		// CLUBHOUSE FUNCTIONS //////////////////////////////
		
		// setup clubhouse door to load last clubhouse
		private function setupClubhouseDoor():void
		{
			// override door's interaction
			var door:Entity = this.getEntityById("doorClubhouse");
			SceneInteraction(door.get(SceneInteraction)).reached = new Signal();
			SceneInteraction(door.get(SceneInteraction)).reached.add(enterClubhouse);
		}
		private function setupPetbarnDoor():void
		{
			// override door's interaction
			var door:Entity = this.getEntityById("doorPetBarn");
			SceneInteraction(door.get(SceneInteraction)).reached = new Signal();
			SceneInteraction(door.get(SceneInteraction)).reached.add(enterPetbarn);
		}
		private function setupStarcadeDoor():void
		{
			// override door's interaction
			var door:Entity = this.getEntityById("doorArcade");
			SceneInteraction(door.get(SceneInteraction)).reached = new Signal();
			SceneInteraction(door.get(SceneInteraction)).reached.add(enterstarcade);
		}
		private function setupStoreDoor():void
		{
			// override door's interaction
			//var door:Entity = this.getEntityById("doorShop");
			//SceneInteraction(door.get(SceneInteraction)).reached = new Signal();
			//SceneInteraction(door.get(SceneInteraction)).reached.add(enterstore);
		}
		// enter last clubhouse when door entered
		private function enterClubhouse(...p):void
		{
			Clubhouse.loadClubhouse(shellApi, shellApi.profileManager.active.login);
		}
		// enter pet if network when door entered
		private function enterPetbarn(...p):void
		{
			if(shellApi.networkAvailable())
			{
				shellApi.loadScene(game.scenes.hub.petBarn.PetBarn);
			}else
			{
				shellApi.showNeedNetworkPopup();
			}
		}
		
		private function enterstarcade(...p):void
		{
			if(shellApi.networkAvailable())
			{
				shellApi.loadScene(game.scenes.hub.starcade.Starcade);
			}else
			{
				shellApi.showNeedNetworkPopup();
			}
		}
		private function enterstore(...p):void
		{
			if(shellApi.networkAvailable())
			{
				shellApi.loadScene(game.scenes.hub.store.Store);
			}else
			{
				shellApi.showNeedNetworkPopup();
			}
		}
		private var _popupClip:MovieClip;
		private var _popupClipEntity:Entity;
		private var _numGifts:String;
		private var _homePopupClip:MovieClip;
	}
}