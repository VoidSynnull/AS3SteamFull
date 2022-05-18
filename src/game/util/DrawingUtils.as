package game.util
{
	import flash.display.MovieClip;
	import flash.geom.Point;

	public class DrawingUtils
	{
		public static function curveThroughPoints(pointsArray:Array, artClip:MovieClip):void 
		{
			artClip.graphics.moveTo(pointsArray[0].x, pointsArray[0].y);
			if (pointsArray.length < 2) {
				return;
			}
			else if (pointsArray.length == 2) {
				artClip.graphics.lineTo(pointsArray[1].x, pointsArray[1].y);
				return;
			}
			
			for (var i:uint=1; i<pointsArray.length-1; i++) {
				var anchorPoint:Point = Point.interpolate(pointsArray[i], pointsArray[i+1], 0.5);
				if (i == pointsArray.length-2) {
					anchorPoint = pointsArray[i+1];
				}
				artClip.graphics.curveTo(pointsArray[i].x, pointsArray[i].y, anchorPoint.x, anchorPoint.y);
			}
		}
	}
}