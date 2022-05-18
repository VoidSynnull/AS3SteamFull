package game.components.motion
{
	import ash.core.Component;
	import engine.components.Spatial;

	public class IKSegment extends Component
	{
		public function IKSegment(size:Number = 20)
		{
			this.size = size;
		}
		
		public var previous:IKSegment;
		public var next:IKSegment;
		
		public var spatial:Spatial;	// reference to Spatial of owning Entity
		public var size:Number ;
	}
}