package game.scenes.shrink.bedroomShrunk01.LampJointSystem
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	
	public class JointedLamp extends Component
	{
		public var joints:Vector.<LampJoint>;
		public var tweens:int;
		public var tweenPosition:int = 0;
		public var tweenTime:Number = 0;
		public var time:Number = 0;
		public var onLamp:Boolean = false;
		public var tweening:Boolean = false;
		
		public function JointedLamp(tweens:int = 3, tweenTime:Number = 1,joints:Vector.<LampJoint> = null)
		{
			this.tweens = tweens;
			this.tweenTime = tweenTime;
			
			if(joints == null)
				joints = new Vector.<LampJoint>();
			
			this.joints = joints;
		}
		
		public function setUpJoinOfLight(joint:Entity,parent:Spatial,positionOffset:Point,rotationOffset:Number = 0,rotation:Number = 0):void
		{
			if(parent == null)
				joint.add(new LampJoint(joint.get(Spatial),null,rotation,true));
			else
			{
				var follow:FollowTarget = new FollowTarget(parent,1,false,true);
				follow.offset = positionOffset;
				follow.rotationOffSet = rotationOffset;
				follow.properties = new Vector.<String>();
				follow.properties.push("x","y","rotation");
				joint.add(follow).add(new LampJoint(joint.get(Spatial),follow,rotation));
			}
			
			if(rotation != 0)
				joints.push(joint.get(LampJoint));
		}
		
		public function get lampIsDown():Boolean{return tweens == tweenPosition;}
	}
}