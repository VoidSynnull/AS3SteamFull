package game.systems.audio
{
	import game.components.audio.Mic;
	import game.nodes.audio.MicNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	public class MicSystem extends GameSystem
	{
		public function MicSystem()
		{
			super(MicNode, updateNode);
			
			this._defaultPriority = SystemPriorities.update;
			
			//Might need these. Haven't tested yet.
			//SoundMixer.useSpeakerphoneForVoice = true;
			//SoundMixer.audioPlaybackMode = AudioPlaybackMode.MEDIA;
		}
		
		private function updateNode(node:MicNode, time:Number):void
		{
			var mic:Mic = node.mic;
			
			if(mic.invalidate)
			{
				mic.invalidate = false;
				
				if(mic.isActive)
				{
					mic.active.dispatch(node.entity);
				}
				else
				{
					mic.inactive.dispatch(node.entity);
				}
			}
		}
	}
}