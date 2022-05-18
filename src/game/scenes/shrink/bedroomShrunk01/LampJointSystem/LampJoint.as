package game.scenes.shrink.bedroomShrunk01.LampJointSystem
{
	import ash.core.Component;
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	
	public class LampJoint extends Component
	{
		public var connectedJoint:FollowTarget;
		public var joint:Spatial;
		public var root:Boolean;
		public var defaultRotation:Number;
		public var maxRotation:Number;
		public function LampJoint(joint:Spatial,connectedJoint:FollowTarget = null, rotation:Number = 0, root:Boolean = false)
		{
			this.root = root;
			this.connectedJoint = connectedJoint;
			this.joint = joint;
			this.defaultRotation = joint.rotation;
			this.maxRotation = defaultRotation + rotation;
			if(connectedJoint == null)
				root = true;
		}
	}
}