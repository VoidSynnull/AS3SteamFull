package engine.systems
{
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.AudioSequence;
	import engine.data.AudioWrapper;
	import engine.nodes.AudioSequenceNode;
	
	import game.data.sound.SoundData;

	public class AudioSequenceSystem extends ListIteratingSystem
	{
		public function AudioSequenceSystem()
		{
			super(AudioSequenceNode, updateNode, null, nodeRemoved);
		}
		
		private function updateNode(node:AudioSequenceNode, time:Number):void
		{
			var sequence:AudioSequence = node.audioSequence;
			var wrapper:AudioWrapper = node.audioSequence.playing;
			
			if(sequence.play)
			{
				if(sequence._stopped)
				{
					sequence._stopped = false;
				}
				
				if(wrapper == null)
				{
					playNextSound(node);
				}
				else
				{
					if(wrapper.playbackComplete)
					{
						playNextSound(node);
					}
				}
			}
			else if(!sequence._stopped)
			{
				if(wrapper)
				{
					node.audio.stop(wrapper.url);
				}
				sequence._stopped = true;
				sequence.playing = null;
			}
		}
		
		private function playNextSound(node:AudioSequenceNode):void
		{
			var sequence:AudioSequence = node.audioSequence;
			
			if(sequence._index < sequence.sequence.length || sequence.loop)
			{
				if(sequence._index == sequence.sequence.length)
				{
					sequence._index = 0;
				}
				
				var nextSound:* = sequence.sequence[sequence._index];
				
				sequence._index++;
				
				if(nextSound is SoundData)
				{
					sequence.playing = node.audio.playFromSoundData(nextSound);
				}
				else
				{
					sequence.playing = node.audio.play(nextSound);
				}
			}
			else
			{
				sequence.play = false;
				sequence.playing = null;
				sequence.playbackComplete.dispatch();
			}
		}
		
		private function nodeRemoved(node:AudioSequenceNode):void
		{
			var sequence:AudioSequence = node.audioSequence;
			
			sequence.sequence = null;
			sequence.playbackComplete.removeAll();
			sequence.playing = null;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(AudioSequenceNode);
			
			super.removeFromEngine(systemManager);
		}
	}
}