// Used by:
// Card "magic_sand" on arab2 island uing item an_magic_sand

package game.data.specialAbility.islands.arab
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.Emitter;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.ValidHit;
	import game.components.motion.Edge;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Throw;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.GameScene;
	import game.scenes.arab1.shared.particles.EmberParticles;
	import game.scenes.arab2.shared.MagicSand;
	import game.scenes.arab2.shared.MagicSandGroup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	/**
	 * Avatar throws sand swf particles with sparkles and smoke burst
	 */
	public class ThrowMagicSand extends SpecialAbility
	{
		private var _bomb:Entity;
		private var _container:DisplayObjectContainer;
		
		private var _isthrown:Boolean = false;
		
		private const FUZE_SOUND:String = SoundManager.EFFECTS_PATH+"lit_fuse_01_L.mp3";
		
		private const BOMB_PATH:String = "scenes/arab2/shared/magic_sand_particle.swf";
		private var sparkleEnt:Entity;
		private var _magicSandGroup:MagicSandGroup;
		
		private var _emberParticles:EmberParticles;
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			_container = GameScene(super.group).hitContainer;
			_magicSandGroup = super.group.addChildGroup(new MagicSandGroup(_container)) as MagicSandGroup;
			
			this.loadAsset(BOMB_PATH, createBombParticle);
		}
		
		override public function removeSpecial(node:SpecialAbilityNode):void
		{
			this.group.removeEntity(_bomb);
			super.removeSpecial(node);
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			// if not active, then load bomb
			if(!super.data.isActive && _bomb)
			{
				super.setActive(true);
				
				CharUtils.setAnim(super.entity, Throw);
				CharUtils.getTimeline(super.entity).handleLabel("trigger", bombThrow);
				//super.loadAsset(BOMB_PATH, createBombParticle);
			}
		}
		
		/**
		 * When bomb loaded 
		 * @param clip
		 */
		private function createBombParticle(clip:MovieClip):void
		{
			_bomb = EntityUtils.createMovingEntity(super.group, clip, super.entity.get(Display).container);
			
			MotionUtils.addColliders(_bomb, null, super.group);
			
			var bitmapCollider:BitmapCollider = _bomb.get(BitmapCollider);
			bitmapCollider.useEdge = true;
			
			_bomb.remove(HazardCollider);
			
			_bomb.add(new Edge(-15, -15, 30, 30));
			
			var ignoreHits:ValidHit = new ValidHit("ballPlatform");
			ignoreHits.inverse = true;
			_bomb.add(ignoreHits);
			
			// create sparkles
			var emberParticles:EmberParticles = new EmberParticles();
			EmitterCreator.create(super.group, _container, emberParticles, 0, 0, _bomb, "bombEmbers", _bomb.get(Spatial));
			emberParticles.init(super.group, 0xff9900, 0xffff99, 1.5, 30, -140, -5);
		}
		
		private function bombThrow():void
		{
			_isthrown = true;
			
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
			
			_bomb.sleeping = false;
			 
			var bombSpatial:Spatial = _bomb.get(Spatial);
			bombSpatial.x = xPos;
			bombSpatial.y = yPos;
			
			var entity:Entity = super.group.getEntityById("bombEmbers");
			EmberParticles(Emitter(entity.get(Emitter)).emitter).stream();
			
			var vel:Number = Math.random() * 50 + 150;
			var accel:Number = Math.random() * 50 + 500;
			
			var motion:Motion = _bomb.get(Motion);
			motion.rotationVelocity = 0;
			motion.velocity.setTo(vel * direction, -300);
			motion.acceleration.setTo(0, accel);
			motion.friction.setTo(0.4 * direction, 0);
			motion.rotationAcceleration = 200 * -direction;
			
			AudioUtils.playSoundFromEntity(_bomb, FUZE_SOUND, 300, 0.3, 2, Quad.easeInOut);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(_bomb && _isthrown)
			{
				var motion:Motion = _bomb.get(Motion);
				
				if(motion != null)
				{
					if(motion.velocity.y == 0)
					{
						_bomb.sleeping = true;
						
						var entity:Entity = super.group.getEntityById("bombEmbers");
						EmberParticles(Emitter(entity.get(Emitter)).emitter).stopPuff();
						  
						// Timer to blow up bomb
						SceneUtil.addTimedEvent(super.group, new TimedEvent(0.1, 1, blowUp));
						// magicSand platform
						var currHit:Entity;
						if(_bomb.has(CurrentHit))
						{
							currHit = CurrentHit(_bomb.get(CurrentHit)).hit;
						}
						if(currHit != null)
						{
							if(currHit.has(MagicSand))
							{
								_magicSandGroup.applyMagicSandEffect(currHit);
							}
							else if(currHit.has(CurrentHit))
							{
								currHit = CurrentHit(currHit.get(CurrentHit)).hit;
								if(currHit.has(MagicSand))
								{
									_magicSandGroup.applyMagicSandEffect(currHit);
								}
							}
						}
						super.setActive(false);
					}
				}
			}
		}
		
		private function blowUp():void
		{
			// create smoke burst
			_isthrown = false;
			_magicSandGroup.explodeAt(_bomb.get(Spatial));
			
			// remove bomb
			//super.group.removeEntity(bomb);
		}
	}
}
