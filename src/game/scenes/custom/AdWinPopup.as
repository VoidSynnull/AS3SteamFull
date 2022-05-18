package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.adparts.parts.AdVideo;
	import game.components.ui.CardItem;
	import game.data.ads.AdTrackingConstants;
	import game.managers.ads.AdManager;
	import game.scene.template.ui.CardGroup;
	import game.scene.template.ui.CardGroupPop;
	import game.scenes.custom.AdBasePopup;
	import game.scenes.hub.starcade.Starcade;
	import game.ui.card.CardView;
	import game.util.SceneUtil;
	import game.utils.AdUtils;
	
	public class AdWinPopup extends AdBasePopup
	{
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set popup type to win
			_popupType = AdTrackingConstants.TRACKING_WIN;
			super.init(container);
			
			// tracking (win)
			if (_isArcadeGame)
				shellApi.track(Starcade.TRACK_ARCADE_GAME_WIN, shellApi.arcadeGame, null, "Starcade");
			else
				AdManager(shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_WIN, _trackingChoice);
			
			// trigger event that we completed the game
			shellApi.completeEvent(_questName + "Completed");
			
			// update game buttons on video unit
			updateVideoGameButton("firstGameButton", "win");
			updateVideoGameButton("secondGameButton", "win");
		}
		
		/**
		 * Setup specific popup buttons 
		 */
		override protected function setupPopup():void
		{
			// setup card group
			_cardGroup = CardGroupPop(super.getGroupById(CardGroup.GROUP_ID));
			if( !_cardGroup )
				_cardGroup = CardGroupPop(super.addChildGroup( new shellApi.itemManager.cardGroupClass() ));
			
			// set up video button, if any
			if (super.screen["replayVideoButton"] != null)
				setupButton(super.screen["replayVideoButton"], replayVideo);
			
			// setup score if any
			if (super.screen["score"] != null)
				super.screen["score"].text = String(_score);
			
			// load and display cards for gender
			loadCards(AdUtils.getCardList(shellApi, super.campaignData.campaignId, super.campaignData.gameID));
		}
		
		/**
		 * Load filtered cards
		 * @param cardData
		 */
		private function loadCards(cardData:Vector.<String>):void
		{
			trace("AdWinPopup: cardData: " + cardData);
			
			// for each card listed in campaign.xml
			for (var i:int = 0; i != cardData.length; i++)
			{
				// get card ID
				var cardID:String = cardData[i];
				
				// get card container movie clip (index starts at 1)
				var containerClip:MovieClip = super.screen["card" + (i + 1)];
				// if card container clip
				if (containerClip)
				{
					// make invisible
					containerClip.visible = false;
					// award card with no animation
					shellApi.getItem(cardID, CardGroup.CUSTOM, false );
					var ItemCardID:String = "item" + cardID;
					// create card view
					var cardView:CardView = _cardGroup.createCardViewByItem( this, super.screen, ItemCardID, CardGroup.CUSTOM, null, Command.create(onCardLoaded, i));
					// add card view to array
					_cardViews.push(cardView);
					// setup spatial based on card container clip
					var spatial:Spatial = cardView.cardEntity.get(Spatial);
					spatial.x = containerClip.x;
					spatial.y = containerClip.y;
					spatial.scaleX = spatial.scaleY = containerClip.scaleX;
					spatial.rotation = containerClip.rotation;
				}
				else
				{
					trace("AdWinPopup: Error: No card container found for card " + (i + 1));
				}
			}
		}
		
		/**
		 * When card loaded 
		 * @param cardItem
		 */
		private function onCardLoaded( cardItem:CardItem = null, viewPos:int = 0):void
		{
			var cardView:CardView = _cardViews[viewPos];
			// bitmap card and show
			// if there is no reason to wait for a special because its null, or has card art
			if(cardItem.cardData.specialIds == null || cardItem.cardData.assetsData.length >= 2)
			{
				bitmapCardView(cardView);
			}
			else
			{
				// should be a better way, but accessing when any special ability could be ready 
				// but it seems out of the realm of reasonability with out some deeper reworking
				SceneUtil.delay(this,1, Command.create(bitmapCardView, cardView));
			}
		}
		
		private function bitmapCardView(cardView:CardView):void
		{
			cardView.bitmapCardAll(BITMAP_CARD_SCALE);
			cardView.hide( false );
		}
		
		private function replayVideo(button:Entity):void
		{
			closePopupForVideo();
			shellApi.sceneManager.currentScene.getEntityById("videoContainer").get(AdVideo).fnReplay();
		}
		
		/**
		 * Set score for win popup
		 * @param score
		 */
		public function setScore(score:Number):void
		{
			_score = score;
			
			// if arcade game, then send score to server
			if (_isArcadeGame)
			{
				AdUtils.setScore(shellApi, score);
			}
		}

		private const BITMAP_CARD_SCALE:Number = 2;
		private var _cardGroup:CardGroupPop;
		private var _cardViews:Array = new Array();
		private var _score:Number = 0;
	}
}