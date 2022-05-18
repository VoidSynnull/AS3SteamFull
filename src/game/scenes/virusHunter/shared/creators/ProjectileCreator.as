package game.scenes.virusHunter.shared.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.EntityType;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.hit.MovieClipHit;
	import game.managers.EntityPool;
	import game.scenes.virusHunter.shared.BulletView;
	import game.scenes.virusHunter.shared.components.Projectile;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;

	public class ProjectileCreator
	{
		public function ProjectileCreator(pool:EntityPool, group:Group)
		{
			_pool = pool;
			_group = group;
			
			//_pool.setSize("projectile", 20);
		}
				
		public function create(weapon:Weapon, parentSpatial:Spatial, rotation:Number, container:DisplayObjectContainer, parentMotion:Motion, parentHit:MovieClipHit, offset:Number = 0):Entity
		{
			var projectile:Entity = _pool.request(/*weapon.type*/"projectile");
			var motion:Motion;
			var sleep:Sleep;
			var spatial:Spatial;
			var hit:MovieClipHit;
			var display:Display;
			var projectileComponent:Projectile;
			var type:EntityType;
			var id:Id;
			
			rotation *= (Math.PI / 180);
			
			var cos:Number = Math.cos(rotation);
			var sin:Number = Math.sin(rotation);
			
			if(projectile != null)
			{
				display = projectile.get(Display);
				hit = projectile.get(MovieClipHit);
				hit.isHit = false;
				motion = projectile.get(Motion);
				sleep = projectile.get(Sleep);
				sleep.sleeping = false;
				projectile.ignoreGroupPause = false;
				spatial = projectile.get(Spatial);
				projectileComponent = projectile.get(Projectile);
				type = projectile.get(EntityType);
				id = projectile.get(Id);
				
				if(weapon.projectileColor != projectileComponent.color || weapon.projectileSize != projectileComponent.size || weapon.type != projectileComponent.type)
				{
					container.removeChild(display.displayObject);
					display.displayObject = new BulletView(weapon.projectileColor, weapon.projectileSize) as DisplayObjectContainer;
					container.addChild(display.displayObject);
					
					if(weapon.type == WeaponType.GOO)
					{
						createGoo(display.displayObject, weapon);
					}
				}
			}
			else
			{
				var bullet:DisplayObjectContainer = new BulletView(weapon.projectileColor, weapon.projectileSize) as DisplayObjectContainer;
				container.addChild(bullet);
				projectileComponent = new Projectile();
				
				if(weapon.type == WeaponType.GOO)
				{
					createGoo(bullet, weapon);
				}
				
				motion = new Motion();
				sleep = new Sleep();
				sleep.ignoreOffscreenSleep = true;
				spatial = new Spatial();
				hit = new MovieClipHit();
				//hit.shapeHit = true;
				display = new Display(bullet);
				
				type = new EntityType();
				id = new Id();
				
				projectile = new Entity()
					.add(projectileComponent)
					.add(spatial)
					.add(display)
					.add(sleep)
					.add(hit)
				    .add(type)
					.add(id)
					.add(motion);
				
				_group.addEntity(projectile);
			}
			
			spatial.scale = 1;
			
			if(weapon.type == WeaponType.GOO)
			{
				projectileComponent.spin = 7 - Math.random() * 14;
			}
			else
			{
				projectileComponent.spin = 0;
			}
			
			id.id = hit.type = parentHit.type + "Projectile";
			hit.validHitTypes = new Dictionary();
			
			if(weapon.type == WeaponType.ENEMY_GUN)
			{
				hit.validHitTypes["ship"] = true;
			}
			else
			{
				hit.validHitTypes[EnemyType.ENEMY_HIT] = true;
			}
			
			/*
			for(var n:String in parentHit.validHitTypes)
			{
				hit.validHitTypes[n] = true;
			}
			*/
			type.type = weapon.type;
			
			projectileComponent.lifespan = weapon.projectileLifespan;
			projectileComponent.type = weapon.type;
			projectileComponent.level = weapon.level;
			projectileComponent.color = weapon.projectileColor;
			projectileComponent.size = weapon.projectileSize;
			
			spatial.x = cos * weapon.offsetX - sin * (weapon.offsetY + offset) + parentSpatial.x;
			spatial.y = sin * weapon.offsetX + cos * (weapon.offsetY + offset) + parentSpatial.y;

			display.displayObject.x = motion.x = motion.previousX = spatial.x;
			display.displayObject.y = motion.y = motion.previousY = spatial.y;
			
			motion.velocity = new Point(cos * weapon.velocity + parentMotion.velocity.x, sin * weapon.velocity + parentMotion.velocity.y);
			
			return(projectile);
		}
		
		private function createGoo(container:DisplayObjectContainer, weapon:Weapon):void
		{
			var bullet:DisplayObjectContainer;
			
			for(var x:int = 0; x < 6; x++)
			{
				bullet = new BulletView(weapon.projectileColor, weapon.projectileSize + (3 - Math.random() * 4)) as DisplayObjectContainer;
				container.addChild(bullet);
				bullet.x += (8 - Math.random() * 16);
				bullet.y += (8 - Math.random() * 16);
				bullet.alpha = Math.random() * 1;
			}
		}
		
		public function releaseEntity(entity:Entity):void
		{
			var hit:MovieClipHit = entity.get(MovieClipHit);
			hit.isHit = false;
			hit._colliderId = null;
			var sleep:Sleep = entity.get(Sleep);
			sleep.sleeping = true;
			entity.ignoreGroupPause = true;
			_pool.release(entity, "projectile"/*Id(entity.get(Id)).id*/);
		}
		
		private var _pool:EntityPool;
		private var _group:Group;
	}
}