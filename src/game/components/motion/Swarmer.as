package game.components.motion
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Swarmer extends Component
	{
		public function Swarmer(agnWt:Number = 8, sepWt:Number = 5, coWt:Number = 6, wanWt:Number = 4, tetWt:Number = 10)
		{
			alignWeight = agnWt;
			separationWeight = sepWt;
			cohesionWeight = coWt;
			wanderWeight = wanWt;
			tetherWeight = tetWt;
		}
		
		public var obstacles:Vector.<Entity>;
		public var followTarget:FollowTarget;
		
		public var avoidWeight:Number;
		public var tetherWeight:Number;		
		public var alignWeight:Number;
		public var separationWeight:Number;
		public var cohesionWeight:Number;
		public var wanderWeight:Number;	
		public var followWeight:Number;
		
		public var tether:Number = 200; // distance from scene ends to turn around at
		public var wanderRadius:Number = 40;
		public var wanderAngle:Number = 0;
		public var wanderDist:Number = 400;
		public var wanderMax:Number = 90;
	}
}