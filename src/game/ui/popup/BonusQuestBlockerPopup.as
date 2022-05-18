package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import game.data.island.IslandEvents;
	import game.data.ui.ButtonSpec;
	import game.data.ui.TransitionData;
	import game.ui.elements.MultiStateButton;
	import game.ui.hud.HudPopBrowser;
	import game.util.DataUtils;
	
	/**
	 * BonusQuestPopup presents an interface urging nonmembers
	 * to sign up to play the bonus quest,
	 * or to start the bonus quest if they are a member.
	 */
	public class BonusQuestBlockerPopup extends Popup
	{
		public function BonusQuestBlockerPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		public function configBonusQuestPopup( groupPrefix:String = "", assetName:String="",islandCampaignName:String = "",bonusBlockedEvent:String = "",bonusStartedEvent:String = ""):void
		{
			if( DataUtils.validString( groupPrefix ) )			{ super.groupPrefix = groupPrefix; }
			if( DataUtils.validString( assetName ) )			{ super.screenAsset = assetName; }
			if( DataUtils.validString( islandCampaignName ) )	{ _gCampaignName = islandCampaignName; }
			if( DataUtils.validString( bonusBlockedEvent ) )	{ _bonusBlockedEvent = bonusBlockedEvent; }
			if( DataUtils.validString( bonusStartedEvent ) )	{ _bonusStartedEvent = bonusStartedEvent; }
		}

		public override function init(container:DisplayObjectContainer=null):void 
		{
			transitionIn = new TransitionData();
			transitionIn.duration = .3;
			transitionIn.startPos = new Point(0, -shellApi.viewportHeight);
			transitionOut = transitionIn.duplicateSwitch();	// this shortcut method flips the start and end position of the transitionIn
			
			darkenBackground = true;
			
			super.init(container);
			super.load();
		}	
		
		// all assets ready
		public override function loaded():void 
		{
			super.preparePopup();
			
			this.layout.centerUI(screen.content);
			
			if(true)
			{
				//remove this for coming soon period
				super.screen.content.btnMembership.visible = false;
				super.screen.content.nonMemberText.visible = false;
				
				_btnBeginQuest = MultiStateButton.instanceFromButtonSpec(
					ButtonSpec.instanceFromInitializer(
						{
							displayObjectContainer:super.screen.content.btnBeginQuest,
							pressAction:super.playClick,
							clickHandler:clickBtnBeginQuest
						}
					)
				)
			}
			else 
			{
				super.shellApi.completeEvent(_bonusBlockedEvent);
				super.shellApi.track("BonusQuest", "BonusQuestBlock", "Impressions", _gCampaignName);
				
				//remove this for coming soon period
				super.screen.content.btnBeginQuest.visible = false;
				
				_btnMembership = MultiStateButton.instanceFromButtonSpec(
					ButtonSpec.instanceFromInitializer(
						{
							displayObjectContainer:super.screen.content.btnMembership,
							pressAction:super.playClick,
							clickHandler:clickBtnMembership
						}
					)
				)
			}
			
			super.loadCloseButton();
			
			super.groupReady();
		}
		
		private function clickBtnMembership(e:MouseEvent):void 
		{
			super.shellApi.track("BonusQuest", "BonusQuestBlock", "Clicks", _gCampaignName);
			HudPopBrowser.buyMembership(super.shellApi);
		}
		
		private function clickBtnBeginQuest(e:MouseEvent):void 
		{
			//check if they've been blocked before, so we can track if they are a converted member or not
			if (super.shellApi.checkEvent(_bonusBlockedEvent)) 
			{
				super.shellApi.track("BonusQuest", "Started", "Converted", _gCampaignName);
			}
			else 
			{
				super.shellApi.track("BonusQuest", "Started", null, _gCampaignName);
			}
			//Begin the bonus quest. Complete started_bonus_quest.
			super.shellApi.completeEvent(_bonusStartedEvent); //saved event for scenes to check against to know if we are in bonus quest state
			
			startBonusQuest();
		}
		
		/**
		 * For override, determines what should happen once the bonus quest begins.
		 */
		protected function startBonusQuest():void
		{
			// EXAMPLE : shellApi.loadScene(BonusScene);	// it mightbe the case where you want to load a new scene to begin teh bonus quest
			super.handleCloseClicked();						// or the bonus quest may be ready to go and all that is required is closing the popup.
		}

		protected var _gCampaignName:String = "";
		protected var _events:IslandEvents;
		protected var _bonusBlockedEvent:String;
		protected var _bonusStartedEvent:String;		
		
		private var _btnMembership:MultiStateButton;
		private var _btnBeginQuest:MultiStateButton;
	}
}