package game.util
{	

	import ash.core.Entity;
	
	import engine.ShellApi;
	
	import game.components.entity.character.Profile;
	import game.data.profile.TribeData;

	public class TribeUtils
	{	
		public static function getTribeDataByIndex( index:int ):TribeData
		{
			if( index >= 4000 )
			{
				index -= 4001;
			}
			
			if( index > -1 && index < TRIBES.length )
			{
				return TRIBES[index]
			}
			else 
			{
				return null;
			}
		}
		
		public static function getTribeDataById( id:String ):TribeData
		{
			for (var i:int = 0; i < TRIBES.length; i++) 
			{
				if( TRIBES[i].id == id )
				{
					return TRIBES[i];
				}
			}
			trace( "TribeUtils :: getTribeDataById : invalid tribe id : " + id );
			return null;
		}
		
		/**
		 * Use to retrieve active user's Tribe data
		 * @param shellApi
		 * @return 
		 */
		public static function getTribeOfPlayer( shellApi:ShellApi ):TribeData 
		{
			if( shellApi.profileManager.active.tribeData == null )
			{
				var tribeValue:* = shellApi.getUserField( TribeUtils.TRIBE_FIELD );
				trace("TRIBE VALUE RETURNED FROM USERFIELD: " + tribeValue);
				if( DataUtils.isValidStringOrNumber(tribeValue) )
				{
					shellApi.profileManager.active.tribeData = TribeUtils.getTribeDataByIndex( tribeValue as int );
				}
			}
			return shellApi.profileManager.active.tribeData;
		}
		
		/**
		 * Returns a character's TribeData, check's Profile component.
		 * @param playerEntity
		 * @return 
		 */
		public static function getTribeByEntity( charEntity:Entity ):TribeData 
		{
			var profile:Profile = charEntity.get( Profile );
			if( profile )
			{
				return profile.profileData.tribeData;
			}
			return null;
		}

		/**
		 * Sets the user tribe in ProfileData &amp; LSO.
		 * If shellApi is included, will push changes to server.
		 * If callback supplied, the result of setting the tribe on the server side
		 * is sent to the callback function as a result:PopResponse object.
		 * 
		 * if result.succeeded == false, the call to the server failed; and the tribe
		 * on the server side was not set.
		 */
		public static function setPlayerTribe( tribeId:String, shellApi:ShellApi, saveToServer:Boolean = false, callback:Function = null ):void 
		{
			var tribeData:TribeData = TribeUtils.getTribeDataById( tribeId );
			if( tribeData )
			{
				trace( "TribeUtils :: setPlayerTribe : setting to tribeData: " + tribeData.name );
				// set tribe as userfield to profile and backend
				// even if tribe is the same, may not have been save yet
				shellApi.profileManager.active.tribeData = tribeData;	
				shellApi.setUserField( TRIBE_FIELD, convertId( tribeData.index, false ), "", saveToServer, callback );
			}	
			else
			{
				trace( "TribeUtils :: setPlayerTribe : no TribeData found for tribeId: " + tribeId );
				if( callback != null ) { callback(); }
			}
		}
		
		/**
		 * Converts server tribe id into tribe index ( tribe ids start at 4001 for some reason )
		 */
		public static function convertId( indexId:int, fromServer:Boolean = true ):int 
		{
			if( fromServer )
			{
				return ( indexId - 4001 );
			}
			else
			{
				return ( indexId + 4001 );
			}
		}
		
		public static function get tribeTotal():int { return TRIBES.length; }
		
		public static const TRIBE_FIELD:String = "Tribe";
		//private static const COMMON_ROOM_PREFIX:String = "TribalCommon";
		
		public static const SQUID:String 	= "squid";
		public static const WILDFIRE:String = "wildfire";
		public static const YELLOW:String 	= "yellow";
		public static const PATH:String 	= "path";
		public static const FLAGS:String 	= "flags";
		public static const NIGHT:String 	= "night";
		public static const SERAPHIM:String = "seraphim";
		public static const NANOBOTS:String = "nanobots";
		
		private static const TRIBES:Vector.<TribeData> = new <TribeData>
							[
							new TribeData( 0, SQUID, "Flying Squid"),
							new TribeData( 1, WILDFIRE, "Wildfire"),
							new TribeData( 2, YELLOW, "Yellowjackets", "yellowj"),
							new TribeData( 3, PATH, "Pathfinders" ),
							new TribeData( 4, FLAGS, "Black Flags" ),
							new TribeData( 5, NIGHT, "Nightcrawlers" ),
							new TribeData( 6, SERAPHIM, "Seraphim", "seraphins"),
							new TribeData( 7, NANOBOTS, "Nanobots")
							];

	}
}
		
		

		
		
	