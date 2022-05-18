package game.scenes.testIsland.physicsTest.PhysicsSystem
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import game.scenes.testIsland.physicsTest.LineSegment;
	import game.scenes.testIsland.physicsTest.Collider.ColliderMaterial;
	import game.scenes.testIsland.physicsTest.Collider.ColliderType;
	import game.scenes.testIsland.physicsTest.Collider.Collision;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.PointUtils;
	
	public class PhysicsSystem extends GameSystem
	{
		public function PhysicsSystem(showHits:Boolean = false, container:DisplayObjectContainer = null)
		{
			super(PhysicsNode, updateNode);
			this._defaultPriority = SystemPriorities.checkCollisions;
			
			if(showHits)
			{
				display = new MovieClip();
				var hits:Entity = EntityUtils.createSpatialEntity(group, display, container);
			}
			this.showHits = showHits;
		}
		
		public const GRAVITY:Number = 481;
		
		private var hitList:NodeList;
		
		private var display:MovieClip;
		public var showHits:Boolean;
		
		
		override public function addToEngine( systemManager:Engine ):void 
		{
			hitList = systemManager.getNodeList( PhysicsNode );
			super.addToEngine(systemManager);
		}
		
		public function updateNode(node:PhysicsNode, time:Number):void
		{
			if(node.motion == null || node.rigidBody == null)
				return;
			
			if(node.motion.pause)
				return;
			
			if(showHits)
				display.graphics.clear();
			
			if(node.rigidBody.useGravity)
				node.rigidBody.addForce(new Point(0, 1),GRAVITY, time);
			
			node.rigidBody.timeStep = time;
			
			node.collider.staticCollisions = new Vector.<Collision>();
			node.collider.elasticCollisions = new Vector.<Collision>();
			
			for(var other:PhysicsNode = hitList.head; other; other = other.next)
			{
				if(node == other)
					continue;
				
				node.collider.colliderType.checkIfHit(other.collider, this);
			}
			
			var force:Point = new Point(node.motion.velocity.x * node.rigidBody.mass, node.motion.velocity.y * node.rigidBody.mass);
			var magnitude:Number = PointUtils.getMagnitude(force);
			var trajectoryAngle:Number = PointUtils.getRadiansOfTrajectory(force);
			
			var newVelocity:Point = new Point();
			
			var newTorque:Number = 0;
			
			var validCollisions:Number = 0;
			
			var averageStaticCollision:Collision = ColliderType.getAverageCollision(node.collider.staticCollisions);
			
			var averageElasticCollision:Collision = ColliderType.getAverageCollision(node.collider.elasticCollisions, true);
			var collision:Collision;
			
			if(averageStaticCollision != null)
			{
				collision = averageStaticCollision;
				
				var myMat:ColliderMaterial = collision.myCollider.colliderMaterial;
				var otherMat:ColliderMaterial = collision.otherCollider.colliderMaterial;
				
				var bounce:Number = ColliderMaterial.getPropertyValue(ColliderMaterial.BOUNCE, myMat, otherMat);
				
				var friction:Number = ColliderMaterial.getPropertyValue(ColliderMaterial.FRICTION, myMat, otherMat);
				
				var normalAngle:Number = PointUtils.getRadiansOfTrajectory(collision.normal);
				
				if(Math.abs(normalAngle - trajectoryAngle) > Math.PI / 2 && Math.abs(normalAngle - collision.intersectedLine.radians) > Math.PI / 2)
				{
					node.collider.colliderType.moveOutOfCollision(collision);
					
					var newTrajectoryAngle:Number = normalAngle * 2 - trajectoryAngle + Math.PI;
					
					var trajectory:Point = PointUtils.createTrajectory(newTrajectoryAngle, magnitude);
					
					var frictionDirection:Point = new Point(-node.motion.velocity.x * Math.abs(1 - collision.normal.x), -node.motion.velocity.y * Math.abs(1 - collision.normal.y));
					
					trace(trajectory + collision.normal + " " + (1 - bounce));
					
					var lostVelocity:Point = PointUtils.times(collision.normal, (1 - bounce) * PointUtils.getMagnitude(trajectory));
					
					trajectory = trajectory.subtract(lostVelocity);
					
					newVelocity = newVelocity.add(trajectory);
					
					validCollisions++;
				}
			}
			
			if(averageElasticCollision != null)
			{
				collision = averageStaticCollision;
				
				// take care of rigid body collisions dealing with momentum and such
			}
			
			/*// tried looping through, but it made things messy
			for(var i:int = 0; i < collisions.length; i++)
			{
				var collision:Collision = collisions[i];
				
				if(showHits)
					drawCircle(collision.hitPosition, 5, 0xFF0000);
				
				var myMat:ColliderMaterial = collision.myCollider.colliderMaterial;
				var otherMat:ColliderMaterial = collision.otherCollider.colliderMaterial;
				
				var bounce:Number = ColliderMaterial.getPropertyValue(ColliderMaterial.BOUNCE, myMat, otherMat);
				
				var friction:Number = ColliderMaterial.getPropertyValue(ColliderMaterial.FRICTION, myMat, otherMat);
				
				var normalAngle:Number = PointUtils.getRadiansOfTrajectory(collision.normal);
				
				if(Math.abs(normalAngle - trajectoryAngle) < Math.PI / 2)
					continue;
				
				node.collider.colliderType.moveOutOfCollision(collision);
				
				var newTrajectoryAngle:Number = normalAngle * 2 - trajectoryAngle + Math.PI;
				
				var trajectory:Point = PointUtils.createTrajectory(newTrajectoryAngle, magnitude);
				
				var frictionDirection:Point = new Point(-node.motion.velocity.x * Math.abs(1 - collision.normal.x), -node.motion.velocity.y * Math.abs(1 - collision.normal.y));
				
				trace(trajectory + collision.normal + " " + (1 - bounce));
				
				var lostVelocity:Point = PointUtils.times(collision.normal, (1 - bounce) * PointUtils.getMagnitude(trajectory));
				
				trajectory = trajectory.subtract(lostVelocity);
				
				newVelocity = newVelocity.add(trajectory);
				
				//node.rigidBody.addTorque(bounceDirection, 1 + bounce, time, collision.hitPosition);
				
				//node.rigidBody.addForceAtPoint(frictionDirection, collision.hitPosition, 1 + friction, time);
			}
			//*/
			if(validCollisions > 0)
			{
				newVelocity = PointUtils.times(newVelocity, 1 / validCollisions);
				
				node.motion.velocity = newVelocity;
			}
		}
		
		public function drawLine(line:LineSegment, color:Number = -1):void
		{
			display.graphics.lineStyle(2, color);
			display.graphics.moveTo(line.start.x, line.start.y);
			display.graphics.lineTo(line.end.x, line.end.y);
		}
		
		public function drawCircle(origin:Point, radius:Number, color:Number = -1):void
		{
			if(color == -1)
				color = 0xFFFFFF * Math.random();
			
			display.graphics.lineStyle(2, color);
			display.graphics.drawCircle(origin.x, origin.y, radius);
		}
		
		override public function removeFromEngine( systemManager:Engine ):void 
		{
			systemManager.releaseNodeList( PhysicsNode );
			hitList = null;
			super.removeFromEngine(systemManager);
		} 
	}
}