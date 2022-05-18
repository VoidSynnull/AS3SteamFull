package game.scenes.nightWatch.parkingLot{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.PlatformerGameScene;
	
	public class ParkingLot extends PlatformerGameScene
	{
		public function ParkingLot()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/nightWatch/parkingLot/";
			
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
		}
	}
}