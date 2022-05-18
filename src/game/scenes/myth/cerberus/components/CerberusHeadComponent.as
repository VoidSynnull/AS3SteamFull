package game.scenes.myth.cerberus.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	
	public class CerberusHeadComponent extends Component
	{
		public function CerberusHeadComponent( time:Number )
		{
			timer = time;
		}
		
		public var isBlinking:Boolean = false;
		public var isHit:Boolean = false;
		public var state:String = 	"idle";
		
		public var rotation:Number = 0;
		
		public var faceNeutral:Number = 0;
		
		public var faceTimeline:Timeline;
		public var blinkTimeline:Timeline;
		
		public var faceSpatial:Spatial;
		public var neckSpatial:Spatial;
		public var blinkSpatial:Spatial;
		
		public var hitDisplay:Display;
		
		public var hit:Entity;
		
		public var timer:Number = 0;
		public var blinkCounter:Number = 0;
		public var hitCounter:Number = 0;
		public var snoreCounter:Number = 0;
 	}
}