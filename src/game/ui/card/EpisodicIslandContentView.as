package game.ui.card
{
	import flash.display.DisplayObjectContainer;
	
	import game.components.ui.CardItem;
	import game.data.ParamList;
	import game.util.DataUtils;
	
	public class EpisodicIslandContentView extends CardContentView
	{
		public function EpisodicIslandContentView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		private var islandsCompleted:Vector.<EpisodicIslandData>;
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			var params:ParamList = cardItem.cardData.cardClassParams;
			
			var asset:String = DataUtils.getString(params.getParamId("asset").value);
			var island:String = DataUtils.getString(params.getParamId("island").value);
			var episodes:uint = DataUtils.getUint(params.getParamId("episodes").value);
			
			islandsCompleted = EpisodicIslandData.generateIslandData(shellApi, island, episodes);
			
			super.loadFile(asset, cardContentLoaded, cardItem, onComplete);
		}
		
		private function cardContentLoaded(asset:DisplayObjectContainer, cardItem:CardItem, handler:Function = null):void
		{
			super.unpause();
			this.groupContainer.addChild(asset);
			
			var isMale:Boolean = (shellApi.profileManager.active.gender == "male");
			
			EpisodicIslandData.configureContent(asset, islandsCompleted, isMale);
			
			if(handler != null)
				handler();
		}
	}
}