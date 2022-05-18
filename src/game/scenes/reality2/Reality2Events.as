package game.scenes.reality2
{
	import game.data.island.IslandEvents;
	import game.scenes.reality2.cheetahRun.CheetahRun;
	import game.scenes.reality2.common.Common;
	import game.scenes.reality2.deepDive.DeepDive;
	import game.scenes.reality2.gameShow.GameShow;
	import game.scenes.reality2.mainStreet.MainStreet;
	import game.scenes.reality2.spearThrow.SpearThrow;

	public class Reality2Events extends IslandEvents
	{
		public function Reality2Events()
		{
			super();
			super.scenes = [MainStreet, Common, GameShow, DeepDive, SpearThrow, CheetahRun];
			super.popups = [];
			
			this.island = "reality2";
		}
		
		//Events
		public const SAW_INTRO:String				= "saw_intro";				//saw helicopter intro on main street
		
		public const GAMES_STARTED:String			= "games_started";
		
		public static const COMPLETED_GAME:String	= "completed_game_";
		public const COMPETITION_FINISHED:String	= "competition_finished";	//3 games played and award ceremony over
		public static const CONTESTANTS_CHOSEN:String	= "contestants_chosen";		//contestants chosen

		
		//user field constants
		public const CONTESTANTS_FIELD:String		= "contestants";
		public static const GAMES_PLAYED_FIELD:String	= "games_played";
		
		//Items
		public const MEDAL_REALITY2:String			= "medal_reality2";
	}
}