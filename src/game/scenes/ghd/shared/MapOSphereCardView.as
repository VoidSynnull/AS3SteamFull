package game.scenes.ghd.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.ui.CardItem;
	import game.scenes.ghd.GalacticHotDogEvents;
	import game.ui.card.CardContentView;
	import game.util.EntityUtils;
	
	public class MapOSphereCardView extends CardContentView
	{
		private var _events:GalacticHotDogEvents;
		
		private const piecesDir:String = "items/ghd/map_o_sphere.swf";
		
		public function MapOSphereCardView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			super.loadFile(piecesDir, cardContentLoaded, onComplete);
		}
		
		private function cardContentLoaded(asset:DisplayObjectContainer, handler:Function = null):void
		{
			super.unpause();
			
			super.groupContainer.addChild(asset);
			
			var tablet:Entity = EntityUtils.createSpatialEntity(this, asset, groupContainer);
			var puzzle:MovieClip = tablet.get(Display).displayObject["cardContent"];
			
			if(!shellApi.checkEvent(_events.GOT_MAP_1)){
				puzzle["piece1"].visible = false;
				puzzle["piece1"].alpha = 0;
			}
			if(!shellApi.checkEvent(_events.GOT_MAP_2)){
				puzzle["piece2"].visible = false;
				puzzle["piece2"].alpha = 0;
			}
			if(!shellApi.checkEvent(_events.GOT_MAP_3)){
				puzzle["piece3"].visible = false;
				puzzle["piece3"].alpha = 0;
			}
			
			if(handler != null){
				handler();
			}
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
	}
}