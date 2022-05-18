package engine.managers
{
	import com.poptropica.AppConfig;
	
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.utils.Dictionary;
	
	import engine.Manager;
	import engine.components.Audio;
	import engine.data.AudioWrapper;
	
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;

	public class SoundManager extends Manager
	{
		public static const MUTE_MIXER:Boolean = true;
		public static const UNMUTE_MIXER:Boolean = false;

		public static const STANDARD_BUTTON_CLICK_FILE:String	= 'ui_button_click.mp3';
		public static const STANDARD_CLOSE_CANCEL_FILE:String	= 'ui_close_cancel.mp3';

		private var oldMixerVolume:Number;		// when we unmute the mixer we restore its previous value (only 0 or 1)

		public function SoundManager()
		{
			oldMixerVolume = SoundMixer.soundTransform.volume;
			// force to 1 if non-zero
			if (oldMixerVolume != 0)
			{
				oldMixerVolume = 1.0;
			}
			// mute mixer on startup
			//muteMixer(mute);
		}
		
		// get muted setting from server (after player has logged in)
		public function getMutedSetting():void
		{
			// get user field
			this.shellApi.getUserField("muted", "", gotMuted);
		}
		
		// when retrieved muted setting, then mute or unmute mixer
		private function gotMuted(setting:*):void
		{
			// mute mixer if setting is true (can be undefined for first time)
			muteMixer(setting == true);
		}
		
		// update muted setting (called by updateAudioBtn in Hud.as)
		public function updateMuted():void
		{
			// if mixer volume has changed
			if (oldMixerVolume != SoundMixer.soundTransform.volume)
			{
				var muted:Boolean = (SoundMixer.soundTransform.volume == 0);
				trace("mixer volume changed: set muted to " + muted);
				shellApi.setUserField("muted", muted, "", true);
			}
		}
		
		/**
		 * Just a cover for <code>SoundMixer.soundTransform</code> 
		 * 
		 * @return The <code>SoundTransform</code> property of the global <code>SoundMixer</code>.
		 * @see flash.media.SoundMixer
		 * @see flash.media.SoundTransform
		 */		
		public function get mixerTransform():SoundTransform {
			return SoundMixer.soundTransform;
		}

		/**
		 * A convenience property which reflects the current
		 * volume setting of the global <code>SoundMixer</code>.
		 * 
		 * @return	A value from 0.0 to 1.0, representing silence and full volume, respectively.
		 * 
		 */		
		public function get mixerVolume():Number {
			return SoundMixer.soundTransform.volume;
		}
		/** 
		 * @private
		 */		
		public function set mixerVolume(newVolume:Number):void {
			newVolume = Math.max(0, Math.min(newVolume, 1.0));
			oldMixerVolume = SoundMixer.soundTransform.volume;
			// force to 1 if non-zero
			if (oldMixerVolume != 0)
			{
				oldMixerVolume = 1.0;
			}
			var trans:SoundTransform = SoundMixer.soundTransform;
			trans.volume = newVolume;
			SoundMixer.soundTransform = trans;
		}
		
		/**
		 * Sets the volume of the global <code>SoundMixer</code>
		 * @param flag	Either <code>SoundManager.MUTE_MIXER (true)</code>,
		 * which silences all sound or
		 * <code>SoundManager.UNMUTE_MIXER (false)</code>, which restores
		 * the prior volume setting.
		 */		
		public function muteMixer(flag:Boolean=true):void {
			var willMute:Boolean = MUTE_MIXER == flag;
			var newVolume:Number = willMute ? 0 : 1;
			//if (! willMute) trace("restoring old volume of", oldMixerVolume);
			mixerVolume = newVolume;
		}

		/**
		 * Causes the <code>SoundManager</code> to begin playback
		 * of an arbitrary sound file specified by the <code>soundPath</code> parameter.
		 * @param soundPath		A <code>String</code> representing the sound file's pathname relative to <code>SoundManager.SOUND_PATH</code>.
		 * @param playbackVolume	A value from 0.0 to 1.0, representing silence and full volume, respectively.
		 * @see	engine.managers.SoundManager.play
		 */		
		public function playLibrarySound(soundPath:String, playbackVolume:Number=NaN):void {
			if (isNaN(playbackVolume)) 
			{
				playbackVolume = 1;		
			}
			var trans:SoundTransform = new SoundTransform(playbackVolume);
			play(soundPath, 0, 0, trans);
		}

		/**
		 * In order for a sound to play with zero delay, it is usually
		 * necessary to not only cache its data file, but also to
		 * actually play the sound. This is 'preheating': playing
		 * a sound at zero volume to eliminate playback delays.
		 * <p>This function preheats the two sound effects which are
		 * frequently used in the UI.</p>
		 */		
		public function preheatUISounds():void {
			playLibrarySound(EFFECTS_PATH + STANDARD_BUTTON_CLICK_FILE, 0);
			playLibrarySound(EFFECTS_PATH + STANDARD_CLOSE_CANCEL_FILE, 0);
		}

		/**
		 * Play a sound file.  Sound will start playing immediately if it is in the cache, otherwise it will wait to be loaded before it starts playing.
		 */
		public function play(url:String, startTime:Number = 0, loops:int = 0, soundTransform:SoundTransform = null, audioWrapper:AudioWrapper = null, audio:Audio = null):void
		{
			if(!DataUtils.isNull(url))
			{
				var path:String = SOUND_PATH + url;
				var soundInfo:Object = _cache[url];
	
				if(soundInfo == null)
				{
					var fileManager:FileManager = this.shellApi.getManager(FileManager) as FileManager;
					fileManager.loadFile(fileManager.contentPrefix + path, loaded, [url, startTime, loops, soundTransform, audioWrapper, audio]);
				}
				else
				{
					var sound:Sound = soundInfo.sound;
					var channel:SoundChannel = sound.play(startTime, loops, soundTransform);
					
					if(audioWrapper != null && channel != null)
					{
						setupWrapper(audioWrapper, sound, channel, audio);
					}
				}
			}
		}
		
		/**
		 * Cache a sound file.  This will prevent a delay when the sound is played later.  Sound is added to the cache if it isn't already but not played.
		 */
		public function cache(url:String, useServerFallback:Boolean = false):void
		{
			if(!DataUtils.isNull(url))
			{
				var soundInfo:Object = _cache[url];
				
				if(soundInfo == null)
				{
					var path:String = SOUND_PATH + url;
					var serverFallback:String;
					
					if(useServerFallback)
					{
						serverFallback = AppConfig.assetHost;
					}
					
					var fileManager:FileManager = this.shellApi.getManager(FileManager) as FileManager;
					fileManager.loadFile(fileManager.contentPrefix + path, addToCache, [url], null, serverFallback);
				}
			}
		}

		/**
		 * Stop a sound that is playing or streaming.
		 */
		public function stop(url:String, audioWrapper:AudioWrapper = null):void
		{
			if(_cache != null)
			{
				/*
				var path:String = SOUND_PATH + url;
				var sound:Sound = _cache[url].sound;
				if(sound != null)
				{
					sound.close();
				}
				*/
				if(audioWrapper != null)
				{
					audioWrapper.channel.stop();
				}
			}
		}
		
		/**
		 * Clear the cache of sounds and close each sound.
		 */
		public function clearSoundCache():void
		{
			for each(var soundInfo:Object in _cache)
			{
				//soundInfo.sound.close();
				soundInfo.sound = null;
				_cache[soundInfo.id] = null;
				delete _cache[soundInfo.id];
			}
		}

		//// PROTECTED METHODS ////

		override protected function construct():void
		{
			this.preheatUISounds();
			super.construct();
		}

		protected override function destroy():void
		{
			soundLoaded.removeAll();
			clearSoundCache();
			super.destroy();
		}

		//// PRIVATE METHODS ////

		private function loaded(sound:Sound, url:String, startTime:Number = 0, loops:int = 0, soundTransform:SoundTransform = null, audioWrapper:AudioWrapper = null, audio:Audio = null):void
		{			
			if(sound != null)
			{
				var channel:SoundChannel = sound.play(startTime, loops, soundTransform);
				
				if(audioWrapper != null && channel != null)
				{
					setupWrapper(audioWrapper, sound, channel, audio);
				}
				
				addToCache(sound, url);
				
				this.soundLoaded.dispatch(url);
			}
			else
			{
				trace("SoundManager :: Error : Sound is null");
			}
		}
		
		private function setupWrapper(audioWrapper:AudioWrapper, sound:Sound, channel:SoundChannel, audio:Audio = null):void
		{
			audioWrapper.sound = sound;
			audioWrapper.channel = channel;
			audioWrapper.playbackComplete = false;
			
			if(audioWrapper.playbackCompleted == null)
			{
				audioWrapper.playbackCompleted = new NativeSignal(audioWrapper.channel, Event.SOUND_COMPLETE, Event);
				audioWrapper.playbackCompleted.addOnce(audioWrapper.handlePlaybackComplete);
			}
			
			if(audio != null)
			{
				audio.addToPlaying(audioWrapper);
			}
		}
		
		private function addToCache(sound:Sound, id:String):void
		{			
			if(sound != null)
			{
				var soundInfo:Object = new Object();
				soundInfo.sound = sound;
				soundInfo.id = id;
				
				_cache[id] = soundInfo;
				// TODO: preheat the sound, maybe
				/****
					if (flag) {
						sound.play(0, 0, new SoundTransform(ZERO_VOLUME, CENTER_PANNING));
					} 
				****/
			}
			else
			{
				trace("SoundManager :: Error : Sound is null");
			}
		}

		public var soundLoaded:Signal = new Signal(String);
		private var _cache:Dictionary = new Dictionary();
		public static const SOUND_PATH:String = "sound/";
		public static const AMBIENT_PATH:String = "ambient/";
		public static const MUSIC_PATH:String = "music/";
		public static const EFFECTS_PATH:String = "effects/";
		public static const SPEECH_PATH:String	= "speech/";
	}
}