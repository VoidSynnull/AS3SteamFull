package game.ui.card
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.components.ui.CardItem;
	import game.util.DataUtils;


	public class MultiFrameContentView extends CardContentView
	{

		/**
		 * Interface class for the card content
		 */
		public function MultiFrameContentView(container:DisplayObjectContainer = null) 
		{
			super(container);
		}
		
		/**
		 * Method to override, call by CardGroup within card creation sequence.
		 */
		override public function create( cardItem:CardItem, onComplete:Function = null ):void
		{		
			super.loadFile(cardItem.cardData.cardClassParams.params[0].value, cardContentLoaded, cardItem, onComplete);
		}
		
		private function cardContentLoaded(asset:DisplayObjectContainer, cardItem:CardItem, handler:Function = null):void
		{
			super.unpause();
			
			if( asset != null )
			{
				_asset = asset as MovieClip;
				this.groupContainer.addChild(_asset);
				if( DataUtils.isValidStringOrNumber(cardItem.value) )
				{
					_asset.gotoAndStop(cardItem.value);
				}
				else
				{
					_asset.gotoAndStop(1);
				}
			}
			
			if(handler != null)
			{
				handler();
			}
		}
		
		override public function update( cardItem:CardItem ):void
		{
			if( _asset != null )
			{
				_asset.gotoAndStop(cardItem.value);
			}
		}
		
		private var _asset:MovieClip;
	}
}