package game.scenes.testIsland.physicsTest.Collider
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.scenes.testIsland.physicsTest.RigidBody;
	
	
	public class Collider extends Component
	{
		public var colliderType:ColliderType;
		
		public var entity:Entity;
		
		public var rigidBody:RigidBody;
		
		public var spatial:Spatial;
		
		public var colliderMaterial:ColliderMaterial;
		
		public var staticCollisions:Vector.<Collision>;
		
		public var elasticCollisions:Vector.<Collision>;
		
		public function Collider(colliderType:ColliderType, entity:Entity, colliderMaterial:ColliderMaterial = null)
		{
			this.colliderType = colliderType;
			spatial = entity.get(Spatial);
			rigidBody = entity.get(RigidBody);
			this.colliderType.collider = this;
			
			if(colliderMaterial == null)
				this.colliderMaterial = new ColliderMaterial();
			else
				this.colliderMaterial = colliderMaterial;
			
			staticCollisions = new Vector.<Collision>();
			elasticCollisions = new Vector.<Collision>();
		}
	}
}