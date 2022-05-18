package game.systems.audio
{
	import ash.core.Engine;
	
	import game.data.motion.time.FixedTimestep;
	import game.data.scene.hit.HitAudioData;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.nodes.audio.HitAudioNode;
	import game.systems.GameSystem;
	
	public class HitAudioSystem extends GameSystem
	{
		public function HitAudioSystem()
		{
			super(HitAudioNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(HitAudioNode);
			
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:HitAudioNode, time:Number):void
		{			
			var hitAudioData:HitAudioData;
			var soundData:SoundData;
			var invalidateSoundData:Boolean = false;
			
			if(node.currentHit.hit != null)
			{
				if(node.hitAudio.active)
				{
					node.hitAudio.active = false;
					
					// if the last hit entity is different than the stored one, do another lookup for the latest soundData
					if(node.hitAudio.hitEntity != node.currentHit.hit)
					{
						node.hitAudio.hitEntity = node.currentHit.hit;
						node.hitAudio.soundData = null;
					}
					
					if(node.hitAudio.soundData)
					{
						if(node.hitAudio.soundData.action == node.hitAudio.action)
						{
							soundData = node.hitAudio.soundData;
						}
						else
						{
							invalidateSoundData = true;
						}
					}
					else
					{
						invalidateSoundData = true;
					}
					
					if(invalidateSoundData)
					{
						hitAudioData = node.currentHit.hit.get(HitAudioData);
						
						if(hitAudioData != null)
						{
							if(hitAudioData.currentActions != null)
							{
								if(hitAudioData.currentActions[node.hitAudio.action] != null)
								{
									soundData = hitAudioData.currentActions[node.hitAudio.action];
								}
							}
						}
					}
					
					if(soundData)
					{
						soundData.modifiers = [SoundModifier.EFFECTS, SoundModifier.VELOCITY, SoundModifier.POSITION];
						node.audio.playFromSoundData(soundData);
						// cache the current sound data.  If the hit entity changes it will get cleared.
						node.hitAudio.soundData = soundData;
					}
				}
			}
		}
	}
}