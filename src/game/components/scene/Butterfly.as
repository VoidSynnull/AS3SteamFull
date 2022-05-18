package game.components.scene
{
	import com.greensock.easing.Sine;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.entity.OriginPoint;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.util.Utils;
	
	public class Butterfly extends Component
	{
		public var distanceX:Number = 100;
		public var distanceY:Number = 100;
		public var maxDuration:Number = 4;
		public var minDuration:Number = 2;
		
		public function Butterfly()
		{
			super();
		}
		
		public function move(entity:Entity):void
		{
			var originPoint:OriginPoint = entity.get(OriginPoint);
			var x:Number = originPoint.x + Utils.randNumInRange(-distanceX, distanceX);
			var y:Number = originPoint.y + Utils.randNumInRange(-distanceY, distanceY);
			
			var duration:Number = Utils.randNumInRange(minDuration, maxDuration);
			
			var waveData:WaveMotionData;
			var wave:WaveMotion = entity.get(WaveMotion);
			waveData = wave.dataForProperty("y");
			waveData.rate = Utils.randNumInRange(1, 2);
			
			var tween:Tween = entity.get(Tween);
			tween.to(entity.get(Spatial), duration, {x:x, y:y, ease:Sine.easeInOut, onComplete:move, onCompleteParams:[entity]});
		}
	}
}