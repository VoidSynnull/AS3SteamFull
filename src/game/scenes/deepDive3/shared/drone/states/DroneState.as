package game.scenes.deepDive3.shared.drone.states
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import game.scenes.deepDive3.shared.nodes.DroneNode;
	import game.systems.animation.FSMState;
	
	public class DroneState extends FSMState
	{
		public function DroneState()
		{
			super();
		}
		
		protected function flashLight($flashNum:int = 3):void{
			if(!light){
				light = node.display.displayObject["light"] as Sprite;
			}
			node.tween.to(light, 0.1, {alpha:1, yoyo:true, repeat:$flashNum+1, onComplete:resetLight});
		}
		
		protected function resetLight():void
		{
			if(!light){
				light = node.display.displayObject["light"] as Sprite;
			}
			node.tween.to(light, 0.2, {alpha:0});
		}
		
		protected function faceTargetSpatial():void
		{
			if(node.spatial.x < node.drone.lookAtSpatial.x){
				node.spatial.scaleX = -1;
			} else {
				node.spatial.scaleX = 1;
			}
		}
		
		protected function moveToPoint($point:Point, $precise:Boolean = true):Boolean  // return if reached
		{ 
			var origin:Point = new Point(node.spatial.x, node.spatial.y);
			// move to the point
			if(Point.distance(origin, $point) < 20){
				node.motion.zeroAcceleration();
				node.motion.zeroMotion();
				
				return true;
			} else {
				var dY:Number = $point.y - origin.y;
				var dX:Number = $point.x - origin.x;
				
				var angle:Number = Math.atan2(dY, dX);
				var accelPoint:Point = new Point(speed*Math.cos(angle),speed*Math.sin(angle));
				if($precise){
					node.motion.velocity = accelPoint;
				} else {
					node.motion.acceleration = accelPoint;
				}
				
				return false;
			}
		}
		
		public function get node():DroneNode{ return this._node as DroneNode }
		
		public static const IDLE:String = "idle";
		public static const SLEEP:String = "sleep";
		public static const WAKE:String = "wake";
		
		protected var light:Sprite;
		protected var speed:Number = 400;
	}
}