package game.scenes.carnival.ridesEmpty {

import flash.display.DisplayObjectContainer;

import game.scenes.carnival.CarnivalEvents;
import game.ui.elements.MultiStateButton;
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
	private var btnMembership:MultiStateButton;
	private var btnBeginQuest:MultiStateButton;
	private var gCampaignName:String = "MonsterCarnival";
	private var isMember:Boolean;
	private var carnivalEvents:CarnivalEvents;

	public function BonusQuestPopup(container:DisplayObjectContainer=null) {
		super(container);
	}
	
	// pre load setup
	public override function init(container:DisplayObjectContainer=null):void 
	{
		var events:CarnivalEvents = new CarnivalEvents();
		super.configBonusQuestPopup(
			"scenes/carnival/ridesEmpty/", 
			"bonusQuestPopup.swf",
			"MonsterCarnival", 
			events.BLOCKED_FROM_BONUS, 
			events.STARTED_BONUS_QUEST );
		super.init( container );
	}		
	
	// override what happens once bonus quest begins
	protected override function startBonusQuest():void
	{
		// TODO :: Not sure if this is all that is necessary to start the bonus quest.
		super.startBonusQuest();
	}
}

}