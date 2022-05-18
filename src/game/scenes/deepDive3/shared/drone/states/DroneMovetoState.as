package game.scenes.deepDive3.shared.drone.states
{
	import flash.geom.Point;

	public class DroneMovetoState extends DroneState
	{
		public function DroneMovetoState()
		{
			super.type = "moveto";
		}
		
		override public function start():void
		{
			node.motionControl.moveToTarget = false; // disable motionControl (need something more precise)
		}
		
		override public function update(time:Number):void
		{
			// watch follow target
			faceTargetSpatial();

			// move to drone's targetSpatial precicely within 15px)
			moveToPoint(new Point(node.drone.targetSpatial.x, node.drone.targetSpatial.y));
		}
	}
}