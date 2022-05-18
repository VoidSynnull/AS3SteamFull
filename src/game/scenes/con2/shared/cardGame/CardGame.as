package game.scenes.con2.shared.cardGame
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.components.ui.CardItem;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.data.ui.TransitionData;
	import game.scene.SceneSound;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ui.CardGroup;
	import game.scene.template.ui.CardGroupPop;
	import game.scenes.con2.shared.CCGCardManager;
	import game.scenes.con2.shared.cardGame.systems.CCGAISystem.CCGAI;
	import game.scenes.con2.shared.cardGame.systems.CCGAISystem.CCGAISystem;
	import game.scenes.con2.shared.cardGame.systems.CCGHandSystem.CCGHand;
	import game.scenes.con2.shared.cardGame.systems.CCGHandSystem.CCGHandSystem;
	import game.scenes.con2.shared.cardGame.systems.CCGScoreSystem.CCGSCoreSystem;
	import game.scenes.con2.shared.cardGame.systems.CCGScoreSystem.ScoreDisplay;
	import game.scenes.con2.shared.cardGame.systems.CardSlotSystem.CardSlot;
	import game.scenes.con2.shared.cardGame.systems.CardSlotSystem.CardSlotSystem;
	import game.ui.card.CardView;
	import game.ui.popup.CharacterDialogWindow;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class CardGame extends Popup
	{
		public var gameComplete:Signal;
		
		/**
		 * Called when message window completes, available for override. 
		 */
		protected function messageCompleteHandler():void {}
		
		// sound constants
		private const MP3:String			= ".mp3";
		private const STACK_DECK:String 	= "stack_deck_01.mp3";
		private const DRAW_CARD:String		= "card_flip_01.mp3";
		private const SLIDE_CARD:String		= "slide_card_01.mp3";
		private const PLACE_CARD:String		= "swap_cards_01.mp3";
		private const PICK_CARD:String		= "pick_card_0";//2
		private const CARD_THEME:String		= "mighty_action_force.mp3";
		private const WIN:String			= "mini_game_win.mp3";
		private const LOSE:String			= "mini_game_loss.mp3";
		
		private const FORMAT_CARDSLOT:TextFormat = new TextFormat("CreativeBlock BB", 48, 0x000000);
		private const FORMAT_DIALOG:TextFormat = new TextFormat("CreativeBlock BB", 20, 0x000000, null,null,null,null,null, TextFormatAlign.CENTER,null,null,null,2);
		
		public const ENEMY:String 	= "enemy";
		public const PLAYER:String 	= "player";
		public const ATTACK:String 	= "Attack";
		public const BOUNTY:String 	= "Bounty";
		public const DOCK:String 	= "Dock";
		
		private const SET_UP:String 	= "setUp";
		private const DECK:String 		= "Deck";
		private const TRAY:String 		= "Tray";
		private const PORTRAIT:String 	= "Portrait";
		private const NAME:String 		= "Name";
		private const HAND:String 		= "Hand";
		private const SCORE:String 		= "score";
		private const SHOW_HIDE:String 	= "showHide";
		private const CARD_IN:String 	= "cardIn";
		
		private const ENEMY_DATA:String = "ccgnpcs.xml";
		
		private const DIALOG_BUFFER:Number = 10;
		private const DIALOG_HEAD_POSITION:Point = new Point(55, 40);
		private const CARD_SCALE:Number = .6;
		private const CARD_DRAWN_SCALE:Number = .7;
		private const TRAY_BUFFER_Y:uint = 60;
		private const BOARD_CARD_BUFFER:uint = 10;
		private const CARD_HAND_X:uint = 115;
		public const CARD_FLIP_SPEED:Number = .33;
		
		// this get set within setup methods
		private var _cardBounds:Rectangle;
		private var _playerPlaceCardInHand:Point = new Point(CARD_HAND_X, 0);
		private var _enemyPlaceCardInHand:Point = new Point(CARD_HAND_X, 0);
		
		private var _dialogPlayer:CharacterDialogWindow;
		private var _dialogOpponent:CharacterDialogWindow;
		
		public var turnBaseGroup:TurnBasedCCG;
		
		private var _content:MovieClip;
		private var _dockRect:Rectangle;
		private var _attackRect:Rectangle;
		private var _bountyRect:Rectangle;
		
		private var _cardGroup:CardGroupPop;
		private var _charGroup:CharacterGroup;
		
		private var _npcId:String;
		private var _reward:String;
		private var _won:Boolean;
		private var _gameOver:Boolean;
		private var _cardBack:BitmapData;
		private var _endPopup:Entity;
		private var _sides:Array = [ENEMY, PLAYER];
		private var _trayShowing:Boolean = false;
		
		public var showCards:Boolean = true;
		
		private var _cardsReady:Boolean = false;
		
		private var _firstTurn:Boolean = true;
		
		private var enemyAlmost13:Boolean = false;
		private var playerAlmost13:Boolean = false;
		private const ALMOST_13:String = "Almost13";
		
		public function get enemyId():String{return _npcId;}
		
		public var dialogWindow:CharacterDialogWindow;
		
		private var _cardManager:CCGCardManager;
		
		private var cardsLocation:String;
		
		public function CardGame(container:DisplayObjectContainer=null, npcId:String = null, island:String = null, showCards:Boolean = true)
		{
			_npcId = npcId;
			this.showCards = npcId != null;
			this.showCards = showCards;//just a force for testing
			_won = _gameOver = false;
			_reward = "";
			gameComplete = new Signal(String, String, Boolean);
			cardsLocation = island;
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= true;
			
			// updated from hard coded con2.  Island needs a shared/cardGame/ folder containing
			// 	for data : ccgnpcs.xml, dialog.xml, npcs.xml
			// 	for assets : card_game.swf, dialog.swf and 
			if(!DataUtils.validString(groupPrefix))
				this.groupPrefix = "scenes/" + shellApi.island + "/shared/cardGame/";
			this.screenAsset = "card_game.swf";
			
			this.load();
		}
		
		override public function destroy():void
		{
			_cardBack.dispose();
			_cardGroup = null;
			_charGroup = null;
			_endPopup = null;
			_sides = null;
			_dialogOpponent = null;
			_dialogPlayer = null;
			
			super.destroy();
		}
		
		override public function load():void
		{
			loadFiles([ ENEMY_DATA ]);
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			addBaseSystems();
			setUpGroups();
			startMusic();
			
			_content = screen.content;
			
			this.letterbox(_content, new Rectangle(0, -10, 985, 736));
			
			setUpEnemy();// enemy goes first so enemy needs to be set up first
			if(_cardManager != null)
				setUpPlayer();
			else
			{
				_cardManager = shellApi.addManager(new CCGCardManager(), CCGCardManager) as CCGCardManager;
				_cardManager.createDeckData(setUpPlayer, cardsLocation);
			}
			createDialogWindows();
			setUpContent();
		}
		
		private function startMusic():void
		{
			AudioUtils.getAudio(parent, SceneSound.SCENE_SOUND).setVolume(0,SoundModifier.MUSIC);
			var audio:Audio = AudioUtils.getAudio(this);
			audio.play(SoundManager.MUSIC_PATH + CARD_THEME,true);
			audio.fade(SoundManager.MUSIC_PATH + CARD_THEME,shellApi.profileManager.active.musicVolume, NaN, 0, SoundModifier.MUSIC);
		}
		
		private function setUpGroups():void
		{
			turnBaseGroup = addChildGroup( new TurnBasedCCG(_content)) as TurnBasedCCG;
			_charGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			_cardGroup = getGroupById(CardGroup.GROUP_ID) as CardGroupPop;
			_cardManager = shellApi.getManager(CCGCardManager) as CCGCardManager;
		}
		
		private function addBaseSystems():void
		{
			addSystem(new CCGHandSystem());
			addSystem(new CardSlotSystem());
			addSystem(new CCGAISystem());
			addSystem(new CCGSCoreSystem());
		}
		
		//////////////////////////////////////////// SETUP ////////////////////////////////////////////
		
		private function setUpPlayer():void
		{
			var deckString:String = _cardManager.getDeck(cardsLocation);
			
			var index:uint = deckString.indexOf(",");
			var id:String;
			var i:uint = 0;
			
			var user:CCGUser = new CCGUser(PLAYER);
			
			while(deckString.indexOf(",") > -1)
			{
				++i;
				index = deckString.indexOf(",");
				id = deckString.substr(0, index);
				deckString = deckString.substr(index + 1);
				user.cardCollection.cards.push(new CCGCard(id));
				if(i == 10)// if more than 10 only the first 10 are considered to be for play
					break;
			}
			if(deckString.length > 0 && i < 10)//in the case the deck is exactly 10 cards long
			{
				user.cardCollection.cards.push(new CCGCard(deckString));
			}
			
			randomizeCardOrder(user.cardCollection.cards);
			
			var playerEntity:Entity = new Entity();
			playerEntity.add(user);
			turnBaseGroup.addPlayer(playerEntity, PLAYER);
			
			setUpCards();
		}
		
		private function setUpEnemy():void
		{
			var xml:XML = getData( ENEMY_DATA );
			
			if(xml)
				parse(xml);
			else
				trace("enemy data missing");
		}
		
		private function parse(xml:XML):void
		{
			var npc:XML;
			for(var n:uint = 0; n < xml.children().length(); n++)
			{
				if(xml.children()[n].attribute("id")[0] == _npcId)
				{
					npc = xml.children()[n];
					break;
				}
			}
			
			if(npc == null)
			{
				trace(_npcId + " does not exist.");
				return;
			}
			// create his cards
			
			var cards:XMLList = npc.child("cards")[0].child("card");
			var ai:String = npc.child("cards")[0].attribute("ai")[0];
			var user:CCGUser = new CCGUser(ENEMY);
			var card:CCGCard;
			for( var c:uint = 0; c < cards.length(); c++)
			{
				var cardData:XML = cards[c];
				card = new CCGCard(cardData.toString());
				user.cardCollection.cards.push(card);
			}
			
			randomizeCardOrder(user.cardCollection.cards);
			var entity:Entity = new Entity();
			entity.add(user).add(new CCGAI(this,1.33, ai));
			turnBaseGroup.addPlayer(entity, ENEMY);
			
			setUpCards();
			
			// if rewards is null, or if not set up properly, return
			
			var rewards:XML = npc.child("reward")[0];
			
			if(rewards == null)
			{
				_reward = null;
				return;
			}
			
			_reward = rewards.child("card")[0];
			
			if(_reward == null)
				return;
			
			for(var i:int = 1; i < rewards.children().length(); i++)
			{
				var reward:String = rewards.child("card")[i];
				if(reward != null)
					_reward += "," + reward;
			}
		}
		
		private function randomizeCardOrder(cards:Vector.<CCGCard>):void
		{
			var randomized:Vector.<CCGCard> = new Vector.<CCGCard>();
			var rand:uint;
			while(cards.length > 0)
			{
				rand = uint(Math.random() * cards.length);
				randomized.push(cards[rand]);
				cards.splice(rand, 1);
			}
			for(var i:int = 0; i < randomized.length; i++)
			{
				cards.push(randomized[i]);
			}
		}
		
		private function setUpContent():void
		{
			// store bounds of small card size;
			_cardBounds = CardGroup.CARD_BOUNDS.clone();
			_cardBounds.size.x *= this.CARD_SCALE;
			_cardBounds.size.y *= this.CARD_SCALE;
			
			// set positions
			_playerPlaceCardInHand.y = shellApi.viewportHeight + _cardBounds.height/2;
			_enemyPlaceCardInHand.y = -_cardBounds.height/2;
			
			//positionAssets();
			setUpSplashScreens();
			setUpInteractions();
			
			loadCloseButton( "", 40, 40);
		}
		
		private function positionAssets():void
		{
			var midY:Number = super.shellApi.viewportHeight/2;
			var contentClip:MovieClip = screen.content;
			
			// center board
			_content["bg"].y = midY;
			
			//position user specific assets
			var side:String;
			var cardOffset:Number = 0;
			var deckOffset:Number = 8;
			for (var i:int = 0; i < _sides.length; i++) 
			{
				side = _sides[i];
				if( cardOffset == 0 )
				{
					cardOffset = MovieClip( _content[ side + this.DECK ] ).height/2 + this.BOARD_CARD_BUFFER;
				}
				var userOffsetY:Number = ( side == this.PLAYER ) ? cardOffset : -cardOffset;
				
				_content[ side + this.ATTACK ].y = midY + userOffsetY;
				_content[ side + this.DOCK ].y 	= midY + userOffsetY;
				_content[ side + this.BOUNTY ].y = midY + userOffsetY;
				_content[ side + this.DECK ].y 	= midY + userOffsetY + deckOffset;
			}
		}
		
		private function setUpSplashScreens():void
		{
			var clip:MovieClip = _content["splash_mc"];
			//_endPopup = EntityUtils.createSpatialEntity( this, clip );
			//BitmapTimelineCreator.convertToBitmapTimeline( _endPopup, clip );
			_endPopup = BitmapTimelineCreator.createBitmapTimeline(clip,true, true, null, PerformanceUtils.defaultBitmapQuality + 0.1);
			this.addEntity(_endPopup);
			var spatial:Spatial = _endPopup.get(Spatial);
			spatial.y = -200;
			
			EntityUtils.visible( _endPopup, false, true );
		}
		
		private function setUpCards():void
		{
			playSound(STACK_DECK);
			
			var cardContainer:MovieClip;
			var cards:Vector.<CCGCard>;
			var cardView:CardView;
			var side:String;
			var card:CCGCard;
			var offsetY:Number;
			
			//if both sides have not been loaded return;
			if(turnBaseGroup.getPlayerById(PLAYER) == null || turnBaseGroup.getPlayerById(ENEMY) == null)
				return;
			
			var island:String = !DataUtils.validString(cardsLocation)? CardGroup.STORE:cardsLocation;
			var cardId:String;
			
			for(var s:int = 0; s < _sides.length; s++)
			{
				side = _sides[s];
				
				cards = turnBaseGroup.getPlayerById(side).get(CCGUser).cardCollection.cards;
				cardContainer = _content[side+DECK] as MovieClip;
				
				for(var i:int = 0; i < cards.length; i++)
				{
					card = cards[i];
					cardView = _cardGroup.createCardView(this);
					cardId = card.id;
					if(island == CardGroup.STORE)
						cardId = "item"+cardId;
					_cardGroup.createCardViewByItem(this,cardContainer,cardId,island,cardView,Command.create(cardCreated,cardView,card,side));
				}
			}
		}
		
		private function cardCreated(cardItem:CardItem, cardView:CardView, card:CCGCard, side:String):void
		{
			var value:String = cardItem.value;
			var index:int = value.indexOf(",");
			
			if(index > -1)
			{
				card.value = DataUtils.getUint(value.substr(0, index));
				card.effect = value.substring(index + 1);
			}
			else
			{
				card.value = DataUtils.getUint(value);
			}
			
			card.frontDisplay = cardView.cardDisplay;
			card.backDisplay = BitmapUtils.createBitmapSprite(cardView.cardDisplay, 1, cardItem.bounds, true, 0, _cardBack); // disposed when game is destroyed
			
			var display:Display = cardView.cardEntity.get(Display);
			
			display.swapDisplayObject(card.backDisplay);
			
			cardView.cardEntity.add(card);
			
			if( !cardItem.bitmapWrapper ) 
			{ 
				cardView.bitmapCardBack(CardGroup.CARD_BOUNDS, 1);//_cardScale);
			}
			cardView.displayCardItem();
			cardView.hide( false );
			
			var spatial:Spatial = cardView.cardEntity.get(Spatial);
			
			var offsetScale:Number = 5;
			
			var user:CCGUser = turnBaseGroup.getPlayerById(side).get(CCGUser);
			
			spatial.x += user.deck.length * offsetScale;
			spatial.y -= user.deck.length * offsetScale;
			
			display.container.setChildIndex(display.displayObject, user.deck.length);
			
			user.deck.push(cardView.cardEntity);
			
			trace(turnBaseGroup.getPlayerById(PLAYER).get(CCGUser).deck.length + " " + turnBaseGroup.getPlayerById(ENEMY).get(CCGUser).deck.length);
			
			if(turnBaseGroup.getPlayerById(PLAYER).get(CCGUser).deck.length == 10 && turnBaseGroup.getPlayerById(ENEMY).get(CCGUser).deck.length == 10)
			{
				_cardsReady = true;
				if(_dialogOpponent.isReady)
					startGame();
			}
		}
		
		private function setUpInteractions():void
		{
			var interactions:Array = [DECK, ATTACK, BOUNTY, DOCK, TRAY];
			var addInteraction:Boolean;
			var side:String;
			var interaction:String;
			var clip:MovieClip;
			var entity:Entity;
			var user:CCGUser;
			for(var s:int = 0; s < _sides.length; s++)
			{
				side = _sides[s];
				
				addInteraction = (side == PLAYER);
				
				user = turnBaseGroup.getPlayerById(side).get(CCGUser);
				for(var i:int = 0; i < interactions.length; i++)
				{
					interaction = interactions[i];
					clip = _content[side+interaction];
					entity = EntityUtils.createSpatialEntity(this, clip, _content).add(new Id(clip.name));
					this[SET_UP+interaction](entity, user);
				}
			}
		}
		
		private function setUpDeck(entity:Entity, user:CCGUser):void
		{
			var clip:MovieClip = EntityUtils.getDisplayObject(entity) as MovieClip;
			if(user.id == PLAYER)
			{
				_cardBack = BitmapUtils.createBitmapData(clip);
			}
			
			clip.removeChild(clip.getChildAt(0));			
		}// just so i can keep everything in one set up
		
		private function setUpTray(entity:Entity, user:CCGUser):void
		{
			var clip:MovieClip = EntityUtils.getDisplayObject(entity) as MovieClip;
			clip.mouseEnabled = false;
			
			var hand:Entity = EntityUtils.createSpatialEntity(this, clip["handRef"], clip);
			hand.add(new CCGHand(user)).add(new Id(user.id+HAND));
			
			clip = clip["score"];
			BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality +0.1);
			clip.mouseEnabled = clip.mouseChildren = false;
			var score:Entity = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertAllClips(clip, score, this);
			score.add(new ScoreDisplay(user, 2));
			
			if(user.id == PLAYER)
			{
				var contentEntity:Entity = EntityUtils.createSpatialEntity(this, _content).add(new Id("content"));
				var interaction:Interaction = InteractionCreator.addToEntity(contentEntity, [ InteractionCreator.DOWN ]);
				interaction.down.add(Command.create(checkIfClickOutOfTray, user));
				
				// position tray along bottom 
				//Spatial(entity.get(Spatial)).y = super.shellApi.viewportHeight;
			}
			else
			{
				// position tray along bottom 
				Spatial(entity.get(Spatial)).y = 0;
			}
		}
		
		private function setUpAttack(entity:Entity, user:CCGUser):void
		{
			setUpCardSlot(entity);
			
			user.attack = entity.get(CardSlot);
			
			if(user.id == PLAYER)
			{
				user.attack.text = TextUtils.convertText( Display(entity.get(Display)).displayObject["context"], FORMAT_CARDSLOT )
				_attackRect = MovieClip(EntityUtils.getDisplayObject(entity))["area"].getRect(_content);
				var interaction:Interaction = InteractionCreator.addToEntity(entity, [ InteractionCreator.CLICK ]);
				interaction.click.add(Command.create(clickSlot, user));
			}
		}
		
		private function setUpBounty(entity:Entity, user:CCGUser):void
		{
			setUpCardSlot(entity);
			
			user.bounty = entity.get(CardSlot);
			
			if(user.id == PLAYER)
			{
				user.bounty.text = TextUtils.convertText( Display(entity.get(Display)).displayObject["context"], FORMAT_CARDSLOT )
				_bountyRect = MovieClip(EntityUtils.getDisplayObject(entity))["area"].getRect(_content);
				var interaction:Interaction = InteractionCreator.addToEntity(entity, [ InteractionCreator.CLICK  ]);
				interaction.click.add(Command.create(clickSlot, user));
			}
		}
		
		private function clickSlot(entity:Entity, user:CCGUser):void
		{
			if(user.state == CCGUser.PLACE)
				placeCardInSlot(entity, getEntityById(user.id + DOCK), user);
		}
		
		private function setUpDock(entity:Entity, user:CCGUser):void
		{
			setUpCardSlot(entity);
			
			user.dock = entity.get(CardSlot);
			
			if(user.id == PLAYER)
			{
				user.dock.text = TextUtils.convertText( Display(entity.get(Display)).displayObject["context"], FORMAT_CARDSLOT )
				_dockRect = EntityUtils.getDisplayObject(entity).getRect(_content);
				var interaction:Interaction = InteractionCreator.addToEntity(entity, ["click"]);
				interaction.click.add(Command.create(clickDock, user));
			}
		}
		
		private function setUpCardSlot(entity:Entity):void
		{
			// setup highlight clip
			var display:Display = entity.get(Display);
			var highlightClip:MovieClip = MovieClip(display.displayObject)["area"];
			convertContainer(highlightClip, PerformanceUtils.defaultBitmapQuality);
			highlightClip.alpha = 0;
			display.displayObject.setChildIndex(highlightClip, 0);
			
			entity.add( new CardSlot( highlightClip, 1, .5 ) );
		}
		
		//////////////////////////////////////////// GAME ////////////////////////////////////////////
		private var _tweeningTray:Boolean;
		private function checkIfClickOutOfTray(entity:Entity, user:CCGUser):void
		{
			if(_gameOver)
			{
				var audio:Audio = AudioUtils.getAudio(this);
				audio.fade(SoundModifier.MUSIC + CARD_THEME,0, NaN, 1, SoundModifier.MUSIC);
				SceneUtil.delay(this, 1, close);
				return;
			}
			
			if(_tweeningTray)
				return;
			
			var spatial:Spatial = shellApi.inputEntity.get(Spatial);
			var viewportHalf:int = shellApi.viewportHeight/2;
			
			if(_trayShowing)
			{
				//if(spatial.y < SHOW_TRAY_Y - offset && user.currentSelection == null || spatial.y < SHOW_TRAY_Y - offset * 3)
				if( user.currentSelection != null )
				{
					if( EntityUtils.getDisplayObject(user.currentSelection).hitTestPoint( spatial.x, spatial.y ) )
					{
						// selected card was clicked
						return;
					}
				}
				
				if( spatial.y < viewportHalf )
				{
					// return currently selected to tray
					if(user.currentSelection != null)
					{
						placeCardInContainer(user.currentSelection, getEntityById(user.id + HAND));
					}
					user.currentSelection = null;
					showHideTray(entity, user, false, true);
				}
			}
			else
			{
				if(spatial.y >= shellApi.viewportHeight - this.TRAY_BUFFER_Y)
				{
					showHideTray(entity, user, true, true);
				}
			}
		}
		
		private function clickDock(entity:Entity, user:CCGUser):void
		{
			if(user.state == CCGUser.PICK)
			{
				showHideTray(entity, user);
			}
			if(user.state == CCGUser.PLAY)
			{
				var interaction:Interaction;
				if(user.attack.card != null)
				{
					interaction = user.attack.card.get(Interaction);
					interaction.up.removeAll();
					interaction.down.removeAll();
				}
				
				if(user.bounty.card != null)
				{
					interaction = user.bounty.card.get(Interaction);
					interaction.up.removeAll();
					interaction.down.removeAll();
				}
				
				turnBaseGroup.actionComplete();
			}
		}
		
		private function startGame():void
		{
			turnBaseGroup.start();
		}
		
		public function setWinner(user:CCGUser = null):void
		{
			var  timeline:Timeline = _endPopup.get(Timeline);
			
			var state:String;
			
			if(user == null)
			{
				state = "tie";
			}
			else
			{
				if(user.id == PLAYER)
				{
					state = "win";
					_won = true;
				}
				else
				{
					state = "lose";
				}
			}
			timeline.gotoAndStop(state);
			
			playMessage(state, false, showSpashScreen);
		}
		
		private function showSpashScreen():void
		{
			if(_won)
				playSound(WIN);
			else
				playSound(LOSE);
			
			clearBoard();
			EntityUtils.visible(_endPopup, true);
			TweenUtils.entityTo(_endPopup, Spatial, 2, {y:736/2, ease:Bounce.easeOut, onComplete:tapToExit});
		}
		
		private function tapToExit():void
		{
			_gameOver = true;
		}
		
		public function setUser(entity:Entity):void
		{
			var user:CCGUser = entity.get(CCGUser);
			if(user.skip || user.hand.length == 0)
			{
				if(user.hand.length == 0)
					playMessage(user.id + "_out_of_cards");
				user.skip = false;
				turnBaseGroup.actionComplete();
				return;
			}
			if(user.deck.length > 0)
			{
				dealCards(entity);
				SceneUtil.delay(this, 2, Command.create(startTurn, user));
			}
			else
				SceneUtil.delay(this, 1, Command.create(startTurn, user));
		}
		
		private function startTurn(user:CCGUser):void
		{
			user.myTurn = true;
			
			if(user.score.score >= 10)
			{
				if(!this[user.id+ALMOST_13])
				{
					playMessage(user.id + ALMOST_13);
					this[user.id+ALMOST_13] = true;
				}
			}
			
			if(user.id == PLAYER)
			{
				if(_firstTurn)
				{
					playMessage("firstTurn");
					_firstTurn = false;
				}
			}
		}
		
		public function dealCards(userEntity:Entity, cards:uint = 1):void
		{
			var user:CCGUser = userEntity.get(CCGUser);
			if(user.deck.length < cards)
				return;
			SceneUtil.addTimedEvent(this, new TimedEvent(1, cards, Command.create(animateDrawCard, user)));
		}
		
		private function showHideTray(entity:Entity, user:CCGUser, show:Boolean = true, forceShow:Boolean = false):void
		{
			if(!canPlayAnotherCard(user) || _tweeningTray)
				return;	// TODO :: Should be able to open up deck and choose another crad, that will remove the current card in play. Polish. - Bard
			
			if(!forceShow)
				show = !_trayShowing;
			
			_tweeningTray = true;
			
			_trayShowing = show;
			
			var tray:Entity = getEntityById(PLAYER + TRAY);
			var hand:CCGHand = getEntityById(PLAYER + HAND).get(CCGHand)
			
			if(show)
			{
				TweenUtils.entityTo(tray,Spatial, .5, {y:368 + this.TRAY_BUFFER_Y, ease:Quad.easeOut, onComplete:tweenComplete});
				takeCurrentSelection(hand, user, false);
			}
			else
			{
				TweenUtils.entityTo(tray,Spatial, 1, {y:716, ease:Bounce.easeOut, onComplete:tweenComplete});
				takeCurrentSelection(hand, user);
			}
		}
		
		private function tweenComplete():void
		{
			_tweeningTray = false;
		}
		
		private function canPlayAnotherCard(user:CCGUser):Boolean
		{
			if(user.hand.length == 0 || !user.myTurn)
				return false;
			
			if(user.attack.isEmpty && user.bounty.isEmpty)
				return true;
			
			var effect:String;
			if(!user.attack.isEmpty &&  user.bounty.isEmpty)
			{
				effect = CCGCard(user.attack.card.get(CCGCard)).effect;
				if(effect == CCGEffects.BOTH || effect == CCGEffects.SACRIFICE)
				{
					return true;
				}
			}
			
			if(user.attack.isEmpty && !user.bounty.isEmpty)
			{
				effect = CCGCard(user.bounty.card.get(CCGCard)).effect;
				if(effect == CCGEffects.BOTH || effect == CCGEffects.SACRIFICE)
				{
					return true;
				}
			}
			
			return false;
		}
		
		public function takeCurrentSelection(hand:CCGHand, user:CCGUser, toDock:Boolean = true):void
		{
			if(user.currentSelection == null && toDock)
				return;
			hand.takeCurrentSelection = toDock;
			if(user.dock.card != null)
			{
				placeCardInHand(user, user.dock.card);
				user.dock.card = null;
			}
			if(!toDock)
				return;
			
			placeCardInDock(user, user.currentSelection);
		}
		
		private var pickUpSlotName:String;
		
		private function pickUpSlotCard(card:Entity):void
		{
			if(card.get(Tween) || _tweeningTray)
				return;
			playSound(PICK_CARD, 2);
			pickUpSlotName = getSlot();
			Display(card.get(Display)).setContainer(_content);
			card.add(new FollowTarget(shellApi.inputEntity.get(Spatial)));
		}
		
		private function dropOffSlotCard(pickUpCard:Entity, user:CCGUser):void
		{
			if(pickUpSlotName == null || pickUpCard.get(Tween) || _tweeningTray)
				return;
			
			var slotName:String = getSlot();
			
			pickUpCard.remove(FollowTarget);
			
			var pickUpSlot:Entity = getEntityById(user.id + pickUpSlotName);
			var from:CardSlot = pickUpSlot.get(CardSlot);
			
			// return card to original slot
			if(slotName == null || slotName == DOCK)
			{
				user.dock.card = from.card;
				if(pickUpSlotName != DOCK)
					from.card = null;
				if(canPlayAnotherCard(user))
					showHideTray(pickUpCard, user, true, true);	
				else
				{
					from.card = pickUpCard;
					placeCardInContainer(pickUpCard, pickUpSlot);
				}
				pickUpSlotName = null;
				return;
			}
			
			if(slotName == pickUpSlotName)
			{
				placeCardInContainer(pickUpCard, pickUpSlot);
				pickUpSlotName = null;
				return;
			}
			
			var dropOffSlot:Entity = getEntityById(user.id + slotName);
			placeCardInSlot(dropOffSlot, pickUpSlot, user,false);
			
			pickUpSlotName = null;
		}
		
		private function getSlot():String
		{
			var spatial:Spatial = shellApi.inputEntity.get(Spatial);
			
			if(_dockRect.contains(spatial.x, spatial.y))
				return DOCK;
			
			if(_bountyRect.contains(spatial.x, spatial.y))
				return BOUNTY;
			
			if(_attackRect.contains(spatial.x, spatial.y))
				return ATTACK;
			
			return null;
		}
		
		public function placeCardInSlot(toSlot:Entity, fromSlot:Entity, user:CCGUser, tween:Boolean = true):void
		{
			var to:CardSlot = toSlot.get(CardSlot);
			var from:CardSlot = fromSlot.get(CardSlot);
			
			if(CardSlot.canSwapCards(from, to))
			{
				moveCardToSlot(from.card, toSlot, tween, CARD_SCALE);
				if(to.card != null)
				{
					if(CCGCard(to.card.get(CCGCard)).effect == CCGEffects.BOTH && from == user.dock)
					{
						if(to == user.attack)
						{
							user.bounty.card = from.card;
							from.card = null;
							from = user.bounty;
							fromSlot = getEntityById(user.id + BOUNTY);
						}
						else
						{
							user.attack.card = from.card;
							from.card = null;
							from = user.attack;
							fromSlot = getEntityById(user.id + ATTACK);
						}
					}
					moveCardToSlot(to.card, fromSlot, CARD_SCALE);
				}
				CardSlot.swapCards(from, to);
			}
			
			if(canPlayAnotherCard(user))
				user.state = CCGUser.PICK;
			else
				user.state = CCGUser.PLAY;
		}
		
		public function moveCardToSlot(card:Entity, slot:Entity, tween:Boolean = true, scale:Number = 1):void
		{
			if(tween)
			{
				playSound(SLIDE_CARD);
				
				placeCardIntoContent(card, scale);
				
				var slotSpatial:Spatial = slot.get(Spatial);
				
				TweenUtils.entityTo(card, Spatial, .5, {x:slotSpatial.x, y:slotSpatial.y, scaleX:slotSpatial.scaleX, scaleY:slotSpatial.scaleY, onComplete:Command.create(placeCardInContainer, card, slot)});
			}
			else
			{
				playSound(PICK_CARD, 2);
				placeCardInContainer( card, slot);
			}
		}
		
		public function placeCardInDock(user:CCGUser, card:Entity):void
		{
			moveCardToSlot(card, getEntityById(user.id + DOCK));
			if(user.id == PLAYER)
			{
				var interaction:Interaction = card.get(Interaction);
				interaction.click.removeAll();
				interaction.down.add(pickUpSlotCard);
				interaction.up.add(Command.create(dropOffSlotCard, user));
				interaction.releaseOutside.add(Command.create(dropOffSlotCard, user));
			}
			
			user.dock.card = card;
			user.currentSelection = null;
			
			user.state = CCGUser.PLACE;
		}
		
		public function placeCardIntoContent(card:Entity, scale:Number = 1):void
		{
			var spatial:Spatial = card.get(Spatial);
			
			var display:Display = EntityUtils.getDisplay(card);
			var pos:Point = new Point(spatial.x, spatial.y);
			
			pos = DisplayUtils.localToLocalPoint(pos, display.container, _content);
			
			placeCardInContainer(card, getEntityById("content"));
			
			spatial.x = pos.x;
			spatial.y = pos.y;
			spatial.scale = scale;
		}
		
		public function placeCardInHand(user:CCGUser, card:Entity = null):void
		{
			if(card == null)
				card = user.deck.pop();
			user.hand.push(card);
			placeCardInContainer(card, getEntityById(user.id + HAND));
			
			if(user.id == PLAYER)
			{
				var interaction:Interaction = card.get(Interaction);
				interaction.click.add(Command.create(selectCard, user));
				interaction.up.removeAll();
				interaction.down.removeAll();
			}
			else
			{
				if(showCards)
					flipCard(user, card, false, true, true, CARD_DRAWN_SCALE);
			}
			
			if(user.myTurn)
				user.state = CCGUser.PICK;
		}
		
		private function placeCardInContainer(card:Entity, parent:Entity):void
		{
			card.remove(Tween);
			var display:Display = card.get(Display);
			var container:DisplayObjectContainer = Display(parent.get(Display)).displayObject;
			var rect:Rectangle = container.getRect(container);
			display.setContainer(container);
			var spatial:Spatial = card.get(Spatial);
			spatial.scale = 1;
			spatial.y = rect.height / 2 + rect.top;
			spatial.x = 0;
		}
		
		public function selectCard(card:Entity, user:CCGUser):void
		{
			if(user.dock.card != null || _tweeningTray)
				return;
			
			playSound(PICK_CARD, 2);
			
			if(user.currentSelection != card)
				user.currentSelection = card;
			else
			{
				if(user.id == PLAYER)
					showHideTray(card, user, false, true);
				else
					takeCurrentSelection(getEntityById(user.id+ HAND).get(CCGHand),user);
			}
		}
		
		private function animateDrawCard(user:CCGUser):void
		{
			playSound(DRAW_CARD);
			
			var card:Entity = user.deck.pop();
			Display(card.get(Display)).setContainer(_content);
			var spatial:Spatial = card.get(Spatial);
			var deckSpatial:Spatial = getEntityById(user.id + DECK).get(Spatial);
			spatial.x = deckSpatial.x;
			spatial.y = deckSpatial.y;
			spatial.scale = deckSpatial.scaleX;
			
			var yOffset:int = 20;
			var targetSpatial:Spatial = getEntityById(user.id + DOCK).get(Spatial);
			
			var onComplete:Function = Command.create(animateCardIntoHand, user, card);
			
			if(user.id == PLAYER)
			{
				TweenUtils.entityTo(card, Spatial, .5, {x:targetSpatial.x, y:targetSpatial.y + yOffset, scaleY:CARD_DRAWN_SCALE, onComplete:Command.create(animateCardIntoHand, user, card)});
				flipCard(user, card,true, true, false, CARD_DRAWN_SCALE);
			}
			else
			{
				TweenUtils.entityTo(card, Spatial, .5, {x:targetSpatial.x, y:targetSpatial.y - yOffset, scale:CARD_DRAWN_SCALE, onComplete:Command.create(animateCardIntoHand, user, card)});
			}
			
		}
		
		public function flipCard(user:CCGUser, card:Entity, playerOnly:Boolean = true, faceUp:Boolean = true, force:Boolean = false, scale:Number = 1):void
		{
			if(user.id != PLAYER && playerOnly || card == null)
				return;
			
			var ccgCard:CCGCard = card.get(CCGCard);
			if(force && faceUp == ccgCard.faceUp)
				return;
			
			if(!force)
				faceUp = !ccgCard.faceUp;
			
			TweenUtils.entityTo(card, Spatial, CARD_FLIP_SPEED, {scaleX:0, ease:Linear.easeNone, onComplete:Command.create(cardFlipped, user, card, faceUp, scale)});
		}
		
		private function cardFlipped(user:CCGUser, card:Entity, faceUp:Boolean = true, scale:Number = 1):void
		{
			var ccgCard:CCGCard = card.get(CCGCard);
			var display:Display = card.get(Display);
			
			if(faceUp)
				display.swapDisplayObject(ccgCard.frontDisplay);
			else
				display.swapDisplayObject(ccgCard.backDisplay);
			
			ccgCard.faceUp = faceUp;
			
			if(user.id == PLAYER)
				InteractionCreator.addToEntity(card, [ InteractionCreator.CLICK, InteractionCreator.UP, InteractionCreator.DOWN, InteractionCreator.RELEASE_OUT ]);
			
			TweenUtils.entityTo(card, Spatial, CARD_FLIP_SPEED, {scaleX:scale, ease:Linear.easeNone});
		}
		
		private function animateCardIntoHand(user:CCGUser, card:Entity):void
		{
			var point:Point = this["_" + user.id + "PlaceCardInHand"];
			TweenUtils.entityTo(card, Spatial, 1, {x:point.x, y:point.y, ease:Quad.easeOut, onComplete:Command.create(placeCardInHand, user, card)});
		}
		
		public function clearBoard(currentUser:Entity = null):void
		{
			playSound(SLIDE_CARD);
			
			var user:CCGUser = turnBaseGroup.getPlayerById(PLAYER).get(CCGUser);
			var card:Entity;
			
			var contentEntity:Entity;
			var exitX:int = -200;
			
			card = user.attack.card;
			if(card != null)
			{
				placeCardIntoContent(card,CARD_SCALE);
				TweenUtils.entityTo(card, Spatial, 1, {x:exitX, onComplete:Command.create(removeCard, card, user.attack)});
			}
			card = user.bounty.card;
			if(card != null)
			{
				placeCardIntoContent(card,CARD_SCALE);
				TweenUtils.entityTo(card, Spatial, 1, {x:exitX, onComplete:Command.create(removeCard, card, user.bounty)});
			}
			
			user = turnBaseGroup.getPlayerById(ENEMY).get(CCGUser);
			card = user.attack.card;
			if(card != null)
			{
				placeCardIntoContent(card,CARD_SCALE);
				TweenUtils.entityTo(card, Spatial, 1, {x:exitX, onComplete:Command.create(removeCard, card, user.attack)});
			}
			card = user.bounty.card;
			if(card != null)
			{
				placeCardIntoContent(card,CARD_SCALE);
				TweenUtils.entityTo(card, Spatial, 1, {x:exitX, onComplete:Command.create(removeCard, card, user.bounty)});
			}
			
			if(currentUser != null)
				SceneUtil.delay(this, 1.5, Command.create(setUser, currentUser));
		}
		
		private function removeCard(card:Entity, slot:CardSlot):void
		{
			if(slot.card == null)
				return;
			var group:Group = card.group;
			group.removeEntity(card);
			removeGroup(group);
			slot.card = null;			
		}
		
		override public function remove():void
		{
			gameComplete.dispatch(_npcId, _reward, _won);
			super.remove();
		}
		
		//////////////////////////////////////////// DIALOG ////////////////////////////////////////////
		
		/**
		 * Play message in dropdown message window. 
		 * @param dialogId
		 * @param callback
		 * 
		 */
		
		public function hasDialog(dialogId:String, isPlayer:Boolean):Boolean
		{
			dialogWindow = ( isPlayer ) ? _dialogPlayer : _dialogOpponent;
			var dialog:Dialog = dialogWindow.charEntity.get(Dialog);
			return (dialog.getDialog(dialogId) != null);
		}
		
		public function playMessage( dialogId:String, isPlayer:Boolean = false, callback:Function = null ):void
		{
			dialogWindow = ( isPlayer ) ? _dialogPlayer : _dialogOpponent;
			dialogWindow.playMessage( dialogId, true, true );
			
			if(callback) { dialogWindow.messageComplete.addOnce(callback); }
		}
		
		// setup dialog, now that all entities have been created
		private function createDialogWindows():void
		{
			// add new container
			var overlayContainer:MovieClip = new MovieClip();
			super.groupContainer.addChild( overlayContainer );
			//_dialogPlayer = createCharacterDialogWindow( overlayContainer );
			super.shellApi.triggerEvent( _npcId, true );
			_dialogOpponent = createCharacterDialogWindow( overlayContainer, _npcId, false );
		}
		
		private function createCharacterDialogWindow( overlayContainer:MovieClip, charId:String = "", isPlayer:Boolean = true ):CharacterDialogWindow
		{
			var dialogWindow:CharacterDialogWindow = new CharacterDialogWindow( overlayContainer );
			dialogWindow.config( null, null, false, false, false, false );
			dialogWindow.configData( groupPrefix, "dialog_window.swf", true, true );
			dialogWindow.ready.addOnce( Command.create(characterDialogWindowReady, charId) );
			dialogWindow.messageComplete.add(messageCompleteHandler);
			super.addChildGroup(dialogWindow);
			
			return dialogWindow;
		}
		
		protected function characterDialogWindowReady( dialogWindow:CharacterDialogWindow = null, charId:String = "" ):void
		{
			dialogWindow.screen.x = super.shellApi.viewportWidth/2 - dialogWindow.screen.width/2;
			dialogWindow.screen.y = 0;
			
			// remove event used earlier to differentiate npc
			super.shellApi.removeEvent( _npcId, null, false );
			
			// adjust character
			dialogWindow.adjustChar( charId, dialogWindow.screen.content.charContainer, DIALOG_HEAD_POSITION);
			
			// convert message background to bitmap
			super.convertToBitmap(dialogWindow.screen.content.background);
			
			// assign textfield
			dialogWindow.textField = TextUtils.refreshText(dialogWindow.screen.content.tf);	
			dialogWindow.textField.embedFonts = true;
			dialogWindow.textField.defaultTextFormat = FORMAT_DIALOG;
			
			// create transition
			var buffer:int = DIALOG_BUFFER;
			var transitionIn:TransitionData = new TransitionData();
			transitionIn.duration = 0.2;
			if( charId == "player" )
			{
				transitionIn.startPos = new Point( dialogWindow.screen.x, super.shellApi.viewportHeight);
				transitionIn.endPos = new Point( dialogWindow.screen.x, super.shellApi.viewportHeight - ( dialogWindow.screen.height + buffer ) );
			}
			else
			{
				transitionIn.startPos = new Point( dialogWindow.screen.x, -dialogWindow.screen.height );
				transitionIn.endPos = new Point( dialogWindow.screen.x, buffer );
			}
			transitionIn.ease = Back.easeOut;
			var transitionOut:TransitionData = transitionIn.duplicateSwitch(Sine.easeIn);
			transitionOut.duration = .15;
			
			dialogWindow.transitionIn = transitionIn;
			dialogWindow.transitionOut = transitionOut;
			if(_cardsReady)
				startGame();
		}
		
		private function playSound(prefix:String, range:uint = 0):void
		{
			var url:String = SoundManager.EFFECTS_PATH + prefix;
			if(range > 0)
				url += Math.ceil(Math.random() * range) + MP3;
			
			AudioUtils.play(this, url);
		}
		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{
			AudioUtils.getAudio(parent, SceneSound.SCENE_SOUND).setVolume(shellApi.profileManager.active.musicVolume,SoundModifier.MUSIC);
			super.close(removeOnClose, onClosedHandler);
		}
	}
}