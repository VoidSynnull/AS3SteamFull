package game.ui.inventory
{
	import game.components.ui.CardItem;
	import game.data.ui.card.CardSet;
	
	/**
	 * A data class that holds relevant data for inventory page
	 */
	public class InventoryPage
	{
		public var id:String = "";
		public var tabIndex:uint;
		public var emptyMessage:String = "";
		public var tabName:String = "";
		public var cardSets:Vector.<CardSet>;
		public var cards:Vector.<CardItem>;
		public var tabTitle:String = "";
		public var savedGridPercent:Number = 0;
		
		// subset buttons could go here as well
		
		public function InventoryPage()
		{
			cardSets = new Vector.<CardSet>();
		}
		
		public function destroy():void
		{
			cards = null;
		}
		
		public function numCards():int
		{
			var total:int = 0;
			for (var i:int = 0; i < cardSets.length; i++) 
			{
				total += cardSets[i].cardIds.length;
			}
			return total;
		}
	}
}


