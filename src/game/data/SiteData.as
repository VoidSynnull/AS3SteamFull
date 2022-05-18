package game.data
{
	public class SiteData
	{
		public var login:String				= "";
		public var pass_hash:String			= "";
		public var dbid:String				= "";
		public var island:String			= "";		// player's previous island
		public var room:String				= "";		// player's previous scene
		public var dest_scene:String		= "";		// the AS3 scene which should be displayed by the Shell, of the form game.scenes.<islandID>.<scenePackage>.<sceneClass>
		public var dest_x:Number			= 0;		// the x location of the player within dest_scene
		public var dest_y:Number			= 0;		// the y location of the player within dest_scene
		public var dest_dir:String			= "";		// the direction the player should be facing: either CharUtils.DIRECTION_LEFT or CharUtils.DIRECTION_RIGHT
		public var valid:Boolean			= false;	// whether these values are sufficient to navigate Poptropica freely
	}
}