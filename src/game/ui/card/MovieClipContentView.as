package game.ui.card
{
	import flash.display.DisplayObjectContainer;
	
	import game.components.ui.CardItem;
	import game.data.ui.card.CardItemData;
	
	/**
	 * @author Scott Wszalek
	 * 
	 * Loads external swfs for display within card, uses CardItem's value variable to determine which swf should be visible.
	 */
	public class MovieClipContentView extends CardContentView
	{
		public function MovieClipContentView(container:DisplayObjectContainer=null)
		{
			super(container);
			_assets = new Array();
		}
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			var cardData:CardItemData = cardItem.cardData;
			for(var i:int = 0; i < cardItem.cardData.cardClassParams.length; i++)
			{
				super.loadFile(cardData.cardClassParams.params[i].value, cardContentLoaded, i, cardData.cardClassParams.length, onComplete);
			}
		}

		override public function update(cardItem:CardItem):void
		{
			for(var i:int = 0; i < _assets.length; i++)
				_assets[i].visible = false;
			
			_assets[Number(cardItem.value)].visible = true;
		}
		
		private function cardContentLoaded(asset:DisplayObjectContainer, index:int, total:int, handler:Function):void
		{
			super.groupContainer.addChild(asset);
			
			// leave the first one visible
			if(index != 0)
			{
				asset.visible = false;
			}
			
			_assets[index] = asset;
			
			if( handler != null )	
			{ 
				if( index == (total - 1) )
				{
					handler();
				}
			}
		}
		
		override public function destroy():void
		{
			_assets = null;
			super.destroy();
		}
		
		private var _assets:Array;
	}
}