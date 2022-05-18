package game.scenes.testIsland.physicsTest
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.scenes.testIsland.physicsTest.Collider.Collider;
	import game.scenes.testIsland.physicsTest.Collider.ColliderMaterial;
	import game.scenes.testIsland.physicsTest.ColliderTypes.BoxCollider;
	import game.scenes.testIsland.physicsTest.ColliderTypes.LineCollider;
	import game.scenes.testIsland.physicsTest.ColliderTypes.SphereCollider;
	import game.util.EntityUtils;

	public class PhysicsObjectCreator
	{
		public static function addBoxColliderToEntity(entity:Entity, bounds:Rectangle, insideOut:Boolean = false, colliderMaterial:ColliderMaterial = null):Entity
		{
			return entity.add( new Collider(new BoxCollider(bounds, insideOut), entity, colliderMaterial));
		}
		
		public static function addSphereColliderToEntity(entity:Entity, radius:Number, colliderMaterial:ColliderMaterial = null):Entity
		{
			return entity.add(new Collider(new SphereCollider(radius), entity, colliderMaterial));
		}
		
		public static function addLineColliderToEntity(entity:Entity, points:Vector.<Point>, colliderMaterial:ColliderMaterial = null):Entity
		{
			return entity.add( new Collider(new LineCollider(points), entity, colliderMaterial));
		}
		
		public static function createEntityWithBoxCollider(group:Group, display:DisplayObjectContainer, container:DisplayObjectContainer, giveRigidBody:Boolean = false):Entity
		{
			var entity:Entity;
			if(giveRigidBody)
			{
				entity = EntityUtils.createMovingEntity(group, display, container);
				entity.add(new RigidBody(entity.get(Motion)));
			}
			else
				entity = EntityUtils.createSpatialEntity(group, display, container);
			
			entity.add(new Sleep());
			
			addBoxColliderToEntity(entity, display.getBounds(display));
			
			return entity;
		}
		
		public static function createEntityWithSphereCollider(group:Group, display:DisplayObjectContainer, container:DisplayObjectContainer, giveRigidBody:Boolean = false):Entity
		{
			var entity:Entity;
			if(giveRigidBody)
			{
				entity = EntityUtils.createMovingEntity(group, display, container);
				entity.add(new RigidBody(entity.get(Motion)));
			}
			else
				entity = EntityUtils.createSpatialEntity(group, display, container);
			
			entity.add(new Sleep());
			
			addSphereColliderToEntity(entity, display.width / 2);
			
			return entity;
		}
		
		public static function createEntityWithLineCollider(group:Group, points:Vector.<Point>, container:DisplayObjectContainer, giveRigidBody:Boolean = false):Entity
		{
			var entity:Entity;
			var display:MovieClip = new MovieClip();
			if(giveRigidBody)
			{
				entity = EntityUtils.createMovingEntity(group, display, container);
				entity.add(new RigidBody(entity.get(Motion)));
			}
			else
				entity = EntityUtils.createSpatialEntity(group, display, container);
			
			entity.add(new Sleep());
			
			addLineColliderToEntity(entity, points);
			
			return entity;
		}
	}
}