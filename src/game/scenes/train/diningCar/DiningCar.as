package game.scenes.train.diningCar
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	
	import game.components.entity.Sleep;
	import game.components.scene.SceneInteraction;
	import game.data.game.GameEvent;
	import game.scenes.train.TrainEvents;
	import game.scene.template.PlatformerGameScene;
	
	public class DiningCar extends PlatformerGameScene
	{
		public function DiningCar()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/train/diningCar/";
			
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
			_anthony = super.getEntityById("anthony");
			_porter = super.getEntityById("porter");
			
			if( super.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.CLUE_PRUNE_JUICE ))
			{
			//	super.shellApi.removeEvent( "setAnthonyInDiningCar" );
			//	super.shellApi.completeEvent( "setAnthonyInCabin" );
			}
			else 
			{
			//	super.shellApi.completeEvent( "setAnthonyInDiningCar" );
				//super.shellApi.removeEvent( "setAnthonyInCabin" );
			}
		}
		
		private var _anthony:Entity;
		private var _porter:Entity;
		private var _events:TrainEvents;
	}
}