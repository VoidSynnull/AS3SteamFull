package game.scenes.virusHunter.shared.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.MovieClipHit;
	import game.components.input.Input;
	import game.components.timeline.Timeline;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.shared.components.Melee;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.creators.ProjectileCreator;
	import game.scenes.virusHunter.shared.nodes.ShipMotionNode;
	import game.scenes.virusHunter.shared.nodes.WeaponControlNode;
	import game.scenes.virusHunter.shared.nodes.WeaponInputControlNode;
	import game.systems.GameSystem;
	
	public class WeaponControlSystem extends GameSystem
	{
		public function WeaponControlSystem(creator:ProjectileCreator, projectileContainer:DisplayObjectContainer, input:Input)
		{
			super(WeaponControlNode, updateNode);
			
			_input = input;
			_creator = creator;
			_projectileContainer = projectileContainer;
		}
		
		public function updateNode(node:WeaponControlNode, time:Number):void
		{
			if(this._input.lockInput) return;
			
			var weapon:Weapon = node.weapon;
			var timelineEntity:Entity;
			var melee:Melee = node.entity.get(Melee);
			var shipNode:ShipMotionNode = _shipMotionNode.head;
			
			weapon.timeSinceLastShot += time;
			
			if(node.weaponControl.lockWhenInputInactive)
			{
				if(!_input.inputActive)
				{
					if(!node.rotateControl.lock)
					{
						node.rotateControl.lock = true;
					}
				}
				else if(node.rotateControl.lock)
				{
					node.rotateControl.lock = false;
				}
			}
			
			if(node.weaponControl.fire)
			{
				if( !shipNode.ship.locked && node.weapon.state == node.weapon.ACTIVE )
				{
					if(weapon.timeSinceLastShot > weapon.minimumShotInterval)
					{
						if(weapon.projectileLifespan > 0)
						{
							var parentMotion:Motion = node.parent.parent.get(Motion);
							var parentSpatial:Spatial = node.parent.parent.get(Spatial);
							var parentClipHit:MovieClipHit = node.parent.parent.get(MovieClipHit);
							var gunBarrelX:Number = 0;
							var gunBarrelRotation:Number = node.spatial.rotation;
	
							for(var n:uint = 0; n < weapon.gunBarrels; n++)
							{
								_creator.create(weapon, parentSpatial, gunBarrelRotation, _projectileContainer, parentMotion, parentClipHit, gunBarrelX);
								gunBarrelX += weapon.gunBarrelSeparation;
								gunBarrelRotation += weapon.gunBarrelAngleSeparation;
							}
							
							playAudio(node.entity);
						}
						
						// if this weapon has an animation associated with it, play it when it fires.
						var timeline:Timeline = node.entity.get(Timeline);
						
						if(timeline)
						{
							timeline.gotoAndPlay("begin");
						}
						
						if(melee)
						{
							if(!melee.alwaysOn)
							{
								melee.active = true;
								playAudio(node.entity);
							}
						}
						
						weapon.timeSinceLastShot = 0;
					}
				}
			}
			else
			{
				if(melee)
				{
					if(!melee.alwaysOn)
					{
						melee.active = false;
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_shipMotionNode = systemManager.getNodeList( ShipMotionNode );
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(WeaponControlNode);
			systemManager.releaseNodeList(ShipMotionNode);
			_shipMotionNode = null;
			super.removeFromEngine(systemManager);
		}
		
		private function playAudio(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			var actions:Dictionary;
			var soundData:SoundData;
			var currentAsset:*;
			var asset:String;
			
			if(audio)
			{
				actions = audio.currentActions;
				soundData = actions["weaponFire"];
				
				if(soundData != null)
				{
					currentAsset = soundData.asset;
					
					if(typeof(currentAsset) == "object")
					{
						var weapon:Weapon = entity.get(Weapon);
						asset = currentAsset[weapon.level];
					}
					else
					{
						asset = currentAsset;
					}
					
					if(!soundData.allowOverlap)
					{
						if(audio.isPlaying(asset))
						{
							return;
						}
					}
					
					audio.play(asset, false, [SoundModifier.EFFECTS, SoundModifier.POSITION, SoundModifier.BASE]);
					
					audio.setVolume(.4, SoundModifier.BASE, asset);
				}
			}
		}
		
		private var _input:Input;
		private var _creator:ProjectileCreator;
		private var _projectileContainer:DisplayObjectContainer;
		private var _shipMotionNode:NodeList;
	}
}