package game.scenes.deepDive3.shared.drone.states
{
	import flash.geom.Point;

	public class DroneScanState extends DroneState
	{
		public function DroneScanState()
		{
			super.type = "scan";
		}
		
		override public function start():void
		{
			node.motionControl.moveToTarget = false; // disable motionControl (need something more precise)
			newScanPoint();
		}
		
		override public function update(time:Number):void
		{
			// watch follow target
			faceTargetSpatial();
			
			var reached:Boolean = moveToPoint(scanPoint, true);
			
			// move drone to a random around the target, then move on once scan and repeat at random points
			if(reached && scanTime >= scanTimeMAX){
				node.drone.scanPlayer.dispatch(); // scan player
				flashLight();
				newScanPoint();
				scanTime = 0;
			} else if(reached){
				scanTime++;
			}
		}
		
		private function newScanPoint():void
		{
			var angle:Number = Math.random()*360;
			scanPoint = new Point( node.drone.targetSpatial.x+(scanPointOffset*Math.cos(angle)), node.drone.targetSpatial.y+(scanPointOffset*Math.sin(angle)) );
		}
		
		private var scanPointOffset:Number = 200;
		private var scanPoint:Point;
		private var scanTime:int = 0;
		private var scanTimeMAX:int = 60;
	}
}