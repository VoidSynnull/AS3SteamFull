package game.util
{
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.data.AudioWrapper;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.data.sound.SoundModifier;

	public class AudioUtils
	{
		/**
		 * A method to play 'global' sounds that aren't associated with a particular entity.
		 * @param group : The group where the global sound entity lives or should be created and cleaned up from.
		 * @param url : The path to the sound asset.
		 * @param baseVolume : This will set the volume independent of all other modifiers.  Useful if you want to make a sound louder or softer while still respecting other modifiers like position.
		 * @param loop : If this sound should loop.
		 * @param modifiers : An array of modifiers that should effect this sound.  The base and effect/music/ambient global modifiers are added automatically, but you can specify addition ones if needed.
		 * @param id : An id to reference the sound entity.  Allows you to use an existing one if available, or create a new one other than the default global entity if needed.
		 * @param overrideVolume : If you want to ignore all modifiers and force a sound to play at a certain volume you can set that here.  Should NOT be used lightly, as it will ignore the sound settings in preferences.
		 */
		public static function play(group:Group, url:*, baseVolume:Number = 1, loop:Boolean = false, modifiers:* = null, id:String = null, overrideVolume:Number = NaN):AudioWrapper
		{
			//trace ("[AudioUtils] play: url" + url )
			if(id == null) { id = GLOBAL_SOUND; }
			
			var audio:Audio = getAudio(group, id);
			
			return(audio.play(url, loop, modifiers, baseVolume, overrideVolume));
		}
		
		/**
		 * places and play positional sound on an entity
		 */
		public static function playSoundFromEntity(target:Entity, soundUrl:String, radius:Number = 500, minVolume:Number = 0, maxVolume:Number = 1, ease:Function = null, loop:Boolean = false):void
		{
			var audio:Audio = target.get(Audio);
			
			if(audio == null)
			{
				audio = new Audio();
				target.add(audio);
			}
			
			var audioRange:AudioRange = target.get(AudioRange);
			
			if(audioRange == null)
			{
				audioRange = new AudioRange(radius, minVolume, maxVolume, ease);
				target.add(audioRange);
			}
			
			audio.play(soundUrl, loop, [SoundModifier.POSITION]);
		}
		
		public static function stop(group:Group, url:* = null, id:String = null):void
		{
			if(id == null) { id = GLOBAL_SOUND; }
			
			var audio:Audio = getAudio(group, id);
			
			if(url != null)
			{
				audio.stop(url);
			}
			else
			{
				audio.stopAll();
			}
		}
		
		/**
		 * Gets the audio component from an entity looked up by id.
		 */
		public static function getAudio(group:Group, id:String = null):Audio
		{
			if(id == null) { id = GLOBAL_SOUND; }
			
			var soundEntity:Entity = group.getEntityById(id);
			var audio:Audio;
			
			if(soundEntity == null)
			{
				soundEntity = createSoundEntity(id);
				group.addEntity(soundEntity);
			}
			
			audio = soundEntity.get(Audio);
			
			return(audio);
		}
		
		/**
		 * Create an entity with the base components needed for playing audio.
		 */
		public static function createSoundEntity(id:String = null, ignoreGroupPause:Boolean = true):Entity
		{
			if(id == null) { id = GLOBAL_SOUND; }
			
			var soundEntity:Entity = new Entity();
			var audio:Audio = new Audio();
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			soundEntity.ignoreGroupPause = ignoreGroupPause;

			soundEntity.add(new Id(id));
			soundEntity.add(sleep);
			soundEntity.add(audio);

			return(soundEntity);
		}
		
		public static const GLOBAL_SOUND:String = "globalSound";
	}
}