package game.scenes.virusHunter.shared.systems
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	
	import engine.components.Audio;
	import engine.components.Motion;
	
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.shared.nodes.ShipMotionNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class ShipMotionSystem extends GameSystem
	{
		public function ShipMotionSystem()
		{
			super(ShipMotionNode, updateNode);
			super._defaultPriority = SystemPriorities.inputComplete;
		}
		
		private function updateNode(node:ShipMotionNode, time:Number):void
		{
			var motion:Motion = node.motion;
			
			if( !node.ship.locked )
			{
				if( motion.maxVelocity.x == 0 )
				{
					motion.maxVelocity 	= new Point(400, 400);
				}
				
				if(motion.acceleration.length == 0)
				{
					motion.friction.x = node.motionControlBase.stoppingFriction;
					motion.friction.y = node.motionControlBase.stoppingFriction;
					
					stopAudio(node);
				}
				else
				{
					motion.friction.x = node.motionControlBase.accelerationFriction;
					motion.friction.y = node.motionControlBase.accelerationFriction;
					
					playAudio(node);
				}
			
				node.display.displayObject["shipFront"].rotation = motion.velocity.x * .08;
				node.display.displayObject["bioSuit"].rotation = motion.velocity.x * .05;
				if(node.display.displayObject["reactor"].alpha == 1) { node.display.displayObject["reactor"].rotation -= (Math.abs(motion.velocity.length) * .04 + 5); }		
			}
			else
			{
				node.motion.maxVelocity = new Point( 0, 0 );
			}
		}
		
		private function playAudio(node:ShipMotionNode):void
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
						node.ship.engineSoundFadeOut = false;
						audio.play(soundData.asset, true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
						audio.fade(soundData.asset, 1);
					}
				}
			}
		}
		
		private function stopAudio(node:ShipMotionNode):void
		{
			if(!node.ship.engineSoundFadeOut)
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
							node.ship.engineSoundFadeOut = true;
						}
					}
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ShipMotionNode);
			super.removeFromEngine(systemManager);
		}
	}
}