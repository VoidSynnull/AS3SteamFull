package game.scenes.deepDive1.shared.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Angler extends Component
	{
		public function Angler(originalLoc:Point, swimAccel:Number, min:Number = 1, max:Number = 2, retreatDist:Number = 300)
		{
			this.originalLoc = originalLoc;
			this.swimAccel = swimAccel;
			minWait = min;
			maxWait = max;
			retreatDistance = retreatDist;
			onEaten = new Signal();
		}
		
		public var minWait:Number;
		public var maxWait:Number;
		public var retreatDistance:Number;
		public var onEaten:Signal;
		
		public var lightOn:Boolean = false;
		public var feeding:Boolean;
		public var inZone:Boolean = false;
		
		public var swimAccel:Number; // make sure you adjust for direction
		public var originalLoc:Point; // the original starting location of the angler fish
		public var fishToEat:Entity; // only set once a fish is in range
	}
}