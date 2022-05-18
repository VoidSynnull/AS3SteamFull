package game.scenes.backlot.soundStage1.KeepWithInDistanceSystem
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import org.osflash.signals.Signal;
	
	public class KeepWithInDistance extends Component
	{
		public var keepTrack:Boolean;
		
		public var minMax:Point;//x for min y for max
		// if distance > min will start counting against you
		// if distance > max will out right signal a loss
		public var offTime:Number;
		
		public var looseTime:Number;
		
		public var target:Spatial;
		
		public var loose:Signal;
		
		public var lost:Boolean;
		public function KeepWithInDistance(minMax:Point, looseTime:Number, target:Spatial, keepTrack:Boolean)
		{
			this.keepTrack = keepTrack;
			this.minMax = minMax;
			this.looseTime = looseTime;
			this.target = target;
			offTime = 0;
			loose = new Signal();
			lost = false;
		}
	}
}