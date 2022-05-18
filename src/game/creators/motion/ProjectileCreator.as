package game.creators.motion
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.EntityType;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.hit.Hazard;
	import game.creators.scene.HitCreator;
	import game.data.scene.hit.HazardHitData;
	import game.managers.EntityPool;
	import game.scene.template.BulletView;
	import game.components.hit.Gun;
	import game.components.hit.Projectile;
	import game.util.GeomUtils;

	public class ProjectileCreator
	{
		public function ProjectileCreator(pool:EntityPool, group:Group)
		{
			_pool = pool;
			_group = group;
			_hitCreator = new HitCreator();
		}
				
		public function create(gun:Gun, weaponSpatial:Spatial, rotation:Number, container:DisplayObjectContainer, weaponMotion:Motion = null, weaponBarrelOffset:Number = 0):Entity
		{
			var projectile:Entity = _pool.request("projectile");
			var motion:Motion;
			var sleep:Sleep;
			var spatial:Spatial;
			var display:Display;
			var projectileComponent:Projectile;
			var id:Id;
			
			rotation *= (Math.PI / 180);
			
			var cos:Number = Math.cos(rotation);
			var sin:Number = Math.sin(rotation);
			
			if(projectile != null)
			{
				display = projectile.get(Display);
				motion = projectile.get(Motion);
				sleep = projectile.get(Sleep);
				sleep.sleeping = false;
				projectile.ignoreGroupPause = false;
				spatial = projectile.get(Spatial);
				projectileComponent = projectile.get(Projectile);
				id = projectile.get(Id);
				
				if(gun.projectileColor != projectileComponent.color || gun.projectileSize != projectileComponent.size || gun.type != projectileComponent.type)
				{
					container.removeChild(display.displayObject);
					display.displayObject = new BulletView(gun.projectileColor, gun.projectileSize) as DisplayObjectContainer;
					container.addChild(display.displayObject);
				}
			}
			else
			{
				var bullet:DisplayObjectContainer = new BulletView(gun.projectileColor, gun.projectileSize) as DisplayObjectContainer;
				container.addChild(bullet);
				projectileComponent = new Projectile();

				motion = new Motion();
				sleep = new Sleep();
				sleep.ignoreOffscreenSleep = true;
				spatial = new Spatial();
				display = new Display(bullet);
				
				id = new Id();
				
				projectile = new Entity()
					.add(projectileComponent)
					.add(spatial)
					.add(display)
					.add(sleep)
					.add(id)
					.add(motion);
												
				_group.addEntity(projectile);
			}
			
			// if a weapon specifies spin rates...
			if(gun.projectileSpinRateMin || gun.projectileSpinRateMax)
			{
				// use a consistent value if min and max rates are equal, otherwise pick a random rate.
				if(gun.projectileSpinRateMin == gun.projectileSpinRateMax)
				{
					projectileComponent.spin = gun.projectileSpinRateMax;
				}
				else
				{
					projectileComponent.spin = GeomUtils.randomInRange(gun.projectileSpinRateMin, gun.projectileSpinRateMax);
				}
			}
			else
			{
				projectileComponent.spin = 0;
			}
			
			id.id = gun.type;
			
			projectileComponent.lifespan = gun.projectileLifespan;
			projectileComponent.type = gun.type;
			projectileComponent.level = gun.level;
			projectileComponent.color = gun.projectileColor;
			projectileComponent.size = gun.projectileSize;
			
			spatial.x = cos * gun.offsetX - sin * (gun.offsetY + weaponBarrelOffset) + weaponSpatial.x;
			spatial.y = sin * gun.offsetX + cos * (gun.offsetY + weaponBarrelOffset) + weaponSpatial.y;
			spatial.scale = 1;
			
			display.displayObject.x = motion.x = motion.previousX = spatial.x;
			display.displayObject.y = motion.y = motion.previousY = spatial.y;
			
			motion.rotation = 0;
			
			var velocityX:Number = cos * gun.velocity;
			var velocityY:Number = sin * gun.velocity;
			
			if(weaponMotion != null)
			{
				if (weaponMotion.velocity.x * velocityX > 0)
				{
					velocityX += weaponMotion.velocity.x;
				}
				
				if (weaponMotion.velocity.y * velocityY > 0)
				{
					velocityY += weaponMotion.velocity.y;
				}
			}
			
			var hasHazard:Boolean = projectile.has(Hazard);
			
			if(!hasHazard && gun.hazardHitData != null)
			{
				makeHazard(projectile, gun.hazardHitData);
			}
			else if(hasHazard && gun.hazardHitData == null)
			{
				projectile.remove(Hazard);
			}
			
			motion.velocity = new Point(velocityX, velocityY);
			
			return(projectile);
		}
			
		private function makeHazard(entity:Entity, hazardHitData:HazardHitData):void
		{			
			var hit:Hazard = new Hazard();
			
			hit.velocity = hazardHitData.knockBackVelocity;
			hit.coolDown = hazardHitData.knockBackCoolDown;
			hit.interval = hazardHitData.knockBackInterval;
			hit.velocityByHitAngle = hazardHitData.velocityByHitAngle;
			
			// bounding box overlap test is more efficient for projectiles.
			hit.boundingBoxOverlapHitTest = true;
			
			entity.add(hit);
		}
		
		public function releaseEntity(entity:Entity):void
		{
			var sleep:Sleep = entity.get(Sleep);
			sleep.sleeping = true;
			entity.ignoreGroupPause = true;
			_pool.release(entity, "projectile");
		}
		
		private var _pool:EntityPool;
		private var _group:Group;
		private var _hitCreator:HitCreator;
	}
}