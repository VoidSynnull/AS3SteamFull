package game.systems.dragAndDrop
{
	import ash.core.Component;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Drop extends Component
	{
		public var dropZone:RectangleZone;
		public var refundable:Boolean;
		public var hideContents:Boolean;
		public var rejectInvalidIds:Boolean;
		public var enabled:Boolean;
		
		public function Drop(refundable:Boolean = true, hideContents:Boolean = false, dropZone:RectangleZone = null, rejectInvalidIds:Boolean = true)
		{
			if(dropZone == null)
				dropZone = new RectangleZone();
			this.refundable = refundable;
			this.hideContents = hideContents;
			this.dropZone = dropZone;
			this.rejectInvalidIds = rejectInvalidIds;
			enabled = true;
		}
	}
}