package game.scenes.shrink.bedroomShrunk01.LampJointSystem
{
	import game.systems.GameSystem;
	
	public class JointedLampSystem extends GameSystem
	{
		public function JointedLampSystem()
		{
			super(JointedLampNode, updateNode);
		}
		
		// make it so that the lamp bends
		
		public function updateNode(node:JointedLampNode, time:Number):void
		{
			if(node.lamp.tweenPosition >= node.lamp.tweens)
				return;
			
			if(node.lamp.tweening)
			{
				node.lamp.time += time;
				if(node.lamp.time > node.lamp.tweenTime)
				{
					node.lamp.tweening = false;
					node.lamp.tweenPosition++;
					return;
				}
				for(var i:int = 0; i < node.lamp.joints.length; i++)
				{
					tweenJoint(node.lamp.joints[i],node.lamp,time)
				}
				return;
			}
			if(node.entityIdList.entities.length > 0)
			{
				if(!node.lamp.onLamp)
				{
					node.lamp.tweening = true;
					node.lamp.onLamp = true;
					node.lamp.time = 0;
				}
			}
			else
				node.lamp.onLamp = false;
		}
		
		private function tweenJoint(joint:LampJoint, lamp:JointedLamp,time:Number):void
		{
			var fullRotation:Number = joint.maxRotation - joint.defaultRotation;
			
			var rotation:Number = fullRotation * time / lamp.tweens;
			
			if(joint.root)
				joint.joint.rotation += rotation;
			else
				joint.connectedJoint.rotationOffSet += rotation;
		}
	}
}