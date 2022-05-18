package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.systems.AudioSystem;
	
	import game.components.ui.CardItem;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ads.AdManager;
	import game.scene.template.ui.CardGroup;
	import game.scene.template.ui.CardGroupPop;
	import game.scenes.custom.targetShootingSystems.TargetShootingSystem;
	import game.scenes.hub.starcade.Starcade;
	import game.systems.SystemPriorities;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.ui.card.CardView;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.ClassUtils;
	import game.utils.AdUtils;
	
	public class TargetShootingGamePower extends Popup
	{
		private var _campaignName:String;
		private var _clickURL:String;
		private var _clickURLButton:Entity;
		private var _playButton:Entity;
		private var _quitButton:Entity;
		private var _curScreen:MovieClip;
		private var _cardView:CardView;
		private var _cardGroup:CardGroupPop;
		private var _system:System;
		private var _audioSystem:AudioSystem;
		private var _bgMusic:String;
		private var _musicVolume:Number;
		
		private var _choice:String = "PopupGame";
		private var _event:String = AdTrackingConstants.TRACKING_START;
		private var _timeout:Number = 0;
		private var _scoreThreshold:int = 500;
		private var _cardID:String;
		private var _gamePath:String;
		private var _gameXML:XML;
		private const BITMAP_CARD_SCALE:Number = 2;
		private var _isArcadeGame:Boolean = false;
		
		public function TargetShootingGamePower()
		{			
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// darken background
			super.darkenBackground = true;
			
			// assets will be found in campaign folder in custom/limited folder
			super.groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/";
			
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// needed systems for animations
			super.addSystem(new TimelineControlSystem(), SystemPriorities.timelineControl);
			super.addSystem(new TimelineClipSystem());
			super.addSystem(new TimelineVariableSystem());

			// game xml matches swf name
			var path:String = AdvertisingConstants.AD_PATH_KEYWORD + "/" + super.data.swfPath.replace("swf","xml");
			var lastPos:int = path.lastIndexOf("/");
			_gamePath = path.substr(0,lastPos+1);
			shellApi.loadFile(shellApi.dataPrefix + path, gameXMLLoaded);
			shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array(super.data.swfPath));
		}
		
		private function gameXMLLoaded(gameXML:XML):void
		{
			// if xml object, then setup
			if (gameXML!= null)
			{
				_gameXML = gameXML;
				if(gameXML.hasOwnProperty("campaign"))
					_campaignName = String(gameXML.campaign);
				if(gameXML.hasOwnProperty("clickURL"))
					_clickURL = String(gameXML.clickURL);
				if(gameXML.hasOwnProperty("scoreThreshold"))
					_scoreThreshold = int(gameXML.scoreThreshold);
				if(gameXML.hasOwnProperty("cardID"))
					_cardID = String(gameXML.cardID);
				if(gameXML.hasOwnProperty("bgMusic"))
					_bgMusic = String(gameXML.bgMusic);
				_isArcadeGame = (_campaignName == "ArcadeVampireBlitz");
			}
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = MovieClip(super.getAsset( super.data.swfPath, true));
			centerPopupToDevice();
			
			if(super.screen.content.gameWinNoCard)
				super.screen.content.gameWinNoCard.visible = false;
			if(super.screen.content.gameWinEarnedCard)
				super.screen.content.gameWinEarnedCard.visible = false;
			if(super.screen.content.gameWinHasCard)
				super.screen.content.gameWinHasCard.visible = false;
			if(super.screen.content.gameScreen)
				super.screen.content.gameScreen.visible = false;
			
			// set up start screen only
			if(super.screen.content.gameStartScreen)
			{
				_curScreen = super.screen.content.gameStartScreen;
				_playButton = setupButton(_curScreen["playButton"], onPlayClicked);
				_quitButton = setupButton(_curScreen["quitButton"], onQuitClicked);
				_clickURLButton = setupButton(_curScreen["clickURL"], visitSponsorSite);
			}
			super.loaded();
		}
		
		private function setupButton(button:MovieClip, action:Function):Entity
		{
			if (button == null)
			{
				trace("null button");
				return null;
			}
			else
			{
				// force button to vanish (it flashes otherwise)
				button.alpha = 0;
				
				//create button entity
				var buttonEntity:Entity = new Entity();
				buttonEntity.add(new Spatial(button.x, button.y));
				buttonEntity.add(new Display(button));
				buttonEntity.get(Display).alpha = 0;
				
				// add enity to group
				super.addEntity(buttonEntity);
				
				// add tooltip
				ToolTipCreator.addToEntity(buttonEntity);
				
				// add interaction
				var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [InteractionCreator.CLICK], button);
				interaction.click.add(action);
				return buttonEntity;
			}
		}
		
		private function onPlayClicked(entity:Entity):void
		{
			if (_isArcadeGame)
			{
				shellApi.track(Starcade.TRACK_ARCADE_GAME_START, shellApi.arcadeGame, null, "Starcade");
			}
			else
			{
				// _event is "Start"
				shellApi.adManager.track(_campaignName, _event, _choice);
			}
			
			// hide screen
			_curScreen.visible = false;
			
			// remove button entities
			this.removeEntity(_playButton);
			this.removeEntity(_quitButton);
			this.removeEntity(_clickURLButton);
			
			loadGame();
		}
		
		private function onReplayClicked(entity:Entity):void
		{
			if (_isArcadeGame)
			{
				shellApi.track(Starcade.TRACK_ARCADE_GAME_REPLAY, shellApi.arcadeGame, null, "Starcade");
			}
			else
			{
				shellApi.adManager.track(_campaignName, AdTrackingConstants.TRACKING_REPLAY, _choice);
			}
			
			// hide screen
			_curScreen.visible = false;
			
			// clear all button interactions
			// need to keep button entities though
			_playButton.get(Interaction).click.removeAll();
			_quitButton.get(Interaction).click.removeAll();
			if (_clickURLButton)
			{
				_clickURLButton.get(Interaction).click.removeAll();
			}
			
			loadGame(true);
		}
		
		private function onQuitClicked(entity:Entity):void
		{
			// if not start screen and has music
			// only if already played game
			if((super.screen.content.gameStartScreen != _curScreen) && (_bgMusic != null))
			{
				_audioSystem.unMuteSounds();
			}
			
			// for arcade game
			if (_isArcadeGame)
			{
				returnPreviousScene();
			}
			super.remove();
		}
		
		private function returnPreviousScene():void
		{
			shellApi.arcadeGame = null;
			var destScene:String = shellApi.sceneManager.previousScene;
			var destSceneX:Number = shellApi.sceneManager.previousSceneX;
			var destSceneY:Number = shellApi.sceneManager.previousSceneY;
			var destSceneDirection:String = shellApi.sceneManager.previousSceneDirection;
			shellApi.loadScene(ClassUtils.getClassByName(destScene), destSceneX, destSceneY, destSceneDirection);
		}
		
		private function loadGame(replay:Boolean = false):void
		{
			_curScreen = super.screen.content.gameScreen;
			_curScreen.visible = true;
			_system  = this.addSystem( new TargetShootingSystem(this, _curScreen, _gamePath, super.screen.content.scoreClip, _gameXML), SystemPriorities.update );
			playMusic();
		}
		
		public function endGame(score:Number):void
		{
			this.removeSystem(_system);
			
			if(_bgMusic != null)
			{
				AudioUtils.stop(this.groupEntity.group);
				_audioSystem.setVolume(_musicVolume,"music");
			}

			_curScreen.visible = false;
			
			// for arcade game
			if (_isArcadeGame)
			{
				_event = AdTrackingConstants.TRACKING_WIN;
				_curScreen = super.screen.content.gameWinNoCard;
			}
			else
			{
				if (score < _scoreThreshold)
				{
					_event = "Win No Card";
					_curScreen = super.screen.content.gameWinNoCard;
				}
				else if (!shellApi.checkHasItem(_cardID, CardGroup.CUSTOM))
				{
					shellApi.getItem(_cardID, CardGroup.CUSTOM);
					_event = "Win Earned Card";
					_curScreen = super.screen.content.gameWinEarnedCard;
					loadCard();
				}
				else
				{
					_event = "Win Has Card";
					_curScreen = super.screen.content.gameWinHasCard;
				}
			}
			
			if (_curScreen)
			{
				_curScreen.visible = true;
				_playButton = setupButton(_curScreen["replayButton"], onReplayClicked);
				_quitButton = setupButton(_curScreen["quitButton"], onQuitClicked);
				_clickURLButton = setupButton(_curScreen["clickURL"], visitSponsorSite);
			}
			
			// for arcade game
			if (_isArcadeGame)
			{
				AdUtils.setScore(shellApi, score);
				shellApi.track(Starcade.TRACK_ARCADE_GAME_WIN, shellApi.arcadeGame, null, "Starcade");
			}
			else
			{
				shellApi.adManager.track(_campaignName, _event, _choice);
			}
		}
		
		private function visitSponsorSite(button:Entity):void
		{
			if (_clickURL)
			{
				AdManager.visitSponsorSite(shellApi, _campaignName, triggerSponsorSite);
			}
		}
		
		private function triggerSponsorSite():void
		{
			shellApi.adManager.track(_campaignName, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _event);
			AdUtils.openSponsorURL(shellApi, _clickURL, _campaignName, _choice, _event);
		}
		
		private function loadCard():void
		{
			_cardGroup = super.getGroupById(CardGroup.GROUP_ID) as CardGroupPop;
			if( !_cardGroup )
			{
				_cardGroup = super.addChildGroup( new shellApi.itemManager.cardGroupClass() ) as CardGroupPop;
			}
			
			var vClip:MovieClip = _curScreen.cardClip;
			// if holder found, then make invisible
			if (vClip != null)
			{
				vClip.visible = false;
				var cardID:String = "item" + _cardID;
				_cardView = _cardGroup.createCardViewByItem( this, _curScreen, cardID, CardGroup.CUSTOM, null, onCardLoaded );
				var spatial:Spatial = _cardView.cardEntity.get(Spatial);
				spatial.x = vClip.x;
				spatial.y = vClip.y;
				spatial.scaleX = spatial.scaleY = vClip.scaleX;
				spatial.rotation = vClip.rotation;
			}
		}
		
		private function onCardLoaded( cardItem:CardItem = null):void
		{
			_cardView.bitmapCardAll(BITMAP_CARD_SCALE);
			_cardView.hide( false );
		}
		
		private function playMusic():void
		{
			if (_audioSystem == null)
				_audioSystem = AudioSystem(this.groupEntity.group.getSystem(AudioSystem));
			
			if(_bgMusic != null)
			{
				_musicVolume = _audioSystem.getVolume("music");
				_audioSystem.setVolume(0.01,"music");
				_audioSystem.setVolume(0,"ambient");
				AudioUtils.play(this.groupEntity.group, SoundManager.MUSIC_PATH + _bgMusic, 15, false);
			}
		}
	}
}