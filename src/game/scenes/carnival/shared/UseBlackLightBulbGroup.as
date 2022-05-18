package game.scenes.carnival.shared
{
	import engine.group.Group;
	
	import game.scenes.carnival.CarnivalEvents;
	import game.util.SkinUtils;

	public class UseBlackLightBulbGroup extends Group
	{
		private var _events:CarnivalEvents;
		
		public function UseBlackLightBulbGroup()
		{
			super(); 
			super.id = "useBlackLightBulbGroup";
		}
		
		public function init():void
		{
			SkinUtils.setSkinPart(super.shellApi.player, SkinUtils.ITEM, "mc_flashlight_black");
			super.shellApi.removeItem(_events.BLACK_LIGHTBULB);
			super.shellApi.removeItem(_events.FLASHLIGHT);
			super.shellApi.getItem(_events.FLASHLIGHT_BLACK, null, true);
			super.shellApi.completeEvent(_events.USED_BLACK_LIGHTBULB, "carnival");
		}
	}
}