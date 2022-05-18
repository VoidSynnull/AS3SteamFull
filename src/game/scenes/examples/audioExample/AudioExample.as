package game.scenes.examples.audioExample
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.data.AudioWrapper;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.data.sound.SoundModifier;
	import game.scene.SceneSound;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.util.AudioUtils;
	import game.util.TimelineUtils;
	
	/**
	 * Entity-specific Sounds **************
	 * 
	 * 'entity specific sounds' are associated with a particular entity to allow things like positioning and making cleanup easier.  The simplest way to add sound to an existing entity is this:
	 * 
	 * var myEntity:Entity = new Entity();
	 *  var audio:Audio = new Audio();
	 *  myEntity.add(audio);
	 *  audio.play(SoundManager.EFFECTS_PATH + "bells_01.mp3");
	 * super.addEntity(myEntity);
	 * 
	 * If the entity has an id and sounds associated with it in sounds.xml, you can add all of those sounds to it with
	 * 
	 * myEntity.add(new Id("myEntity"));
	 * audioGroup.addAudioToEntity(myEntity);
	 * 
	 * Finally, if you want to create an entity from scratch for the purpose of playing sounds, you can use this code:
	 * 
	 * var mySoundEntity:Entity = AudioUtils.createSoundEntity("mySoundEntity");
	 * 
	 * From there you can play sounds on it the normal way:
	 * 
	 * mySoundEntity.get(Audio).play(SoundManager.EFFECTS_PATH + "bells_01.mp3");
	 * 
	 * Check out the other examples in this scene to see how to play positional sounds on an entity.
	 * 
	 * 
	 * Global Sounds ************************
	 *  'global sounds' are sounds that do not need to be associated with a particular entity and don't do any positioning or fading.  These are mostly used for ui, but occasionally they're useful in scenes as well.  In general sounds should be associated with an entity in a scene whenever possible.  If you're sure your sound should be global though you can use this syntax to play it (check out AudioUtils.as for more details):
	 *
	 *	AudioUtils.play(group:Group, url:*, baseVolume:Number = 1, loop:Boolean = false, modifiers:* = null, id:String = null, overrideVolume:Number = NaN):AudioWrapper
	 *	
	 *	ex :
	 *	
	 *	AudioUtils.play(scene, SoundManager.EFFECTS_PATH + OPEN_DOOR);
	 *	
	 *	This creates a sound entity (if a global one doesn't already exist) and plays the sound on its audio component. 
	 *	
	 *	If you don't specify any modifiers one will be picked based on path (so music/ assets will get assigned global music volume by default, etc).
     * 
	 *
	 * Scene Sounds *************************
	 *
	 * 'scene sounds' are just global sounds that are automatically created on scene creation and used to playback music and ambient tracks in the scene.  You can play sounds through the scene
	 * using AudioUtils like this:
	 * 
	 * // in this case im fading out all music first...
	 * AudioUtils.getAudio(this, SceneSound.SCENE_SOUND).fadeAll(0, NaN, 1, SoundModifier.MUSIC);
	 * // now play the new scene music
	 * AudioUtils.play(this, SoundManager.MUSIC_PATH + "PoptropicaTheme.mp3", 1, true, null, SceneSound.SCENE_SOUND);
	 * 
	 */
	
	public class AudioExample extends PlatformerGameScene
	{
		public function AudioExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/audioExample/";
			super.showHits = true;
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			setupButtons();
			
			var npc:Entity = super.getEntityById("npc");
			
			var audioGroup:AudioGroup = super.getGroupById("audioGroup") as AudioGroup;
			// this will add any audio matching this entity's id of 'npc' to its Audio component.
			audioGroup.addAudioToEntity(npc);
			Interaction(npc.get(Interaction)).click.add(npcClicked);
 
			createPositionalSoundSource();
		}
		
		private function doEventSound(...args):void
		{
			// This event is linked to a sound in sound.xml
			super.shellApi.triggerEvent("bigPow");
		}
		
		private function doGlobalSound(...args):void
		{
			// AudioUtils.play allows you to play sounds on an existing entity -or- it will create a 'global' sound entity if one doesn't exist.
			//  Global entities will not use sound positioning.
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "bathroom_toilet_flush_01.mp3");
		}
		
		/**
		 * Creates a new entity and makes it a positional sound source.
		 */
		private function createPositionalSoundSource():void
		{
			var entity:Entity = new Entity();

			var audio:Audio = new Audio();
			// sets the url, looping and adds the 'SoundModifier.POSITION' so this will use the position to control the volume and panning of the sound.
			audio.play(SoundManager.AMBIENT_PATH + "bubbling.mp3", true, SoundModifier.POSITION)

			entity.add(new Display(super.hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial());
			// use an 'AudioRange' to setup the characteristics of the positional audio
			// AudioRange(radius:Number, minVolume:Number = 0, maxVolume:Number = 1, tween:Function = null)
			entity.add(new AudioRange(1000, 0.01, 1, Quad.easeIn));
			entity.add(new Id("soundSource"));
			TimelineUtils.convertClip(super.hitContainer["soundSource"], this, entity);
			
			super.addEntity(entity);
			
			var audioGroup:AudioGroup = super.getGroupById("audioGroup") as AudioGroup;
			// this will add any audio matching this entity's id of 'npc' to its Audio component.
			audioGroup.addAudioToEntity(entity);
		}
		
		private function npcClicked(entity:Entity):void
		{
			var audioComponent:Audio = entity.get(Audio);
			// entities can have any number of sound 'actions' setup in the sounds.xml.
			var wrapper:AudioWrapper = audioComponent.playCurrentAction("effects");
			wrapper.complete.addOnce(handleEffectComplete);
		}
		
		private function handleEffectComplete():void
		{
			trace("effect complete!");
		}
		
		private function switchMusic(button:Entity, type:String):void
		{
			//'SceneSound.SCENE_SOUND' is a sound entity that is available in every scene and responsible for playing music and ambient tracks.
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			audio.fadeAll(0, NaN, 1, SoundModifier.MUSIC);

			var url:String;
			
			if(type == _currentMusicType)
			{
				MovieClip(super._hitContainer).happyMusicLight.gotoAndStop("off");
				MovieClip(super._hitContainer).sadMusicLight.gotoAndStop("off");
				_currentMusicType = null;
				return;
			}
			
			_currentMusicType = type;
			
			if(type == "sad")
			{
				url = "vh_video_romantic_loop.mp3";
				MovieClip(super._hitContainer).happyMusicLight.gotoAndStop("off");
				MovieClip(super._hitContainer).sadMusicLight.gotoAndStop("on");
			}
			else if(type == "happy")
			{
				url = "PoptropicaTheme.mp3";
				MovieClip(super._hitContainer).happyMusicLight.gotoAndStop("on");
				MovieClip(super._hitContainer).sadMusicLight.gotoAndStop("off");
			}
			
			AudioUtils.play(this, SoundManager.MUSIC_PATH + url, 1, true, null, SceneSound.SCENE_SOUND);
		}
		
		private function playAlarm(button:Entity):void
		{
			// we will use the positional sound source to play the alarm ambient sound as an effect.
			var entity:Entity = super.getEntityById("soundSource");
			var audio:Audio = entity.get(Audio);
			
			audio.playCurrentAction("effects");
		}
		
		private function setupButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 12, 0xD5E1FF);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).eventSoundButton, this, doEventSound );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).eventSoundButton, "Trigger Event Sound", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).sadMusicButton, this, Command.create(switchMusic, "sad") );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).sadMusicButton, "Sad Music", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).happyMusicButton, this, Command.create(switchMusic, "happy") );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).happyMusicButton, "Happy Music", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).globalSoundButton, this, doGlobalSound );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).globalSoundButton, "Play Global Sound", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).playAlarmButton, this, playAlarm );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).playAlarmButton, "Play Positional Alarm", labelFormat, ButtonCreator.ORIENT_CENTERED);
		}
		
		private var _currentMusicType:String;
	}
}