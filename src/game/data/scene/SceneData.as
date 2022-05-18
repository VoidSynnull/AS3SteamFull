package game.data.scene 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class SceneData 
	{
		public var cameraLimits:Rectangle;
		public var bounds:Rectangle;
		public var assets:Array;
		public var data:Array;
		public var prefix:String;
		public var layers:Dictionary;
		/** Array of files specified in scene data file that have absolute paths.  A file for globally shared dialog would be an example */
		public var absoluteFilePaths:Array;
		public var prependTypePath:Boolean;
		public var saveLocation:Boolean = true;
		public var sceneType:String = SceneType.DEFAULT;
		public var noCharacters:Boolean = false;   // if we don't need character groups.  May be able to remove this if we tie player creation to npcs.xml.
		public var actId:String;
		public var suppressFollower:Boolean = false;
		public var suppressAbility:Boolean = false;
		public var hasPlayer:Boolean = true;		// flag determining if scene requires the player
		public var pullFromServer:Boolean = false; //flag if to force pulling from server (mobile)
		
		// player specific
		// TODO :: player details should really be defined within npcs.xml. -bard
		public var startPosition:Point;
		public var startDirection:String;
		public var playerScale:Number = NaN;	
	}
}