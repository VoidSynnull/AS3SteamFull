package game.scenes.ghd
{
	import game.scene.template.PlatformerGameScene;
	
	public class GalacticHotDogScene extends PlatformerGameScene
	{
		private const NEON_WIENER:String 			= 	"NeonWiener";
		private const ARENA:String					=	"Arena";
		
		protected var _events:GalacticHotDogEvents;
		
		public function GalacticHotDogScene()
		{
			super();
		}
		
		override public function loaded():void
		{
			_events = super.events as GalacticHotDogEvents;
			
			super.loaded();
			
			shellApi.eventTriggered.add( eventTriggers );
		}
		
		protected function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.USE_FUEL_CELL )
			{
				if( shellApi.checkEvent( _events.GOT_NUCLEAR_PELLET ))
				{
					if( shellApi.sceneName == NEON_WIENER )
					{
						shellApi.triggerEvent( _events.GIVE_FUEL_CELL, true );
					}
						
					else 
					{
						shellApi.triggerEvent( _events.NO_USE_FULL_FUEL_CELL );
					}
				}
				else if( shellApi.sceneName != ARENA)
				{
					shellApi.triggerEvent( _events.NO_USE_EMPTY_FUEL_CELL );
				}
			}
		}
	}
}