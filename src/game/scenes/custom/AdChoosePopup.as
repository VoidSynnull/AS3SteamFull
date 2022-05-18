package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.creators.InteractionCreator;
	
	import game.components.ui.ToolTip;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ui.ToolTipType;
	import game.managers.ads.AdManager;
	import game.scenes.custom.AdBasePopup;
	import game.scenes.custom.questGame.QuestGame;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;
	
	public class AdChoosePopup extends AdBasePopup
	{
		public var selectionMade:Signal = new Signal(int);
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set popup type to choose
			_popupType = "Choose";
			super.init(container);
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			// set up 9 choose buttons
			// 10 won't work because it is 2 digits
			for (var i:int = 1; i!= 9; i++)
			{
				if (super.screen["chooseButton" + i] != null)
					setupButton(super.screen["chooseButton" + i], makeChoice);
				else
					break;
			}
			// to force arrow cursor outside buttons, make sure there is a background clip named "back"
			if (super.screen["back"] != null)
			{
				var back:Entity = setupButton(super.screen["back"], swallowClicks, false);
				var toolTipEntity:Entity = EntityUtils.getChildById(back, "tooltip", false);
				toolTipEntity.get(ToolTip).type = ToolTipType.ARROW;
			}
		}
		
		private function makeChoice(button:Entity):void
		{
			var buttonName:String = button.get(Id).id;
			// get last char from button name
			var selection:int = int(buttonName.substr(buttonName.length-1));
			AdManager(super.shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_SELECTION, buttonName);
			// pass selection to quest game
			selectionMade.dispatch(selection);
			//QuestGame(super.shellApi.sceneManager.currentScene).playerSelection(selection);
			// close popup
			super.close();
		}
		
		/**
		 * swallow mouse clicks on background
		 */
		private function swallowClicks(entity:Entity):void
		{
		}

		override protected function closePopup(button:Entity):void
		{
			if((_isArcadeGame) || (parent is QuestGame))
				returnToInterior();
			else
			{
				selectionMade.dispatch(-1);
				super.close();
			}
		}
	}
}