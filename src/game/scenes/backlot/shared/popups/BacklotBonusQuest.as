package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.backlot.BacklotEvents;
	import game.ui.popup.BonusQuestBlockerPopup;
	
	public class BacklotBonusQuest extends BonusQuestBlockerPopup
	{
		public function BacklotBonusQuest(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		public override function init(container:DisplayObjectContainer=null):void 
		{
			var events:BacklotEvents = new BacklotEvents();
			super.configBonusQuestPopup(
				"scenes/backlot/shared/", 
				"bonusQuest.swf",
				"backlotPromo", 
				events.BLOCKED_FROM_BONUS, 
				events.DAY_2_STARTED );
			super.init( container );
		}		
		
		// override what happens once bonus quest begins
		protected override function startBonusQuest():void
		{
			// TODO :: Would need more here, not sure what would happen
			super.startBonusQuest();
		}
	}
}