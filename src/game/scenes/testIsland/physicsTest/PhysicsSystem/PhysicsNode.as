package game.scenes.testIsland.physicsTest.PhysicsSystem
{
	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.testIsland.physicsTest.Collider.Collider;
	import game.scenes.testIsland.physicsTest.RigidBody;
	
	public class PhysicsNode extends Node
	{
		public var collider:Collider;
		public var spatial:Spatial;
		public var motion:Motion;
		public var rigidBody:RigidBody;
		public var optional:Array = [Motion, RigidBody];
	}
}