package game.scenes.arab3.treasureKeep
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Linear;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.BigStomp;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.DuckNinja;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Overhead;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Sleep;
	import game.data.animation.entity.character.Soar;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Think;
	import game.data.animation.entity.character.Tremble;
	import game.data.specialAbility.islands.arab.MagicCarpet;
	import game.particles.emitter.specialAbility.FlameBlast;
	import game.scenes.arab1.shared.groups.SmokeBombGroup;
	import game.scenes.arab1.shared.particles.EmberParticles;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.scenes.arab2.treasureKeep.particles.GoldSparkleParticle;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.arab3.desert.Desert;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class TreasureKeep extends Arab3Scene
	{	
		private const FADE_SOUND:String = SoundManager.EFFECTS_PATH + "event_09.mp3";
		private const STOMP_SOUND:String = SoundManager.EFFECTS_PATH + "big_pow_05.mp3";
		private const CRACK_SOUND:String = SoundManager.EFFECTS_PATH + "smash_01.mp3";
		private const QUAKE_SOUND:String = SoundManager.EFFECTS_PATH + "earthquake_02_loop.mp3";
		private const GLOW_SOUND:String = SoundManager.EFFECTS_PATH + "event_06.mp3";
		private const SHATTER_SOUND:String = SoundManager.EFFECTS_PATH + "glass_break_03.mp3";
		private const POOF_SOUND:String = SoundManager.EFFECTS_PATH + "poof_02.mp3";
		private const MAGIC_SOUND:String = SoundManager.EFFECTS_PATH + "choral_stinger_01.mp3";
		private const SMASH_SOUND:String = SoundManager.EFFECTS_PATH + "stone_break_06.mp3";
		private const HIT_SOUND:String = SoundManager.EFFECTS_PATH+"big_pow_01.mp3";
		
		private var masterThief:Entity;
		private var masterCoin:Entity;
		private var jailer:Entity;
		private var enforcer:Entity;
		private var genie:Entity;
		
		private var goldCoins:Entity;
		
		private var barbell:Entity;	
		
		private var rocks:Array;
		private var cracks:Array;
		
		private var _correctLamp:Entity;
		private var _smokeParticleEmitter:Entity;
		private var _emberParticleEmitter:Entity;	
		private var _lightOverlayEntity:Entity;
		
		private var _smokeParticles:SmokeParticles;
		private var _emberParticles:EmberParticles;
		private var _goldCoinEmitter:Entity;
		
		private var _smokeBombGroup:SmokeBombGroup;
		private var smallRocks:Array;
		
		public function TreasureKeep()
		{
			super();
		}
		
		override public function load():void
		{
			if(!shellApi.checkEvent(_events.INTRO_COMPLETE))
			{
				SceneUtil.removeIslandParts(this);
			}
			super.load()
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.groupPrefix = "scenes/arab3/treasureKeep/";
			_numSpellTargets = 6;
			super.init( container );
		}
		
		override public function smokeReady():void
		{
			if(!shellApi.checkEvent(_events.INTRO_COMPLETE))
			{
				CharUtils.removeSpecialAbilityByClass(player,MagicCarpet);
			}
			super.smokeReady();		
			setupEntities();
			setupFallingRocks();
			setupGenieAppearance();	
			//			startFallingSmallRocks();
			//			startFallingRocks();
		}
		
		private function setupFallingRocks():void
		{
			this.addSystem(new FallingRockSystem());
			this.addSystem(new ThresholdSystem());
			var clip:MovieClip;
			var rock:Entity;
			rocks = new Array();
			var rockCount:int = 10;
			if(PerformanceUtils.qualityLevel<PerformanceUtils.QUALITY_HIGH){
				rockCount = 5;
			}
			clip = _hitContainer["rock0"];
			var data:BitmapData = BitmapUtils.createBitmapData(clip,1.0);
			var sprite:Sprite// = BitmapUtils.createBitmapSprite(clip,1,null,true, 0, data);
			
			for (var i:int = 0; i < rockCount; i++) 
			{
				sprite = BitmapUtils.createBitmapSprite(clip,1,null,true, 0, data);
				_hitContainer.addChild(sprite);
				rock = EntityUtils.createMovingEntity(this, sprite);
				rock.add(new game.components.entity.Sleep(false, true));
				rock.add(new Id("rock"+i));
				var fall:FallingRock = new FallingRock();
				fall.timer = 0.2 * i;
				fall.resetOffet = GeomUtils.randomInRange(-0.3,0.3);
				fall.setState(fall.LOCKED);
				var spawnX:Number = GeomUtils.randomInRange(fall.xMin,fall.xMax);
				EntityUtils.position(rock,spawnX,-210);
				rock.add(fall);
				DisplayUtils.moveToTop(EntityUtils.getDisplayObject(rock));
				rocks.push(rock);
			}
			
			smallRocks = new Array();
			for (i = 0; i < rockCount; i++) 
			{
				sprite = BitmapUtils.createBitmapSprite(clip,1,null,true, 0, data);
				_hitContainer.addChild(sprite);
				rock = EntityUtils.createMovingEntity(this, sprite);
				rock.add(new game.components.entity.Sleep(false, true));
				rock.add(new Id("rock"+i));
				fall = new FallingRock();
				fall.timer = 0.2 * i;
				fall.resetOffet = GeomUtils.randomInRange(-0.5,0.5);
				fall.setState(fall.LOCKED);
				spawnX = GeomUtils.randomInRange(fall.xMin,fall.xMax);
				EntityUtils.position(rock,spawnX,-210);
				rock.add(fall);
				DisplayUtils.moveToTop(EntityUtils.getDisplayObject(rock));
				smallRocks.push(rock);
			}
			
			// ball that hits player, has hazard
			clip = _hitContainer["barbell"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			}
			barbell = EntityUtils.createMovingEntity(this, clip as MovieClip);
			barbell.get(Spatial).x = player.get(Spatial).x;
			var thresh:Threshold =  new Threshold("y", ">");
			thresh.threshold = player.get(Spatial).y-40;
			thresh.entered.addOnce(knockOutPlayer);
			barbell.add(thresh);
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(barbell));
			
		}
		
		private function knockOutPlayer():void
		{
			var motion:Motion = barbell.get(Motion);
			motion.velocity.y = -400;
			// SOUND 
			AudioUtils.play(this, HIT_SOUND, 1.0, false,null,null,1.5);
			CharUtils.setAnim(player, game.data.animation.entity.character.Sleep);
			SkinUtils.setSkinPart(player, SkinUtils.EYES, "dazed", false);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1,Command.create(shellApi.loadScene,Desert)));
		}
		
		private function startFallingRocks():void
		{
			var scale:Number = 1.0;
			for (var i:int = 0; i < rocks.length; i++) 
			{
				var rock:Entity = rocks[i];
				var fall:FallingRock = rock.get(FallingRock);
				var sign:Number = GeomUtils.randomInt(0,1);
				if(sign == 0){
					sign = -1;
				}
				fall.scale = scale * sign;
				SceneUtil.addTimedEvent(this, new TimedEvent(i,1,Command.create(fall.setState,fall.FALLING)));
			}
		}
		
		private function startFallingSmallRocks():void
		{
			var scale:Number = 0.4;
			for (var i:int = 0; i < smallRocks.length; i++) 
			{
				var rock:Entity = smallRocks[i];
				var fall:FallingRock = rock.get(FallingRock);
				var sign:Number = GeomUtils.randomInt(0,1);
				if(sign == 0){
					sign = -1;
				}
				fall.scale = scale * sign;
				SceneUtil.addTimedEvent(this, new TimedEvent(i,1,Command.create(fall.setState,fall.FALLING)));
			}
		}
		
		private function setupEntities():void
		{
			_smokeBombGroup = this.addChildGroup(new SmokeBombGroup(this, this._hitContainer)) as SmokeBombGroup;
			
			EntityUtils.position(player, 1925,623);
			CharUtils.setDirection(player, true);
			CharUtils.setAnim(player, Tremble);
			SceneUtil.lockInput(this, true);
			
			masterThief = getEntityById("masterThief");
			masterCoin = getEntityById("masterCoin");
			jailer = getEntityById("jailer");
			enforcer = getEntityById("enforcer");
			
			genie = getEntityById("genie");
			Display(genie.get(Display)).visible = false;
			Display(genie.get(Display)).alpha = 0;
			
			ToolTipCreator.removeFromEntity(masterThief);
			ToolTipCreator.removeFromEntity(masterCoin);
			ToolTipCreator.removeFromEntity(jailer);
			ToolTipCreator.removeFromEntity(enforcer);
			ToolTipCreator.removeFromEntity(genie);
			
			super.addGenieWaveMotion(genie);
			
			var crack:Entity;
			var clip:MovieClip;
			cracks = new Array();
			for (var i:int = 0; i < 4; i++) 
			{
				clip = _hitContainer["crack"+i];
				crack = EntityUtils.createMovingTimelineEntity(this, clip, null);
				cracks.push(crack);
			}
		}	
		
		private function setupGenieAppearance():void
		{
			// setup correct lamp
			_correctLamp = EntityUtils.createSpatialEntity(this, _hitContainer["correctLamp"], _hitContainer);
			
			// setup genie smoke (for correct lamp)
			shellApi.loadFile(shellApi.assetPrefix + "scenes/arab2/shared/smoke_particle_genie.swf", setupGenieSmoke);
			shellApi.loadFile(shellApi.assetPrefix + "scenes/arab3/shared/glint_particle.swf", setupGoldSparkle);
		}
		
		private function setupGenieSmoke(clip:DisplayObjectContainer):void{
			var loc:Point = EntityUtils.getPosition(genie);
			_smokeParticles = new SmokeParticles();
			_smokeParticleEmitter = EmitterCreator.create(this, _hitContainer, _smokeParticles, Spatial(_correctLamp.get(Spatial)).x, Spatial(_correctLamp.get(Spatial)).y);
			_smokeParticles.init(this, clip, 1.5, 10, 20, 0.5, -40, -20, true, 0x310a8a);
			_smokeParticles.addAction(new GravityWell(160,loc.x,loc.y,60));
			
			_emberParticles = new EmberParticles();
			_emberParticleEmitter = EmitterCreator.create(this, this.overlayContainer, _emberParticles, 0, 0, null, null); 
			_emberParticles.initViewPort(this, shellApi.viewportWidth, shellApi.viewportHeight); // scene wide
			
			beginIntro();
		}
		
		private function smokeLamp():void{
			//TweenUtils.entityTo(_lightOverlayEntity, Display, 1, {alpha:0, onComplete:darkenScene});
			_emberParticles.sparkle();
			_smokeParticles.stream(20, 25);
		}
		
		private function stopSmokeLamp():void
		{
			_emberParticles.stop();
			_smokeParticles.stream(1, 25);
		}
		
		// bring in genie, stop  smoke, start talking
		private function beginIntro():void
		{			
			smokeLamp();
			
			var actions:ActionChain = new ActionChain(this);
			
			actions.addAction(new PanAction(getEntityById("camZone")));
			actions.addAction(new TalkAction(masterThief, "stand"));
			// SOUND
			actions.addAction(new AudioAction(genie, FADE_SOUND, 500, 1));
			actions.addAction(new CallFunctionAction(showGenie));
			//Command.create(this.screenEffects.fadeToBlack, 2.0, showGenie)
			actions.execute();
		}
		
		private function showGenie(...p):void
		{
			_smokePuffGroup.poofAt(genie, 3.4);
			//_smokePuffGroup.poofAt(_correctLamp, 3);
			for (var i:int = 0; i < 3; i++) 
			{
				var smoke:Entity = getEntityById("smokeZone"+i);
				_smokePuffGroup.poofAt(smoke, 2.6);
			}
			
			_smokePuffGroup.trapJinn(genie, null, dummy, _correctLamp,  null);
			SkinUtils.setSkinPart(genie, SkinUtils.MOUTH, "teethgrin2");
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,show));
			stopSmokeLamp();
			// SOUND
			AudioUtils.playSoundFromEntity(genie, FADE_SOUND, 500, 1);
			SceneUtil.addTimedEvent(this, new TimedEvent(3.6,1,beginCollapse));
		}
		
		private function show(...p):void
		{
			Display(genie.get(Display)).visible = true;
			Display(genie.get(Display)).alpha = 0;
			TweenUtils.entityTo(genie, Display, 2.5, {alpha:1.0, ease:Linear.easeInOut});
		}
		
		private function dummy(...p):void
		{
			// need this for genie puff for some reason
		}
		
		private function beginCollapse(...p):void
		{
			var actions:ActionChain = new ActionChain(this);
			
			//actions.addAction(new PanAction(genie));
			actions.addAction(new PanAction(getEntityById("camZone")));
			actions.addAction(new WaitAction(1.5));
			actions.addAction(new TalkAction(masterThief, "power"));
			actions.addAction(new TalkAction(genie, "small"));
			actions.addAction(new AnimationAction(masterThief, Think) ).noWait = true;
			actions.addAction(new TalkAction(masterThief, "wish"));
			actions.addAction( new AnimationAction(enforcer, BigStomp, "", 45) );
			actions.addAction(new AnimationAction(player, Dizzy)).noWait = true;
			actions.addAction(new AnimationAction(masterThief, Dizzy)).noWait = true;
			Timeline(enforcer.get(Timeline)).handleLabel("sumoStomp",playStompSound);
			actions.addAction(new WaitAction(0.1));
			actions.addAction(new TalkAction(enforcer, "me"));
			actions.addAction(new MoveAction(enforcer,new Point(2250,600),new Point(60,60)));
			actions.addAction(new WaitAction(0.1));
			actions.addAction(new MoveAction(enforcer,new Point(2250,500),new Point(60,60)));
			actions.addAction(new WaitAction(0.3));
			actions.addAction(new CallFunctionAction(Command.create(MotionUtils.zeroMotion,enforcer)));
			actions.addAction(new CallFunctionAction(Command.create(EntityUtils.position,enforcer,2200,510)));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,enforcer,true)));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new AnimationAction(enforcer, Score, "", 35) );
			actions.addAction(new SetSkinAction(enforcer, SkinUtils.ITEM, "an3_lamp", false, true) );
			actions.addAction(new CallFunctionAction(grabLamp));
			actions.addAction(new WaitAction(0.1));
			actions.addAction(new TalkAction(enforcer, "smash"));
			actions.addAction(new TalkAction(genie, "command"));
			actions.addAction(new CallFunctionAction(Command.create(_smokePuffGroup.startSpellCasting, genie)));	
			actions.addAction(new WaitAction(1.1));
			actions.addAction(new CallFunctionAction(Command.create(_smokePuffGroup.castSpell, genie, new <Entity>[ enforcer ], null, collapsePart2)));	
			//SOUND
			//actions.addAction(new AudioAction(genie, POOF_SOUND, 800, 1.5, 1.5));
			//actions.addAction(new AudioAction(enforcer, MAGIC_SOUND, 800, 2.0, 2.0));
			
			actions.execute();
		}
		
		private function collapsePart2(...p):void
		{
			var actions:ActionChain = new ActionChain(this);
			
			actions.addAction(new AnimationAction(player, Tremble)).noWait = true;
			actions.addAction(new AnimationAction(masterThief, Stand)).noWait = true;
			actions.addAction(new WaitAction(0.8));
			actions.addAction(new AnimationAction(enforcer, Proud) );
			actions.addAction(new CallFunctionAction(startShaking));
			var lamp:Entity = SkinUtils.getSkinPartEntity(enforcer, SkinUtils.ITEM);
			actions.addAction(new AudioAction(enforcer, GLOW_SOUND, 550, 1));
			actions.addAction(new TimelineAction(lamp,"glow"));
			actions.addAction(new AnimationAction(enforcer, Tremble)).noWait = true;
			actions.addAction(new TalkAction(enforcer, "uhoh"));
			actions.addAction(new TalkAction(masterThief, "break"));
			actions.addAction(new TalkAction(genie, "anything"));
			actions.addAction(new AnimationAction(enforcer, Grief, "end", 0, false));
			actions.addAction(new AnimationAction(enforcer, Tremble)).noWait = true;
			actions.addAction(new CallFunctionAction(Command.create(_smokeBombGroup.thiefAt,enforcer.get(Spatial), false, true)));
			actions.addAction(new CallFunctionAction(destroyLamp));
			actions.addAction(new AnimationAction(genie, Laugh)).noWait = true;
			actions.addAction(new SetSkinAction(enforcer, SkinUtils.ITEM, "empty"));
			actions.addAction(new WaitAction(1.6));
			actions.addAction(new TalkAction(genie, "free"));
			actions.addAction(new CallFunctionAction(genieLeaves));
			actions.addAction(new WaitAction(1.0));
			actions.addAction(new CallFunctionAction(startBigShaking));
			actions.addAction(new WaitAction(0.7));
			actions.addAction(new TalkAction(jailer, "out"));
			actions.addAction(new PanAction(getEntityById("camZone1")));
			actions.addAction(new MoveAction(jailer, _hitContainer["nav1"], new Point(60,100))).noWait = true;
			actions.addAction(new MoveAction(masterCoin, _hitContainer["nav0"], new Point(60,100)));
			actions.addAction(new MoveAction(masterThief, _hitContainer["nav2"], new Point(60,100)));
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new CallFunctionAction(thiefLeaves));
			actions.addAction(new WaitAction(0.1));
			actions.addAction(new CallFunctionAction(grabCoins));
			actions.addAction(new WaitAction(0.6));
			actions.addAction(new MoveAction(masterCoin, _hitContainer["nav1"], new Point(60,100)));
			actions.addAction(new CallFunctionAction(rockHitsPlayer));
			
			actions.execute();
		}
		
		private function rockHitsPlayer():void
		{
			//drop rock/ball n'chain directly on player, knock out, fade
			var motion:Motion = barbell.get(Motion);
			motion.velocity.y = 600;
			motion.acceleration.y = 1000;
		}
		
		private function genieLeaves():void
		{
			genie.add(new game.components.entity.Sleep(false, true));
			TweenUtils.entityTo(genie, Spatial, 2.2, {y:-200, ease:Back.easeIn, onComplete:crashRoof});
			CharUtils.setAnim(genie, Soar);
			
			CharUtils.setAnim(enforcer,Tremble);
		}
		
		private function crashRoof():void
		{
			AudioUtils.play(this, SMASH_SOUND, 2, false, null, null, 2);
			removeEntity(genie);
		}
		
		private function destroyLamp():void
		{			
			_smokePuffGroup.removeLampSmokes();
			_smokePuffGroup.releaseJinn(genie);
			//makePoof(enforcer.get(Spatial).x,enforcer.get(Spatial).y);
			// SOUND
			AudioUtils.playSoundFromEntity(enforcer, SHATTER_SOUND, 500, 1);
			_smokePuffGroup.removeLampSmokes();
		}
		
		private function grabLamp():void
		{
			var lamp:Entity = SkinUtils.getSkinPartEntity(enforcer, SkinUtils.ITEM);
			_smokePuffGroup.removeLampSmokes();
			_smokePuffGroup.trapJinn(genie,null,dummy,lamp);
			SkinUtils.setSkinPart( genie, SkinUtils.MOUTH, "teethgrin2" );
			
			this.removeEntity(_correctLamp);
		}
		
		private function playStompSound(...p):void
		{
			AudioUtils.play(this, STOMP_SOUND, 1.4);
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false);
		}		
		
		private function setupGoldSparkle(clip:DisplayObjectContainer):void
		{
			var emitter:game.scenes.arab2.treasureKeep.particles.GoldSparkleParticle;
			var entity:Entity;
			
			//Table Coins
			emitter = new game.scenes.arab2.treasureKeep.particles.GoldSparkleParticle();
			_goldCoinEmitter = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1340, 660, 1340 + 120, 660 + 38), 2);
			Display(_goldCoinEmitter.get(Display)).moveToBack();
			
			//Lamps
			emitter = new game.scenes.arab2.treasureKeep.particles.GoldSparkleParticle();
			entity = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1693, 474, 1693 + 188, 474 + 48), 2);
			Display(entity.get(Display)).moveToBack();
			
			//Coins Between Lamps
			emitter = new game.scenes.arab2.treasureKeep.particles.GoldSparkleParticle();
			entity = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1944, 604, 1944 + 248, 604 + 58), 2);
			Display(entity.get(Display)).moveToBack();
			
			//Coins Under Lamps
			emitter = new game.scenes.arab2.treasureKeep.particles.GoldSparkleParticle();
			entity = EmitterCreator.create(this, _hitContainer, emitter);
			emitter.init(clip, new RectangleZone(1618, 660, 1618 + 890, 660 + 78), 4);
			Display(entity.get(Display)).moveToBack();
			
			DisplayUtils.moveToBack(Display(_goldCoinEmitter.get(Display)).displayObject);
			goldCoins = EntityUtils.createSpatialEntity(this, _hitContainer["coins"]);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				DisplayUtils.bitmapDisplayComponent(goldCoins,true, PerformanceUtils.defaultBitmapQuality);
			}
			DisplayUtils.moveToBack(Display(goldCoins.get(Display)).displayObject);
		}
		
		private function startShaking():void
		{
			cameraShake(0.7);
			Timeline(cracks[0].get(Timeline)).gotoAndPlay("start");
			AudioUtils.play(this, CRACK_SOUND, 1.1, false, null, null, 1.1);
			startFallingSmallRocks();
		}
		
		private function startBigShaking():void
		{
			_smokePuffGroup.removeLampSmokes();
			_smokePuffGroup.releaseJinn(genie);
			cameraShake(2.0);
			startFallingRocks();
			// SOUND
			AudioUtils.play(this, CRACK_SOUND, 1.1, false, null, null, 1.1);
			AudioUtils.play(this, QUAKE_SOUND, 1.6, true, null, null, 1.6);
			// start spreading cracks
			for (var i:int = 1; i < cracks.length; i++) 
			{
				Timeline(cracks[i].get(Timeline)).gotoAndPlay("start");	
			}
			
			for each (var rock:Entity in rocks) 
			{
				var fall:FallingRock = rock.get(FallingRock);
				if(fall){
					fall.scale = 1.0;
				}
			}
			
		}
		
		private function cameraShake(magnitude:Number = 0.8):void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion = new WaveMotion();
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 0.8;
			waveMotionData.rate = 1;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			if(!super.hasSystem(WaveMotionSystem))
			{
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
		}
		
		private function stopcameraShake():void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			cameraEntity.remove(WaveMotion);
		}
		
		private function makePoof( x:Number, y:Number ):void
		{
			var puff:FlameBlast = new FlameBlast();
			puff.counter = new Blast( 30);
			puff.addInitializer(new Lifetime(0.3, 0.4));
			puff.addInitializer(new Velocity(new DiscSectorZone(new Point(0,0), 300, 200, -Math.PI, Math.PI )));
			puff.addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			puff.addInitializer(new ImageClass(Blob, [7,0xffffff], true, 6));
			puff.addAction(new Age());
			puff.addAction(new Move());
			puff.addAction(new RotateToDirection());
			puff.addAction(new Fade(0.8,0.1));
			EmitterCreator.create(this,_hitContainer,puff,x,y);
		}
		
		private function grabCoins():void
		{
			SkinUtils.setSkinPart(masterCoin, SkinUtils.ITEM, "an3_coin_pile");
			removeEntity(goldCoins);
			removeEntity(_goldCoinEmitter);
			var rigAnim:RigAnimation = CharUtils.getRigAnim(masterCoin, 1);
			if(rigAnim == null)
			{
				var animationSlot:Entity = AnimationSlotCreator.create(masterCoin);
				rigAnim = animationSlot.get(RigAnimation) as RigAnimation;
			}
			rigAnim.next = Overhead;
			rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK);
		}
		
		private function thiefLeaves():void
		{
			CharUtils.setAnim( masterThief, DuckNinja );
			SceneUtil.addTimedEvent(this, new TimedEvent(0.2,1,poofOut) );
		}
		
		private function poofOut():void
		{
			var display:Display = masterThief.get( Display );
			display.visible = false;
			
			_smokeBombGroup.thiefAt( masterThief.get(Spatial), false, true );
		}
	}
}