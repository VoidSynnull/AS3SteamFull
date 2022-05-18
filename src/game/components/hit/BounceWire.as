package game.components.hit
{
	import ash.core.Component;
	
	public class BounceWire extends Component
	{
		public var radius:Number;
		public var lineColor:uint;
		public var lineSize:Number = 3;
		public var hitChild:String;
		public var tension:Number;
		public var dampening:Number;
	}
}