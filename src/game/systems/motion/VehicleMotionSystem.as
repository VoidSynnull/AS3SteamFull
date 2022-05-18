package game.systems.motion
{
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	
	import engine.components.Audio;
	import engine.components.Motion;
	
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.nodes.motion.VehicleMotionNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class VehicleMotionSystem extends GameSystem
	{
		public function VehicleMotionSystem()
		{
			super(VehicleMotionNode, updateNode);
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		private function updateNode(node:VehicleMotionNode, time:Number):void
		{
			var motion:Motion = node.motion;
			
			if(motion.acceleration.length == 0)
			{
				motion.friction.x = node.motionControlBase.stoppingFriction;
				motion.friction.y = node.motionControlBase.stoppingFriction;
				
				if(node.vehicle.onlyRotateOnAccelerate)
				{
					node.accelerateToTargetRotation.lock = true;
				}
				
				stopAudio(node);
			}
			else
			{
				motion.friction.x = node.motionControlBase.accelerationFriction;
				motion.friction.y = node.motionControlBase.accelerationFriction;
				
				if(node.vehicle.onlyRotateOnAccelerate)
				{
					node.accelerateToTargetRotation.lock = false;
				}
				
				playAudio(node);
			}
			
			if(node.perspectiveAnimation)
			{
				node.perspectiveAnimation.step = (motion.velocity.length * time) * node.perspectiveAnimation.velocityMultiplier + node.perspectiveAnimation.baseStep;
			}
		}
		
		private function playAudio(node:VehicleMotionNode):void
		{
			var audio:Audio = node.audio;
			var actions:Dictionary;
			var soundData:SoundData;
			
			if(audio)
			{
				actions = audio.currentActions;
				soundData = actions["move"];
				
				if(soundData != null)
				{			
					if(!audio.isPlaying(soundData.asset))
					{
						node.vehicle.engineSoundFadeOut = false;
						audio.play(soundData.asset, true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
						audio.fade(soundData.asset, 1);
					}
				}
			}
		}
		
		private function stopAudio(node:VehicleMotionNode):void
		{
			if(!node.vehicle.engineSoundFadeOut)
			{
				var audio:Audio = node.audio;
				var actions:Dictionary;
				var soundData:SoundData;
				
				if(audio)
				{
					actions = audio.currentActions;
					soundData = actions["move"];
					
					if(soundData != null)
					{			
						if(audio.isPlaying(soundData.asset))
						{
							audio.fade(soundData.asset, 0);
							node.vehicle.engineSoundFadeOut = true;
						}
					}
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(VehicleMotionNode);
			super.removeFromEngine(systemManager);
		}
	}
}
