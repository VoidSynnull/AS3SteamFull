package engine.components
{
	/**
	 * A standard component for managing all sounds on an entity.
	 */
	
	import flash.media.SoundTransform;
	import flash.utils.Dictionary;
	
	import engine.data.AudioWrapper;
	
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.util.ArrayUtils;
	import ash.core.Component;
	
	public class Audio extends Component
	{
		/**
		 * These contain a list of sounds that should change their state.  The AudioSystem will pop them all from this list once their state has been changed.
		 */
		public var toPlay:Vector.<AudioWrapper> = new Vector.<AudioWrapper>();
		public var toStop:Vector.<AudioWrapper> = new Vector.<AudioWrapper>();
		public var toFade:Vector.<AudioWrapper> = new Vector.<AudioWrapper>();
		/**
		 * If true, will remove this entity when its sound is complete.
		 */
		public var remove:Boolean = false;
		/**
		 * Contains all audio accross all events.  Sounds are stored first by id, then event, and finally by action.
		 */
		public var allEventAudio:Dictionary;
		/**
		 * Contains all the audio actons for the current event.  This is updated on eventTrigger.
		 */
		public var currentActions:Dictionary = new Dictionary();
		/**
		 * These contain lists of sounds that are currently in the playing or fading state.  These are maintained by the AudioSystem.
		 */
		public var _playing:Vector.<AudioWrapper> = new Vector.<AudioWrapper>();
		public var _fading:Vector.<AudioWrapper> = new Vector.<AudioWrapper>();
		/**
		 * set the default fadestep based on 60 fps over 1 sec  TODO : make this fps adjustable.
		 */
		private var _defaultFadeStep:Number; 
		
		public function Audio()
		{
			this.defaultFadeTime = 1;
		}
		
		/**
		 * Stop all sounds playing, fading, or about to play or fade using this url accross this component.
		 * @param url : The url to play.  This should include the type, ex : 'music/SneakySuspense.mp3'.
		 */
		public function stop(url:String, type:String = null):void
		{			
			var wrappers:Vector.<AudioWrapper> = getAllWrappersOfUrl(url, this._playing);
			wrappers = wrappers.concat(getAllWrappersOfUrl(url, this._fading));
			var wrapperIndex:int;
			var playIndex:int;
			var total:int;
			var wrapper:AudioWrapper;
			
			for(wrapperIndex = 0; wrapperIndex < wrappers.length; wrapperIndex++)
			{
				wrapper = wrappers[wrapperIndex];
				
				if(type == null || wrapper.volumeModifiers[type] != null)
				{
					wrapper.loop = false;
					this.toStop.push(wrapper);
					
					total = this.toPlay.length;
					
					for (playIndex = total - 1; playIndex > -1; playIndex--)
					{
						if(this.toPlay[playIndex] == wrapper)
						{
							this.toPlay.splice(playIndex, 1);
							break;
						}
					}
					
					total = this.toFade.length;
					
					for (playIndex = total - 1; playIndex > -1; playIndex--)
					{
						if(this.toFade[playIndex] == wrapper)
						{
							this.toFade.splice(playIndex, 1);
							break;
						}
					}
				}
			}
		}
		
		/**
		 * Play a sound.
		 * @param url : The url to play.  This should include the type, ex : 'music/SneakySuspense.mp3'.
		 * @param loop : loop infinitely if true.  Sound must be manually stopped to end loop.
		 * @param modifiers : All the volume modifiers that should effect this sound.  By Default the 'type' modifier will be added so the global sfx and music volume effect this.
		 *                       also gets added to allow this sound to fade in and out.
		 */
		public function play(url:*, loop:Boolean = false, modifiers:* = null, baseVolume:Number = 1, overrideVolume:Number = NaN):AudioWrapper
		{
			var wrapper:AudioWrapper = createAudioWrapper(getAsset(url), loop, modifiers, baseVolume, overrideVolume);
			toPlay.push(wrapper);
			
			return(wrapper);
		}
				
		/**
		 * Fade a sound to a target volume.
		 * @param url : The url to play.  This should include the type, ex : 'music/SneakySuspense.mp3'.
		 * @param targetVolume : The target volume to fade to.  Can be greater or less than current volume.
		 * @param step : The rate of change for this sound.  Defaults to a one second fade time assuming 60 fps.
		 * @param type : To limit the fade to only being applied to sounds of a particular type.
		 */
		public function fade(url:String, targetVolume:Number, step:Number = NaN, initialVolume:Number = NaN, type:String = null):void
		{			
			if(isNaN(step))
			{
				step = _defaultFadeStep;
			}
			
			// ensure that the sound to fade is either currently being played or in the queue to be played.
			var allPlaying:Vector.<AudioWrapper> = this._playing.concat(this.toPlay);
			var wrappers:Vector.<AudioWrapper> = getAllWrappersOfUrl(url, allPlaying);
			var wrapper:AudioWrapper;
			
			for(var n:uint = 0; n < wrappers.length; n++)
			{
				wrapper = wrappers[n];
				
				if(type == null || wrapper.volumeModifiers[type] != null)
				{
					if(!isNaN(initialVolume))
					{
						wrapper.volumeModifiers[SoundModifier.FADE] = initialVolume;
					}
					else if(wrapper.volumeModifiers[SoundModifier.FADE] == null)
					{
						wrapper.volumeModifiers[SoundModifier.FADE] = 1;
					}
					
					wrapper.fadeTarget = targetVolume;
					wrapper.fadeStep = step;
					
					toFade.push(wrapper);
				}
			}
		}
		
		public function isPlaying(url:String):Boolean
		{
			var allPlaying:Vector.<AudioWrapper> = this._playing.concat(this.toPlay);
			
			for(var n:uint = 0; n < allPlaying.length; n++)
			{
				if(String(allPlaying[n].url).indexOf(url) > -1)
				{
					return(true);
				}
			}
			
			return(false);
		}
				
		public function setVolume(volume:Number, type:String = null, url:String = null):void
		{
			if(type == null) { type = SoundModifier.BASE; }
			
			var wrapper:AudioWrapper;
			var wrappers:Vector.<AudioWrapper>;
			
			if(url == null)
			{
				wrappers = this._playing.concat(this.toPlay);
			}
			else
			{
				wrappers = getAllWrappersOfUrl(url, this._playing.concat(this.toPlay));
			}
			
			for(var n:uint = 0; n < wrappers.length; n++)
			{
				wrapper = wrappers[n];

				if(wrapper.volumeModifiers[type] != null)
				{
					if((url != null && url == wrapper.url) || url == null)
					{
						if(wrapper.volumeModifiers[type] != volume)
						{
							wrapper.volumeModifiers[type] = volume;
							updateVolume(wrapper);
						}
					}
				}
			}
		}
				
		public function setPosition(volume:Number, pan:Number, url:String = null):void
		{
			var currentLevel:Number;
			var finalVolume:Number = 1;
			var wrapper:AudioWrapper;
			var wrappers:Vector.<AudioWrapper>;
			
			if(url == null)
			{
				wrappers = this._playing.concat(this.toPlay);
			}
			else
			{
				wrappers = getAllWrappersOfUrl(url, this._playing.concat(this.toPlay));
			}
			
			for(var n:uint = 0; n < wrappers.length; n++)
			{
				wrapper = wrappers[n];
				
				if(wrapper.volumeModifiers[SoundModifier.POSITION] != null)
				{
					if((url != null && url == wrapper.url) || url == null)
					{
						wrapper.volumeModifiers[SoundModifier.POSITION] = volume;
						
						finalVolume = 1;
						
						for each(currentLevel in wrapper.volumeModifiers)
						{
							finalVolume *= currentLevel;
						}
						
						wrapper.transform.volume = finalVolume;
						wrapper.transform.pan = pan;
						
						if(wrapper.channel != null)
						{
							wrapper.channel.soundTransform = wrapper.transform;
						}
					}
				}
			}
		}
		
		public function stopAll(type:String = null):void
		{
			var wrapper:AudioWrapper;
			
			for(var n:uint = 0; n < this._playing.length; n++)
			{
				wrapper = this._playing[n];
				
				stop(wrapper.url, type);
			}
		}
		
		public function fadeAll(targetVolume:Number, step:Number = NaN, initialVolume:Number = 1, type:String = null):void
		{
			if(isNaN(step))
			{
				step = _defaultFadeStep;
			}
			
			var wrapper:AudioWrapper;
			
			for(var n:uint = 0; n < this._playing.length; n++)
			{
				wrapper = this._playing[n];
				
				fade(wrapper.url, targetVolume, step, initialVolume, type);
			}
		}
				
		public function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(this.allEventAudio != null)
			{
				var eventActions:Dictionary = this.allEventAudio[event];
				
				if(eventActions != null)
				{
					var actionSoundData:SoundData;
					
					if(makeCurrent)
					{
						for(var action:String in eventActions)
						{
							if(removeEvent == null || removeEvent == this.currentActions[action].event)
							{
								// only override new actions defined for this event.
								this.currentActions[action] = eventActions[action];
							}
						}
					}
					
					if(!init && removeEvent == null)
					{
						for(var nextAction:String in eventActions)
						{
							actionSoundData = this.currentActions[nextAction];
							
							if(actionSoundData.triggeredByEvent == event)
							{
								playFromSoundData(actionSoundData);
							}
						}
					}
				}
			}
		}
		
		// identifier can be the id or an event if there is no id.
		public function getEventAudio(identifier:String):*
		{
			if(this.allEventAudio != null)
			{
				return(this.allEventAudio[identifier]);
			}
			
			return(null);
		}
		
		public function addToPlaying(wrapper:AudioWrapper):void
		{
			if(_playing)
			{
				_playing.push(wrapper);
				updateVolume(wrapper);
			}
		}
		
		/**
		 * Plays a sound associated with an action on the entity.
		 * @param action : The action you want to play.
		 */
		public function playCurrentAction(action:String):AudioWrapper
		{
			if(this.currentActions[action] != null)
			{
				return(playFromSoundData(this.currentActions[action]));
			}
			
			return(null);
		}
		
		public function stopActionAudio(action:String):void
		{
			stop(SoundData(this.currentActions[action]).asset);
		}
		
		public function fadeActionAudio(action:String, targetVolume:Number = 0):void
		{
			this.fade(SoundData(this.currentActions[action]).asset, targetVolume);
		}
		
		/**
		 * Plays a sound using sound data.  All of the playback parameters are set in the SoundData instance.
		 * @param soundData : The SoundData instance to play.
		 */
		public function playFromSoundData(soundData:SoundData):AudioWrapper
		{
			var asset:String = getAsset(soundData.asset);
			if( asset != null )
			{
				// don't re-add an exclusive sound if it is already playing.
				if(soundData.exclusive || soundData.exclusiveType || !soundData.allowOverlap)
				{
					var wrappers:Vector.<AudioWrapper> = getAllWrappersOfUrl(asset, this._playing);
					wrappers = wrappers.concat(getAllWrappersOfUrl(asset, this.toPlay));
					
					if(wrappers.length > 0)
					{
						//setVolume(soundData.baseVolume, SoundModifier.BASE, asset);
						return(null);
					}
				}
			
				if(soundData.exclusive)
				{
					fadeAll(0, _defaultFadeStep);
				}
				else if(soundData.exclusiveType)
				{
					fadeAll(0, _defaultFadeStep, 1, soundData.type);
				}
				
				var modifiers:Array = [soundData.type];
				
				if(soundData.modifiers != null)
				{
					modifiers = soundData.modifiers;
				}
				
				var wrapper:AudioWrapper = play(asset, soundData.loop, modifiers, soundData.baseVolume);
				
				if(soundData.fade)
				{
					fade(asset, 1, _defaultFadeStep, 0);
				}
			
				return(wrapper);
			}
			else
			{
				return null;
			}
		}
		
		/**
		 * The default time in seconds that sounds played from this component should fade.  Changing this will update the default fadestep.
		 */
		public function set defaultFadeTime(time:Number):void { _defaultFadeStep = 1 / (time * 60); }
		
		private function getAsset(url:*):String
		{
			var asset:String;
			
			if(typeof(url) == "object")
			{
				asset = ArrayUtils.getRandomElement(url);
			}
			else
			{
				asset = url;
			}
			
			return(asset);
		}
		
		private function getWrapper(url:String, wrappers:Vector.<AudioWrapper>):AudioWrapper
		{
			for(var n:uint = 0; n < wrappers.length; n++)
			{
				if(String(wrappers[n].url).indexOf(url) > -1)
				{
					return(wrappers[n]);
				}
			}
			
			return(null);
		}
		
		private function getAllWrappersOfUrl(url:String, wrappers:Vector.<AudioWrapper>):Vector.<AudioWrapper>
		{
			var allWrappers:Vector.<AudioWrapper> = new Vector.<AudioWrapper>;
			
			for(var n:uint = 0; n < wrappers.length; n++)
			{
				if(String(wrappers[n].url).indexOf(url) > -1)
				{
					allWrappers.push(wrappers[n]);
				}
			}
			
			return(allWrappers);
		}
		
		private function updateVolume(wrapper:AudioWrapper):void
		{
			var currentLevel:Number;
			var finalVolume:Number = 1;
			
			for each(currentLevel in wrapper.volumeModifiers)
			{
				finalVolume *= currentLevel;
			}
			
			if(!isNaN(wrapper.overrideVolume))
			{
				wrapper.transform.volume = wrapper.overrideVolume;
			}
			else
			{
				wrapper.transform.volume = finalVolume;
			}
			
			if(wrapper.channel != null)
			{
				wrapper.channel.soundTransform = wrapper.transform;
			}
		}
		
		private function createAudioWrapper(url:String, loop:Boolean = false, modifiers:* = null, baseVolume:Number = 1, overrideVolume:Number = NaN):AudioWrapper
		{
			var wrapper:AudioWrapper = new AudioWrapper();
			wrapper.loop = loop;
			wrapper.volumeModifiers = new Dictionary();
			wrapper.volumeModifiers[SoundModifier.BASE] = baseVolume;
			wrapper.overrideVolume = overrideVolume;
			
			if(modifiers != null)
			{
				if(typeof(modifiers) == "string")
				{
					wrapper.volumeModifiers[modifiers] = 1;
				}
				else if(typeof(modifiers) == "object")
				{
					for(var n:uint = 0; n < modifiers.length; n++)
					{
						wrapper.volumeModifiers[modifiers[n]] = 1;
					}
				}
			}
			
			if(wrapper.volumeModifiers[SoundModifier.MUSIC] == null && wrapper.volumeModifiers[SoundModifier.AMBIENT] == null && wrapper.volumeModifiers[SoundModifier.EFFECTS] == null)
			{
				if(url.indexOf(SoundModifier.MUSIC) > -1)
				{
					wrapper.volumeModifiers[SoundModifier.MUSIC] = 1;
				}
				else if(url.indexOf(SoundModifier.AMBIENT) > -1)
				{
					wrapper.volumeModifiers[SoundModifier.AMBIENT] = 1;
				}
				else if(url.indexOf(SoundModifier.EFFECTS) > -1)
				{
					wrapper.volumeModifiers[SoundModifier.EFFECTS] = 1;
				}
			}
			
			wrapper.transform = new SoundTransform();
			wrapper.url = url;
			
			return(wrapper);
		}
	}
}