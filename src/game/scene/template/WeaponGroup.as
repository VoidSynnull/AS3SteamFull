package game.scene.template
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.creators.motion.ProjectileCreator;
	import game.creators.motion.WeaponCreator;
	import game.managers.EntityPool;
	import game.systems.SystemPriorities;
	import game.systems.hit.HazardHitSystem;
	import game.systems.hit.ProjectileAgeSystem;
	import game.systems.hit.ProjectileHitSystem;
	import game.systems.hit.WeaponControlSystem;
	import game.systems.hit.WeaponInputMapSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;
	
	public class WeaponGroup extends Group
	{
		public function WeaponGroup()
		{
			super();
			super.id = GROUP_ID;
		}
		
		public function setupScene(scene:Scene, container:DisplayObjectContainer):void
		{
			_scene = scene;
			_container = container;
			_entityPool = new EntityPool();
			_projectileCreator = new ProjectileCreator(_entityPool, this);
			_weaponCreator = new WeaponCreator(_projectileCreator);
			
			this.weaponLoaded = new Signal();
			this.allWeaponsLoaded = new Signal();

			super.addSystem(new RotateToTargetSystem(), SystemPriorities.move);
			super.addSystem(new ProjectileAgeSystem(_projectileCreator), SystemPriorities.update);
			super.addSystem(new WeaponControlSystem(_projectileCreator, container), SystemPriorities.update);
			super.addSystem(new WeaponInputMapSystem(), SystemPriorities.update);			
			super.addSystem(new MotionTargetSystem(), SystemPriorities.move);
			super.addSystem(new TargetEntitySystem(), SystemPriorities.update);	
			super.addSystem(new HazardHitSystem(), SystemPriorities.resolveCollisions);
			super.addSystem(new ProjectileHitSystem(_projectileCreator), SystemPriorities.resolveCollisions);
		}
		
		public function loadGun(gunData:GunData, container:DisplayObjectContainer = null):Entity
		{
			var entity:Entity = new Entity();
			entity.add(new Spatial(gunData.x, gunData.y));
			super.addEntity(entity);
			
			if(container == null)
			{
				container = _container;
			}
			
			_loading++;
			
			EntityUtils.loadAndSetToDisplay(container, gunData.asset, entity, _scene, Command.create(gunLoaded, gunData));
			
			return entity;
		}
		
		public function makeGun(entity:Entity, gunData:GunData):void
		{
			_weaponCreator.makeGun(entity, gunData, _scene.getGroupById(AudioGroup.GROUP_ID) as AudioGroup);
		}
		
		private function gunLoaded(clip:MovieClip, entity:Entity, gunData:GunData):void
		{
			makeGun(entity, gunData);
			
			this.weaponLoaded.dispatch(entity);
			
			_loading--;
			
			if(_loading == 0)
			{
				allLoaded();
			}
		}
		
		private function allLoaded():void
		{
			this.allWeaponsLoaded.dispatch();
		}
		
		public static const GROUP_ID:String = "weaponGroup";
		public var allWeaponsLoaded:Signal;
		public var weaponLoaded:Signal;
		private var _loading:int;
		private var _weaponCreator:WeaponCreator;
		private var _projectileCreator:ProjectileCreator;
		private var _entityPool:EntityPool;
		private var _container:DisplayObjectContainer;
		private var _scene:Scene;
	}
}