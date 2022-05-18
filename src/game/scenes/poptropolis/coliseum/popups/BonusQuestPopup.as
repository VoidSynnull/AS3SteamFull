package game.scenes.poptropolis.coliseum.popups
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.ui.elements.MultiStateButton;
	import game.ui.popup.BonusQuestBlockerPopup;
	
	public class BonusQuestPopup extends BonusQuestBlockerPopup
	{
		private var btnMembership:MultiStateButton;
		private var btnBeginQuest:MultiStateButton;
		private var campaign:String = "PoptropolisPromo";
		private var isMember:Boolean;
		private var events:PoptropolisEvents = new PoptropolisEvents();
	
		public function BonusQuestPopup(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		// pre load setup
		public override function init(container:DisplayObjectContainer=null):void 
		{
			var events:PoptropolisEvents = new PoptropolisEvents();
			super.configBonusQuestPopup(
				"scenes/poptropolis/coliseum/", 
				"bonusQuestPopup.swf",
				"PoptropolisPromo", 
				events.BLOCKED_FROM_BONUS, 
				events.BONUS_STARTED );
			super.init( container );
		}		
		
		// override what happens once bonus quest begins
		protected override function startBonusQuest():void
		{
			// TODO :: Not sure if this is all that is necessary to start the bonus quest.
			super.shellApi.triggerEvent("beginBonusQuest"); //trigger to listen for in cityLeft scene to start bonus quest
			super.handleCloseClicked();
		}
		
	}
}