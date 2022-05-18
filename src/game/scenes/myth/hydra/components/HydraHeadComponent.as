package game.scenes.myth.hydra.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.components.hit.Hazard;
	
	public class HydraHeadComponent extends Component
	{
		public function HydraHeadComponent( hit:Entity, number:int )
		{
			var spatial:Spatial = hit.get( Spatial );
			startY = spatial.y;
			startX = spatial.x;
			
			headNumber = number;
			headHit = hit;
		}

		public var headTimeline:Timeline;
		//public var headTimelineClip:TimelineClip;
		public var headSpatial:Spatial;
		public var headHit:Entity;
		public var hitDisplay:Display;
		
		public var headNumber:int;
		public var startY:Number;
		public var startX:Number;
		
		public var seekTargetX:Number;
		public var seekTargetY:Number;
		
		public var attackTargetX:Number;
		public var attackTargetY:Number;
		
		public var hittable:Boolean = false;
		public var midBite:Boolean = false;
		public var stretch:Boolean = false;
		public var attack:Boolean = false
	
		public var hit:Boolean = false;
		public var dead:Boolean = false;
			
//		public var isHit:Boolean = false;
		public var state:String = 		"normal";
		
		public function removeHit():void
		{
			headHit.remove( Hazard );
		}
	}
}