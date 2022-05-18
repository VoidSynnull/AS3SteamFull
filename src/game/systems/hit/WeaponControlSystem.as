package game.systems.hit
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.hit.Gun;
	import game.components.input.Input;
	import game.components.timeline.Timeline;
	import game.creators.motion.ProjectileCreator;
	import game.data.motion.time.FixedTimestep;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.nodes.hit.WeaponControlNode;
	import game.nodes.input.InputNode;
	import game.systems.GameSystem;
	
	public class WeaponControlSystem extends GameSystem
	{
		public function WeaponControlSystem(creator:ProjectileCreator, projectileContainer:DisplayObjectContainer)
		{
			super(WeaponControlNode, updateNode);
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			
			_projectileCreator = creator;
			_projectileContainer = projectileContainer;
		}
		
		public function updateNode(node:WeaponControlNode, time:Number):void
		{
			var weapon:Gun = node.gun;
			var timelineEntity:Entity;

			weapon.timeSinceLastShot += time;
			
			// code to lock weapon rotation unless input is down (for touch devices.)
			if(node.rotateControl != null && node.weaponControl.lockWhenInputInactive && _inputNodes.head != null)
			{
				var input:Input = InputNode(_inputNodes.head).input;
				
				if(!input.inputActive)
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
				if(node.gun.state == node.gun.ACTIVE)
				{
					if(weapon.timeSinceLastShot > weapon.minimumShotInterval)
					{
						if(weapon.projectileLifespan > 0)
						{
							var parentMotion:Motion;
							var parentSpatial:Spatial = node.spatial;
							
							if(node.parent != null)
							{
								parentMotion = node.parent.parent.get(Motion);
								parentSpatial = node.parent.parent.get(Spatial);
							}
							
							var gunBarrelX:Number = 0;
							var gunBarrelRotation:Number = node.spatial.rotation;
	
							for(var n:uint = 0; n < weapon.gunBarrels; n++)
							{
								_projectileCreator.create(weapon, parentSpatial, gunBarrelRotation, _projectileContainer, parentMotion, gunBarrelX);
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
						
						weapon.timeSinceLastShot = 0;
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			
			_inputNodes = systemManager.getNodeList(InputNode);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			_inputNodes = null;
			systemManager.releaseNodeList(WeaponControlNode);
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
						var weapon:Gun = entity.get(Gun);
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
					
					//audio.setVolume(.4, SoundModifier.BASE, asset);
				}
			}
		}
		
		private var _projectileCreator:ProjectileCreator;
		private var _projectileContainer:DisplayObjectContainer;
		private var _inputNodes:NodeList;
	}
}