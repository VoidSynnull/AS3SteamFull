package game.scenes.virusHunter.shared.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.creators.entity.EmitterCreator;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.Burst;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	import game.scenes.virusHunter.shared.creators.ShipCreator;
	import game.scenes.virusHunter.shared.nodes.ShipDamageNode;
	import game.systems.GameSystem;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	public class ShipDamageSystem extends GameSystem
	{
		public function ShipDamageSystem(shipCreator:ShipCreator, scene:ShipScene)
		{
			super(ShipDamageNode, updateNode);
			gameover = new Signal();
			_shipCreator = shipCreator;
			_scene = scene;
		}
		
		private function updateNode(node:ShipDamageNode, time:Number):void
		{
			if(node.ship.state != node.ship.DEAD)
			{
				if(node.damageTarget.lastPointOfImpact)
				{
					var deltaX:Number = node.spatial.x - node.damageTarget.lastPointOfImpact.x;
					var deltaY:Number = node.spatial.y - node.damageTarget.lastPointOfImpact.y;
					var angle:Number = Math.atan2(deltaY, deltaX);
					
					node.motion.velocity.x += Math.cos(angle) * node.ship.damageVelocity;
					node.motion.velocity.y += Math.sin(angle) * node.ship.damageVelocity;
					node.damageTarget.lastPointOfImpact = null;
				}
				
				if(node.damageTarget.damage >= node.damageTarget.maxDamage)
				{
					if(node.weaponSlots.active)
					{
						node.ship.state = node.ship.DEAD;
						SceneUtil.lockInput(super.group, true, false);
						CharUtils.lockControls(node.entity, true, true);
						WeaponControl(node.weaponSlots.active.get(WeaponControl)).fire = false;
						playAudio(node.entity, "die");
					}
				}
				
				if(node.damageTarget.isHit)
				{
					node.damageTarget.isHit = false;
					_shipCreator.changeGunLevel(node.entity, -1);
					
					if(node.damageTarget.damage < node.damageTarget.maxDamage)
					{
						if(node.entity.get(Player))
						{
							_scene.shellApi.setUserField( (_scene.shellApi.islandEvents as VirusHunterEvents).DAMAGE_FIELD, node.damageTarget.damage, _scene.shellApi.island);
						}
					}
				}
			}
			else if(node.damageTarget.deathExplosions > 0)
			{
				if(node.damageTarget.deathExplosionWait <= 0)
				{
					node.damageTarget.deathExplosionWait = .5;
					node.damageTarget.deathExplosions--;
					createBurst(Utils.randInRange(node.spatial.x - node.spatial.width * .5, node.spatial.x + node.spatial.width * .5), Utils.randInRange(node.spatial.y - node.spatial.height * .5, node.spatial.y + node.spatial.height * .5), node.display.container);
				}
				else
				{
					node.damageTarget.deathExplosionWait -= time;
				}
			}
			else
			{
				if(node.entity.get(Player))
				{
					Sleep(node.entity.get(Sleep)).sleeping = true;
					Sleep(node.entity.get(Sleep)).ignoreOffscreenSleep = true;
					node.entity.ignoreGroupPause = true;
					gameover.dispatch();
					_scene.playMessage("ship_destroyed", false, null, "drLang", reloadScene);
				}
				else
				{
					_scene.removeEntity(node.entity, true);
				}
			}
		}
		
		private function reloadScene():void
		{
			_scene.shellApi.setUserField( (_scene.shellApi.islandEvents as VirusHunterEvents).DAMAGE_FIELD, 0, _scene.shellApi.island);
			_scene.shellApi.loadScene(ClassUtils.getClassByObject(_scene), _scene.shellApi.profileManager.active.lastX, _scene.shellApi.profileManager.active.lastY);
		}
		
		private function playAudio(entity:Entity, action:String):void
		{
			var audio:Audio = entity.get(Audio);
			var actions:Dictionary;
			var soundData:SoundData;
			
			if(audio)
			{
				actions = audio.currentActions;
				soundData = actions[action];
				
				if(soundData)
				{
					audio.play(soundData.asset, false, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
				}
			}
		}
		
		private function createBurst(x:Number, y:Number, container:DisplayObjectContainer):void
		{
			var emitter:Burst = new Burst();
			emitter.init(2, 0x33ffcc00, 0xffff6600);
			
			var entity:Entity = EmitterCreator.create(super.group, container, emitter);	
			entity.get(Spatial).x = x;
			entity.get(Spatial).y = y;
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			
			entity.add(sleep);
			Emitter(entity.get(Emitter)).remove = true;
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ShipDamageNode);
			super.removeFromEngine(systemManager);
		}
		
		public var gameover:Signal;
		private var _shipCreator:ShipCreator;
		private var _scene:ShipScene;
	}
}