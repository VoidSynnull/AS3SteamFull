package game.components.motion
{	
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	import org.osflash.signals.Signal;
	
	public class FollowTarget extends Component
	{
		public function FollowTarget( target:Spatial = null, rate:Number = 1, applyCameraOffset:Boolean = false, accountForRotation:Boolean = false, allowXFlip:Boolean = false)
		{
			reachSignal = new Signal();
			this.target = target;
			this.rate = rate;
			this.applyCameraOffset = applyCameraOffset;
			this.accountForRotation = accountForRotation;
			this.allowXFlip = allowXFlip;
			properties = new <String>["x","y"];
		}
		
		public var accountForRotation:Boolean;
		public var rotationOffSet:Number = 0;
		public var reachSignal:Signal;
		public var isTargetReached:Boolean = false;
		public var target:Spatial;
		public var rate:Number;			// rate at which follower will track to target, 1 is a one-to-one rate
		public var properties:Vector.<String>;
		public var offset:Point;
		public var applyCameraOffset:Boolean;
		public var allowXFlip:Boolean;
	}
}