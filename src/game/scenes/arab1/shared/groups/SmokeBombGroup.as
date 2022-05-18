package game.scenes.arab1.shared.groups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Cough;
	import game.data.ui.ToolTipType;
	import game.scene.template.GameScene;
	import game.scenes.arab1.shared.particles.EmberParticles;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.systems.entity.EyeSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;

	public class SmokeBombGroup extends Group
	{
		public function SmokeBombGroup(scene:GameScene, container:DisplayObjectContainer)
		{
			_scene = scene;
			_container = container;
		}
		
		override public function added():void
		{
			this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/arab1/shared/sb_explosion.swf", makeBombEffect);
		}
		
		private function makeBombEffect(clip:DisplayObjectContainer):void{
			_bombEffect = EntityUtils.createSpatialEntity(this, clip, _container);
			TimelineUtils.convertClip(clip as MovieClip, this, null, _bombEffect, true);
			_bombEffect.add(new Id("bombEffect"));
			
			//this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/arab1/shared/particles/smoke_particle.swf", setupSmokeParticles);
			this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/arab1/shared/particles/smoke_particle_thief.swf", setupThiefParticles);
			//this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/arab1/shared/particles/smoke_particle_genie.swf", setupGenieParticles);
		}
		
		private function setupSmokeParticles(clip:DisplayObjectContainer):void{
			_smokeClip = clip;
			
			_smokeParticles = new SmokeParticles();
			_smokeParticleEmitter = EmitterCreator.create(this, _container, _smokeParticles, 0, -20, null, null, _bombEffect.get(Spatial));
			_smokeParticles.init(this, clip);
			
			_emberParticles = new EmberParticles();
			_emberParticleEmitter = EmitterCreator.create(this, _container, _emberParticles, 0, 0, null, null, _bombEffect.get(Spatial));
			_emberParticles.init(this);
			
			
			DisplayUtils.moveToTop(Display(_bombEffect.get(Display)).displayObject);
		}
		
		private function setupThiefParticles(clip:DisplayObjectContainer):void{
			_thiefSmoke = new SmokeParticles();
			_thiefSmokeEmitter = EmitterCreator.create(this, _container, _thiefSmoke, 0, -20, null, null, _bombEffect.get(Spatial));
			_thiefSmoke.init(this, clip, 0.8, 60, 35, 1, -200, 40);
			
			_thiefParticles = new EmberParticles();
			_thiefParticleEmitter = EmitterCreator.create(this, _container, _thiefParticles, 0, 0, null, null, _bombEffect.get(Spatial));
			_thiefParticles.init(this, 0xFFFFFF, 0xFF3300, 1.4, 120);
		}
		
		private function setupGenieParticles(clip:DisplayObjectContainer):void{
			_genieParticles = new SmokeParticles();
			_genieParticleEmitter = EmitterCreator.create(this, _container, _genieParticles, 0, -20, null, null, _bombEffect.get(Spatial));
			_genieParticles.init(this, clip, 2.0, 30, 45);
			
			_magicParticles = new EmberParticles();
			_magicParticleEmitter = EmitterCreator.create(this, _container, _magicParticles, 0, 0, null, null, _bombEffect.get(Spatial));
			_magicParticles.init(this, 0xCC3399, 0x66ffff, 1.3, 40);
		}
		
		public function createTest($testEntity:Entity, $handler:Function):void{
			
			if($handler == this.testBomb){
				_testBomb = $testEntity;
			}
			
			if($handler == this.testSmoke){
				_testSmoke = $testEntity;
			}
			
			if($handler == this.testGenie){
				_testGenie = $testEntity;
			}
			
			// create clickable state
			var inter:Interaction = InteractionCreator.addToEntity($testEntity,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.minTargetDelta.y = 170;
			sceneInter.minTargetDelta.x = 170;
			sceneInter.reached.add($handler);
			
			ToolTipCreator.addToEntity($testEntity, ToolTipType.CLICK);
			
			$testEntity.add(sceneInter);
			$testEntity.add(new ToolTip());
			
		}
		
		public function testBomb(...p):void{
			explodeAt(_testBomb.get(Spatial));
		}
		
		public function testSmoke(...p):void{
			thiefAt(_testSmoke.get(Spatial));
		}
		
		public function testGenie(...p):void{
			genieAt(_testGenie.get(Spatial));
		}
		
		private function explodeAt($spatial:Spatial):void{
			var effectSpatial:Spatial = _bombEffect.get(Spatial);
			effectSpatial.x = $spatial.x;
			effectSpatial.y = $spatial.y;
			
			var timelineEntity:Entity = Children(_bombEffect.get(Children)).children[0];
			Timeline(timelineEntity.get(Timeline)).gotoAndPlay(2);
			_smokeParticles.puff();
			_emberParticles.puff();
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"big_pop_01.mp3");
			
			var playerSpatial:Spatial = _scene.player.get(Spatial);
			// detect npc/player entities around radius
			if(Point.distance(new Point(effectSpatial.x, effectSpatial.y), new Point(playerSpatial.x, playerSpatial.y)) < SMOKE_BOMB_RADIUS){
				smokeChar(_scene.player);
			}
		}
		
		public function thiefAt($spatial:Spatial, $silent:Boolean = false, $fast:Boolean = false):void{
			var effectSpatial:Spatial = _bombEffect.get(Spatial);
			effectSpatial.x = $spatial.x;
			effectSpatial.y = $spatial.y;
			
			var timelineEntity:Entity = Children(_bombEffect.get(Children)).children[0];
			Timeline(timelineEntity.get(Timeline)).gotoAndPlay(2);
			if(!$fast){
				_thiefSmoke.screen();
			} else {
				_thiefSmoke.puff();
			}
			_thiefParticles.puff();
			
			if(!$silent){
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"whoosh_04.mp3", 1.4);
			}
		}
		
		private function genieAt($spatial:Spatial):void{
			var effectSpatial:Spatial = _bombEffect.get(Spatial);
			effectSpatial.x = $spatial.x;
			effectSpatial.y = $spatial.y;
			
			_genieParticles.stream();
			_magicParticles.stream();
		}
		
		private function smokeChar($character:Entity):void{
			// create smoke on character's face
			var smokeParticles:SmokeParticles = new SmokeParticles();
			var smokeEmitter:Entity = EmitterCreator.create(this, _container, smokeParticles, 0, -40, null, null, $character.get(Spatial));
			smokeParticles.init(this, _smokeClip, 1.0, 20, 20, 0.7, -50);
			smokeParticles.stream();
			
			CharUtils.stateDrivenOff($character, 9999);
			
			// close eyes
			var eyesEntity:Entity = CharUtils.getPart($character, "eyes");
			var eyes:Eyes = eyesEntity.get(Eyes);
			eyes.state = EyeSystem.ANGRY;
			
			// start coughing fit
			CharUtils.setAnimSequence($character, new <Class>[Cough], true);
			smokeParticles.endParticle.addOnce(Command.create(resetChar, $character));
		}
		
		
		private function resetChar($character:Entity):void{
			CharUtils.setAnimSequence($character, new <Class>[], false); // clear anim sequence
			CharUtils.stateDrivenOn($character);
			CharUtils.setState($character, "stand");
		}
		
		private var _smokeClip:DisplayObjectContainer;
		
		private var _testBomb:Entity;
		private var _testSmoke:Entity;
		private var _testGenie:Entity;
		private var _bombEffect:Entity;
		private var _container:DisplayObjectContainer;
		private var _scene:GameScene
		
		private var _smokeParticles:SmokeParticles;
		private var _smokeParticleEmitter:Entity;
		private var _emberParticles:EmberParticles;
		private var _emberParticleEmitter:Entity;
		
		private var _thiefSmoke:SmokeParticles;
		private var _thiefSmokeEmitter:Entity;
		private var _thiefParticles:EmberParticles;
		private var _thiefParticleEmitter:Entity;
		
		private var _genieParticles:SmokeParticles;
		private var _genieParticleEmitter:Entity;
		private var _magicParticles:EmberParticles;
		private var _magicParticleEmitter:Entity;
		
		private const SMOKE_BOMB_RADIUS:Number = 100;
	}
}