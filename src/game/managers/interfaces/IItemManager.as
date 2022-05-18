package game.managers.interfaces
{
	import flash.utils.Dictionary;
	
	import game.data.ui.card.CardSet;

	public interface IItemManager
	{
		function checkHas(item:String, setId:String):Boolean;
		/**
		 * Returns CardSet if it exists, otherwise makes a new CardSet with given setId and returns that.
		 * @param setId - id of CardSet retrieving or creating
		 * @param filterExpired - flag determining if card set should be filter for possiblye experation
		 * @return 
		 */
		function getMakeSet( setId:String, filterExpired:Boolean = false ):CardSet;
		function getSets():Vector.<CardSet>;
		function showItem( itemId:String, type:String, transitionCompleteHandler:Function = null ):void;
		function reset( setId:String = null, save:Boolean = true ):void;
		function remove(item:String, setId:String):Boolean;
		function getItem(item:*, type:String = null, showCard:Boolean = false, showCompleteCallback:Function = null):Boolean;
		
		/**
		 * Convert given item ids back into CardSets.
		 * If set is not specified restores all sets with given Dictionary.
		 * @param itemSets - Dictionary, using key of setId, of Arrays containing item ids
		 * @param setId - id of the set of items ( example store, custom, carrot )
		 */
		function restoreSets( itemSets:Dictionary, setId:String = null ):void
			
		function get cardGroupClass():Class;
		function set cardGroupClass( value:Class):void;
		
		/**
		 * List of valid items for current content (island) 
		 * @return 
		 */
		function get validCurrentItems():Vector.<String>
		function set validCurrentItems( value:Vector.<String>):void
			
		/**
		 * List of store items
		 * @return 
		 */
		function get storeItems():Dictionary
		function set storeItems( value:Dictionary):void
	}
}