package game.scenes.poptropolis.shared.data {

	import flash.utils.Dictionary;
	
	import game.scenes.poptropolis.archery.Archery;
	import game.scenes.poptropolis.diving.Diving;
	import game.scenes.poptropolis.hurdles.Hurdles;
	import game.scenes.poptropolis.javelin.Javelin;
	import game.scenes.poptropolis.longJump.LongJump;
	import game.scenes.poptropolis.poleVault.PoleVault;
	import game.scenes.poptropolis.shotput.Shotput;
	import game.scenes.poptropolis.skiing.Skiing;
	import game.scenes.poptropolis.tripleJump.TripleJump;
	import game.scenes.poptropolis.volleyball.Volleyball;
	import game.scenes.poptropolis.weightLift.WeightLift;
	import game.scenes.poptropolis.wrestling.Wrestling;

	/**
	 * The constants in the Matches class indicate the order the match ranks should be stored
	 * in the results arrays; this is the order the match results will be stored on the server
	 * as well, so its important they dont change.
	 * 
	 * It's possible to only put the ordering information in the upload encoder/decoder and
	 * to refer to match results within the program by match name, but it seems better to
	 * just link the names and the results-order here, once and for all.
	 */
	public class Matches {

		/**
		 * We don't count wrestling, currently.
		 */
		public static const NUM_TYPES:int = 11;

		public static const NONE:int = -1;
		public static const ARCHERY:int = 0;
		public static const DIVING:int = 1;
		public static const HURDLES:int = 2;
		public static const JAVELIN:int = 3;
		public static const LONG_JUMP:int = 4;
		public static const POLE_VAULT:int = 5;
		public static const POWER_LIFTING:int = 6;
		public static const SHOT_PUT:int = 7;
		public static const TRIPLE_JUMP:int = 8;
		public static const SKIING:int = 9;
		public static const VOLLEYBALL:int = 10;

		public static const WRESTLING:int = 11;

		public static var ByName:Dictionary;		// stores match ids by name.
		public static var Types:Vector.<MatchType>;

		/**
		 * Singleton method that creates Vector &amp; Dictionary of MatchType.
		 */
		static public function InitTypes():void 
		{
			var m:MatchType;

			if ( Matches.Types != null ) {
				return;
			}

			var types:Vector.<MatchType> = Matches.Types = new Vector.<MatchType>( Matches.NUM_TYPES );
			var byName:Dictionary = Matches.ByName = new Dictionary();

			m = new MatchType( Matches.ARCHERY, "Archery", "archery", 95, 0, "pts" );
			byName[ m.eventName ] = m;
			types[ Matches.ARCHERY ] = m;

			m = new MatchType( Matches.DIVING, "Diving", "diving", 45, 0, "pts", 5 );
			byName[ m.eventName ] = m;
			types[ Matches.DIVING ] = m;

			m = new MatchType( Matches.HURDLES, "Hurdles", "hurdles", 36, 29, "sec", 0.1 );
			m.invertScore = true;
			byName[ m.eventName ] = m;
			types[ Matches.HURDLES ] = m;

			m = new MatchType( Matches.JAVELIN, "Javelin", "javelin", 185, 0 );
			byName[ m.eventName ] = m;
			types[ Matches.JAVELIN ] = m;

			m = new MatchType( Matches.LONG_JUMP, "Long Jump", "long_jump", 115, 0, "", 0.1 );
			byName[ m.eventName ] = m;
			types[ Matches.LONG_JUMP ] = m;

			m = new MatchType( Matches.POLE_VAULT, "Pole Vault", "pole_vault", 45, 30, "", 0.1 );
			byName[ m.eventName ] = m;
			types[ Matches.POLE_VAULT ] = m;

			m = new MatchType( Matches.POWER_LIFTING, "Power Lifting", "weight_lifting", 530, 0, "kg" );
			byName[ m.eventName] = m;
			types[ Matches.POWER_LIFTING ] = m;

			m = new MatchType( Matches.SHOT_PUT, "Shot Put", "shotput", 126, 0 );
			byName[ m.eventName ] = m;
			types[ Matches.SHOT_PUT ] = m;

			m = new MatchType( Matches.TRIPLE_JUMP, "Triple Jump", "triple_jump", 110, 40, "", 0.1 );
			byName[ m.eventName ] = m;
			types[ Matches.TRIPLE_JUMP ] = m;

			m = new MatchType( Matches.SKIING, "Volcano Race", "skiing", 34, 16, "sec", 0.1 );
			m.invertScore = true;
			byName[ m.eventName ] = m;
			types[ Matches.SKIING ] = m;

			m = new MatchType( Matches.VOLLEYBALL, "Volleyball", "volleyball", 6, 1, "pts" );
			byName[ m.eventName ] = m;
			types[ Matches.VOLLEYBALL ] = m;

			m = new MatchType( Matches.WRESTLING, "Wrestling", "wrestling", 4, 0 );
			byName[ m.eventName ] = m;
			types[ Matches.WRESTLING ] = m;

		}

		public function Matches() {}

		public static function getMatchType( id:int ):MatchType { return Matches.Types[id]; }

		public static function getMatchName( id:int ):String { return Matches.Types[id].displayName; }

		public static function getMatchId( s:String ):int 
		{
			if ( Matches.ByName[s] != null ) {
				return Matches.ByName[s].id;
			}

			return Matches.NONE;
		}

		// Make a list of empty (-1) scores to assign to new opponent/player objects.
		public static function MakeRankList():Vector.<int> 
		{
			var none:int = Matches.NONE;
			var ranks:Vector.<int> = new Vector.<int>( Matches.NUM_TYPES );
			for( var i:int = ranks.length-1; i >= 0; i-- ) {
				ranks[i] = none;
			}

			return ranks;
		}

	}
}