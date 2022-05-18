package game.scenes.train.teslaCabin
{
	import ash.core.Entity;
	
	import engine.components.Interaction;
	
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.train.TrainEvents;
	
	import game.scene.template.PlatformerGameScene;

	
	public class TeslaCabin extends PlatformerGameScene
	{
		public function TeslaCabin()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/train/teslaCabin/";
			
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
			if ( super.shellApi.checkEvent( _events.CAUGHT_TESLA ))
			{
				super.shellApi.completeEvent( _events.CHECKED_TESLA_CABIN );			
			}
			
			//_tesla = super.groupManager.getEntityById("tesla", this);
		}
		
		//private var _tesla:Entity;
		private var _events:TrainEvents;
	}
}