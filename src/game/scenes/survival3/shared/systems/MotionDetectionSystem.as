package game.scenes.survival3.shared.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.nodes.MotionNode;
	
	import game.scenes.survival3.shared.nodes.MotionDetecteeNode;
	import game.scenes.survival3.shared.nodes.MotionDetectionNode;
	import game.systems.SystemPriorities;
	
	public class MotionDetectionSystem extends System
	{
		private var _motion:NodeList;
		private var _motionSensors:NodeList;
		
		public function MotionDetectionSystem()
		{
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		override public function update(time:Number):void
		{
			for(var detector:MotionDetectionNode = _motionSensors.head; detector; detector = detector.next)
			{
				var motionDetected:Boolean = false;
				for(var detectee:MotionDetecteeNode = _motion.head; detectee; detectee = detectee.next)
				{
					if(detector.hitIds.entities.length > 0)
					{
						if(detected(detector, detectee) && !detector.motionDetection.motionDetected)
						{
							motionDetected = true;
						}
					}
				}
				if(motionDetected != detector.motionDetection.motionDetected)
				{
					detector.motionDetection.motionDetected = motionDetected;
					detector.motionDetection.detected.dispatch(detector.entity, motionDetected);
				}
			}
		}
		
		private function detected(detector:MotionDetectionNode, detectee:MotionDetecteeNode):Boolean
		{
			for(var i:int = 0; i < detector.hitIds.entities.length; i++)
			{
				var hitId:String = detector.hitIds.entities[i];
				if(hitId == detectee.id.id)
				{
					if(Math.abs(detectee.motion.lastVelocity.x) > detector.motionDetection.minVelDectection.x
						|| Math.abs(detectee.motion.lastVelocity.y) > detector.motionDetection.minVelDectection.y)
					{
						return true;
					}
				}
			}
			return false
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this._motion 	= systemManager.getNodeList(MotionDetecteeNode);
			this._motionSensors = systemManager.getNodeList(MotionDetectionNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(MotionNode);
			systemManager.releaseNodeList(MotionDetectionNode);
			
			this._motion 	= null;
			this._motionSensors = null;
		}
	}
}