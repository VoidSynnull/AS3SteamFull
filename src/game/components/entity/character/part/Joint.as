package game.components.entity.character.part
{	
	import ash.core.Component;
	
	import game.data.animation.entity.PartAnimationData;
	
	public class Joint extends Component
	{
		public static const PREFIX:String = "joint_";
		
		public var id:String;						// id for the joint, corresponds with animations
		public var partAnimData:PartAnimationData;	// rig animation data for part
		
		// associated with transform offset, currently not in use
		public var initX:Number = 0;
		public var initY:Number = 0;
		public var isSet:Boolean = false;
		public var ignoreRotation : Boolean = false;
		public var ignoreRig:Boolean = false;
	}
}
