package game.scenes.deepDive2.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.ui.CardItem;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.ui.card.CardContentView;
	import game.util.EntityUtils;
	
	/**
	 * atlantis puzzle card view
	 * 
	 */
	public class PuzzleKeyCardView extends CardContentView
	{
		private var _events:DeepDive2Events;
		
		private const piecesDir:String = "items/deepDive2/puzzle_key.swf";
		//private const completeDir:String = "items/deepDive2/puzzle_key2.swf";
		
		public function PuzzleKeyCardView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			super.loadFile(piecesDir, cardContentLoaded, !shellApi.checkEvent(_events.PUZZLE_ASSEMBLED), onComplete);
		}
		
		private function cardContentLoaded(asset:DisplayObjectContainer, inPieces:Boolean, handler:Function = null):void
		{
			super.unpause();
			
			super.groupContainer.addChild(asset);
			
			var tablet:Entity = EntityUtils.createSpatialEntity(this, asset, groupContainer);
			var puzzle:MovieClip = tablet.get(Display).displayObject["cardContent"];
			// check events, do nothing for complete puzzle
			if(inPieces){
				for (var i:int = 1; i <= 6; i++) 
				{
					if(!shellApi.checkEvent(_events.GOT_PUZZLE_PIECE_+i)){
						puzzle["piece"+i].visible = 0;
					}
				}
				puzzle["whole"].visible = 0;
			}
			else{
				for (var j:int = 1; j <= 6; j++) 
				{
					puzzle["piece"+j].visible = 0;
				}
				puzzle["whole"].visible = 1;
			}			
			
			if(handler != null)
				handler();
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
	}
}