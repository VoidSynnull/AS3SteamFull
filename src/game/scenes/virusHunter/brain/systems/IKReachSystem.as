package game.scenes.virusHunter.brain.systems
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.scenes.virusHunter.brain.components.IKReach;
	import game.scenes.virusHunter.brain.components.IKSegment;
	import game.scenes.virusHunter.brain.nodes.IKReachNode;
	
	public class IKReachSystem extends ListIteratingSystem
	{
		public function IKReachSystem($container:DisplayObjectContainer, $group:Group)
		{
			_sceneGroup = $group;
			_container = $container;
			super(IKReachNode, updateNode);
		}
		
		protected function updateNode($node:IKReachNode, $time:Number):void{
			for each(var ikReachEntity:Entity in $node.ikReachBatch.ikReachBatch){
				var ikReach:IKReach = IKReach(ikReachEntity.get(IKReach));
				if(ikReach.reaching == true){
					
					var targetDisplay:Display = ikReach.targetEntity.get(Display);
					var targetPoint:Point = localToLocal(targetDisplay.displayObject, ikReach.display);
				
					if(_targetPoint != targetPoint){
						_targetPoint = targetPoint;
						var tween:TweenLite = new TweenLite(ikReach.reachPoint, 1, {x:_targetPoint.x, y:_targetPoint.y});
					}
					
					var target:Point = reach(ikReach.segments[0], ikReach.reachPoint.x, ikReach.reachPoint.y);
					
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
				} else {
					ikReach.revertToOriginal();
				}
			}
		}
		
		protected function reach(segment:IKSegment, xpos:Number, ypos:Number):Point
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
		
		protected function position($segmentA:IKSegment, $segmentB:IKSegment):void
		{
			$segmentA.display.x = $segmentB.getPin().x;
			$segmentA.display.y = $segmentB.getPin().y;
		}
		
		protected function localToLocal(fr:DisplayObject, to:DisplayObject):Point {
			// super awesome useful snippet :)
			return to.globalToLocal(fr.localToGlobal(new Point()));
		}
		
		protected var _targetPoint:Point = new Point();
		protected var _smoothPoint:Point = new Point();
		protected var _smoothTween:TweenLite;
		
		protected var _container:DisplayObjectContainer;
		protected var _sceneGroup:Group;
	}
}