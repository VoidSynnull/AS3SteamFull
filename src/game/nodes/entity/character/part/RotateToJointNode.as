package game.nodes.entity.character.part
{
	import ash.core.Node;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.RotateToJoint;
	
	public class RotateToJointNode extends Node
	{
		public var display:Display;
		public var rig:Rig;
		public var rotateToJoint:RotateToJoint;
		public var spatial:Spatial;
	}
}