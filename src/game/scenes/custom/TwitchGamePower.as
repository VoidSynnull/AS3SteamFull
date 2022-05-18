package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.systems.AudioSystem;
	
	import game.components.timeline.Timeline;
	import game.components.ui.CardItem;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.ads.CampaignData;
	import game.managers.ScreenManager;
	import game.managers.ads.AdManager;
	import game.scene.template.ui.CardGroup;
	import game.scenes.custom.twitchcomponents.TwitchDragItem;
	import game.scenes.custom.twitchsystems.TwitchDragSystem;
	import game.scenes.hub.starcade.Starcade;
	import game.systems.SystemPriorities;
	import game.ui.card.CardView;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.ClassUtils;
	import game.util.PerformanceUtils;
	import game.util.SkinUtils;
	import game.utils.AdUtils;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineControlSystem;
	
	public class TwitchGamePower extends Popup
	{
		public var loadedCloseButton:Boolean = false;
		private var scoreText:TextField;
		
		//Balloon Scale Vars
		private var _scaleLimit:Number = 5;
		private var _scaleRateMin:Number = 0.35;
		private var _scaleRateMax:Number = 0.45;
		private var _fastScaleRate:Number = 0.6;
		private var _decayRate:Number = 2;
		private var _soundEffect:String;
		private var _winSound:String;
		private var _loseSound:String;
		private var _bgMusic:String;
		private var _audioSystem:AudioSystem;
		private var _fontName:String;
		private var _fontGameColor:String;
		private var _fontEndColor:String;
		private var _fontSize:Number;
		private var _fontX:Number;
		private var _fontY:Number;
		private var _text:TextField;
		private var _textFormat:TextFormat;
		private var _replayButton:Entity;
		private var _closeButton:Entity;
		private var _startButton:Entity;
		private var _yMin:Number = 0;
		private var _yMax:Number = 0;
		private var _bounce:Boolean = false;
		private var _timer:Timer;
		private var _allowClick:Boolean = true;
		private var _campaignName:String;
		private var _clickURL:String;
		private var _clickURLButton:Entity;
		
		private var _isReplay:Boolean;
		private var _timeout:Number = 0;
		private var _event:String = AdTrackingConstants.TRACKING_START;
		private var _choice:String = "PopupGame";
		private var _cardView1:CardView;
		private var _cardView2:CardView;
		private var _cardGroup:CardGroup;
		private var _isArcadeGame:Boolean = false;
		
		private var _dragItems:Vector.<TwitchDragItem> = new Vector.<TwitchDragItem>();
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			/// hide hud's dimmed background
			super.darkenBackground = true;
			
			// assets will be found in campaign folder in custom/limited folder
			super.groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/";
			
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{	
			_isReplay = false;
			var path:String = shellApi.dataPrefix + AdvertisingConstants.AD_PATH_KEYWORD + "/" + super.data.param1;
			super.shellApi.loadFile(path, gameXMLLoaded);
			
			
			super.addSystem(new TimelineControlSystem());
			super.addSystem(new BitmapSequenceSystem());
			
			trace(super.data.swfPath);
		}
		
		private function gameXMLLoaded(gameXML:XML):void
		{
			// if xml object, then setup
			if (gameXML!= null)
			{
				if(gameXML.scaleRateMin)
					_scaleRateMin = gameXML.scaleRateMin;
				
				if(gameXML.scaleRateMax)
					_scaleRateMax = gameXML.scaleRateMax;
				
				if(gameXML.fastScaleRate)
					_fastScaleRate = gameXML.fastScaleRate;
				
				if(gameXML.decayRate)
					_decayRate = gameXML.decayRate;
				
				if(gameXML.scaleLimit)
					_scaleLimit = gameXML.scaleLimit;
				
				if(gameXML.campaign)
					_campaignName = gameXML.campaign;
				
				if(gameXML.clickURL)
					_clickURL = gameXML.clickURL;
				
				if(gameXML.soundEffect)
					_soundEffect = gameXML.soundEffect;
				
				if(gameXML.winSound)
					_winSound = gameXML.winSound;
				
				if(gameXML.loseSound)
					_loseSound = gameXML.loseSound;
				
				if(gameXML.bgMusic)
					_bgMusic = gameXML.bgMusic;
				
				if(gameXML.fontName)
					_fontName = gameXML.fontName;
				
				if(gameXML.fontGameColor)
					_fontGameColor = gameXML.fontGameColor;
				
				if(gameXML.fontEndColor)
					_fontEndColor = gameXML.fontEndColor;
				
				if(gameXML.fontSize)
					_fontSize = gameXML.fontSize;
				
				if(gameXML.ymin)
					_yMin = gameXML.ymin;
				
				if(gameXML.ymax)
					_yMax = gameXML.ymax;
				
				if(gameXML.timeout)
					_timeout = gameXML.timeout;
				
				if(gameXML.bounce)
				{
					if(gameXML.bounce == "true")
						_bounce = true;
					else
						_bounce = false;
				}
				
				_textFormat = new TextFormat( _fontName, _fontSize, _fontGameColor, false, false, false, null, null, "left", null, 0, null, 0 );
				
				trace("===================== GAMEXMLLOADED =============" );
				
				_isArcadeGame = (_campaignName == "ArcadePoptastic");
				
				super.shellApi.loadFiles(new Array(shellApi.assetPrefix + AdvertisingConstants.AD_PATH_KEYWORD + "/" + super.data.swfPath),loaded);

			}
			else
			{
				trace("===================== GAMEXMLERROR =============" );
			}
		}
		
		public function loadClose(score:Number, win:Boolean, replay:Boolean):void
		{	
			_isReplay = replay;
			_allowClick = false;
			_timer = new Timer(1000, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, allowClick);
			_timer.start();
			
			if(_bgMusic != null)
			{
				AudioUtils.stop(this.groupEntity.group);
			}
			if(win)
			{
				_event = AdTrackingConstants.TRACKING_WIN;
								
				scoreText = super.screen.content.gameWinScreen.score;

				// set up clickURL button
				setupButton(super.screen.content.gameWinScreen["clickURL"], visitSponsorSite, "win","clickurl");
				setupButton(super.screen.content.gameWinScreen["closeButton"], onCloseClicked, "win","close");
				setupButton(super.screen.content.gameWinScreen["replayButton"], onReplayClicked, "win","replay");
				
				if(_winSound != null)
					AudioUtils.play(this.groupEntity.group, SoundManager.EFFECTS_PATH + _winSound, 1.5, false);
				
				if(super.screen.content.gameWinScreen)
					super.screen.content.gameWinScreen.visible = true;
				
				// display winning cards
				_cardGroup = super.getGroupById(CardGroup.GROUP_ID) as CardGroup;
				if( !_cardGroup )
				{
					_cardGroup = super.addChildGroup( new shellApi.itemManager.cardGroupClass() ) as CardGroup;
				}
				// get cards MMQ location not quest location (quest is not an active campaign for MMQs)
				var campaignData:CampaignData = AdManager(this.shellApi.adManager).getActiveCampaign(_campaignName);
				
				if (campaignData == null)
					trace("Can't find data among active campaigns for campaign " + _campaignName)
				else
				{
					trace("AdWinPopup: Getting campaign data for " + _campaignName); 
					// if cards are found in campaigns.cml for campaign, then they are loaded based on their respective order
					switch(shellApi.profileManager.active.gender)
					{
						case SkinUtils.GENDER_MALE:
						case null:
							loadCards(campaignData.boycards)
							break;
						case SkinUtils.GENDER_FEMALE:
							loadCards(campaignData.girlcards)
							break;
					}
				}
			}
			else
			{
				_event = AdTrackingConstants.TRACKING_LOSE;
				
				scoreText = super.screen.content.gameOverScreen.score;
				
				// set up clickURL button
				setupButton(super.screen.content.gameOverScreen["clickURL"], visitSponsorSite, "lose","clickurl");
				
				if(super.screen.content.gameOverScreen)
					super.screen.content.gameOverScreen.visible = true;
				
				if(_loseSound != null)
					AudioUtils.play(this.groupEntity.group, SoundManager.EFFECTS_PATH + _loseSound, 1.5, false);
				
				setupButton(super.screen.content.gameOverScreen["closeButton"], onCloseClicked, "lose","close");
				setupButton(super.screen.content.gameOverScreen["replayButton"], onReplayClicked, "lose","replay");
			}
			
			// for arcade game
			if (_isArcadeGame)
			{
				if (_event == AdTrackingConstants.TRACKING_WIN)
				{
					AdUtils.setScore(shellApi, score);
					shellApi.track(Starcade.TRACK_ARCADE_GAME_WIN, shellApi.arcadeGame, null, "Starcade");
				}
				else
				{
					shellApi.track(Starcade.TRACK_ARCADE_GAME_LOSE, shellApi.arcadeGame, null, "Starcade");
				}
			}
			else
			{
				shellApi.adManager.track(_campaignName, _event, _choice);
			}
			// set score text
			scoreText.text = score.toString();
			
			loadedCloseButton = true;
		}
		
		private function allowClick(e:Event):void
		{
			_allowClick = true;
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, allowClick);
		}
		private function loadCards(cardData:Vector.<String>):void
		{
			// for two cards only
			for (var i:int = 1; i!=3; i++)
			{
				var vClip:MovieClip = super.screen.content.gameWinScreen["card" + i];
				// if holder found, then make invisible
				if (vClip != null)
				{
					vClip.visible = false;
					if (cardData != null)
					{
						// if enough items in array
						if (cardData.length >= i)
						{
							var cardNum:String = cardData[i-1];
							
							// award card
							shellApi.getItem(cardNum, CardGroup.CUSTOM, false );
							
							var cardID:String = "item" + cardNum;
							var spatial:Spatial;
							var containerClip:MovieClip;
							if (i == 1)
							{
								containerClip = super.screen.content.gameWinScreen["card1"];
								_cardView1 = _cardGroup.createCardViewByItem( this, super.screen, cardID, CardGroup.CUSTOM, null, onCardLoaded1 );
								spatial = _cardView1.cardEntity.get(Spatial);
								spatial.x = containerClip.x;
								spatial.y = containerClip.y;
								spatial.scaleX = spatial.scaleY = containerClip.scaleX;
								spatial.rotation = containerClip.rotation;
							}
							else if (i == 2)
							{
								containerClip = super.screen.content.gameWinScreen["card2"];
								_cardView2 = _cardGroup.createCardViewByItem( this, super.screen, cardID, CardGroup.CUSTOM, null, onCardLoaded2 );
								spatial = _cardView2.cardEntity.get(Spatial);
								spatial.x = containerClip.x;
								spatial.y = containerClip.y;
								spatial.scaleX = spatial.scaleY = containerClip.scaleX;
								spatial.rotation = containerClip.rotation;
							}
						}
					}
				}
			}
		}
		
		private function onCardLoaded1( cardItem:CardItem = null):void
		{
			_cardView1.bitmapCardAll(2);
			_cardView1.hide( false );
		}
		
		private function onCardLoaded2( cardItem:CardItem = null):void
		{
			_cardView2.bitmapCardAll(2);
			_cardView2.hide( false );
		}
		
		private function onStartClicked(entity:Entity):void
		{
			
			if(!_isReplay && super.screen.content.gameWinScreen.visible == false &&
				super.screen.content.gameOverScreen.visible == false)
			{
				if (_isArcadeGame)
					shellApi.track(Starcade.TRACK_ARCADE_GAME_START, shellApi.arcadeGame, null, "Starcade");
				else
					shellApi.adManager.track(_campaignName, AdTrackingConstants.TRACKING_START, _choice);
			}
			super.screen.content.gameStartScreen.visible = false;
			this.removeEntity(_clickURLButton);
			this.removeEntity(_closeButton);
			this.removeEntity(_startButton);
			
			loadGame();
			
		}
		
		private function onReplayClicked(entity:Entity):void
		{
			
			if(_allowClick)
			{	
				if (_isArcadeGame)
					shellApi.track(Starcade.TRACK_ARCADE_GAME_REPLAY, shellApi.arcadeGame, null, "Starcade");
				else
					shellApi.adManager.track(_campaignName, AdTrackingConstants.TRACKING_REPLAY, _choice);
				
				this.removeEntity(_replayButton);
				this.removeEntity(_closeButton);
				
				this.removeEntity(_clickURLButton);
				shellApi.loadFile("assets/limited/"+super.data.swfPath, loadGame);
				_textFormat.color = _fontGameColor;
				
				if(_cardView1 != null)
					_cardView1.removeEntity(_cardView1.cardEntity);
				
				if(_cardView2 != null)
					_cardView2.removeEntity(_cardView2.cardEntity);
			}
		}
		
		private function onCloseClicked(entity:Entity):void
		{
			if(_allowClick)
			{
				if(!_isReplay && super.screen.content.gameWinScreen.visible == false &&
					super.screen.content.gameOverScreen.visible == false)
				{
					shellApi.adManager.track(_campaignName, AdTrackingConstants.TRACKING_QUIT, _choice);
				}
				
				// only if already played game
				if(!super.screen.content.gameStartScreen.visible && _bgMusic != null)
					_audioSystem.unMuteSounds();
				
				// for arcade game
				if (_isArcadeGame)
				{
					returnPreviousScene();
				}
				
				super.remove();
			}
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

		private function loadGame(swf:MovieClip=null):void
		{
			if(this.getSystem(TwitchDragSystem) == null)
			{
				this.addSystem( new TwitchDragSystem(_scaleLimit, _scaleRateMin,_scaleRateMax, _decayRate, _yMin, _yMax, 
					_bounce, _timeout, _textFormat, _soundEffect, this), SystemPriorities.update );
				var hitContainer:MovieClip = super.screen.content;
				for (var i:int = hitContainer.numChildren - 1; i!= -1; i--)
				{
					var child:DisplayObjectContainer = DisplayObjectContainer(hitContainer.getChildAt(i));
					if (child is MovieClip)
					{
						var clip:MovieClip = MovieClip(child);
						// look for underscore (all hit objects need to have underscore in name)
						// objects without underscores are ignored
						var pos:int = clip.name.indexOf("_");
						if (pos != -1)
						{
							// set position if coordinates given with NxN
							var id:String = clip.name.substr(pos+1);
							var xpos:int = id.indexOf("x");
							if (xpos != -1)
							{
								clip.x = Number(id.substr(0,xpos));
								clip.y = Number(id.substr(xpos+1)); 
							}
							
							//these should be all the objects that will scale
							if (clip.name.substr(0, 12) == "scaledObject")
							{
								var timeline:Timeline;
								var animClip:MovieClip = clip["anim"];
								if (animClip != null)
								{
									// convert to bitmap timeline
									var bmEntity:Entity = BitmapTimelineCreator.createBitmapTimeline(animClip, true, true, null, PerformanceUtils.defaultBitmapQuality);
									this.addEntity(bmEntity);
									timeline = bmEntity.get(Timeline);
									timeline.play();
								}
								
								var dragItem:TwitchDragItem;
								dragItem = new TwitchDragItem( this, clip, timeline );
								
								// add to list
								_dragItems.push(dragItem);
								InteractionCreator.addToEntity(dragItem.entity,[InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
								dragItem.draggable.bounds = new Rectangle(super.screen.content.bounds.x,super.screen.content.bounds.y,super.screen.content.bounds.width,super.screen.content.bounds.height);
								dragItem.draggable.shouldShow = false;
								dragItem.draggable.scaleRate = randomMinMax(_scaleRateMin,_scaleRateMax);
								//these objects will scale at a faster rate
								if(clip.name.substr(12, 4) == "Fast")
								{
									dragItem.draggable.scaleRate = _fastScaleRate;
									dragItem.draggable.speedy = true;
								}
								// these objects will tween around the screen
								if(clip.name.substr(12, 4) == "Jump")
									dragItem.draggable.jumper = true;
							}					
						}
					}
				}
				
				playMusic();
				
				trace("===================== GAMELOADED =============" );
			}
			else
			{
				// if replaying reset the sysem
				this.removeSystemByClass(TwitchDragSystem);
				for each (dragItem in _dragItems)
				{
					dragItem.popped = false;
					dragItem.firstTouch = true;
					dragItem.draggable.shouldShow = false;
					if (!dragItem.draggable.speedy)
						dragItem.draggable.scaleRate = randomMinMax(_scaleRateMin,_scaleRateMax);
				}
				this.addSystem(new TwitchDragSystem(_scaleLimit, _scaleRateMin,_scaleRateMax, _decayRate, _yMin, _yMax, 
					_bounce, _timeout, _textFormat, _soundEffect, this, true), SystemPriorities.update );
				playMusic();
			}
		}
		
		private function playMusic():void
		{
			if (_audioSystem == null)
				_audioSystem = AudioSystem(this.groupEntity.group.getSystem(AudioSystem));
			
			if(_bgMusic != null)
			{
				_audioSystem.setVolume(.01,"music");
				_audioSystem.setVolume(0,"ambient");
				AudioUtils.play(this.groupEntity.group, SoundManager.MUSIC_PATH + _bgMusic, 15, false);
			}
		}
		// all assets ready
		override public function loaded():void
		{			
			trace("===================== LOADSTART =============" );
			super.screen = super.getAsset( super.data.swfPath, true) as MovieClip;
			//super.screen = shellApi.getFile(shellApi.assetPrefix + AdManager.AD_PATH_KEYWORD + "/" + super.data.swfPath,false) as MovieClip;
			if(super.screen.content.gameOverScreen)
				super.screen.content.gameOverScreen.visible = false;
			if(super.screen.content.gameWinScreen)
				super.screen.content.gameWinScreen.visible = false;
			
			if(super.screen.content.gameStartScreen)
			{
				setupButton(super.screen.content.gameStartScreen["startButton"], onStartClicked,"start", "start");
				setupButton(super.screen.content.gameStartScreen["closeButton"], onCloseClicked, "start", "close");
				setupButton(super.screen.content.gameStartScreen["clickURL"], visitSponsorSite, "start", "clickurl");
				
			}
			
			if(super.screen.content.popEffect)
				super.screen.content.popEffect.visible = false;
			
			centerPopupToDeviceContent();
			
			super.screen.content.x = shellApi.camera.center.x;
			super.screen.content.y = shellApi.camera.center.y;
			
			var hitContainer:MovieClip = super.screen.content;
			for (var i:int = hitContainer.numChildren - 1; i!= -1; i--)
			{
				var child:DisplayObjectContainer = DisplayObjectContainer(hitContainer.getChildAt(i));
				if (child is MovieClip)
				{
					var clip:MovieClip = MovieClip(child);
					// look for underscore (all hit objects need to have underscore in name)
					// objects without underscores are ignored
					var pos:int = clip.name.indexOf("_");
					if (pos != -1)
					{
						// set position if coordinates given with NxN
						var id:String = clip.name.substr(pos+1);
						var xpos:int = id.indexOf("x");
						if (xpos != -1)
						{
							clip.x = Number(id.substr(0,xpos));
							clip.y = Number(id.substr(xpos+1)); 
						}
					}
				}
			}
			super.loaded();
			
			
			trace("===================== LOADED =============" );
		}
		
		private function randomMinMax( min:Number, max:Number ):Number
		{
			return min + (max - min) * Math.random();
		}
		
		private function setupButton(button:MovieClip, action:Function, screen:String, type:String):void
		{
			if (button == null)
				trace("null button");
			else
			{
				// force button to vanish (it flashes otherwise)
				button.alpha = 0;
				//create button entity
				var buttonEntity:Entity = new Entity();
				buttonEntity.add(new Spatial(button.x, button.y));
				buttonEntity.add(new Display(button));
				buttonEntity.get(Display).alpha = 0;
				
				// need this because showing the popup a second time will not have buttons
				if(screen == "start")
				{
					if (button.parent != super.screen.content.gameStartScreen)
						super.screen.content.gameStartScreen.addChild(button);
				}
				if(screen == "lose")
				{
					if (button.parent != super.screen.content.gameOverScreen)
						super.screen.content.gameOverScreen.addChild(button);
				}
				if(screen == "win")
				{
					
					if (button.parent != super.screen.content.gameWinScreen)
						super.screen.content.gameWinScreen.addChild(button);
				}
				
				if(type == "clickurl")
					_clickURLButton = buttonEntity;
				if(type == "replay")
					_replayButton = buttonEntity;
				if(type == "close")
					_closeButton = buttonEntity;
				if(type == "start")
					_startButton = buttonEntity;
				
				// add enity to group
				super.addEntity(buttonEntity);
				
				// add tooltip
				ToolTipCreator.addToEntity(buttonEntity);
				
				// add interaction
				var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [InteractionCreator.CLICK], button);
				interaction.click.add(action);
			}
		}
		
		private function visitSponsorSite(button:Entity):void
		{
			if ((_allowClick) && (_clickURL))
				AdManager.visitSponsorSite(shellApi, _campaignName, triggerSponsorSite);
		}
		
		private function triggerSponsorSite():void
		{
			shellApi.adManager.track(_campaignName, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _event);
			AdUtils.openSponsorURL(shellApi, _clickURL, _campaignName, _choice, _event);
		}
		
		public function centerPopupToDeviceContent():void
		{
			// target proportions for device
			var targetProportions:Number = shellApi.viewportWidth/shellApi.viewportHeight;
			var destProportions:Number = ScreenManager.GAME_WIDTH/ScreenManager.GAME_HEIGHT;
			// if wider, then fit to width and center vertically
			if (destProportions >= targetProportions)
			{
				var scale:Number = shellApi.viewportWidth/ScreenManager.GAME_WIDTH;
			}
			else
			{
				// else fit to height and center horizontally
				scale = shellApi.viewportHeight/ScreenManager.GAME_HEIGHT;
			}
			//super.screen.content.x = shellApi.viewportWidth / 2;
			//super.screen.content.y = shellApi.viewportHeight / 2;
			super.screen.content.scaleX = super.screen.content.scaleY = scale;
		}
	}
}
