package game.ui.card
{
	import flash.display.DisplayObjectContainer;
	
	import engine.group.DisplayGroup;
	
	import game.components.ui.CardItem;
	import game.data.display.BitmapWrapper;
	
	import org.osflash.signals.Signal;

	public class CardContentView extends DisplayGroup
	{
		public var contentLoaded:Signal;
		public var canRefresh:Boolean = false;
		public var loadingWrapper:BitmapWrapper;
		
		/**
		 * Interface class for the card content
		 */
		public function CardContentView(container:DisplayObjectContainer = null) 
		{
			super(container);
			contentLoaded = new Signal();
		}

		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init( container );
		}
		
		/**
		 * Method to override, creates new content.
		 */
		override public function destroy():void
		{
			if( loadingWrapper )	// loadingWrapper's bitmap is disposed by the Inventory in which it originated
			{
				//loadingWrapper.destroy();
				loadingWrapper = null;
			}
			super.destroy();
		}
		
		/**
		 * Method to override, creates new content.
		 */
		public function create( cardItem:CardItem, onComplete:Function = null ):void
		{
		}
		
		/**
		 * Method to override, refreshes current content.
		 */
		public function refresh( cardItem:CardItem, onComplete:Function = null ):void
		{
		}
		
		/**
		 * Method to override.
		 */
		public function start():void
		{
		}
		
		/**
		 * Method to override.
		 */
		public function stop():void
		{
		}
		
		/**
		 * Method to override.
		 */
		public function update( cardItem:CardItem ):void
		{
		}
		
		/**
		 * Method to override, makes bitmap source visible.  
		 * Usage generally associated with bitmapping of card.
		 */
		public function bitmapSourceVisible( showSource:Boolean = true ):void
		{
		}
	}
}