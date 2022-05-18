/**
 * Stores data that is shared between all profiles.
 */
package game.data.profile
{
	import flash.utils.Dictionary;

	public class GlobalData
	{
		/**
		 * A <code>Dictionary</code> of DLCContentData that holds all of the info 
		 * regarding DLC and whether content is downloaded, purchased, or free and a checkSum
		 * for validating zips with the backend.
		 */
		public var dlc:Dictionary;
		/**
		 * A <code>Dictionary</code> of DLCFileData that holds all of the info 
		 * regarding DLC files including their checksum and if they are installed.
		 */
		public var dlcFiles:Dictionary;
		/**
		 * A list of all versions of the app that have existed on this device.
		 */
		public var appVersions:Array;
		/**
		 * The last username used to play the game.  This determines the default profile to load.
		 */
		public var lastLogin:String;
	}
}