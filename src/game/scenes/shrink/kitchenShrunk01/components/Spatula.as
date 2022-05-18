package game.scenes.shrink.kitchenShrunk01.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import game.components.hit.HitTest;
	import game.util.PointUtils;
	
	public class Spatula extends Component
	{
		public var handleHit:HitTest;
		public var headHit:HitTest;
		
		public var maxRotation:Number;
		public var atMax:Boolean = true;
		public var trajectoryAmplification:Number;
		
		public var handleTrajectory:Point;
		public var headTrajectory:Point;
		
		public function Spatula(handleHit:HitTest, headHit:HitTest, maxRotation:Number = 15, trajectoryAmplification:Number = 1):void
		{
			this.handleHit = handleHit;
			this.headHit = headHit;
			this.maxRotation = maxRotation;
			this.trajectoryAmplification = trajectoryAmplification;
			
			handleTrajectory = new Point(0, -1);
			headTrajectory = PointUtils.getUnitDirectionOfAngle((-maxRotation - 90) * Math.PI / 180);
			trace(headTrajectory);
		}
	}
}