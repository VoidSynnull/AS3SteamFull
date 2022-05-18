package game.scenes.poptropolis.shared {

	import flash.external.ExternalInterface;
	
	import engine.ShellApi;
	import engine.group.Scene;
	
	import game.data.animation.entity.character.WeightLifting;
	import game.data.animation.entity.character.poptropolis.DiveAnim;
	import game.data.animation.entity.character.poptropolis.HurdleAnim;
	import game.data.animation.entity.character.poptropolis.HurdleJump;
	import game.data.animation.entity.character.poptropolis.HurdleRun;
	import game.data.animation.entity.character.poptropolis.HurdleStart;
	import game.data.animation.entity.character.poptropolis.HurdleStop;
	import game.data.animation.entity.character.poptropolis.JavelinAnim;
	import game.data.animation.entity.character.poptropolis.LongJumpAnim;
	import game.data.animation.entity.character.poptropolis.LongJumpLand;
	import game.data.animation.entity.character.poptropolis.LongJumpRun;
	import game.data.animation.entity.character.poptropolis.PoleVaultAnim;
	import game.data.animation.entity.character.poptropolis.ShotputAnim;
	import game.data.animation.entity.character.poptropolis.WrestleAnim;
	import game.data.profile.TribeData;
	import game.scene.template.CharacterGroup;
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.scenes.poptropolis.coliseum.Coliseum;
	import game.scenes.poptropolis.shared.data.Competitor;
	import game.scenes.poptropolis.shared.data.MatchType;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.scenes.poptropolis.shared.data.Opponent;
	import game.scenes.poptropolis.shared.data.PoptropolisPlayer;
	import game.util.DataUtils;
	import game.util.TribeUtils;
	
	import org.osflash.signals.Signal;

	/**
	 * Helper class used with Poptropolis 
	 * @author Justin Lacy
	 */
	public class Poptropolis {

		public static var NUM_OPPONENTS:int = 7;

		public const LAST_MATCH_FIELD:String = "last_poptropolis_match";

		public var opponents:Vector.<Opponent>;
		public var player:PoptropolisPlayer;

		public var ranker:Rankings;						// computes ranking information.
		public var dataLink:PoptropolisDataLoader;		// used for storing/loading poptropolis data.

		public var isPractice:Boolean;					// true if current match is a practice match.
		public var curMatch:MatchType;					//current MatchType

		private var shellApi:ShellApi;
		private var _poptropolisAnims:Vector.<Class> = new <Class>[ DiveAnim, HurdleAnim, HurdleJump, HurdleRun, HurdleStart, HurdleStop, JavelinAnim, LongJumpAnim, LongJumpLand, LongJumpRun, PoleVaultAnim, ShotputAnim, WrestleAnim, WeightLifting ];

		/**
		 * Dispatched when all the poptropolis data has finished loading from the servers.
		 */
		public var loadComplete:Signal;

		/**
		 * Dispatched when the results popup from a completed event is closed.
		 */
		public var onResultsDone:Signal;

		/**
		 * if true, autoLoad the coliseum after the results screen completes.
		 */
		private var autoLoadColiseum:Boolean;

		private var _loaded:Boolean = false;

		public function Poptropolis( api:ShellApi, loadHandler:Function=null ) 
		{
			// create MatchType singleton
			Matches.InitTypes();

			this.shellApi = api;

			// preload poptropolis specific animations
			var scene:Scene = this.shellApi.sceneManager.currentScene;
			var charGroup:CharacterGroup = scene.getGroupById("characterGroup") as CharacterGroup;
			if( charGroup ) 
			{ 
				charGroup.preloadAnimations( _poptropolisAnims ); 
			}
			
			// performs various ranking/sorting functions and npc score generation.
			this.ranker = new Rankings();		
			
			/**
			 * There used to be some code here for inserting a scene-level callback for when the user tribe changes.
			 * This is because, if the user changes his tribe from another menu while the games are in progress,
			 * the tribe needs to update in Poptropolis. Something must be done about this. but the old way doesn't work.
			 */
			// create signals
			this.loadComplete = new Signal( Poptropolis );
			if ( loadHandler != null ) { this.loadComplete.addOnce( loadHandler ); }
			this.onResultsDone = new Signal();
		}
		
		public function setup():void
		{
			// determine tribe & setup poptroplis specific data for player
			var tribeData:TribeData = TribeUtils.getTribeOfPlayer( this.shellApi );
			if( tribeData == null ) 
			{
				this.displayTribeSelect();
			}
			else 
			{
				this.initWithTribe( tribeData );
			}
		}

		public static function QuickLog( ...args ):void {

			if (ExternalInterface.available) {
				ExternalInterface.call( 'dbug', args.join( " " ) );
			}

		} //

		// *************** INITIALIZE DATA *************** //

		private function displayTribeSelect():void {

			var scene:Scene = this.shellApi.sceneManager.currentScene;

			var popup:TribeSelectPopup = scene.addChildGroup(
				new TribeSelectPopup( "scenes/poptropolis/shared/tribeSelectPopup.swf", scene.overlayContainer ) ) as TribeSelectPopup;

			popup.onTribeSelected.add( this.initWithTribe );

		} //

		private function initWithTribe( tribeData:TribeData ):void {

			this.player = new PoptropolisPlayer( tribeData );

			// load looks, tribal npcs, & ranks
			this.dataLink = new PoptropolisDataLoader( this.shellApi );
			this.dataLink.doLoad( this.onGameDataLoaded );

		} //

		/**
		 * The data has been loaded by PoptropolisDataLoader, which returns list of Opponents &amp; rank string?
		 */
		public function onGameDataLoaded( opponentList:Vector.<Opponent>, rankString:String ):void {

			if ( opponentList )	// saved opponents found, reapply 
			{
				this.opponents = opponentList;
			} 
			else 				// opponents were not previously saved, create new & save
			{						
				this.createOpponents();
				this.dataLink.saveNpcData( this.opponents );
			}
			
			// We still might have found rank data; the tribes won't match but it will preserve the player's score.
			// This is kind of bad since the dataLink does the encoding and we do the decoding.
			// can't think of a good way, yet, to organize everything.
			// rank was found, decode and apply to competitors
			if ( DataUtils.validString(rankString) )
			{
				var encoder:RanksEncoder = new RanksEncoder();
				encoder.decodeRanks( this.player, this.opponents, rankString );
			} 
			else 									// rank was not found, create and save
			{
				this.createRanks();
				// it might be a bad idea to save ranks here because we don't actually know if the
				// data doesn't still exist on the server, but just didn't get through.
				this.dataLink.saveRanks( this.player, this.opponents );
			}

			var lastMatch:String = shellApi.getUserField(LAST_MATCH_FIELD, shellApi.island) as String;
			if ( lastMatch != null ) {
				this.curMatch = Matches.ByName[ lastMatch ];
			}

			// Note: check here that none of the opponents have the same tribe as the player. If so we will need to recreate the opponents
			this.checkDuplicateTribe();

			_loaded = true;
			loadComplete.dispatch( this );
			loadComplete.removeAll();	// Don't need the signal any more.

		} //

		// Tribe was changed from the quidget. Update all the stuff.
		public function tribeChanged():void {

			// get the new player tribe from the tribe id in the LSO.
			this.player.tribe;

			var ind:Number = this.checkDuplicateTribe();
			if ( ind != -1 ) {
				// duplicate tribe occured. need to re-save opponent tribe to lso with the new tribe changed.
				this.dataLink.saveNpcData( this.opponents );
			}

			/**
			 * NOTE: HERE WE NEED TO CHECK IF THE PLAYER IS WEARING THE JERSEY OF AN OPPOSING TRIBE.
			 * IF SO, CHANGE IT TO THE CORRECT JERSEY AND SAVE.
			 */
			var changed:Boolean = false;

			/*if ( avatar.shirtFrame.indexOf( "pg_jersey_" ) != -1 ) {

				if ( avatar.shirtFrame != player.tribe.jersey ) {
					avatar.shirtFrame = player.tribe.jersey;
					avatar.loadPart( "shirt", avatar.shirtFrame );
					changed = true;
				} //

			} // End-if.*/

			/*if ( avatar.pantsFrame.indexOf( "pg_jersey_" ) != -1 ) {

				if ( avatar.pantsFrame != player.tribe.jersey ) {
					avatar.pantsFrame = player.tribe.jersey;
					avatar.loadPart( "pants", avatar.pantsFrame );
					changed = true;
				} //

			} // End-if.*/

		} // End function tribeChanged()

		/**
		 * Start a new game of poptropolis. tribeID is the player tribe.
		 * note: tribes data must have already been loaded for this to work.
		 */
		public function startNewGame():void {

			this.createOpponents();

			// Generate Empty ranks for all opponents and the player.
			var ranks:Vector.<int> = Matches.MakeRankList();
			for( var i:int = opponents.length-1; i >= 0; i-- )  
			{
				this.opponents[i].setRanks( ranks.slice() );
			}

			//this.player.clearScores();
			this.player.setRanks( ranks );		// note this is the same array, not a slice()

			this.dataLink.saveNpcData( this.opponents );
			this.dataLink.saveRanks( this.player, this.opponents );

		} //

		// Reset all opponents and data for this player's poptropolis game.
		public function doIslandReset():void {

			this.startNewGame();
			this.shellApi.loadScene( Coliseum );

		} //

		// *************** SCENE/POPUP INTERACTIONS *************** //

		/**
		 * Report a score for a completed match.
		 * 
		 * matchType - the match just completed. use one of the static constants from the Matches class: e.g. Matches.HURDLES
		 *
		 * pScore - the score the player got.
		 * 
		 * autoLoadColiseum - (true by default), if true, the coliseum will automatically load
		 * after the player closes the score dialog.
		 */
		public function reportScore( matchType:int, pScore:Number, autoLoadColiseum:Boolean=true ):void {

			this.autoLoadColiseum = autoLoadColiseum;
			this.curMatch = Matches.getMatchType( matchType );
			pScore = this.curMatch.roundScore( pScore );

			/**
			 * Might need to complete the event here that indicates the match has been played?
			 * Unless people are doing that in their local games.
			 */

			// save player score.
			this.player.setMatchScore( this.curMatch.id, pScore );		// player.tempScore = playerScore

			// generate scores for opponents, then ranks based on those scores.
			this.ranker.assignScores( this.curMatch, this.opponents );
			this.ranker.assignRanks( this.curMatch, this.player, this.opponents );

			this.shellApi.track( "GotScore", this.curMatch.eventName, this.player.getRank( matchType ) );

			// report/save scores internally.
			this.dataLink.saveRanks( this.player, this.opponents );

			var scene:Scene = this.shellApi.sceneManager.currentScene;
			var popup:TribeResultsPopup = new TribeResultsPopup( this, "scenes/poptropolis/shared/tribeResultsPopup.swf",
				scene.overlayContainer );
			scene.addChildGroup( popup );
			popup.popupRemoved.addOnce( this.resultsPopupClosed );

		} //

		public function displayRanksPopup():TribeRanksPopup
		{
			var scene:Scene = this.shellApi.sceneManager.currentScene;
			var popup:TribeRanksPopup = new TribeRanksPopup( this, "scenes/poptropolis/shared/tribeRanksPopup.swf", scene.overlayContainer );
			scene.addChildGroup( popup );
			return popup;
		} //

		/**
		 * Called by the results popup after the results button has been clicked.
		 */
		public function resultsPopupClosed():void {

			var events:PoptropolisEvents = new PoptropolisEvents();

			if ( this.curMatch != null ) {

				this.shellApi.setUserField(LAST_MATCH_FIELD, this.curMatch.eventName, shellApi.island);

				this.shellApi.completeEvent( this.curMatch.eventName  + "_completed" );
				this.shellApi.completeEvent( events.EVENT_COMPLETED );

			}

			onResultsDone.dispatch();
			onResultsDone.removeAll();

			if (autoLoadColiseum) {
				shellApi.loadScene( Coliseum );
			}
		}

		// *************** OPPONENTS *************** //

		/**
		 * Returns the index of the opponent whose tribe had to be changed (because it matched the player's),
		 * or returns -1 if all tribes are unique.
		 */
		public function checkDuplicateTribe():int {

			var tribe:game.data.profile.TribeData;

			for( var i:int = this.opponents.length-1; i >= 0; i-- ) {

				if ( this.opponents[i].tribe.index != this.player.tribe.index ) {
					//trace( "no match: " + opponents[i].tribe.id );
					continue;
				}

				// Stupid double loop to find an unused tribe.
				for( var j:int = TribeUtils.tribeTotal-1; j >= 0; j-- ) {

					tribe = TribeUtils.getTribeDataByIndex( j );
					for( var k:int = this.opponents.length-1; k >= 0; k-- ) {

						if ( tribe == this.opponents[k].tribe ) {

							//trace( "cant use: " + t.id );
							tribe = null;
							break;

						} //
					}

					if ( tribe != null ) {
						// Made it through entire opponents list without duplicate tribe.
						//trace( "setting tribe to: " + t.id );
						this.opponents[i].setTribe( tribe );
						return i;
						//this._shellApi.logWWW( "TRIBE CHANGED: " + tribe.id );
					}
				}

			} //

			return -1;

		} //

		private function createRanks():void {

			// Generate Empty ranks for all opponents and the player.
			var ranks:Vector.<int> = Matches.MakeRankList();
			for( var i:int = opponents.length-1; i >= 0; i-- ) {
				this.opponents[i].setRanks( ranks.slice() );
			}

			//this.player.clearScores();
			this.player.setRanks( ranks );		// note this is the same array, not a slice()

		} //

		// create a random set of NUM_OPPONENTS
		private function createOpponents():void {

			// Need empty opponents to recieve the opponent looks when they're loaded.
			this.opponents = new Vector.<Opponent>();

			var opponent:Opponent;

			var opponentLooks:Vector.<int> = Opponent.SelectLooks( NUM_OPPONENTS );
			var lookIndex:int;		// look index.
			var tribeIndex:int = 0;

			for( var i:int = 0; i < NUM_OPPONENTS; i++ ) {

				if( tribeIndex == player.tribe.index ) {
					tribeIndex++;
				}

				opponent = new Opponent();

				// assign avaialble tribe
				opponent.tribe = TribeUtils.getTribeDataByIndex(tribeIndex);
				tribeIndex++;

				// assign look id
				lookIndex = Math.floor( Math.random() * opponentLooks.length );	// randomize the look orders ( since girls are selected first, then boys. )
				opponent.lookId = opponentLooks[lookIndex];
				opponentLooks.splice( lookIndex, 1 );			// delete look id (locally) so it is not used again

				this.opponents.push(opponent);

			} //

			// assign random skill ranks to the opponents - REPLACE by tribe standings later.
			this.ranker.assignSkills( this.opponents );
		}

		/**
		 * Get opponent by its order in the opponent vector (id) or by the opponent tribe name.
		 */
		public function getOpponent( obj:Object ):Opponent {

			var type:String = typeof( obj );

			if ( type == "string" ) {

				for( var i:int = this.opponents.length-1; i >= 0; i-- ) {

					if ( this.opponents[i].tribe.name == obj ) {
						return this.opponents[i];
					}

				} // end for-loop.

			} else if ( type == "number" ) {

				return this.opponents[ int(obj) ];
			}

			return null;

		} //

		// *************** RANKINGS  / SCORING *************** //
		
		public function initRanks( rankList:Vector.< Vector.<int> > ):void {

			for( var i:int = 0; i < this.opponents.length; i++ ) {

				this.opponents[i].setRanks( rankList[i] );	// opponents are matched to ranking by index in relative lists

			}
			this.player.setRanks( rankList[i] );	// player's rank is last in list

		}

		/**
		 * Return an array of opponent/player objects sorted in decreasing order of scores for a single match.
		 * If no match is specified, the match from the last reportScore() function is used.
		 * rankings[0] is the opponent or player with the best score in a match.
		 * 
		 **/
		public function getRankings( matchName:String=null ):Vector.<Competitor> {

			var matchType:MatchType;
			
			if  ( matchName == null ) {
				matchType = this.curMatch;
				if ( matchType == null ) {			// error: no previous match.
					return null;
				}
			} else {

				matchType = Matches.ByName[ matchName.toLowerCase() ];

			} //

			return this.ranker.getRankings( matchType.id, this.player, this.opponents );

		} //

		/**
		 * Returns a list of the top-ranked opponents, with the best ranked at the front of the vector.
		 * 
		 * maxReturn - limits the number of npcs returned.
		 */
		public function getNpcLeaders( maxReturn:int=8 ):Vector.<Opponent> {

			var list:Vector.<Opponent> = this.ranker.getNpcLeaders( opponents );
			if ( list.length > maxReturn ) {
				list.length = maxReturn;
			}

			return list;

		} //

		/**
		 * Returns list of Competitors, players + npcs.
		 * Lowest in the array is the top leader for all games.
		 */
		public function getLeaders():Vector.<Competitor> {

			var list:Vector.<Competitor> = this.ranker.getLeaders( this.player, this.opponents );
			return list;

		} //

		// *************** MATCH/EVENT TYPES *************** //
		// Most of these functions duplicate the behavior of the Matches class, without
		// the programmer having to link to that class directly. (to avoid swf recompile.)

		public function getCurMatch():MatchType {

			return this.curMatch;

		} // End function getCurMatch()
		
		public function getMatchName( id:int ):String {

			return Matches.getMatchName( id );

		} // End function getMatchName()

		public function getMatchId( s:String ):int {

			return Matches.getMatchId( s );

		} // End function getMatchId()

		public function getMatchCount():int {
			return Matches.NUM_TYPES;
		}

		public function get loaded():Boolean {
			return this._loaded;
		}

	} // class

} // package