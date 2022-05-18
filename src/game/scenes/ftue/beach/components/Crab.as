package game.scenes.ftue.beach.components
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class Crab extends Component
	{
		public var leftHole:Spatial;
		public var rightHole:Spatial;
		public var leftBlocked:Boolean;
		public var rightBlocked:Boolean;
		public var speed:Number;
		public var hidingLeft:Boolean;
		public var scurry:Number;
		public var startScurrying:Boolean;
		public var hasWrench:Boolean;
		public var scurryDistance:Number;
		
		public function Crab(leftHole:Spatial, rightHole:Spatial, speed:Number = 250, startLeft:Boolean = true, scurry:Number = 200)
		{
			this.leftHole = leftHole;
			this.rightHole = rightHole;
			this.speed = speed;
			hidingLeft = startLeft;
			leftBlocked = rightBlocked = startScurrying = false;
			this.scurry = scurryDistance = scurry;
		}
	}
}