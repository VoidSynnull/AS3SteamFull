package game.scenes.arab3.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.character.objects.ImpactResponse;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.scenes.arab2.shared.SparkleBlast;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	
	public class DivinationImpactResponse extends ImpactResponse
	{
		private const SMOKE_PATH:String = "scenes/arab3/shared/divination_smoke_particle.swf";
		private const EXPLOSION_PATH:String = "scenes/arab2/shared/sb_explosion.swf";
		
		private const POP_SOUND:String = SoundManager.EFFECTS_PATH+"small_explosion_03.mp3";
		
		private var _smokeParticles:SmokeParticles;
		private var _smokeParticleEmitter:Entity;
		private var _bombEffect:Entity;
		private var callback:Function;
		
		public var active:Boolean = false;
		
		private var _container:DisplayObjectContainer;
		private var parent:Group;
		private var _sparkParticles:SparkleBlast;
		private var _sparkParticleEmitter:Entity;
		
		
		public function DivinationImpactResponse()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer, parent:Group):void
		{
			this.parent = parent
			_container = container;
			parent.shellApi.loadFile(parent.shellApi.assetPrefix + EXPLOSION_PATH, createBombEffect);
		}
		
		override public function activate(hitObject:Entity, projectile:Entity, callback:Function = null):void
		{
/*			if(hitObject)
			{*/
				if(!active){
					active = true;
					this.callback = callback;
					Motion(projectile.get(Motion)).zeroMotion();
					Motion(projectile.get(Motion)).zeroAcceleration();
					makeExplosion(hitObject, projectile);
					applyDivinationEffect(hitObject, projectile);
				}
/*			}
			else
			{
				this.particlesComplete();
			}*/
		}
		
		private function makeExplosion(hitObject:Entity, projectile:Entity):void
		{
			var spatial:Spatial = projectile.get(Spatial);
			explodeAt(spatial);
		}
		
		private function applyDivinationEffect(hitObject:Entity, projectile:Entity):void
		{
			// examine hitObject, decide whether to fire signal out	
			var div:DivinationTarget = hitObject.get(DivinationTarget);
			if(div){
				div.response.dispatch(projectile);
			}
		}
		
		public function explodeAt(spatial:Spatial):void{
			var effectSpatial:Spatial = _bombEffect.get(Spatial);
			effectSpatial.x = spatial.x;
			effectSpatial.y = spatial.y;	
			
			_bombEffect.get(Timeline).gotoAndPlay(2);
			
			addMagicSparks(effectSpatial);
			
			_smokeParticles.puff();
			_smokeParticles.endParticle.addOnce(particlesComplete);
			
			AudioUtils.play(parent, POP_SOUND,2.0,false,null,null,.5);
		}
		
		private function particlesComplete(...p):void
		{
			if(callback){
				callback();
			}
			complete.dispatch();
			active = false;
		}
		
		private function addMagicSparks(spatial:Spatial):void
		{
			_sparkParticles = new SparkleBlast();
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				_sparkParticles.init(parent,Command.create(cleanUp,_sparkParticleEmitter),spatial.x,spatial.y, 90, 50);
			}
			else{
				_sparkParticles.init(parent,Command.create(cleanUp,_sparkParticleEmitter),spatial.x,spatial.y, 90, 100);
			}
			_sparkParticleEmitter = EmitterCreator.create(parent, _container, _sparkParticles, 0, 0, _bombEffect, null);
		}
		
		private function cleanUp(ent:Entity):void
		{
			if(ent != null){
				parent.removeEntity(ent);
			}
		}	
		
		private function createBombEffect(clip:MovieClip):void
		{
			_bombEffect = EntityUtils.createMovingTimelineEntity(parent, clip, _container);
			//TimelineUtils.convertClip(clip as MovieClip, parent, null, _bombEffect, true, 25);
			_bombEffect.add(new Id("bombEffect"));
			
			parent.shellApi.loadFile(parent.shellApi.assetPrefix + SMOKE_PATH, setupSmokeParticles);
		}
		
		private function setupSmokeParticles(clip:DisplayObjectContainer):void
		{			
			_smokeParticles = new SmokeParticles();
			_smokeParticleEmitter = EmitterCreator.create(parent, _container, _smokeParticles, 0, -20, null, null, _bombEffect.get(Spatial));
			_smokeParticles.init(parent, clip, 2.0, 70,80,1,-200,40,false,0x00ccff);
			
			DisplayUtils.moveToTop(Display(_bombEffect.get(Display)).displayObject);
		}
		override public function destroy():void
		{
			parent.removeEntity(_smokeParticleEmitter);
			parent.removeEntity(_sparkParticleEmitter);
			parent.removeEntity(_bombEffect);
			_container = null;
			super.destroy();
		}
	}
}