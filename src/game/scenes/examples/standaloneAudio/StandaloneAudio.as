package game.scenes.examples.standaloneAudio
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.AudioSequence;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.RenderSystem;
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.scene.SceneSound;
	import game.scene.template.AudioGroup;
	import game.scene.template.GameScene;
	import game.systems.SystemPriorities;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	
	public class StandaloneAudio extends Scene
	{
		public function StandaloneAudio()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/standaloneAudio/";
			
			super.init(container);
			
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// only need sounds.xml for this scene and a background
			super.loadFiles(["background.swf", GameScene.SOUNDS_FILE_NAME], false, true, loaded);
		}
		
		// all files ready
		override public function loaded():void
		{
			_screen = super.groupContainer.addChild(super.getAsset("background.swf", true)) as MovieClip;
			
			// for the cursor
			super.addSystem(new RenderSystem(), SystemPriorities.render);             // syncs an entity's Display component with its Spatial component
			// for buttons
			super.addSystem(new InteractionSystem(), SystemPriorities.update);	 
			
			setupAudio();
			
			setupButtons();
			
			super.loaded();
		}
		
		/**
		 * The audio provides access to some utilities for parsing sound.xml and adding sfx to entities.
		 */
		private function setupAudio():void
		{
			var audioGroup:AudioGroup = new AudioGroup();
			
			// this sets up systems necessary for audio playback
			audioGroup.setupGroup(this, super.getData(GameScene.SOUNDS_FILE_NAME));
			
			// you can pre-cache sounds if you don't want to wait for them to load later.
			_soundManager.cache(SoundManager.MUSIC_PATH + "Sneaky_Suspense.mp3");
			_soundManager.cache(SoundManager.MUSIC_PATH + "poseidon_realm.mp3");
			
			// this sets up an entity that we can use to playback sounds.
			setupSoundEntity();
			
			// the AudioGroup can associate all sounds mapped to an Entity's Id to its audio component.
			audioGroup.addAudioToAllEntities();
			
			makeEntityFollowInput(_soundEntity);
		}
		
		/**
		 * This is an example of adding an audio playback sequence to an entity.
		 */
		private function toggleAudioSequence(button:Entity):void
		{
			var audioSequence:AudioSequence = _soundEntity.get(AudioSequence);
			
			if(audioSequence == null)
			{
				audioSequence = new AudioSequence();
				// an audio sequence can loop if needed, this defaults to 'false'.
				audioSequence.loop = false;
				// add sounds to the sequence.  You can mix and match sound urls with SoundData.
				audioSequence.sequence.push(SoundManager.EFFECTS_PATH + "bear_growl_01.mp3");
				audioSequence.sequence.push(SoundManager.EFFECTS_PATH + "being_swallowed.mp3");
				audioSequence.sequence.push(SoundManager.EFFECTS_PATH + "bells_01.mp3");
				audioSequence.sequence.push(new SoundData(SoundManager.EFFECTS_PATH + "buzzer_02.mp3", [SoundModifier.POSITION]));
				audioSequence.sequence.push(new SoundData(SoundManager.EFFECTS_PATH + "buzzer_02.mp3", [SoundModifier.POSITION]));
				audioSequence.sequence.push(new SoundData(SoundManager.EFFECTS_PATH + "buzzer_02.mp3", [SoundModifier.POSITION]));
				audioSequence.playbackComplete.add(sfxSequenceComplete);
				_soundEntity.add(audioSequence);
			}
			
			// toggle between playing this sequence and stopping it.  Stopping the sequence will stop the sound immediately.  If you play it again it will 'resume' by playing
			//   the next sound in the sequence.
			audioSequence.play = !audioSequence.play;
			
			if(audioSequence.play)
			{
				_screen.sfxSequenceLight.gotoAndStop("on");
			}
			else
			{
				_screen.sfxSequenceLight.gotoAndStop("off");
			}
		}
		
		/**
		 * This is an example of creating a new entity from scratch and using it to play back sounds.
		 */
		private function setupSoundEntity():void
		{
			_soundEntity = new Entity();
			// all that is needed to playback sounds from an entity is an Audio component.
			_soundEntity.add(new Audio());
			
			// adding an id to an entity allows it to be associated with sound effects specified in 'sounds.xml'.  This is not required unless you want
			//   to map sounds from sounds.xml to it.
			_soundEntity.add(new Id("soundEntity"));
						
			super.addEntity(_soundEntity);
		}
		
		/**
		 * This method uses an entity's Audio component to play a sound url directly.  You need to specify the path to the audio file starting with the type.
		 */
		private function playEntitySound(button:Entity):void
		{
			var audio:Audio = _soundEntity.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "camera_01.mp3");
		}
		
		/**
		 * This method uses an entity's Audio component to play sound data directly.  You can use SoundData to configure more aspects of playback.  The path is determined based on its 'type'.
		 */
		private function playEntitySoundData(button:Entity):void
		{
			var audio:Audio = _soundEntity.get(Audio);
			var soundData:SoundData = new SoundData();
			soundData.asset = SoundManager.EFFECTS_PATH + "cat_meow_01.mp3";
			audio.playFromSoundData(soundData);
		}
		
		/**
		 * This method uses an entity's Audio component to play a sound associated with an action specified in 'sounds.xml'.
		 */
		private function playEntitySoundAction(button:Entity):void
		{
			var audio:Audio = _soundEntity.get(Audio);
			audio.playCurrentAction("myAction");
		}
		
		/**
		 * This method uses a global sound entity to playback sound.  This doesn't require manual creation of an entity, but it will not have positioning.  Suitable for music or non-positional sfx.
		 */
		private function playGlobalSound(button:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "cannon_shot_01.mp3");
		}
		
		/**
		 * This triggers events which are mapped to global sounds specified in 'sounds.xml'.
		 */
		private function switchMusic(button:Entity, track:int):void
		{
			if(track != _previousTrack)
			{
				super.shellApi.triggerEvent("playTrack" + track);
				_screen["track" + track + "Light"].gotoAndStop("on");
				if(_previousTrack != 0)
				{
					_screen["track" + _previousTrack + "Light"].gotoAndStop("off");
				}
				_previousTrack = track;
			}
			else
			{
				var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
				audio.stopAll(SoundType.MUSIC);
				//audio.fadeAll(0, NaN, 1, SoundType.MUSIC);
				_screen["track" + _previousTrack + "Light"].gotoAndStop("off");
				_previousTrack = 0;
			}
		}
		
		private function setupButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 16, 0xD5E1FF);
			
			ButtonCreator.createButtonEntity( _screen.track1Button, this, Command.create(switchMusic, 1) );
			ButtonCreator.addLabel( _screen.track1Button, "Play Track 1", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_screen.track1Light.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( _screen.track2Button, this, Command.create(switchMusic, 2) );
			ButtonCreator.addLabel( _screen.track2Button, "Play Track 2", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_screen.track2Light.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( _screen.track3Button, this, Command.create(switchMusic, 3) );
			ButtonCreator.addLabel( _screen.track3Button, "Play Track 3", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_screen.track3Light.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( _screen.track4Button, this, Command.create(switchMusic, 4) );
			ButtonCreator.addLabel( _screen.track4Button, "Play Track 4", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_screen.track4Light.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( _screen.track5Button, this, Command.create(switchMusic, 5) );
			ButtonCreator.addLabel( _screen.track5Button, "Play Track 5", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_screen.track5Light.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( _screen.sfxSequenceButton, this, toggleAudioSequence);
			ButtonCreator.addLabel( _screen.sfxSequenceButton, "Play SFX Sequence", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_screen.sfxSequenceLight.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( _screen.playEntitySoundButton, this, playEntitySound);
			ButtonCreator.addLabel( _screen.playEntitySoundButton, "Play Entity Sound", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( _screen.playEntitySoundDataButton, this, playEntitySoundData);
			ButtonCreator.addLabel( _screen.playEntitySoundDataButton, "Play Entity SoundData", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( _screen.playEntityActionButton, this, playEntitySoundAction);
			ButtonCreator.addLabel( _screen.playEntityActionButton, "Play Entity Sound Action", labelFormat, ButtonCreator.ORIENT_CENTERED);
			
			ButtonCreator.createButtonEntity( _screen.playGlobalSoundButton, this, playGlobalSound);
			ButtonCreator.addLabel( _screen.playGlobalSoundButton, "Play Global Sound", labelFormat, ButtonCreator.ORIENT_CENTERED);
		}
			
		private function makeEntityFollowInput(entity:Entity):void
		{
			//  ... we'll add positioning to this one, but it is not required.
			// use an 'AudioRange' to setup the characteristics of the positional audio
			// AudioRange(radius:Number, minVolume:Number = 0, maxVolume:Number = 1, tween:Function = null)
			_soundEntity.add(new AudioRange(400, 0.1, 1, Quad.easeIn));
			// the spatial component will determine the source of the positional sound.
			_soundEntity.add(new Spatial(480, 320));
			
			// ... we'll also add an optional display component so the sound entity can be seen.
			_soundEntity.add(new Display(_screen.soundTarget));
			
			EntityUtils.followTarget(entity, super.shellApi.inputEntity, .02, null, true);
			super.addSystem(new FollowTargetSystem(), SystemPriorities.move);
		}
		
		private function sfxSequenceComplete():void
		{
			_screen.sfxSequenceLight.gotoAndStop("off");
			var audioSequence:AudioSequence = _soundEntity.get(AudioSequence);
			audioSequence._index = 0;  // reset the index so the sequence can be started over.
		}
		
		private var _previousTrack:int = 0;
		private var _screen:MovieClip;
		private var _soundEntity:Entity;
		
		[Inject]
		public var _soundManager:SoundManager;
	}
}