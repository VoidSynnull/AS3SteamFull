package game.data.game
{
	/**
	 * ...
	 * @author billy
	 */
	public class GameData 
	{
		public var islands:Array;
		public var firstScene:String;     		// the entry point scene into the application.
		public var defaultScene:String;   		// the default scene to load if no previous scene data is available. 
		public var overrideScene:String;  		// only for testing or 'standalone' builds that should automatically launch a minigame.
		public var autoLoadFirstScene:Boolean;  // should the first scene be loaded on startup?  defaults to true, can turn it off for testing.
		// these next two variables decouple the core Hud from its destination scenes. the app-specific *Shell class will initialize them in createGame()
		public var homeClass:Class;
		public var mapClass:Class;
		public var storeClass:Class;
	}
}