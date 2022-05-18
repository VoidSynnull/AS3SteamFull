package game.scenes.virusHunter.brain.components
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	public class IKReach extends Component
	{
		public function IKReach($segmentPrefix:String, $display:DisplayObject, $segWidth:Number, $startAtInt:int = 0)
		{
			segmentPrefix = $segmentPrefix; // string prefix for segments such as "ik_node###"
			display = $display; // reference to display that contains the segments.
			startAtInt = $startAtInt;
			segWidth = $segWidth; 
			
			storeSegments();
		}
		
		protected function storeSegments():void{
			segments = new Vector.<IKSegment>;
			
			var c:int = startAtInt;
			while(display[segmentPrefix+c] != null){
				segments.push(new IKSegment(display[segmentPrefix+c], segWidth));
				c++;
			}
		}
		
		public function revertToOriginal():void{
			// revert to original "form"
			// have each segment tween back to original form
			if(reverting == false){
				
				for each(var ikSegment:IKSegment in segments){
					TweenLite.to(ikSegment.display, 1, {x:ikSegment.origPoint.x, y:ikSegment.origPoint.y, rotation:ikSegment.origRotation});
				}
				reverting = true;
				reachPoint = new Point(revertPoint.x, revertPoint.y); // reset reach point
				connectedToPoint = null;
			}
		}

		public var display:DisplayObject;
		public var segmentPrefix:String;
		public var segWidth:Number;
		public var startAtInt:int;
		public var segments:Vector.<IKSegment>;
		public var targetEntity:Entity; // target entity - will target the entity's display x/y + grabRadius
		public var grabRadius:Number; // a radius outside the target entity to "grab" onto
		public var revertPoint:Point;
		
		public var reachPoint:Point = new Point(); // end point of IKReach's amature
		public var reaching:Boolean = false; // in the process of reaching if true - reach for reachPoint, if false - revert back to original shape/form
		public var reverting:Boolean = false; // in the process of reverting back to its original shape/form
		public var connectedToPoint:Point;
		public var pauseMotion:Boolean = false;
		public var hitWaitTime:Number = 0;
		public var minHitWaitTime:Number = 1;
	}
}