package game.systems.motion
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.components.motion.IKControl;
	import game.components.motion.IKSegment;
	import game.nodes.motion.IKNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class IKSystem extends GameSystem
	{
		public function IKSystem()
		{
			super(IKNode, updateNode);
			super._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:IKNode, time:Number):void
		{
			var control:IKControl = node.control;
			var nextSegment:IKSegment = node.control.head.next;
			var currentSpatial:Spatial;
			var previousSpatial:Spatial;
			var target:Point = reach(node.control.head, new Point(node.targetSpatial.target.x, node.targetSpatial.target.y), node.control);
			
			while(nextSegment != null)
			{
				reach(nextSegment.previous, target, control);
				nextSegment = nextSegment.next;
			}
			
			nextSegment = node.control.head.next;
			
			while(nextSegment != null)
			{
				position(nextSegment.previous, nextSegment, control);
				nextSegment = nextSegment.next;
			}
			// determine target, may want to apply a rate to it, so you can ease to it
			
			// update target starting from control.tail, use while loop, may want apply an angle max to prevent 'crimping'
			
			// update segment spatial using new target, starting from control.head, use while loop
		}
		
		public function reach(segment:IKSegment, target:Point, control:IKControl):Point
		{
			var currentSpatial:Spatial = segment.spatial;
			var dx:Number = target.x - currentSpatial.x;
			var dy:Number = target.y - currentSpatial.y;
			var angle:Number = Math.atan2(dy, dx);
			currentSpatial.rotation = angle * 180 / Math.PI;
			
			var pin:Point = getPin(segment);
			var w:Number = pin.x - currentSpatial.x;
			var h:Number = pin.y - currentSpatial.y;
			var tx:Number = target.x - w;
			var ty:Number = target.y - h;
			
			return(new Point(tx, ty));
		}
		
		public function position(target:IKSegment, current:IKSegment, control:IKControl):void
		{
			var pin:Point = getPin(target);
			current.spatial.x = pin.x;
			current.spatial.y = pin.y;
		}
		
		public function getPin(segment:IKSegment):Point
		{
			var spatial:Spatial = segment.spatial;
			var angle:Number = spatial.rotation * Math.PI / 180;
			var xPos:Number = spatial.x + Math.cos(angle) * segment.size;
			var yPos:Number = spatial.y + Math.sin(angle) * segment.size;
			
			return new Point(xPos, yPos);
		}
		/*
		for each(var ikReachEntity:Entity in $node.ikReachBatch.ikReachBatch){
			var ikReach:IKReach = IKReach(ikReachEntity.get(IKReach));
			
			if(_targetPoint != new Point(ikReach.container.mouseX, ikReach.container.mouseY)){
				_targetPoint = new Point(ikReach.container.mouseX, ikReach.container.mouseY);
				var tween:TweenLite = new TweenLite(ikReach.reachPoint, 3, {x:_targetPoint.x, y:_targetPoint.y});
			}
			
			//var target:Point = reach(ikReach.segments[0], ikReach.container.mouseX, ikReach.container.mouseY);
			var target:Point = reach(ikReach.segments[0], ikReach.reachPoint.x, ikReach.reachPoint.y);
			//var target:Point = reach(ikReach.segments[0], _targetPoint.x, _targetPoint.y);
			
			// get targets
			for each(var ikSegment:IKSegment in ikReach.segments)
			{
				target = reach(ikSegment, target.x, target.y);
			}
			
			// position segments
			for(var i:int = ikReach.segments.length - 1; i > 0; i--)
			{
				var segmentA:IKSegment = ikReach.segments[i];
				var segmentB:IKSegment = ikReach.segments[i - 1];
				position(segmentB, segmentA);
			}
		}
	}
	
	private function reach(segment:IKSegment, xpos:Number, ypos:Number):Point
	{
		var dx:Number = xpos - segment.display.x;
		var dy:Number = ypos - segment.display.y;
		var angle:Number = Math.atan2(dy, dx);
		segment.display.rotation = angle * 180 / Math.PI;
		
		var w:Number = segment.getPin().x - segment.display.x;
		var h:Number = segment.getPin().y - segment.display.y;
		var tx:Number = xpos - w;
		var ty:Number = ypos - h;
		return new Point(tx, ty);
	}
		
		private function position($segmentA:IKSegment, $segmentB:IKSegment):void
		{
		$segmentA.display.x = $segmentB.getPin().x;
		$segmentA.display.y = $segmentB.getPin().y;
		}
		*/
	}
}