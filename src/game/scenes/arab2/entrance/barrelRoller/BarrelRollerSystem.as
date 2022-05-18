package game.scenes.arab2.entrance.barrelRoller
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.collider.ZoneCollider;
	import game.components.motion.SceneObjectMotion;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.data.animation.entity.character.Place;
	import game.data.game.GameEvent;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitAudioData;
	import game.data.scene.hit.HitType;
	import game.data.sound.SoundAction;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.particles.emitter.characterAnimations.Dust;
	import game.systems.GameSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.PerformanceUtils;
	import game.util.Utils;
	
	import org.flintparticles.common.counters.Random;
	
	public class BarrelRollerSystem extends GameSystem
	{
		private var _sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
		private var _hitCreator:HitCreator = new HitCreator();
		
		public function BarrelRollerSystem()
		{
			super(BarrelRollerNode, updateNode);
		}
		
		private function updateNode(node:BarrelRollerNode, time:Number):void
		{
			if(node.roller._manualRoll)
			{
				node.roller._manualRoll = false;
				this.animate(node);
			}
			
			if(node.roller._automaticRoll)
			{
				node.roller.time += time;
				
				if(node.roller.time >= node.roller.wait)
				{
					node.roller.time = 0;
					node.roller.wait = Utils.randNumInRange(node.roller.minWait, node.roller.maxWait);
					
					this.animate(node);
				}
			}
		}
		
		private function animate(node:BarrelRollerNode):void
		{
			CharUtils.setAnim(node.entity, Place);
			node.timeline.handleLabel("trigger", Command.create(doABarrelRoll, node));
		}
		
		//PRESS "Z" OR "R" TWICE TO...
		private function doABarrelRoll(node:BarrelRollerNode):void
		{
			const sprite:Sprite = BitmapUtils.createBitmapSprite(node.roller.barrelDisplay, 1, null, true, 0, node.roller.barrelBitmapData);
			node.display.displayObject.parent.addChild(sprite);
			
			const barrel:Entity = _sceneObjectCreator.createCircle(sprite, 0.2, node.display.displayObject.parent, node.spatial.x, node.spatial.y, null, null, null, node.entity.group);
			
			barrel.add(new ZoneCollider());
			barrel.add(new Id("barrel" + Math.random().toFixed(4)));
			barrel.add(new AudioRange(1000));
			
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "wood_barrel_roll_01_loop.mp3", true, [SoundModifier.EFFECTS]);
			barrel.add(audio);
			
			var hitAudioData:HitAudioData = new HitAudioData();
			var soundData:SoundData = new SoundData();
			soundData.type = SoundType.EFFECTS;
			soundData.action = SoundAction.IMPACT;
			soundData.asset = "effects/wood_heavy_impact_01.mp3";
			soundData.baseVolume = 1;
			soundData.modifiers = [SoundModifier.EFFECTS];
			soundData.event = GameEvent.DEFAULT;
			soundData.id = "barrel";
			soundData.loop = false;
			hitAudioData.currentActions[SoundAction.IMPACT] = soundData;
			barrel.add(hitAudioData);
			
			if(node.roller.makeHazard)
			{
				var hitData:HazardHitData = new HazardHitData();
				hitData.type = "thiefHit";
				hitData.knockBackCoolDown = .75;
				hitData.knockBackVelocity = new Point(1800, 500);
				hitData.velocityByHitAngle = false;
				
				_hitCreator.makeHit(barrel, HitType.HAZARD, hitData, node.entity.group);
			}
			
			var sceneObjectMotion:SceneObjectMotion = barrel.get(SceneObjectMotion);
			sceneObjectMotion.platformFriction = 0;
			
			var rollVelocity:Number = node.roller.rollVelocity;
			if(node.spatial.scaleX >= 0)
			{
				rollVelocity *= -1;
			}
			
			var motion:Motion = barrel.get(Motion);
			motion.velocity.x = rollVelocity;
			motion.restVelocity = 0;
			
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM)
			{
				var barrelSpatial:Spatial = barrel.get(Spatial);
				
				var emitter:Dust = new Dust();
				emitter.init(barrelSpatial);
				emitter.counter = new Random(5, 20);
				
				EmitterCreator.create(node.entity.group, node.display.displayObject.parent, emitter, 0, 40, barrel, null, barrelSpatial);
			}
		}
	}
}