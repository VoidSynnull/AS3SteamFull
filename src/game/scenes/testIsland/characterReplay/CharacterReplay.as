package game.scenes.testIsland.characterReplay
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.creators.ui.ButtonCreator;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	
	public class CharacterReplay extends PlatformerGameScene
	{
		public function CharacterReplay()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/testIsland/characterReplay/";
			
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
			createDummy();
			
			setupUI();
			
			super.addSystem(new CharacterReplaySystem());
			super.addSystem(new CharacterSceneStateSystem());
			
			super.loaded();
		}
		
		private function createDummy():void
		{
			var characterGroup:CharacterGroup = super.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			var lookConverter:LookConverter = new LookConverter();
			var lookData:LookData = lookConverter.lookDataFromPlayerLook( shellApi.profileManager.active.look );
			characterGroup.createDummy("replayDummy", lookData, CharUtils.DIRECTION_RIGHT, "", null, null, dummyLoaded);
		}
		
		private function dummyLoaded(charEntity:Entity):void
		{
			_characterReplay = new CharacterReplayComponent();
			_characterReplay.source = super.player;
			_characterReplay.sampleRate = _sampleRates[0];
			charEntity.add(_characterReplay);
			charEntity.add(new CurrentCharacterSceneState());
			charEntity.remove(Sleep);
			charEntity.sleeping = false;
			
			var spatial:Spatial = charEntity.get(Spatial);
			var playerSpatial:Spatial = super.player.get(Spatial);
			spatial.x = playerSpatial.x;
			spatial.y = playerSpatial.y;
			spatial.scaleX = playerSpatial.scaleX;
			spatial.scaleY = playerSpatial.scaleY;
			
			//EntityUtils.followTarget( charEntity, super.player, .02, null, false);
		}
		
		private function setupUI():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 12, 0xD5E1FF);
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).recordButton, this, handleToggleRecord );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).recordButton, "Recording", labelFormat, ButtonCreator.ORIENT_CENTERED);
			MovieClip(super._hitContainer).recordToggleLight.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity(MovieClip(super._hitContainer).playButton, this, handleTogglePlay );
			ButtonCreator.addLabel(MovieClip(super._hitContainer).playButton, "Playing", labelFormat, ButtonCreator.ORIENT_CENTERED);
			MovieClip(super._hitContainer).playToggleLight.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).sampleRateButton, this, handleCycleSampleRate );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).sampleRateButton, "Cycle Sample Rate", labelFormat, ButtonCreator.ORIENT_CENTERED);
			_sampleRateText = MovieClip(super._hitContainer).sampleRateText;
			_sampleRateText.text = String(_sampleRates[_sampleRateIndex]) + _sampleRateLabels[_sampleRateIndex];
			
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).randomSampleRateButton, this, handleToggleRandomSample );
			ButtonCreator.addLabel( MovieClip(super._hitContainer).randomSampleRateButton, "Random Sample Rate", labelFormat, ButtonCreator.ORIENT_CENTERED);
			MovieClip(super._hitContainer).randomSampleRateToggleLight.gotoAndStop("off");
		}
		
		private function handleToggleRecord(button:Entity):void
		{
			_recording = !_recording;
			
			var frame:String = "off";
			
			if(_recording)
			{
				frame = "on";
				_characterReplay.recordTime = 0;
				_characterReplay.replayTime = 0;
				_characterReplay.states.length = 0;
			}
			
			_characterReplay.record = _recording;
			
			MovieClip(super._hitContainer).recordToggleLight.gotoAndStop(frame);
		}
		
		private function handleTogglePlay(button:Entity):void
		{
			_playing = !_playing;
			
			var frame:String = "off";
			
			if(_playing)
			{
				frame = "on";
				_characterReplay.replayTime = 0;
			}
				
			_characterReplay.play = _playing;
			
			MovieClip(super._hitContainer).playToggleLight.gotoAndStop(frame);
		}
		
		private function handleCycleSampleRate(button:Entity):void
		{
			_sampleRateIndex++;
	
			if(_sampleRateIndex == _sampleRates.length)
			{
				_sampleRateIndex = 0;
			}
			
			_characterReplay.sampleRate = _sampleRates[_sampleRateIndex];
			_sampleRateText.text = _sampleRates[_sampleRateIndex].toString() + _sampleRateLabels[_sampleRateIndex];
		}
		
		private function handleToggleRandomSample(button:Entity):void
		{
			_randomSample = !_randomSample;
			
			var frame:String = "off";
			
			_characterReplay.randomSamples = _randomSample;
			
			if(_randomSample)
			{
				frame = "on";
			}
			else
			{
				_characterReplay.sampleRate = _sampleRates[_sampleRateIndex];
			}

			MovieClip(super._hitContainer).randomSampleRateToggleLight.gotoAndStop(frame);
		}
		
		private var _sampleRateText:TextField;
		private var _randomSampleRate:Boolean = false;
		private var _sampleRates:Array = [.016, .033, .067, .2, .5, 1];
		private var _sampleRateLabels:Array = ["(60 fps)", "(30 fps)", "(15 fps)", "(5 fps)", "(2 fps)", "(1 fps)"];
		private var _sampleRateIndex:int = 0;
		private var _recording:Boolean = false;
		private var _randomSample:Boolean = false;
		private var _characterReplay:CharacterReplayComponent;
		private var _playing:Boolean = false;
	}
}