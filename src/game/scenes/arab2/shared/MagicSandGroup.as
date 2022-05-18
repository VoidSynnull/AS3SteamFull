package game.scenes.arab2.shared
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.hit.Platform;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.LabelHandler;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.GameScene;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab1.shared.particles.EmberParticles;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class MagicSandGroup extends Group
	{
		private var _container:DisplayObjectContainer;
		
		private var _bombEffect:Entity;
		
		private var _smokeParticleEmitter:Entity;
		private var _smokeParticles:SmokeParticles;
		private var _emberParticles:EmberParticles;
		private var _emberParticleEmitter:Entity;
		private var _sparkParticles:SparkleBlast;
		private var _sparkParticleEmitter:Entity;
		
		
		private var _smokeClip:DisplayObjectContainer;
		
		public var effectDuration:Number = 5;
		public var resetTimerEnabled:Boolean = true;
		
		public var platEffected:Signal = new Signal(String);
		
		private const POP_SOUND:String = SoundManager.EFFECTS_PATH+"small_explosion_03.mp3";
		private const FADE_SOUND:String = SoundManager.EFFECTS_PATH+"sand_slide_01.mp3";
		
		private const EXPLOSION_PATH:String = "scenes/arab2/shared/sb_explosion.swf";
		private const SMOKE_PATH:String = "scenes/arab2/shared/smoke_particle_genie.swf";
		
		public static const GROUP_ID:String = "MagicSandGroup";
		
		public function MagicSandGroup(container:DisplayObjectContainer)
		{
			this.id = GROUP_ID;
			_container = container;
		}
		
		override public function added():void
		{
			this.shellApi.loadFile(this.shellApi.assetPrefix + EXPLOSION_PATH, createBombEffect);
		}
		
		/**
		 * prepair existing platforms to work with magic sand effects
		 * requires that platforms are already created in xml and have the correct names
		 */
		public function setupPlatforms():void
		{
			var sandPlatform:Entity;
			var sandArt:Entity;
			var sharedSequence:BitmapSequence;
			for (var i:int = 0; null != _container["magicSandArt"+i]; i++) 
			{
				// setup sand aniamtion entity
				DisplayUtils.moveToTop(_container["magicSandArt"+i]);
				sandArt = EntityUtils.createMovingTimelineEntity(parent, _container["magicSandArt"+i], _container,false,22);
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					if(!sharedSequence){
						sharedSequence = BitmapTimelineCreator.createSequence(_container["magicSandArt"+i],true,PerformanceUtils.defaultBitmapQuality);
					}
					sandArt = BitmapTimelineCreator.convertToBitmapTimeline(sandArt,null,true,sharedSequence,PerformanceUtils.defaultBitmapQuality,22);
				}
				sandArt.add(new Id("magicSandArt"+i));
				// setup platform
				sandPlatform = parent.getEntityById("magicSandPlat"+i);
				sandPlatform.get(Display).visible = false;
				sandPlatform.add(new MagicSand());
				sandPlatform.add(new Sleep(false,true));
				sandArt.add(new Sleep(false,true));
			}
		}
		
		public function explodeAt(spatial:Spatial):void{
			var effectSpatial:Spatial = _bombEffect.get(Spatial);
			effectSpatial.x = spatial.x;
			effectSpatial.y = spatial.y;	
			
			var timelineEntity:Entity = Children(_bombEffect.get(Children)).children[0];
			Timeline(timelineEntity.get(Timeline)).gotoAndPlay(2);
			
			addMagicSparks(effectSpatial);
			
			_smokeParticles.puff();
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH){
				_emberParticles.puff();
			}
			
			AudioUtils.play(parent, POP_SOUND,2.0,false,null,null,.5);
		}
		
		private function addMagicSparks(spatial:Spatial):void
		{
			_sparkParticles = new SparkleBlast();
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				_sparkParticles.init(this,Command.create(cleanUp,_sparkParticleEmitter),spatial.x,spatial.y, 90, 50);
			}
			else{
				_sparkParticles.init(this,Command.create(cleanUp,_sparkParticleEmitter),spatial.x,spatial.y, 90, 100);
			}
			_sparkParticleEmitter = EmitterCreator.create(parent, _container, _sparkParticles, 0, 0, _bombEffect, null);
		}
		
		private function cleanUp(ent:Entity):void
		{
			if(ent != null){
				removeEntity(ent);
			}
		}	
		
		private function createBombEffect(clip:MovieClip):void
		{
			if(PlatformUtils.isMobileOS)
			{
				PlatformerGameScene(parent).convertContainer(clip);
			}
			_bombEffect = EntityUtils.createSpatialEntity(parent, clip, _container);
			TimelineUtils.convertClip(clip as MovieClip, parent, null, _bombEffect, true, 25);
			_bombEffect.add(new Id("bombEffect"));
			
			parent.shellApi.loadFile(parent.shellApi.assetPrefix + SMOKE_PATH, setupSmokeParticles);
		}
		
		private function setupSmokeParticles(clip:DisplayObjectContainer):void
		{
			if(PlatformUtils.isMobileOS)
			{
				PlatformerGameScene(parent).convertContainer(clip);
			}
			_smokeClip = clip;
			
			_smokeParticles = new SmokeParticles();
			_smokeParticleEmitter = EmitterCreator.create(parent, _container, _smokeParticles, 0, -20, null, null, _bombEffect.get(Spatial));
			_smokeParticles.init(parent, clip, 2.0, 70);
			
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH){
				_emberParticles = new EmberParticles();
				_emberParticleEmitter = EmitterCreator.create(parent, _container, _emberParticles, 0, 0, null, null, _bombEffect.get(Spatial));
				_emberParticles.init(parent);
			}
			
			DisplayUtils.moveToTop(Display(_bombEffect.get(Display)).displayObject);
		}
		
		public function applyMagicSandEffect(platform:Entity, duration:Number = 0):void
		{
			if(duration > 0){
				effectDuration = duration;
			}
			var i:String = platform.get(Id).id;
			i = i.substr(i.length - 1);
			var art:Entity = parent.getEntityById("magicSandArt"+i);
			
			// dispatch signal
			platEffected.dispatch(i);
			
			//anim
			var timeline:Timeline = art.get(Timeline);
			timeline.gotoAndPlay("start");
			if(!timeline.labelHandlers){
				timeline.labelHandlers = new Vector.<LabelHandler>();
				//timeline.labelReached = new Signal();
			}
			timeline.handleLabel("loop", Command.create(killPlatform, platform));
			
			// add sparkles
			startParticles(art);
			// reset timer
			if(resetTimerEnabled){
				SceneUtil.addTimedEvent(platform.group,new TimedEvent(effectDuration,1,Command.create(removeMagicSandEffect,platform,art)));
			}
			AudioUtils.playSoundFromEntity(platform,FADE_SOUND,500,0.3,1.2,Quad.easeInOut);
		}
		
		public function resetSand(sandPlatform:Entity, sandArt:Entity):void
		{
			removeMagicSandEffect(sandPlatform,sandArt);
		}
		
		private function killPlatform(platform:Entity):void
		{
			platform.remove(Platform);
		}
		
		private function removeMagicSandEffect(platform:Entity, art:Entity):void
		{
			stopParticles(art);
			//anim
			var timeline:Timeline = art.get(Timeline);
			timeline.gotoAndPlay("fade");
			timeline.handleLabel("end", Command.create(addPlatform, platform));
			
			AudioUtils.playSoundFromEntity(platform,FADE_SOUND,500,0.1,0.8,Quad.easeInOut);
		}
		
		private function addPlatform(platform:Entity):void
		{
			platform.add(new Platform());
		}
		
		private function blowUp(node:SpecialAbilityNode, bomb:Entity):void
		{
			// create smoke burst
			explodeAt(bomb.get(Spatial));
			
			// remove bomb
			node.owning.group.removeEntity(bomb);
		}
		
		private function stopParticles(artEnt:Entity):void
		{
			if(artEnt.has(Children)){
				var sparkleEnt:Entity = Children(artEnt.get(Children)).getChildByName("emitter");
				Emitter(sparkleEnt.get(Emitter)).stop = true;
			}
		}
		
		// falling dusty sand
		private function startParticles(artEnt:Entity):void
		{
			var pos:Spatial = artEnt.get(Spatial);
			var sparkleEnt:Entity;
			if(artEnt.has(Children)){
				sparkleEnt = Children(artEnt.get(Children)).getChildByName("emitter");
			}
			if(sparkleEnt == null){
				var box:RectangleZone = new RectangleZone(pos.x-pos.width/2,pos.y-pos.height/2,pos.x+pos.width/2,pos.y+pos.height/2);
				var sparkles:Emitter2D = new Emitter2D();
				sparkles.counter = new Random( 10, 25 );
				sparkles.addInitializer(new ImageClass(Dot, [1.8, 0xE7B13F], true));
				sparkles.addInitializer(new Position(box));
				sparkles.addInitializer(new Lifetime(1.8));
				sparkles.addInitializer(new AlphaInit(0.7,1.0));			
				sparkles.addAction(new Move());
				sparkles.addAction(new Accelerate(0, 35));
				sparkles.addAction(new RandomDrift(60, 10));
				sparkles.addAction(new Fade(1,0));
				sparkles.addAction(new Age());	
				sparkleEnt = EmitterCreator.create(artEnt.group, GameScene(artEnt.group).hitContainer, sparkles,0,0, artEnt);
			}else{
				Emitter(sparkleEnt.get(Emitter)).start = true;
			}
		}
	}
}