package game.scenes.deepDive1.shared.systems
{
	import flash.utils.Dictionary;
	
	import engine.components.Audio;
	import engine.components.Motion;
	
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.scenes.deepDive1.shared.nodes.SubMotionNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.flintparticles.common.counters.Random;
	
	public class SubMotionSystem extends GameSystem
	{
		public function SubMotionSystem()
		{
			super(SubMotionNode, updateNode);
			super._defaultPriority = SystemPriorities.inputComplete;
		}
		
		private function updateNode(node:SubMotionNode, time:Number):void
		{
			var motion:Motion = node.motion;
			
			if(motion.acceleration.length == 0)
			{
				motion.friction.x = node.motionControlBase.stoppingFriction;
				motion.friction.y = node.motionControlBase.stoppingFriction;
				
				//stopAudio(node);
			}
			else
			{
				motion.friction.x = node.motionControlBase.accelerationFriction;
				motion.friction.y = node.motionControlBase.accelerationFriction;
				
				//playAudio(node);
			}
			
			if(motion.velocity.x > 100 && motion.acceleration.x > 0 && node.spatial.scaleX > 0)
			{
				node.spatial.scaleX = -node.spatial.scaleX;
			}
			else if(motion.velocity.x < -100 && motion.acceleration.x < 0 && node.spatial.scaleX < 0)
			{
				node.spatial.scaleX = -node.spatial.scaleX;
			}

			var velX:Number = -Math.abs(motion.velocity.x);
			
			if(velX < -300)
			{
				velX = -300;
			}

			// TODO :: why are we rotating the display directly?
			//node.display.displayObject["content"].rotation = velX * .1;
			node.spatialAddition.rotation = ( node.spatial.scaleX > 0 ) ? velX * .1 : velX * -.1;
			
			if(node.sub.trail != null)
			{
				var trail:Random = node.sub.trail.counter as Random;
				
				if(motion.velocity.length < 50)
				{
					/*
					if(node.sub.trail.counter.running)
					{
						node.sub.trail.counter.stop();
					}
					*/
					trail.maxRate = 2;
					trail.minRate = 0;
				}
				else
				{
					if(motion.velocity.length > 300)
					{
						trail.maxRate = 20;
						trail.minRate = 10;
					}
					else
					{
						trail.maxRate = 10;
						trail.minRate = 5;
					}
				}
			}
			
			if(node.hazardCollider.isHit && motion.rotationVelocity == 0)
			{
				if(node.motion.velocity.x > 0)
				{
					motion.rotationVelocity = 600;
				}
				else
				{
					motion.rotationVelocity = -600;
				}
				
				motion.rotationFriction = 200;
				node.motionControl.lockInput = true;
				node.motionControl.inputActive = false;
			}
			else if(Math.abs(motion.rotationVelocity) < 400)
			{
				if(motion.rotation != 0)
				{
					node.motionControl.lockInput = false;
					
					motion.rotationVelocity = 0;
					motion.rotationFriction = 0;
					
					motion.rotation *= .9;
					
					if(Math.abs(motion.rotation) < 1)
					{
						motion.rotation = 0;
					}
				}
				
			}
			//if(node.display.displayObject["reactor"].alpha == 1) { node.display.displayObject["reactor"].rotation -= (Math.abs(motion.velocity.length) * .04 + 5); }
		}
		
		private function playAudio(node:SubMotionNode):void
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
						node.sub.engineSoundFadeOut = false;
						audio.play(soundData.asset, true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
						audio.fade(soundData.asset, 1);
					}
				}
			}
		}
		
		private function stopAudio(node:SubMotionNode):void
		{
			if(!node.sub.engineSoundFadeOut)
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
							node.sub.engineSoundFadeOut = true;
						}
					}
				}
			}
		}
	}
}