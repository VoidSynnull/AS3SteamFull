package game.scenes.survival1.knollside
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.shared.SurvivalScene;
	
	public class Knollside extends SurvivalScene
	{
		public function Knollside()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival1/knollside/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var sur:Survival1Events;
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			sur = events as Survival1Events;
			
//			if( shellApi.checkEvent( sur.HAS_PAGE_ + "5" ))
//				removeEntity( getEntityById( "handbookPage" ));
			
			if(shellApi.checkHasItem(sur.WET_KINDLING))
				removeEntity(getEntityById("wetKindling"));
		}
	}
}