package game.scenes.poptropolis.skiing.util
{
	public class SkiUtils
	{
		public function SkiUtils()
		{
		}
		
		public static function getSlopeAndConst(x1,y1,x2,y2):Object {
			var m:Number = (y2-y1)/(x2-x1)
			var b:Number = y2 - m*x2
			return ({m:m, b:b}) 
		}
	}
}