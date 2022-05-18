package game.data.scene.hit 
{
	import flash.geom.Point;
	
	import org.osflash.signals.Signal;

	/**
	 * A data class for hit areas that move in a scene such as a moving platform.
	 */
	public class MovingHitData extends HitDataComponent
	{
		public var points:Array;
		public var velocity:Number;
		public var pointIndex:Number;
		public var friction:Point;
		public var loop:Boolean;
		public var teleportToStart:Boolean;
		public var pause:Boolean;
		public var reachedPoint:Signal = new Signal();
		public var reachedFinalPoint:Signal = new Signal();
	}
}