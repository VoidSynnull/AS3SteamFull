package game.scenes.virusHunter.brain.systems
{
	import com.greensock.TimelineLite;
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.brain.components.IKSegment;
	import game.scenes.virusHunter.brain.components.TentacleReach;
	import game.scenes.virusHunter.brain.nodes.IKReachNode;
	
	public class TentacleReachSystem extends IKReachSystem
	{
		public function TentacleReachSystem($container:DisplayObjectContainer, $group:Group)
		{
			super($container, $group);
		}
		
		override protected function updateNode($node:IKReachNode, $time:Number):void{
			
			for each(var ikReachEntity:Entity in $node.ikReachBatch.tentacleBatch){
				var ikReach:TentacleReach = TentacleReach(ikReachEntity.get(TentacleReach));
				var targetPoint:Point;
				var rightClaw:Entity;
				var leftClaw:Entity;
				if(ikReach.reaching == true){
					if(ikReach.reaching == true){
						
						if(ikReach.display.name == "tenticleRight"){
							var rightClawPoint:Point = localToLocal(ikReach.display["ikNode_0"], _container);
							rightClaw = _sceneGroup.getEntityById("rightClaw");
							Spatial(rightClaw.get(Spatial)).x = rightClawPoint.x;
							Spatial(rightClaw.get(Spatial)).y = rightClawPoint.y;
						} else {
							var leftClawPoint:Point = localToLocal(ikReach.display["ikNode_0"], _container);
							leftClaw = _sceneGroup.getEntityById("leftClaw");
							Spatial(leftClaw.get(Spatial)).x = leftClawPoint.x;
							Spatial(leftClaw.get(Spatial)).y = leftClawPoint.y;
						}
						
						// reach for player ship 
						var targetDisplay:Display = ikReach.targetEntity.get(Display);
						
						if(_shipPoint == null){
							_shipPoint = localToLocal(targetDisplay.displayObject, ikReach.display);
						}
						
						//targetPoint = _shipPoint;
						
						targetPoint = localToLocal(targetDisplay.displayObject, ikReach.display); // follow ship
						
						//_waving = false;
					
					} else {
						// reach for a random wave pattern-NOT DONE YET
						/*var centerPoint:Point = localToLocal(_container["boss"], ikReach.display); // target center
						var rotation:Number = _container["boss"].rotation;
						
						if(ikReach.display.name == "tenticleRight"){
							centerPoint.x += _waveOffset.x; // add 200 - check trig
							centerPoint.y += _waveOffset.y;
						} else {
							centerPoint.x -= _waveOffset.x;
							centerPoint.y += _waveOffset.y;
						}
						
						targetPoint = centerPoint;
						
						if(_waving == false){
							_waving = true;
							// if not waving, then start the wave
							
						}*/
					}
					
					if(ikReach.display.name == "tenticleRight"){
						if(_targetRightPoint != targetPoint){
							_targetRightPoint = targetPoint;
							_rightTween = new TweenLite(ikReach.reachPoint, 0.8, {x:_targetRightPoint.x, y:_targetRightPoint.y});
						}
					} else {
						if(_targetLeftPoint != targetPoint){
							_targetLeftPoint = targetPoint;
							_leftTween = new TweenLite(ikReach.reachPoint, 1, {x:_targetLeftPoint.x, y:_targetLeftPoint.y});
						}
					}
					
					// start ik sequence
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
				}	else {
					
					// kill and null tweens
					if(_rightTween){
						if(_rightTween.active){
							_rightTween.kill();
						}
						_rightTween = null;
					}
					if(_leftTween){
						if(_leftTween.active){
							_leftTween.kill();
						}
						_leftTween = null;
					}
					
					// revert back to original form
					_shipPoint = null;
					ikReach.revertToOriginal();
					
					if(ikReach.display.name == "tenticleRight"){
						//var rightClawPoint:Point = localToLocal(ikReach.display["ikNode_0"], _container);
						rightClaw = _sceneGroup.getEntityById("rightClaw");
						Spatial(rightClaw.get(Spatial)).x = 0;
						Spatial(rightClaw.get(Spatial)).y = 0;
					} else {
						//var leftClawPoint:Point = localToLocal(ikReach.display["ikNode_0"], _container);
						leftClaw = _sceneGroup.getEntityById("leftClaw");
						Spatial(leftClaw.get(Spatial)).x = 0;
						Spatial(leftClaw.get(Spatial)).y = 0;
					}
					
				}
			}
		}
		
		private var _leftTween:TweenLite;
		private var _rightTween:TweenLite;
		
		private var _shipPoint:Point;
		private var _targetRightPoint:Point;
		private var _targetLeftPoint:Point;
		
		private var _waveLine:TimelineLite;
		private var _waving:Boolean = false;
		private var _waveOffset:Point = new Point(200,0);
	}
}