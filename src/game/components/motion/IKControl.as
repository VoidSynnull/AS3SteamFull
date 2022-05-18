package game.components.motion
{
	import ash.core.Component;
	//import engine.components.Spatial;


	public class IKControl extends Component
	{
		//public var segments:Vector.<IKSegment>;
		public var head:IKSegment;
		public var tail:IKSegment;
		public var length:Number;
		
		public var maxBend:Number;
		//public var target:Spatial;
	}
}