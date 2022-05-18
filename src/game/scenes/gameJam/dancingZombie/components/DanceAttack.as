package game.scenes.gameJam.dancingZombie.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import game.util.DataUtils;
	
	// component to fire attack pattern across dance floor
	public class DanceAttack extends Component
	{
		//public const patternsColors:Array  = [0xff0000, 0x00ff00, 0x0000ff, 0xffff00, 0x00ffff];
		
		public var patternId:String ="";
		// vector of points that flow out from dancer in order to hit zombies
		public var patternPoints:Vector.<Point> = new Vector.<Point>();
		public var patternIndex:int = 0;
		
		public var lightColor:uint = 0Xff000;
		// data file for all patterns
		private var data:XML;
		
		public function DanceAttack(patternId:String, data:XML)
		{
			this.patternId = patternId;
			this.data = data;
			parsePattern();
		}
		
		private function parsePattern():void
		{
			var patterns:XMLList = data.pattern;
			var points:XMLList;
			// get the attack we want from xml
			for each (var pattern:XML in patterns) 
			{
				if(pattern.attribute("id") == patternId){
					points = pattern.point;
					break;
				}
			}
			for each (var point:XML in points) 
			{
				var pt:Point = DataUtils.getPoint(point);
				patternPoints.push(pt);
				trace("POINT:"+pt);
			}
			// get color
			this.lightColor = DataUtils.getUint(pattern.color);
		}
		
		override public function destroy():void
		{
			patternPoints.splice(0,patternPoints.length);
			patternPoints = null;
			data = null;
			super.destroy();
		}
	}
}