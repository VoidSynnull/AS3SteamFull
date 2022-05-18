package game.scenes.custom.items
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import game.components.ui.CardItem;
	import game.ui.card.CardContentView;
	
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;

	public class TicketContentView extends CardContentView
	{

		/**
		 * Interface class for the card content
		 */
		public function TicketContentView(container:DisplayObjectContainer = null) 
		{
			super(container);
		}
		
		/**
		 * Method to override, call by CardGroup within card creation sequence.
		 */
		override public function create( cardItem:CardItem, onComplete:Function = null ):void
		{		
			super.loadFile(_assetPath, cardContentLoaded, cardItem, onComplete);
		}

		private function cardContentLoaded(asset:DisplayObjectContainer, cardItem:CardItem, handler:Function = null):void
		{
			super.unpause();
			this.groupContainer.addChild(asset);
			
			// Figure out # of tickets; can assume it is at least length one
			// (user can't have the card without having collected a ticket)
			var lso:SharedObject = SharedObject.getLocal("Char", "/");
			lso.objectEncoding = ObjectEncoding.AMF0;
			
			try {
				var ticketCollectionArray:Array = lso.data.userData.contestIslandMap;
			}
			catch (error:Error) {
				((asset as MovieClip).ticketField as TextField).text = "You have collected\nno tickets!";
				return;
			}
			
			var ticketsCollected:Number = 0;
			for ( var i:Number = 0; i < ticketCollectionArray.length; i ++ ) {
				if ( ticketCollectionArray[i] == 1 ) {
					ticketsCollected ++;
				}
			}
			
			// Format string
			var ticketProgress:String;
			if ( ticketsCollected == 1 ) {
				ticketProgress = "1 ticket";
			}
			else { 
				ticketProgress = String(ticketsCollected) + " tickets";
			}
			
			// Update text field
			((asset as MovieClip).ticketField as TextField).text = "You have collected\n" + ticketProgress + "!";

			if(handler != null) { handler(); }
		}
		
		private var _assetPath:String = "items/limited/item2739.swf"
	}
} 