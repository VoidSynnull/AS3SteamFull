package game.scenes.virusHunter.bloodStream
{
	import flash.display.DisplayObject;
	
	import ash.core.Component;
	
	import game.data.display.BitmapWrapper;
	
	public class BloodStreamUpdate extends Component
	{
		public var shadingContainer:String 		= "shading";
		public var bloodCellContainer:String 	= "bloodCells";
		public var segmentContainer:String 		= "segments";
		
		public var segment:DisplayObject;
		public var bloodCell:DisplayObject;
		
		public var segments:Vector.<BitmapWrapper> = new Vector.<BitmapWrapper>();
		public var bloodCells:Vector.<BloodCell> = new Vector.<BloodCell>();
		
		public var offsetX:Number;
		public var offsetY:Number;
		
		public var time:Number = 0;
		public var segmentWait:Number = 0;
		
		public var velocityZ:Number = 100;
		public var engaged:Boolean = false;
		
		public function BloodStreamUpdate(segment:DisplayObject, bloodCell:DisplayObject)
		{
			this.segment 	= segment;
			this.bloodCell  = bloodCell;
		}
	}
}