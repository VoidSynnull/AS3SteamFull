package game.components.hit
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class SeeSaw extends Component
	{
		public function SeeSaw(lmass:Number, rmass:Number, lMaxAngle:Number = -20, rMaxAngle:Number = 20, followingDisplay:Entity = null)
		{
			leftMass = lmass;
			rightMass = rmass;
			leftMaxAngle = lMaxAngle;
			rightMaxAngle = rMaxAngle;
			follow = followingDisplay;
			maxTiltReached = new Signal(Entity, Boolean);
			changedDirections = new Signal(Entity, Boolean);
			maxedLeft = maxedRight = false;
		}
		
		public var follow:Entity
		public var rightMass:Number;
		public var leftMass:Number;
		public var leftMaxAngle:Number;
		public var rightMaxAngle:Number;
		public var maxTiltReached:Signal;
		public var maxedLeft:Boolean;
		public var maxedRight:Boolean;
		public var tiltingRight:Boolean;
		public var changedDirections:Signal;
	}
}