package game.scenes.cavern1
{
	import game.data.island.IslandEvents;
	import game.data.specialAbility.islands.cavern.MagBelt;
	import game.scenes.cavern1.cave.Cave;
	import game.scenes.cavern1.caveEntrance.CaveEntrance;
	import game.scenes.cavern1.mainStreet.MainStreet;
	import game.scenes.cavern1.surveySite.SurveySite;
	import game.scenes.cavern1.underMainStreet.UnderMainStreet;
	import game.scenes.cavern1.underSurvey.UnderSurvey;
	import game.scenes.cavern1.visitorsCenter.VisitorsCenter;
	
	public class Cavern1Events extends IslandEvents
	{
		public function Cavern1Events()
		{
			super();
			super.scenes = [MainStreet, VisitorsCenter, SurveySite, CaveEntrance, Cave, UnderSurvey, UnderMainStreet];
			super.popups = [];
			var specials:Array = [MagBelt];
			this.island = "cavern1";
		}
		
		// permanent events
		
		public const LOOK_FOR_ANTLERS:String	= "look_for_antlers";
		public const RETURNED_ANTLERS:String	= "returned_antlers";
		public const STANLEY_IN_CAVE:String		= "stanley_in_cave";
		
		// group & temp events
		
		
		
		// items
		public const BUTTON:String			= "button";
		public const ELK_ANTLERS:String		= "elk_antlers";
		public const JUNIOR_ID:String		= "junior_id";
		public const MAGNETIC_BELT:String	= "magnetic_belt";
		public const JOURNAL:String			= "journal"; // journal binding
		public const JOURNAL_PAGE_:String	= "journal_entry" // 1-4 (12 total for the 3 episodes)
		public const MEDAL_CAVERN1:String	= "medal_cavern1";
	}
}