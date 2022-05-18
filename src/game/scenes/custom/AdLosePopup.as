package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.data.ads.AdTrackingConstants;
	import game.managers.ads.AdManager;
	import game.scene.template.ui.CardGroup;
	import game.scene.template.ui.CardGroupPop;
	import game.scenes.custom.AdBasePopup;
	import game.scenes.hub.starcade.Starcade;
	import game.utils.AdUtils;
	
	public class AdLosePopup extends AdBasePopup
	{
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set popup type to lose
			_popupType = AdTrackingConstants.TRACKING_LOSE;
			super.init(container);
			
			// tracking (lose)
			if (_isArcadeGame)
				shellApi.track(Starcade.TRACK_ARCADE_GAME_LOSE, shellApi.arcadeGame, null, "Starcade");
			else
				AdManager(shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_LOSE, _trackingChoice);
			
			// trigger event that we completed the game
			super.shellApi.completeEvent(_questName + "Completed");
			
			// update game buttons on video unit
			updateVideoGameButton("firstGameButton", "lose");
			updateVideoGameButton("secondGameButton", "lose");

			// update game buttons on video unit
			var gameButton:Entity = shellApi.sceneManager.currentScene.getEntityById("secondGameButton");
			if (gameButton != null)
			{
				var timeline:Timeline = gameButton.get(Timeline);
				if (timeline != null)
				{
					// check if have cards (first one)
					var cards:Vector.<String> = AdUtils.getCardList(shellApi, super.campaignData.campaignId, super.campaignData.gameID);
					// if cards and player doesn't have first one, then set button to replay for prize
					if ((cards.length != 0) && (!shellApi.itemManager.checkHas(cards[0], "custom")))
						timeline.gotoAndStop("replayForPrize");
					else
						timeline.gotoAndStop("replay");
				}
			}
		}
		override protected function setupPopup():void
		{
			// setup score if any
			if (super.screen["score"] != null)
				super.screen["score"].text = String(_score);
		}
		public function setScore(score:Number):void
		{
			_score = score;
			
			// if arcade game, then send score to server
			//if (_isArcadeGame)
			//{
				//AdUtils.setScore(shellApi, score);
			//}
		}
		private var _score:Number = 0;
	}
}