package game.scenes.custom
{
	import com.poptropica.AppConfig;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.data.AudioWrapper;
	import engine.managers.SoundManager;
	import engine.systems.AudioSystem;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.sound.SoundModifier;
	import game.managers.ads.AdManager;
	import game.scene.template.CharacterGroup;
	import game.scenes.custom.beatGameSystems.BeatGameSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class BeatGamePower extends AdBasePopup
	{
		// these are accessed by BeatGameSystem
		public var playing:Boolean = true;
		public var bitmaps:Array = []; // array of bitmapData objects
		public var targetY:Number; // destination y position for falling objects (place base object on top of drum in FLA)
		public var barLength:Number = 200; // maximum length of progress bar (length is pulled from FLA)
		public var largeDrop:MovieClip; // large drop clip over drums to be scaled up

		private var _system:BeatGameSystem;
		private var _audioSystem:AudioSystem;
		private var _xmlPath:String; // path to xml
		private var _npcPlayer:Entity; // avatar entity in game
		private var _animClass:Class; // avatar animation class
		private var _needleStatus:int = 0; // current needle status
		private var _numHits:int = 0; // total number of hits
		private var _correctHits:int = 0; // number of correct hits
		private var _totalNotes:int = 0; // total number of notes (falling objects)
		private var _flashingTimeline:Timeline; // flashing timeline - optional
		private var _flashing:Boolean = false; // is flashing flag
		private var _muted:Boolean = false; // game is muted flag
		
		// music variables
		private var _muteBtn:Entity;
		private var _unmuteBtn:Entity;
		private var _musicWrapperCurVolume:Number;
		private var _ambientCurVolume:Number;
		private var _musicWrapper:AudioWrapper; // wrapper for music
		
		// these params map to xml file
		private var _musicFile:String; // name of music MP3 file (required)
		private var _musicVolume:Number = 50; // music volume (50 is default)
		private var _correctSound:String; // sound effect file for correct hit
		private var _incorrectSound:String; // sound effect file for incorrect hit
		private var _sfxVolume:Number = 1.5; // base volume for sfx
		private var _coords:Array; // npc coordinates (required)
		private var _scale:Number = 0.36; // scale for npc (0.36 is standard)
		private var _item:String; // item part ID - optional
		private var _bpm:Number = 42; // beats per minute
		public var _timeout:Number = 30; // timeout in seconds
		public var _speed:Number = 140; // distance in pixels per second
		public var _buttonScale:Number = 0; // how much the falling object scales up on a correct hit (0 is off)
		private var _animClassName:String = "game.data.animation.entity.character.GuitarLoop"; // animation for avatar
		private var _accuracy:Number = 0.75; // target hit accuracy to determine game success
		private var _overlap:Number = 85; // amount of overlap in pixels when checking drums
		private var _initialDist:Number = 0; // initial distance added to beginning of all falling objects (use to fine-tune alignment of all notes)
		private var _needleJump:Number = 0; // amount in degrees needle rotates per hit (0 is off)
		private var _numLights:Number = 0; // number of animated lights
		private var _numAnims:Number = 0; // number of animated movie clip timelines
		private var _numDrums:Number = 3; // number of drum buttons (buttons are normally transparent)
		private var _note0:Array; // array of notes for first note
		private var _note1:Array; // array of notes for second note
		private var _note2:Array; // array of notes for third note
		private var _note3:Array; // array of notes for fourth note
		private var _particleClassName:String; // particle class for effect on correct hit
		private var _color1:Array; // color for particle class (required if using particle class)
		private var _color2:Array; // color for particle class (required if using particle class)
		private var _particleRange:Array; // minimum and maximum values for number of particles (required if using particle class)
		
		/**
		 * Init popup 
		 * @param container
		 */
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set tracking to empty so that it will be game ID only
			_popupType = "";
			// set gametype to Game for popup game
			_gameType= "Game";
			super.init(container);
		}
		
		/**
		 * initiate asset load of scene specific assets
		 */
		override public function load():void
		{
			// get path to swf and xml
			_swfPath = _questName + _swfName;
			_xmlPath = _swfPath.replace(".swf", ".xml");
			trace("Loading " + _xmlPath);
			super.loadFile(_xmlPath, loadedXML);
		}
		
		/**
		 * When xml loaded, now load swf
		 */
		private function loadedXML(gameXML:XML):void
		{
			// parse xml
			parseGameXML(gameXML);
			
			// convert classname to class
			_animClass = ClassUtils.getClassByName(_animClassName);
			
			trace("Loading " + _swfPath);
			super.loadFile(_swfPath, loadedSwf);
		}
				
		/**
		 * When swf loaded
		 */
		private function loadedSwf(clip:MovieClip):void
		{
			// save clip to screen
			super.screen = clip;
			super.loaded();
		}
		
		/**
		 * Parse game xml 
		 */
		private function parseGameXML(gameXML:XML):void
		{
			trace("Parsing " + _xmlPath);
			// if xml object, then setup
			if (gameXML != null)
			{
				// parse game xml
				var items:XMLList = gameXML.children();
				// for each group in xml
				for (var i:int = items.length() - 1; i != -1; i--)
				{
					var propID:String = "_" + items[i].name();
					var value:String = items[i].valueOf();
					try
					{
						// check number value
						var numberVal:Number = Number(value);
						// if true
						if (value.toLowerCase() == "true")
						{
							this[propID] = true;
						}
						else if (value.toLowerCase() == "false")
						{
							// if false
							this[propID] = false;
						}
						else if (isNaN(numberVal))
						{
							// if string
							// if contains comma, then assume array
							if (value.indexOf(",") != -1)
							{
								var arr:Array = value.split(",");
								// convert to numbers if array has numbers
								for (var j:int = arr.lenghth-1; j != -1; j--)
								{
									numberVal = Number(arr[j]);
									// if number, then swap
									if (!isNaN(numberVal))
										arr[j] = numberVal;
								}
								this[propID] = arr;
							}
							else
							{
								this[propID] = value;
							}
						}
						else
						{
							// if number
							this[propID] = numberVal;
						}
					}
					catch (e:Error)
					{
						trace("Property " + propID + " does not exist in class!");
					}
				}
			}
			else
			{
				trace("Game XML not loaded");
			}
		}
		
		/**
		 * Setup specific popup buttons 
		 */
		override protected function setupPopup():void
		{
			trace("BeatGamePower: setupPopup");
			
			// setup mute and umnute buttons
			if (super.screen.muteButton)
				_muteBtn = setupButton(super.screen.muteButton, mute, false);
			if (super.screen.soundButton)
			{
				_unmuteBtn = setupButton(super.screen.soundButton, unmute, false);
				_unmuteBtn.get(Display).visible = 0;
			}
			
			// add flashing clip if found, then setup
			if (super.screen.flashing)
			{
				var flashingEntity:Entity = TimelineUtils.convertClip(super.screen.flashing, super);
				flashingEntity.add(new Id("flashing"));
				_flashingTimeline = flashingEntity.get(Timeline);
				TimelineUtils.onLabel(flashingEntity, "ending", loopFlashing, false);
			}
			
			// set up drum buttons
			for (var i:int = 0; i != _numDrums; i++)
			{
				// buttons trigger on mouse down
				setupButton(super.screen["drum" + i], Command.create(clickDrum, i), false, InteractionCreator.DOWN);
			}
			
			// setup lights
			for (i = 0; i != _numLights; i++)
			{
				setupLight(super.screen["light" + i]);
			}
			
			// setup anims
			for (i = 0; i != _numAnims; i++)
			{
				setupAnim(super.screen["anim" + i]);
			}
			
			// setup falling objects
			for (i = 0; i != _numDrums; i++)
			{
				setupDrop(super.screen["drop" + i]);
			}
			
			// get progress bar length
			if (super.screen.meter)
			{
				barLength = super.screen.meter.bar.height;
				super.screen.meter.bar.height = 0;
			}
			
			// look for web/mobile elements
			if ((super.screen["web"] != null) && (AppConfig.mobile))
				super.screen.removeChild(super.screen["web"]);
			if ((super.screen["mobile"] != null) && (!AppConfig.mobile))
				super.screen.removeChild(super.screen["mobile"]);
			
			// if avatar animation, then don't load player
			if (super.screen["avatar"] == null)
			{
				// get character group
				var charGroup:CharacterGroup = new CharacterGroup();
				charGroup.setupGroup( this, super.screen );
				
				// add item to player if found
				var oldItem:String;
				if (_item)
				{
					oldItem = super.shellApi.profileManager.active.look.item;
					super.shellApi.profileManager.active.look.item = _item;
				}
				
				// create NPC player			
				_npcPlayer = charGroup.createNpcPlayer(onCharLoaded, null, new Point(_coords[0], _coords[1]));
				_npcPlayer.get(Display).visible = false;
	
				// restore old item to player
				if (oldItem)
					super.shellApi.profileManager.active.look.item = oldItem;
			}
			else
			{
				startGame();
			}
		}
		
		/**
		 * When NPC player is loaded 
		 * @param charEntity
		 */
		private function onCharLoaded( charEntity:Entity):void
		{
			// flip char
			_npcPlayer.get(Spatial).scaleX = -_scale;
			_npcPlayer.get(Spatial).scaleY = _scale;
			
			// move char to depth of foreground
			var clip:MovieClip = charEntity.get(Display).displayObject;
			clip.parent.setChildIndex(clip, clip.parent.getChildIndex(super.screen.foreground));
			
			// show avatar
			_npcPlayer.get(Display).visible = true;
			
			// play animation
			if(_animClass)
				CharUtils.setAnim(_npcPlayer, _animClass);
			else
				trace("Class is not found: " + _animClassName);

			startGame();
 		}
		
		/**
		 * Start game
		 */
		private function startGame():void
		{
			// uncover game
			super.screen.cover.visible = false;
			
			// move player if requested
			if (_returnY != 0)
			{
				var player:Spatial = super.shellApi.player.get(Spatial);
				player.x = _returnX;
				player.y = _returnY;
			}

			// calculate multiplier to spread out notes so they land on the beat
			var multiplier:Number = _speed * 60 / _bpm;
			
			// create array with all notes
			var notes:Array = [];
			for (var i:int = 0; i != _numDrums; i++)
			{
				// expand note array by multiplier
				var note:Array = this["_note" + i];
				//trace("Processing note array for note column " + i + ": " + note);
				_totalNotes += note.length;
				for (var j:int = note.length - 1; j != -1; j--)
				{
					note[j] *= multiplier;
					note[j] += _initialDist;
				}
				notes.push(note);
			}
			
			// add game system
			_system  = BeatGameSystem(this.addSystem( new BeatGameSystem(this, notes), SystemPriorities.update ));
			
			// play music
			if (_audioSystem == null)
				_audioSystem = AudioSystem(this.groupEntity.group.getSystem(AudioSystem));
			if(_musicFile != null)
			{
				_musicWrapperCurVolume = _audioSystem.getVolume("music");
				_ambientCurVolume = _audioSystem.getVolume("ambient");
				// if music is set to zero, then the game music won't play
				_audioSystem.setVolume(0.01, "music");
				_audioSystem.setVolume(0, "ambient");
				_musicWrapper = AudioUtils.play(this, SoundManager.MUSIC_PATH + _musicFile, _musicVolume, true);
			}
		}
		
		/**
		 * Loop flashing animation 
		 */
		private function loopFlashing():void
		{
			_flashingTimeline.gotoAndPlay("loop");
		}
		
		/**
		 * When click drum 
		 * @param button
		 * @param num
		 */
		private function clickDrum(button:Entity, num:int):void
		{
			// check overlap
			if (_system.checkDrum(num, _overlap))
			{
				// if overlap
				_numHits++;
				_correctHits++;
				_needleStatus++;
				checkAccuracy();
				
				// scale up falling object only if there is _buttonScale
				if (_buttonScale != 0)
				{
					largeDrop = super.screen["drop" + num];
					largeDrop.start = getTimer();
				}
				
				// set up confetti effect
				var emitterClass:Class = ClassUtils.getClassByName(_particleClassName);
				if (emitterClass)
				{
					var emitterObj:Object = new emitterClass();
					// set counter according to particle range
					emitterObj.init(_color1[num], _color2[num], _particleRange[0] + _correctHits / _totalNotes * (_particleRange[1] - _particleRange[0]));
					var spatial:Spatial = button.get(Spatial);
					EmitterCreator.create(this, super.screen, Emitter2D(emitterObj), spatial.x, spatial.y);
				}
				
				// play sound if unmuted
				if ((!_muted) && (_correctSound))
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + _correctSound, _sfxVolume, false);
			}
			else
			{
				// if incorrect
				// play sound if unmuted
				if ((!_muted) && (_incorrectSound))
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + _incorrectSound, _sfxVolume, false);
				// play incorrect animation
				var timeline:Timeline = button.get(Timeline);
				if (timeline != null)
					timeline.gotoAndPlay(2);
			}
		}
		
		/**
		 * When falling object reaches drum
		 */
		public function missHit():void
		{
			_numHits++;
			_needleStatus--;
			checkAccuracy();
		}
		
		/**
		 * check accuracy of hits and update flashing display
		 */
		private function checkAccuracy():void
		{
			// update needle
			if (_needleJump != 0)
				super.screen.needle.rotation = _needleJump * _needleStatus;
			
			var percent:Number = _correctHits/_numHits;
			trace("accuracy: " + percent);
			
			// if losing and more than one hit, then show flashing
			if (_flashingTimeline)
			{
				if ((percent < _accuracy) && (_numHits > 1))
				{
					if (!_flashing)
					{
						_flashing = true;
						loopFlashing();
					}
				}
				else
				{
					// if winning, then hide flashing
					if (_flashing)
					{
						_flashing = false;
						_flashingTimeline.gotoAndPlay(0);
					}
				}
			}
		}
		
		// SETUP FUNCTIONS //////////////////////////////////////////////////////////////////
		
		private function setupLight(light:MovieClip):void
		{
			if (light)
			{
				var entity:Entity = EntityUtils.createSpatialEntity(this, light, super.screen);
				rotateLight(entity);
			}
		}
		
		private function rotateLight(light:Entity):void
		{
			var target:Number = getRandomNumber(15, 35);
			if (light.get(Spatial).rotation > 0)
				target = -target;
			TweenUtils.entityTo(light, Spatial, getRandomNumber(1, 4), {rotation:target, repeat:0, onComplete:Command.create(rotateLight, light)});
		}
		
		private function setupAnim(anim:MovieClip):void
		{
			if (anim)
				TimelineUtils.convertClip(anim, super);
		}
		
		private function setupDrop(clip:MovieClip):void
		{
			if (clip)
			{
				// set target Y to y position of drop clips in FLA (these should be aligned over drum buttons)
				targetY = clip.y;
				clip.centerX = clip.x + clip.width/2;
				clip.centerY = clip.y + clip.height/2;
				clip.time = 1000; // time in milliseconds for animation when correct hit
				
				// save bitmap
				var bitmapData:BitmapData = new BitmapData(clip.width, clip.height, true, 0x00000000);
				bitmapData.draw(clip);
				// create object with bitmap data and x location
				var drop:Object = {bd:bitmapData, x:clip.x};
				bitmaps.push(drop);
			}
		}
		
		private function mute(button:Entity):void
		{
			_muteBtn.get(Display).visible = false;
			_unmuteBtn.get(Display).visible = true;
			updateVolume(0);
			// prevents scene music from being heard
			_audioSystem.setVolume(0, "music");
			_muted = true;
		}
		
		private function unmute(button:Entity):void
		{
			_muteBtn.get(Display).visible = true;
			_unmuteBtn.get(Display).visible = false;
			updateVolume(_musicVolume);
			// restores soft scene music
			_audioSystem.setVolume(0.01, "music");
			_muted = false;
		}
		
		private function updateVolume(volume:Number):void
		{
			_musicWrapper.volumeModifiers[SoundModifier.BASE] = volume;
			var currentLevel:Number;
			var finalVolume:Number = 1;
			for each(currentLevel in _musicWrapper.volumeModifiers)
			{
				finalVolume *= currentLevel;
			}
			_musicWrapper.transform.volume = finalVolume;
			_musicWrapper.channel.soundTransform = _musicWrapper.transform;
		}
		
		/**
		 * End game 
		 */
		public function endGame():void
		{
			playing = false;
			
			// dispose of bitmaps
			for (var i:int = bitmaps.length -1; i != -1; i--)
			{
				var drop:Object = bitmaps[i];
				drop.bd.dispose();
				bitmaps.splice(i,1);
			}
			
			// mute music and restore previous audio
			updateVolume(0);
			_audioSystem.setVolume(_musicWrapperCurVolume, "music");
			_audioSystem.setVolume(_ambientCurVolume, "ambient");

			// calculate accuracy
			var percent:Number = _correctHits/_numHits;
			
			// determine win or lose popup by accuracy
			var popupClass:Class;
			if (percent >= _accuracy)
				popupClass = AdWinGamePopup;
			else
				popupClass = AdLoseGamePopup;
			
			// load popup
			var popup:Popup = super.shellApi.sceneManager.currentScene.addChildGroup(new popupClass()) as Popup;
			popup.campaignData = super.campaignData;
			popup.init( super.shellApi.sceneManager.currentScene.overlayContainer );
		}
		
		/**
		 * Close popup
		 * @param button
		 */
		override protected function closePopup(button:Entity):void
		{
			AdManager(super.shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLOSE_GAME_POPUP, _trackingChoice);
			_correctHits = 0;
			endGame();
		}

		/**
		 * Get random number within range 
		 * @param start
		 * @param end
		 * @return Number
		 */
		private function getRandomNumber(start:Number, end:Number):Number
		{
			return start + Math.random() * (end - start);
		}
	}
}