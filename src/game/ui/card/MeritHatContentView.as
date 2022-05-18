package game.ui.card
{
	import flash.display.DisplayObjectContainer;
	
	import game.components.ui.CardItem;
	import game.data.ui.card.CardRadioButtonData;
	
	public class MeritHatContentView extends MultiFrameContentView
	{
		public function MeritHatContentView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		private const MEDAL:String = "medal_";
		
		// this class is dynamic enough that this could work for any episodic island
		// as long as naming conventions are consistant
		
		// each frame of the content is labeled islandName1, islandName2, islandName3 ... 
		// and medals are called "medal_islandName#"
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			super.create(cardItem, onComplete);
			var hasMedal:Boolean;
			var items:Array;
			for(var i:int = 0; i < cardItem.cardData.radioButtonData.length; i++)
			{
				hasMedal = false;
				var radioButtonData:CardRadioButtonData = cardItem.cardData.radioButtonData[i];
				var value:String = radioButtonData.value;
				items = shellApi.profileManager.active.items[value];
				if(items != null)
				{
					if(items.indexOf(MEDAL+value) == 0)
						hasMedal = true;
				}
				if(!hasMedal)
					cardItem.radioButtonHolder.getChildAt(i).visible = false;
			}
		}
	}
}