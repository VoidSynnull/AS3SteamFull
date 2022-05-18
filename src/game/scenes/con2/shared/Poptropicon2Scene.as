package game.scenes.con2.shared
{
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.PointItem;
	import game.data.sound.SoundModifier;
	import game.scene.SceneSound;
	import game.scene.template.AudioGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.con2.Con2Events;
	import game.scenes.con2.shared.cardGame.CardGame;
	import game.scenes.con2.shared.popups.Phone;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;

	public class Poptropicon2Scene extends PlatformerGameScene
	{
		public function Poptropicon2Scene()
		{
			super();
			rewards = new Dictionary();
			rewards["expert"] = "omegon";
			rewards["card2"] = "elf_archer";
			rewards["hippie"] = "gold_face";
			rewards["dealer"] = "world_guy";
		}
		
		override public function load():void
		{
			cardManager = shellApi.getManager(CCGCardManager) as CCGCardManager;
			if(!cardManager)
				cardManager = shellApi.addManager(new CCGCardManager(), CCGCardManager) as CCGCardManager;
			trace( "con2Scene :: check for card deck item, if has, make sure deck data is available.");
			
			if( shellApi.checkHasItem( _events.CARD_DECK ) )
			{
				trace( "con2Scene :: create deck data.");
				cardManager.createDeckData( super.load, shellApi.island );
			}
			else
			{
				super.load();
			}
		}
		
		// all assets ready
		override public function loaded():void
		{
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			_events = shellApi.islandEvents as Con2Events;
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			// NOTE :: Why are we loading this here?  If we're loading we should really wait fo laod to complete - Bard
			if( shellApi.checkHasItem( _events.CELL_PHONE ) )
			{
				shellApi.loadFile( shellApi.assetPrefix + CELL_FLASH_DYNAMIC_PATH, createCellFlash );
			}
			
			super.loaded();
		}
		
		public function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event.indexOf(_events.PLAY) == 0)
			{
				openCardGamePopup(event.substring(_events.PLAY.length));
			}
			else
			{
				if(event.indexOf(FOUND) == 0)// for testing only
				{
					addCardToDeck(event.substr(FOUND.length));
				}
				else
				{
					if(event == CLEAR_DECK)
					{
						clearDeck();
					}
					else
					{
						if(event.indexOf(DEFEAT) == 0)
						{
							autoDefeat(event.substr(DEFEAT.length));
						}
					}
				}
			}
		}
		
		////////////////////////////////////////// CARD GAME //////////////////////////////////////////

		private function autoDefeat(npcId:String):void
		{
			cardGameComplete(npcId, rewards[npcId], true);
		}
		
		private function openCardGamePopup(cardPlayer:String):void
		{
			//var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			//audio.fadeAll(0, NaN, 1, SoundModifier.MUSIC);
			var cardGame:CardGame = new CardGame(overlayContainer, cardPlayer, shellApi.island);
			cardGame.gameComplete.add(cardGameComplete);
			addChildGroup(cardGame);
		}
		
		/**
		 * Method called when card game is closed, determines if a reward is given.
		 * @param opponentId
		 * @param reward
		 * @param won
		 * @param onCardReceived
		 * @param lockInput
		 */
		protected function cardGameComplete(opponentId:String, reward:String, won:Boolean, onCardReceived:Function = null, lockInput:Boolean = false ):void
		{
			/*
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			if(!audio.isPlaying(SoundManager.MUSIC_PATH + MAIN_THEME))
			{
				audio.play(SoundManager.MUSIC_PATH + MAIN_THEME, true);
				audio.fadeAll(1, NaN, 0, SoundModifier.MUSIC);
			}
			*/
			trace(opponentId + " " + reward + " " + won);

			var opponent:Entity = getEntityById(opponentId);
			// prolly have them say a won dialog or loose dialog
			if( won && reward != null)
			{
				if( !shellApi.checkEvent(_events.DEFEATED+opponentId) )
				{
					if( lockInput )	{ SceneUtil.lockInput(this); };
					addCardToDeck( reward, onCardReceived );
					shellApi.triggerEvent( _events.DEFEATED + opponentId, true );
				}
			}
		}
		
		// testing only not used during normal game play
		private function clearDeck():void
		{
			cardManager.updateDeck("", shellApi.island);
			shellApi.removeEvent(_events.STARTER_DECK);
			shellApi.removeItem(_events.CARD_DECK);
		}
		
		/**
		 * Shows the card game cards and adds them to the deck
		 * @param cardId - the first card to give and show
		 * @param onCompleteHandler - function to call when
		 */		
		protected function addCardToDeck( cardId:String, onCompleteHandler:Function = null ):void
		{
			// if you don't have a deck upon receiving a card, give deck
			if( !shellApi.checkHasItem(_events.CARD_DECK) )
			{
				shellApi.getItem(_events.CARD_DECK);
			}
			
			// add new card(s) to currentDeck & save to userfield
			var newCardString:String = ( cardId == _events.CARD_DECK ) ? STARTER_DECK_STRING : cardId;	
			
			cardManager.addCardToDeck(newCardString, shellApi.island);
			// show card
			var itemGroup:ItemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			itemGroup.showItem(cardId, shellApi.island, null, onCompleteHandler);
		}
		
		/**
		 * Determines if card is within deck.
		 * Checks against userfield.
		 * @param cardId
		 * @return  
		 */
		protected function checkHasCard(cardId:String):Boolean
		{
			return cardManager.hasCard(cardId, shellApi.island);
		}
		
		/////////////////////////////// OMEGON PHOTO /////////////////////////////// 
		
		private function createCellFlash( clip:MovieClip ):void
		{
			_cellFlashEntity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			_cellFlashEntity.add(new Sleep(true, true));
			TimelineUtils.convertClip( clip.flashAnim, this, _cellFlashEntity, null, false);
		}
		
		/**
		 * TAKE A PHOTO OF OMEGON'S ARMOR
		 * assumes you handle any scene locks and character positioning in scene
		 * 
		 * @param event - <code>String</code> for what event to complete after you have the photo.
		 * @param handler - scene <code>Function</code> for restoring any motion or removing locks after photo is taken.
		 */
		protected function snapPhoto( event:String, handler:Function ):void
		{
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, PHONE );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, bufferTimeOver ));
			_flashFinished = new Signal();
			_flashFinished.addOnce( handler );
			
			_photoEvent = event;
		}
		
		private function bufferTimeOver():void
		{
			CharUtils.setAnim( player, PointItem );
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "pointing", flashCamera );
			timeline.handleLabel( "ending", launchPhonePopup );
		}
		
		private function flashCamera():void
		{
			var timeline:Timeline = player.get( Timeline );
			timeline.paused = true;
			
			var cellPhone:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.ITEM );
			var cellSpatial:Spatial = cellPhone.get( Spatial );
			var playerSpatial:Spatial = player.get( Spatial );
			
			if( _cellFlashEntity != null )
			{
				var spatial:Spatial = _cellFlashEntity.get( Spatial );
				if( playerSpatial.scaleX < 0 )
				{
					cellSpatial.x *= -1;
				}
				spatial.x = playerSpatial.x + cellSpatial.x * .36;
				spatial.y = playerSpatial.y + cellSpatial.y * .36;
				var sleep:Sleep = _cellFlashEntity.get( Sleep );
				sleep.sleeping = false;
				
				timeline = _cellFlashEntity.get( Timeline );
				timeline.gotoAndPlay( "home" );
				timeline.handleLabel( "complete", endFlash );
			}
			else
			{
				endFlash();
			}
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + CAMERA_FLASH );
		}
		
		private function endFlash():void
		{
			var timeline:Timeline = player.get( Timeline );
			timeline.paused = false;
			
			if( _cellFlashEntity != null )
			{
				var sleep:Sleep = _cellFlashEntity.get( Sleep );
				sleep.sleeping = true;
				
				timeline = _cellFlashEntity.get( Timeline );
				timeline.stop();
			}
		}
		
		private function launchPhonePopup():void
		{
			shellApi.completeEvent( _photoEvent );
			SceneUtil.lockInput( this, false );
			
			var phone:Phone = super.addChildGroup( new Phone( overlayContainer )) as Phone;
			phone.closeClicked.addOnce( getPhoto );
		}
		
		private function getPhoto( phone:Phone ):void
		{
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "empty" );
			
			_flashFinished.dispatch();
		}
		
		/////////////////////////////// HELPERS /////////////////////////////// 
		
		protected function returnControls(...args):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this,player);
		}
		
		private const MAIN_THEME:String		= "poptropicon2_main_theme.mp3";
		
		private const STARTER_DECK_STRING:String = "world_guy,mutton_chops,mutton_chops,meow_bot,meow_bot,meow_bot,hench_bot,hench_bot,hench_bot,hench_bot";
		private var _flashFinished:Signal;
		private var _photoEvent:String;
		
		private var FOUND:String = "found_";
		private var CLEAR_DECK:String = "clear_deck";
		private var DEFEAT:String = "defeat_";
		private var rewards:Dictionary;
		
		public var cardManager:CCGCardManager;
		
		private var _cellFlashEntity:Entity;
		private const PHONE:String = "mk_lead_designer01";
		private const CELL_FLASH_DYNAMIC_PATH:String = "scenes/con2/shared/cell_flash.swf";
		private const CAMERA_FLASH:String = "camera_01.mp3";
		protected var _audioGroup:AudioGroup;
		protected var _events:Con2Events;
	}
}