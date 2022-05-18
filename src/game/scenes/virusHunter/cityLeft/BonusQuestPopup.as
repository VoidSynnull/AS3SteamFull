package game.scenes.virusHunter.cityLeft {

import flash.display.DisplayObjectContainer;

import game.scenes.virusHunter.VirusHunterEvents;
import game.ui.popup.BonusQuestBlockerPopup;

/**
 * BonusQuestPopup presents an interface urging nonmembers
 * to sign up to play the bonus quest,
 * or to start the bonus quest if they are a member.
 * @author Jordan Leary
 * 
 */
public class BonusQuestPopup extends BonusQuestBlockerPopup
{
	public function BonusQuestPopup(container:DisplayObjectContainer=null) {
		super(container);
	}
	
	// pre load setup
	public override function init(container:DisplayObjectContainer=null):void 
	{
		var events:VirusHunterEvents = new VirusHunterEvents();
		super.configBonusQuestPopup(
			"scenes/virusHunter/cityLeft/", 
			"bonusQuestPopup.swf",
			"Mocktropica", 
			events.BLOCKED_FROM_BONUS, 
			events.STARTED_BONUS_QUEST );
		super.init( container );
	}		
	
	// override what happens once bonus quest begins
	protected override function startBonusQuest():void
	{
		super.shellApi.triggerEvent("beginBonusQuest"); //trigger to listen for in cityLeft scene to start bonus quest
		super.handleCloseClicked();
	}
	
}

}
