package game.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	import game.data.photobooth.TransformData;
	
	public class TransformTool extends Component
	{
		public var updateTarget:Boolean;
		public var initPoint:Point;
		public var currentPoint:Point;
		public var transformDatas:Vector.<TransformData>;
		public var transformComplete:Signal;
		public var transformStart:Signal;
		
		public function TransformTool()
		{
			transformComplete = new Signal(Entity);
			transformStart = new Signal(Entity);
			transformDatas = new Vector.<TransformData>();
		}
		
		public function addTransformData(property:String, scale:Number = 1, valueIncrement:Number = NaN):void
		{
			transformDatas.push(new TransformData(property, scale, valueIncrement));
		}
	}
}