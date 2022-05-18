package game.scenes.train.coalCar
{
	import ash.core.Entity;
	
	import engine.components.Interaction;
	
	import flash.display.DisplayObjectContainer;

	import game.components.scene.SceneInteraction;
	import game.scenes.train.TrainEvents;

	import game.scene.template.PlatformerGameScene;

	import game.scenes.train.trainStop.TrainStop;
	
	
	public class CoalCar extends PlatformerGameScene
	{
		public function CoalCar()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/train/coalCar/";
			
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
			
			_events = new TrainEvents();
			_conductor = super.getEntityById("conductor");
			_tesla = super.getEntityById("tesla");
			
		}

		
		//	Interaction(_conductor.get(Interaction)).down.removeAll();
		//	Interaction(_tesla.get(Interaction)).down.removeAll();
			
		//	Interaction(_conductor.get(Interaction)).down.add(conductorClicked);
		//	Interaction(_tesla.get(Interaction)).down.add(teslaClicked);
			
		
		
		/* private function conductorClicked(entity:Entity):void
		{
			if ( super.shellApi.checkEvent( _events.ASK_TO_DISEMBARK ) )
			{
				super.shellApi.loadScene( TrainStop );
			}
		}
		
		private function teslaClicked(entity:Entity):void
		{
			if( super.shellApi.checkEvent( _events.RELEASED_TESLA_2 ))
			{
				super.shellApi.triggerEvent( _events.RELEASED_TESLA_RESPONSE );
			}
			
			if( super.shellApi.checkEvent( _events.RELEASED_TESLA_REPLY ))
			{
				super.shellApi.triggerEvent( _events.RELEASED_TESLA_3 );
			}
		} */
		
		private var _conductor:Entity;
		private var _tesla:Entity;
		private var _events:TrainEvents;
	}
}