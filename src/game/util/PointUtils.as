package game.util
{
	import flash.geom.Point;

	public class PointUtils
	{
		public static function times(point:Point, timesBy:Number):Point
		{
			return new Point(point.x * timesBy, point.y * timesBy);
		}
		
		public static function multiply(point1:Point, point2:Point):Point
		{
			return new Point(point1.x * point2.x, point1.y * point2.y);
		}
		
		public static function getRadiansBetweenPoints(start:Point, end:Point):Number
		{
			return Math.atan2(end.y - start.y, end.x - start.x);
		}
		
		public static function getRadiansOfTrajectory(trajectory:Point):Number
		{
			return Math.atan2(trajectory.y, trajectory.x);
		}
		
		public static function getUnitDirectionOfAngle(angle:Number):Point
		{
			return new Point(Math.cos(angle), Math.sin(angle));
		}
		
		public static function getUnitDirectionOfVector(point:Point):Point
		{
			var direction:Number = getRadiansOfTrajectory(point);
			return getUnitDirectionOfAngle(direction);
		}
		
		public static function getMagnitude(point:Point):Number
		{
			return Math.sqrt(point.x * point.x + point.y * point.y);
		}
		
		public static function createTrajectory(direction:Number, magnitude:Number):Point
		{
			var vector:Point = getUnitDirectionOfAngle(direction);
			return times(vector, magnitude);
		}
	}
}