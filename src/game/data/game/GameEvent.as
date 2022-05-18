package game.data.game
{
	public class GameEvent
	{
		public function GameEvent()
		{
		}
		
		public static const DEFAULT:String = "default";
		
		/**
		 *  This gets triggered (does not save) one time when the specified item is receieved
		 */
		public static const GET_ITEM:String	= "getItem_";
		
		/**
		 * This stores that you had the specified item at some point even if you still don't have it
		 */
		public static const GOT_ITEM:String = "gotItem_";
		
		/**
		 * This stores that you currently have the specified item 
		 */		
		public static const HAS_ITEM:String = "hasItem_";
		
		public static const STARTED:String = "started";
	}
}