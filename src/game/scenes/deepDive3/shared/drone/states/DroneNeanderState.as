package game.scenes.deepDive3.shared.drone.states
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;

	public class DroneNeanderState extends DroneState
	{
		public function DroneNeanderState()
		{
			super.type = "neander";
		}
		
		override public function start():void
		{
			this._node.entity.add(new Sleep());
			node.motionControl.moveToTarget = false; // disable motionControl (need something more precise)
			newSpatial();
			newScanPoint();
		}
		
		override public function update(time:Number):void
		{
			var reached:Boolean = moveToPoint(scanPoint, true);
			
			// move drone to a random around the target, then move on once scan and repeat at random points
			if(reached && scanTime >= scanTimeMAX){
				if(scanNum < scanNumMAX){
					
					if(currentSpatial == node.drone.targetSpatial){
						node.drone.scanPlayer.dispatch();
						flashLight();
					}
					
					newScanPoint();
					scanTime = 0;
					scanNum++;
				} else {
					// change to a new spatial to scan
					newSpatial();
					newScanPoint();
					scanTime = 0;
					scanNum = 0;
				}
			} else if(reached){
				scanTime++;
			}
			
			if(node.spatial.x < currentSpatial.x){
				node.spatial.scaleX = -1;
			} else {
				node.spatial.scaleX = 1;
			}
		}
		
		private function newScanPoint():void
		{
			var angle:Number = Math.random()*360;
			scanPoint = new Point( currentSpatial.x+(scanPointOffset*Math.cos(angle)), currentSpatial.y+(scanPointOffset*Math.sin(angle)) );
		}
		
		private function newSpatial():void{
			if(Math.random() < 0.25){
				// 0.25 chance to scan targetSpatial (typically the player)
				currentSpatial = node.drone.targetSpatial;
			} else if (node.drone.neanderSpatials.length == 0){
				// go to a random point in scene and scan it
				currentSpatial = new Spatial(100+Math.random()*node.drone.bounds.width-200, 100+Math.random()*node.drone.bounds.height-200);
			} else {
				// get one of the spatials set in neanderSpatials
				var index:int = Math.round(Math.random()*(node.drone.neanderSpatials.length-1));
				currentSpatial = node.drone.neanderSpatials[index];
			}
		}
		
		private var currentSpatial:Spatial;
		
		private var scanPointOffset:Number = 200;
		private var scanPoint:Point;
		private var scanTime:int = 0;
		private var scanTimeMAX:int = 60;
		
		private var scanNum:int = 0;
		private var scanNumMAX:int = 4;
	}
}