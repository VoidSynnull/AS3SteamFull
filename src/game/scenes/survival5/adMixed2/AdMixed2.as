package game.scenes.survival5.adMixed2
{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.PlatformerGameScene;
	import game.scenes.survival5.Survival5Events;
	
	public class AdMixed2 extends PlatformerGameScene
	{
		private var _events:Survival5Events;
		
		public function AdMixed2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival5/adMixed2/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
//			super.shellApi.eventTriggered.add( eventTriggers );
		}
//		
//		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
//		{
//			var dialog:Dialog = player.get( Dialog );
//			switch( event )
//			{
//				case _events.USE_FULL_PITCHER:	
//					dialog.sayById( "no_use" );
//					break;
//				case _events.USE_TROPHY_ROOM_KEY:
//					dialog.sayById( "no_use" );
//					break;
//				case _events.USE_ARMORY_KEY:
//					dialog.sayById( "no_use" );
//					break;
//				case _events.USE_EMPTY_PITCHER:
//					dialog.sayById( "no_use" );
//					break;
//				case _events.USE_SPEAR:
//					dialog.sayById( "no_use" );
//					break;
//				case _events.USE_TAINTED_MEAT:
//					dialog.sayById( "no_use" );
//					break;
//			}
//		}
	}
}



