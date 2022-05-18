package game.scenes.poptropolis.shared {
	
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	
	import game.data.profile.ProfileData;
	import game.scenes.poptropolis.shared.data.Opponent;
	import game.scenes.poptropolis.shared.data.PoptropolisPlayer;
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;

	public class PoptropolisDataLoader 
	{
		private const RANK_DATA_FIELD:String = "TribalRanks";
		private const NPC_DATA_FIELD:String = "TribalNpcs";
		private const LOOKS_PATH:String = "scenes/poptropolis/shared/looks.xml";

		// flags used to determine when all data has ben loaded
		private var _looksLoadComplete:Boolean;
		private var _npcsLoadComplete:Boolean;
		private var _ranksLoadComplete:Boolean;

		private var _shellApi:ShellApi;
		private var _rankEncoder:RanksEncoder;
		/**
		 * The encoded rank string recieved from the userfield.
		 * Need to wait for the opponents to be loaded or created to use this in decoding.
		 */
		private var _rankString:String;
		/** List of decoded Opponents */
		private var _opponents:Vector.<Opponent>;
		
		public var onDataLoaded:Signal;

		public function PoptropolisDataLoader( api:ShellApi ) {
			
			this._shellApi = api;
			// signal will return list of opponents and rank string
			this.onDataLoaded = new Signal( Vector.<Opponent>, String );
		}

		// *************** LOADING *************** //
		
		/**
		 * Check if data is available in player profile; if not, load from server.
		 * 
		 * load order: load .xml opponent look files
		 * load opponent information (tribes, look_ids, etc )
		 * load ranking information.
		 */
		public function doLoad( loadHandler:Function=null ):void {

			if ( loadHandler != null ) {
				this.onDataLoaded.addOnce( loadHandler );
			}

			// reset loadComplete flags
			this._looksLoadComplete = false;
			this._npcsLoadComplete = false;
			this._ranksLoadComplete = false;

			this.loadLookData();		// load/check looks
			this.loadNpcAndRankData();	// load/check npcs & rank
			this.checkLoadComplete();	// check for load complete
		}


		/**
		 * Load the LookData for use with the opponent nps. 
		 */
		public function loadLookData():void 
		{
			if ( Opponent.GirlLooks != null && Opponent.BoyLooks != null )
			{
				// look data has already been loaded.
				this._looksLoadComplete = true;
			} 
			else 
			{
				this._shellApi.loadFile( this._shellApi.dataPrefix + LOOKS_PATH, this.looksLoaded );
			}
		}
		
		private function looksLoaded( xmlData:XML ):void 
		{
			if ( xmlData != null ) 
			{
				// sets up looks within Opponent
				Opponent.InitLooks( xmlData.children() ); // NOTE :: Feel like this shoudl be stored in Poptropolis, not Opponent as static 
			} 
			else 
			{
				trace( " Error : PoptropolisDataLoader : scenes/poptropolis/shared/looks.xml failed to load" );
			}

			this._looksLoadComplete = true;
			this.checkLoadComplete();
		}
		
		/**
		 * Get the opponent and rank data from profile userfields.
		 * Makes server call for userFields if not immediately found.
		 */
		private function loadNpcAndRankData():void {

			var profile:ProfileData = this._shellApi.profileManager.active;
			
			// check local profile for opponent field
			this._npcsLoadComplete = decodeOpponents( this._shellApi.getUserField(NPC_DATA_FIELD, _shellApi.island) as Array );

			// check local profile for tribal rank field
			var encodedRanks:String = _shellApi.getUserField(RANK_DATA_FIELD, _shellApi.island ) as String;
			if ( DataUtils.validString(encodedRanks) ) 
			{
				//this._shellApi.logWWW( "PROFILE RANKS FOUND: " + tribalRanks);
				_rankString = encodedRanks;
				this._ranksLoadComplete = true;
			}
			
			// determine what userfields still need to be retrieved from backend
			if ( !this._npcsLoadComplete && !this._ranksLoadComplete ) 
			{
				trace( this," :: loadNpcAndRankData : requesting NPC_DATA_FIELD & RANK_DATA_FIELD from external sources." );
				this._shellApi.getUserFields( [ NPC_DATA_FIELD, RANK_DATA_FIELD ], _shellApi.island, this.fieldDataLoaded, true );
			}
			else if ( !this._npcsLoadComplete )
			{
				trace( this," :: loadNpcAndRankData : RANK_DATA_FIELD found locally, requesting NPC_DATA_FIELD from external sources." );
				this._shellApi.getUserField( NPC_DATA_FIELD, _shellApi.island, this.npcsLoaded, true );
			}
			else if ( !this._ranksLoadComplete )
			{
				trace( this," :: loadNpcAndRankData : NPC_DATA_FIELD found locally, requesting RANK_DATA_FIELD from external sources." );
				this._shellApi.getUserField( RANK_DATA_FIELD, _shellApi.island, this.ranksLoaded, true );
			}
		}

		/**
		 * callback from attempting to load the npcData and rankData at the same time.
		 */
		private function fieldDataLoaded( fieldValues:Dictionary ):void  
		{
			if( fieldValues )
			{
				trace( this," :: fieldDataLoaded : fieldValues returned: " + fieldValues);
				this.ranksLoaded( (fieldValues[RANK_DATA_FIELD] as String), false );
				this.npcsLoaded( (fieldValues[NPC_DATA_FIELD] as Array), false );
			}
			else
			{
				trace( this," :: WARNING :: fieldDataLoaded : userfields were not found, setting to complete regardless ");
				this._ranksLoadComplete = true;
				this._npcsLoadComplete = true;
			}
			
			this.checkLoadComplete();
		} 

		/**
		 * callback from attempting to load rankData
		 */
		private function ranksLoaded( encodedRanks:String, checkComplete:Boolean = true ):void 
		{
			trace( this," :: ranksLoaded : " + encodedRanks);
			this._rankString = encodedRanks as String;
			// set ranksLoadComplete to true, even if encodedRanks is invalid, will prevent a crash at least, want better handling though. - bard
			this._ranksLoadComplete = true;
			if( checkComplete )	{ this.checkLoadComplete(); }
		}

		/**
		 * We should have gotten the npc look data back as an array of
		 * encoded npc objects.
		 */
		private function npcsLoaded( value:*, checkComplete:Boolean = true ):void 
		{
			trace( this," :: npcsLoaded : value: " + value);
			decodeOpponents( value as Array );
			// set npcsLoadComplete to true, even if value failed to load, will prevent a crash at least, want better handling though. - bard
			this._npcsLoadComplete = true;
			if( checkComplete )	{ this.checkLoadComplete(); }
		}

		private function checkLoadComplete():void 
		{
			if( this._looksLoadComplete && this._npcsLoadComplete && this._ranksLoadComplete ) {

				this.onDataLoaded.dispatch( this._opponents, this._rankString );
				this.onDataLoaded.removeAll();
			}
		}

		// *************************** SAVING *********************** //

		/**
		 * Encodes & saves the npcs, their looks, tribe-ids, etc to backend (as2LSO & server) 
		 * 
		 * The data is stored as an array of npc-data objects, that are encoded/decoded with the Opponent
		 * encode/decode functions. Maybe this should be done by a helper class like the ranks are,
		 * but this way nothing needs to know about the internal workings of the Opponent class.
		 * 
		 */
		public function saveNpcData( opponents:Vector.<Opponent> ):void 
		{
			trace( this," :: saveNpcData");
			this._shellApi.setUserField( NPC_DATA_FIELD, encodeOpponents(opponents), _shellApi.island, true );
		}

		// Saves the current rankings in a game.
		/**
		 * Encodes ranking and save to backend (as2LSO & server) 
		 * @param player
		 * @param opponents
		 */
		public function saveRanks( player:PoptropolisPlayer, opponents:Vector.<Opponent> ):void 
		{
			trace( this," :: saveRanks");
			if( _rankEncoder == null)	{ _rankEncoder = new RanksEncoder(); }
			this._shellApi.setUserField( RANK_DATA_FIELD, _rankEncoder.encodeRanks( player, opponents ), _shellApi.island, true );
		}
		
		// *************************** ENCODING/DECODING *********************** //
		
		private function decodeOpponents( encodedOpponents:Array ):Boolean 
		{
			if ( encodedOpponents != null ) 
			{
				_opponents = new Vector.<Opponent>( encodedOpponents.length );
				var opponent:Opponent;
				for( var i:int = encodedOpponents.length-1; i >= 0; i-- ) 
				{
					_opponents[i] = opponent = new Opponent();
					opponent.decode( encodedOpponents[i] );
				}
				return true;
			}
			else
			{
				trace( this," :: Warning : decodeOpponents : given array was null");
				return false;
			}
		}
		
		private function encodeOpponents( opponents:Vector.<Opponent> ):Array 
		{
			// Convert data into backend friendly format
			var encodedNPCData:Array = new Array( opponents.length );
			for( var i:Number = opponents.length-1; i >= 0; i-- ) 
			{
				encodedNPCData[i] = opponents[i].encode();
			}
			trace( this," :: encodeOpponents : encodedNPCData is: " + encodedNPCData);
			return encodedNPCData;
		}

	} // class

} // package