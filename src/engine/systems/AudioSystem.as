package engine.systems
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import engine.ShellApi;
	import engine.components.Audio;
	import engine.data.AudioWrapper;
	import engine.managers.GroupManager;
	import engine.managers.SoundManager;
	import engine.nodes.AudioNode;
	
	import game.data.sound.SoundModifier;
	
	import org.osflash.signals.natives.NativeSignal;

	public class AudioSystem extends ListIteratingSystem
	{
		public function AudioSystem():void
		{
			super(AudioNode, updateNode, null, nodeRemoved);
		}
		
		override public function update( time : Number ) : void
		{			
			for( var node:AudioNode = nodeList.head; node; node = node.next )
			{
				updateNode(node, time);
			}
			
			_updateGlobalVolume = false;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_globalVolumeModifiers = new Dictionary();
			
			// sync sound volume modifiers with global volume settings for each sound type.
			_globalVolumeModifiers[SoundModifier.AMBIENT] = _shellApi.profileManager.active.ambientVolume;
			_globalVolumeModifiers[SoundModifier.MUSIC] = _shellApi.profileManager.active.musicVolume;
			_globalVolumeModifiers[SoundModifier.EFFECTS] = _shellApi.profileManager.active.effectsVolume;
			
			// RLH: need this to update volume if clicking out of screen where video is playing
			_updateGlobalVolume = true;
			
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(AudioNode);
			
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:AudioNode, time:Number):void
		{
			// if muted, then keep muted
			if (_muted)
				muteSounds();
			play(node);
			fade(node);
			stop(node);
			updateSounds(node);
		}
			
		private function nodeRemoved(node:AudioNode):void
		{
			var wrapper:AudioWrapper;
			var total:int;
			var soundIndex:int;
			
			total = node.audio._playing.length;
			
			for (soundIndex = total - 1; soundIndex > -1; soundIndex--)
			{
				wrapper = node.audio._playing[soundIndex];
				wrapper.complete.removeAll();
				if(wrapper.channel != null)
				{
					wrapper.channel.stop();
				}
			}
			
			node.audio.toPlay = null;
			node.audio.toStop = null;
			node.audio.toFade = null;
			node.audio._playing = null;
			node.audio._fading = null;
		}
		
		private function updateSounds(node:AudioNode):void
		{
			if(node.audio._playing.length > 0)
			{
				if(_updateGlobalVolume)
				{
					var modifierType:String;
					
					for (modifierType in _globalVolumeModifiers)
					{
						node.audio.setVolume(_globalVolumeModifiers[modifierType], modifierType);
					}
				}
				
				var wrapper:AudioWrapper;
				var totalPlaying:int = node.audio._playing.length;
				var totalFading:int = node.audio._fading.length;
				var soundIndex:int;
				var volumeDelta:Number;
				var currentFadeVolume:Number;
				
				if(totalFading > 0)
				{
					for (soundIndex = totalFading - 1; soundIndex > -1; soundIndex--)
					{
						wrapper = node.audio._fading[soundIndex];
						currentFadeVolume = wrapper.volumeModifiers[SoundModifier.FADE];
						
						volumeDelta = wrapper.fadeTarget - currentFadeVolume;

						if(Math.abs(volumeDelta) > wrapper.fadeStep)
						{
							if(wrapper.fadeTarget > currentFadeVolume)
							{
								node.audio.setVolume(currentFadeVolume + wrapper.fadeStep, SoundModifier.FADE, wrapper.url);
							}
							else if(wrapper.fadeTarget < currentFadeVolume)
							{
								node.audio.setVolume(currentFadeVolume - wrapper.fadeStep, SoundModifier.FADE, wrapper.url);
							}
						}
						else
						{
							node.audio.setVolume(wrapper.fadeTarget, SoundModifier.FADE, wrapper.url);
							node.audio._fading.splice(soundIndex, 1);
							
							if(wrapper.fadeTarget == 0)
							{
								node.audio.stop(wrapper.url);
								stop(node);
								
								if(node.audio.remove)
								{
									node.entity.group.removeEntity(node.entity);
									return;
								}
							}
						}
					}
				}
				
				totalPlaying = node.audio._playing.length;
				
				for (soundIndex = totalPlaying - 1; soundIndex > -1; soundIndex--)
				{
					wrapper = node.audio._playing[soundIndex];
										
					if(wrapper.channel != null)
					{
						if(wrapper.playbackComplete)
						{
							if(!wrapper.loop)
							{
								wrapper.complete.removeAll();
								node.audio._playing.splice(soundIndex, 1);
							}
							/*
							else
							{
								wrapper.playbackComplete = false;
								wrapper.channel = wrapper.sound.play(0, 0, wrapper.transform);
								wrapper.playbackCompleted = new NativeSignal(wrapper.channel, Event.SOUND_COMPLETE, Event);
								wrapper.playbackCompleted.addOnce(wrapper.handlePlaybackComplete);
							}
							*/
						}
					}
				}
			}
		}
		
		private function play(node:AudioNode):void
		{
			if(node.audio.toPlay.length > 0)
			{
				node.audio.setVolume(_globalVolumeModifiers[SoundModifier.AMBIENT], SoundModifier.AMBIENT);
				node.audio.setVolume(_globalVolumeModifiers[SoundModifier.MUSIC], SoundModifier.MUSIC);
				node.audio.setVolume(_globalVolumeModifiers[SoundModifier.EFFECTS], SoundModifier.EFFECTS);
				//node.audio.setVolume(1, SoundModifier.FADE);
				
				while(node.audio.toPlay.length > 0)
				{
					playSound(node.audio, node.audio.toPlay.pop());
				}
			}
		}
		
		private function fade(node:AudioNode):void
		{
			while(node.audio.toFade.length > 0)
			{
				node.audio._fading.push(node.audio.toFade.pop());
			}
		}
				
		private function stop(node:AudioNode):void
		{
			var wrapper:AudioWrapper;

			while(node.audio.toStop.length > 0)
			{
				wrapper = node.audio.toStop.pop();
				_soundManager.stop(wrapper.url, wrapper);
				removeWrapper(wrapper.url, node.audio._playing);
				//removeWrapper(wrapper.url, node.audio._fading);
			}
		}
		
		private function removeWrapper(url:String, wrappers:Vector.<AudioWrapper>):void
		{
			var total:int = wrappers.length;
			var wrapper:AudioWrapper;
			
			for (var soundIndex:int = total - 1; soundIndex > -1; soundIndex--)
			{
				wrapper = wrappers[soundIndex];
				
				if(wrapper.url == url)
				{
					wrapper.complete.removeAll();
					wrappers.splice(soundIndex, 1);
				}
			}
		}
		
		private function playSound(audio:Audio, wrapper:AudioWrapper):AudioWrapper
		{						
			var loops:int = 0;
			
			if(wrapper.loop)
			{
				loops = int.MAX_VALUE;
			}
			
			_soundManager.play(wrapper.url, 0, loops, wrapper.transform, wrapper, audio);
					
			return(wrapper);
		}

		public function getVolume(type:String):Number
		{
			var level:Number = _globalVolumeModifiers[type];
			return isNaN(level) ? NaN : level;
		}
		public function setVolume(level:Number, type:String):void
		{
			_globalVolumeModifiers[type] = level;
			_updateGlobalVolume = true;
		}
		
		// RLH: added mute and unmute functionality (used when playing video)
		public function muteSounds():void
		{
			_muted = true;
			setVolume(0, SoundModifier.MUSIC);
			setVolume(0, SoundModifier.AMBIENT);
			setVolume(0, SoundModifier.EFFECTS);
		}
		public function unMuteSounds():void
		{
			_muted = false;
			setVolume(_shellApi.profileManager.active.musicVolume, SoundModifier.MUSIC);
			setVolume(_shellApi.profileManager.active.ambientVolume, SoundModifier.AMBIENT);
			setVolume(_shellApi.profileManager.active.effectsVolume, SoundModifier.EFFECTS);
		}
		
		private var _updateGlobalVolume:Boolean = false;
		private var _muted:Boolean = false;
		private var _globalVolumeModifiers:Dictionary;
		[Inject]
		public var _soundManager:SoundManager;
		[Inject]
		public var _shellApi:ShellApi;
	}
}
