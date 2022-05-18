package game.data.island
{
	import game.data.scene.DoorData;

	public class IslandEvents
	{
		public function IslandEvents()
		{
			removeIslandParts = new Vector.<Vector.<String>>();
		}
		
		public var popups:Array;
		public var scenes:Array;
		public var sceneEntrance:DoorData;
		public var removeIslandParts:Vector.<Vector.<String>>;
		
		/**
		 * The internal island name. Ex. "carrot, deepDive, etc."
		 */
		public var island:String;
		
		/**
		 * The class associated with the next episode to this island/episode.
		 */
		public var nextEpisodeEvents:Class;
		
		/**
		 * A flag indicating whether the island is accessible outside of development.
		 */
		public var accessible:Boolean = false;
		
		/**
		 * A flag indicating whether the island is accessible outside of early access/membership limitations.
		 */
		public var earlyAccess:Boolean = false;
		
		/**
		 * A flag indicating whether the island can be reset.
		 */
		public var canReset:Boolean = true;
		
		public var canSaveIslandLocation:Boolean = true;
	}
}