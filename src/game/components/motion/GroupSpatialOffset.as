package game.components.motion
{
	import ash.core.Component;
	import engine.components.SpatialOffset;

	public class GroupSpatialOffset extends Component
	{
		public function GroupSpatialOffset()
		{
			
		}
		
		public var offsets:Vector.<SpatialOffset> = new Vector.<SpatialOffset>();
	}
}