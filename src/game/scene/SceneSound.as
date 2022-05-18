/**
 * Handles the setup and maintainance of sounds which persist between scenes like music and ambient tracks.
 */

package game.scene
{
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Audio;
	import engine.components.Id;
	import engine.data.AudioWrapper;
	import engine.group.Group;
	import engine.systems.AudioSystem;
	
	import game.components.entity.Sleep;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundParser;
	import game.systems.SystemPriorities;

	public class SceneSound
	{		
		public function SceneSound()
		{
		
		}
		
		public function initScene(xml:XML, group:Group):void
		{
			if(initialized)
				return;
			initialized = true;
			
			group.addSystem(new AudioSystem(), SystemPriorities.updateSound);
			
			var data:Dictionary;
			
			if(xml != null)
			{
				var parser:SoundParser = new SoundParser();
				data = parser.parse(xml);
			}
			
			setupAudio(data, group);
		}
		
		public function exitScene():void
		{
			initialized = false;
			storeAudio();
		}
		
		private function storeAudio():void
		{
			var audio:Audio = _audioComponent;
			
			if(audio != null)
			{
				var wrapper:AudioWrapper;
				var total:uint;
				var soundIndex:int;
				var newAudioComponent:Audio = new Audio();
				
				newAudioComponent._playing = audio._playing.slice();
				audio._playing.length = 0;
				newAudioComponent.allEventAudio = audio.allEventAudio;
				_shellApi.setupEventTrigger(newAudioComponent);
				_audioComponent = newAudioComponent;
			}
		}
		//data[soundData.id][soundData.event][soundId]
		private function setupAudio(data:Dictionary, group:Group):void
		{
			if(data != null)
			{
				if(data[SCENE_SOUND] != null)
				{
					var soundEntity:Entity = group.getEntityById(SCENE_SOUND);
					var audio:Audio = new Audio();
					var sleep:Sleep = new Sleep();
					sleep.ignoreOffscreenSleep = true;
					var continueMusic:Boolean = false;
					var continueAmbient:Boolean = false;
					audio.allEventAudio = data[SCENE_SOUND];
					
					_shellApi.setupEventTrigger(audio);
					
					if(soundEntity == null)
					{
						soundEntity = new Entity();
						soundEntity.add(new Id(SCENE_SOUND));
						soundEntity.add(sleep);
						group.addEntity(soundEntity);
					}
					
					soundEntity.ignoreGroupPause = true;
					
					var oldAudio:Audio = _audioComponent;
					
					if(oldAudio != null)
					{
						if(oldAudio._playing)
						{
							var total:int = oldAudio._playing.length;
							var wrapper:AudioWrapper;
							var musicSoundData:SoundData = audio.currentActions[SoundModifier.MUSIC];
							var ambientSoundData:SoundData = audio.currentActions[SoundModifier.AMBIENT];
							
							for (var soundIndex:int = total - 1; soundIndex > -1; soundIndex--)
							{
								wrapper = oldAudio._playing[soundIndex];
								
								if(musicSoundData != null)
								{
									if(wrapper.url == musicSoundData.asset)
									{
										oldAudio._playing.splice(soundIndex, 1);
										audio._playing.push(wrapper);
										//audio.setVolume(musicSoundData.baseVolume, SoundModifier.BASE, musicSoundData.asset);
										if(wrapper.volumeModifiers[SoundModifier.BASE] != musicSoundData.baseVolume)
										{
											//wrapper.volumeModifiers[SoundModifier.BASE] = musicSoundData.baseVolume;
											//audio.fade(musicSoundData.asset, musicSoundData.baseVolume, NaN, wrapper.volumeModifiers[SoundModifier.BASE]);
											audio.setVolume(musicSoundData.baseVolume, SoundModifier.BASE, musicSoundData.asset);
										}
										continueMusic = true;
									}
								}
								
								if(ambientSoundData != null)
								{
									if(wrapper.url == ambientSoundData.asset)
									{
										oldAudio._playing.splice(soundIndex, 1);
										audio._playing.push(wrapper);
										
										if(wrapper.volumeModifiers[SoundModifier.BASE] != ambientSoundData.baseVolume)
										{
											audio.setVolume(ambientSoundData.baseVolume, SoundModifier.BASE, ambientSoundData.asset);
										}
										continueAmbient = true;
									}
								}
							}
							
							fadeOutAudio(group);
						}
					}
					
					if(!continueMusic)
					{
						audio.playCurrentAction(SoundModifier.MUSIC);
					}
					
					if(!continueAmbient)
					{
						audio.playCurrentAction(SoundModifier.AMBIENT);
					}
					
					_audioComponent = audio;
					
					soundEntity.add(_audioComponent);
					return;
				}
			}
			
			// just fade out the background track in the new scene if there isn't a new track to replace it.
			fadeOutAudio(group);
			_audioComponent = null;
		}
		
		private function fadeOutAudio(group:Group):void
		{
			var audio:Audio = _audioComponent;
			
			if(audio != null)
			{
				if(audio._playing != null)
				{
					if(audio._playing.length > 0)
					{
						// create a temporary entity to cross-fade the previous scene's audio if a new one exists.
						var previousAudio:Entity = new Entity();
						var sleep:Sleep = new Sleep();
						sleep.ignoreOffscreenSleep = true;
						previousAudio.ignoreGroupPause = true;
						previousAudio.add(sleep);
						previousAudio.add(new Id("old_ " + SCENE_SOUND));
						group.addEntity(previousAudio);
						previousAudio.add(audio);
						
						audio.fadeAll(0);
						audio.remove = true;
					}
				}
			}
		}
		
		// store background audio between scenes for cross-fading.
		private var initialized:Boolean = false;
		private var _audioComponent:Audio;
		private var FADE_STEP:Number;
		
		[Inject]
		public var _shellApi:ShellApi;
		
		public static const SCENE_SOUND:String = "sceneSound";
	}
}