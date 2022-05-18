// Used by:
// Card "smoke_bomb" on arab1 island using item an_bomb

package game.data.specialAbility.islands.arab
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cough;
	import game.data.animation.entity.character.Throw;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.GameScene;
	import game.scenes.arab1.palaceExterior.components.PalaceGuard;
	import game.scenes.arab1.shared.particles.EmberParticles;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.systems.entity.EyeSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	/**
	 * Avatar throws smoke bomb using swf particles
	 * 
	 * Optional params:
	 * color	uint		Color value (default is black)
	 */
	public class ThrowSmokeBomb extends SpecialAbility
	{
		override public function init(node:SpecialAbilityNode):void
		{
			// need this if we want to load assets
			super.init(node);
			
			if( super.group is GameScene )
			{
				_scene = super.group as GameScene;
				_container = _scene.hitContainer;
			}
			else
			{
				trace(this,":: not in GameScene, abort initialization");
				return;
			}

			// start asset laoding sequence
			super.loadAsset("scenes/arab1/shared/particles/bomb_particle.swf", createBombParticle);
		}
		
		///// LOAD ASSETS /////
		
		private function createBombParticle(clip:MovieClip):void
		{
			if(clip == null)
			{
				var specialAbiliyControl:SpecialAbilityControl = super.entity.get(SpecialAbilityControl);
				specialAbiliyControl.removeSpecialByClass(ThrowSmokeBomb);
			}
			else
			{
				_bombClip = clip;
				super.loadAsset("scenes/arab1/shared/sb_explosion.swf", createBombEffect);
				
				// cache sounds from server
				super.cacheSound(SoundManager.EFFECTS_PATH + "lit_fuse_01_L.mp3");
				super.cacheSound(SoundManager.EFFECTS_PATH + "big_pop_01.mp3");
			}
		}

		private function createBombEffect(clip:MovieClip):void
		{
			_bombEffect = EntityUtils.createSpatialEntity(_scene, clip, _container);
			TimelineUtils.convertClip(clip as MovieClip, _scene, null, _bombEffect, true);
			_bombEffect.add(new Id("bombEffect"));
			
			super.loadAsset("scenes/arab1/shared/particles/smoke_particle.swf", setupSmokeParticles);
		}

		private function setupSmokeParticles(clip:DisplayObjectContainer):void
		{
			_smokeClip = clip;
			
			_smokeParticles = new SmokeParticles();
			_smokeParticleEmitter = EmitterCreator.create(_scene, _container, _smokeParticles, 0, -20, null, null, _bombEffect.get(Spatial));
			_smokeParticles.init(_scene, clip, 2.0, 70);
			
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH){
				_emberParticles = new EmberParticles();
				_emberParticleEmitter = EmitterCreator.create(_scene, _container, _emberParticles, 0, 0, null, null, _bombEffect.get(Spatial));
				_emberParticles.init(_scene);
			}
			
			DisplayUtils.moveToTop(Display(_bombEffect.get(Display)).displayObject);
		}

		///// ACTIVATE /////
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if( _scene )
			{
				if(!super.data.isActive)
				{
					//var bomb:Blob = new Blob(5, _color);
					var mc:MovieClip = new MovieClip();
					mc.addChild(_bombClip);
					
					_currentBomb = null;
					var bombEntity:Entity = new Entity();
					bombEntity.add(new Display(mc, node.entity.get(Display).container));
					
					CharUtils.setAnim(node.entity, Throw);
					CharUtils.getTimeline(node.entity).handleLabel("trigger", Command.create(bombThrow, bombEntity));
					super.setActive(true);
				}
			}
		}
		
		private function bombThrow(bombEntity:Entity):void
		{
			var handSpatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charSpatial:Spatial = super.entity.get(Spatial);
			
			var direction:Number = 1;
			var xPos:Number = charSpatial.x - (handSpatial.x * charSpatial.scale);
			var yPos:Number = charSpatial.y + (handSpatial.y * charSpatial.scale);
			if(charSpatial.scaleX > 0)
			{
				xPos = charSpatial.x + (handSpatial.x * charSpatial.scale);
				direction = -1;
			}
			bombEntity.add(new Spatial(xPos, yPos));
			
			// create sparkles
			var emberParticles:EmberParticles = new EmberParticles();
			EmitterCreator.create(_scene, _container, emberParticles, 0, 0, bombEntity, null, bombEntity.get(Spatial));
			emberParticles.init(_scene, 0xff9900, 0xffff99, 1, 30, -140, -5);
			emberParticles.stream();
			
			var motion:Motion = new Motion();
			bombEntity.add(motion);

			super.group.addEntity(bombEntity);
			MotionUtils.addColliders(bombEntity, null, super.group);
			
			var vel:Number = Math.random() * 50 + 150;
			var accel:Number = Math.random() * 50 + 500;
			
			motion.velocity = new Point(vel * direction, -300);
			motion.acceleration = new Point(0, accel);
			motion.friction = new Point(.4 * direction, 0);
			motion.rotationAcceleration = 200;
			_currentBomb = bombEntity;
			
			// create audio
			AudioUtils.playSoundFromEntity(bombEntity, SoundManager.EFFECTS_PATH+"lit_fuse_01_L.mp3", 300, 0.3, 2, Quad.easeInOut);
		}
		
		///// UPDATE /////
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if( _scene )
			{
				if(_currentBomb)
				{
					var motion:Motion = _currentBomb.get(Motion);
					
					if(motion != null)
					{
						// check to see if a collision has halted the bomb, this let's us know when it should explodebt
						if(motion.velocity.y == 0)
						{
							motion.velocity.x = 0;
							motion.rotationVelocity = 0;
							motion.rotationAcceleration = 0;
							motion.rotation = 0;
							motion.acceleration = new Point(0, 0);
	
							// Timer to blow up bomb
							SceneUtil.addTimedEvent(super.group, new TimedEvent(0.1, 1, Command.create(blowUp, _currentBomb)));
							super.setActive(false);
						}
					}
				}
			}
		}
		
		private function blowUp(bomb:Entity):void
		{
			// create smoke burst
			explodeAt(bomb.get(Spatial));
			
			// remove bomb
			super.group.removeEntity(bomb);
		}
		
		private function explodeAt($spatial:Spatial):void
		{
			var effectSpatial:Spatial = _bombEffect.get(Spatial);
			effectSpatial.x = $spatial.x;
			effectSpatial.y = $spatial.y;
			
			var timelineEntity:Entity = Children(_bombEffect.get(Children)).children[0];
			Timeline(timelineEntity.get(Timeline)).gotoAndPlay(2);
			
			_smokeParticles.puff();
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH){
				_emberParticles.puff();
			}
			
			AudioUtils.play(_scene, SoundManager.EFFECTS_PATH+"big_pop_01.mp3");
			
			// detect any NPCs within a radius
			var npc:Entity;
			var nodeList:NodeList = _scene.systemManager.getNodeList(NpcNode);
			for(var node:NpcNode = nodeList.head; node; node=node.next)
			{
				// TODO :: These kinds of specifics (guard) shouldn't be here, should be handle in appropriate scene
				// Should dispatch an event and allow scene to handle specifics
				npc = node.entity
				if(EntityUtils.distanceBetween(_bombEffect, npc) < SMOKE_BOMB_RADIUS)
				{
					if(npc.get(PalaceGuard) != null){
						if(!PalaceGuard(npc.get(PalaceGuard)).alerted){
							smokeChar(npc);
						}
					} else {
						smokeChar(npc);
					}
				} 
				else if(npc.get(PalaceGuard) != null)	
				{
					if(!PalaceGuard(npc.get(PalaceGuard)).alerted){
						var npcSpatial:Spatial = npc.get(Spatial);
						if(EntityUtils.distanceBetween(npc, _bombEffect) < 600){
							CharUtils.moveToTarget(npc, effectSpatial.x+((Math.random() - 0.5)*100), npcSpatial.y, false, arrived);
						}
					}
				}
			}
		}
		
		private function smokeChar(npc:Entity):void
		{
			// create smoke on character's face
			var smokeParticles:SmokeParticles = new SmokeParticles();
			var smokeEmitter:Entity = EmitterCreator.create(_scene, _container, smokeParticles, 0, -40, null, null, npc.get(Spatial));
			smokeParticles.init(_scene, _smokeClip, 1.0, 20, 20, 0.7, -50);
			smokeParticles.stream();
			
			CharUtils.stateDrivenOff(npc, 9999);
			
			// close eyes
			var eyesEntity:Entity = CharUtils.getPart(npc, "eyes");
			var eyes:Eyes = eyesEntity.get(Eyes);
			eyes.state = EyeSystem.ANGRY;
			
			// start coughing fit
			CharUtils.setAnimSequence(npc, new <Class>[Cough], true);
			smokeParticles.endParticle.addOnce(Command.create(resetChar, npc));
			
			// if a palace guard, set the component to blind
			var palaceGuard:PalaceGuard = npc.get(PalaceGuard);
			if(palaceGuard){
				palaceGuard.blinded = true;
				palaceGuard.blind.dispatch(npc);
			}
		}
		
		private function resetChar(npc:Entity):void{
			CharUtils.setAnimSequence(npc, new <Class>[], false); // clear anim sequence
			CharUtils.stateDrivenOn(npc);
			CharUtils.setState(npc, "stand");
			
			// if a palace guard, set the component to normal
			var palaceGuard:PalaceGuard = npc.get(PalaceGuard);
			if(palaceGuard)
				palaceGuard.blinded = false;
		}
		
		// TODO :: These kinds of specifics shouldn't be here, should be handle in appropriate scene
		private function arrived(npc:Entity):void
		{
			PalaceGuard(npc.get(PalaceGuard)).alert.dispatch(npc);
		}
		
		override public function destroy():void
		{
			_scene = null;
			super.destroy();
		}
		
		private var _scene:GameScene;
		private var _color:uint = 0x000000;
		private var _currentBomb:Entity;
		private var _bombEffect:Entity;
		private var _container:DisplayObjectContainer;
		
		private var _smokeClip:DisplayObjectContainer;
		private var _smokeParticles:SmokeParticles;
		private var _smokeParticleEmitter:Entity;
		
		private var _emberParticles:EmberParticles;
		private var _emberParticleEmitter:Entity;

		private const SMOKE_BOMB_RADIUS:Number = 180;
		private var _bombClip:MovieClip;
	}
}