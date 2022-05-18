package game.scenes.examples.projectiles
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.hit.Gun;
	import game.components.hit.ProjectileCollider;
	import game.data.scene.hit.HazardHitData;
	import game.scene.template.GunData;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.WeaponGroup;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	
	public class Projectiles extends PlatformerGameScene
	{
		public function Projectiles()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/projectiles/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			setup();
			super.loaded();
		}
		
		private function setup():void
		{
			_weaponGroup = new WeaponGroup();
			super.addChildGroup(_weaponGroup);
			_weaponGroup.setupScene(this, super.hitContainer);
			_weaponGroup.allWeaponsLoaded.addOnce(allWeaponsLoaded);
			_weaponGroup.weaponLoaded.add(weaponLoaded);
			
			createBasicEnemyGun(1900, 550);
			createEnemyGun(500, 500);
			createPlayerGun();
		}
		
		// This creates a gun with a fixed firing angle that auto-fires continuously
		private function createBasicEnemyGun(x:Number, y:Number):void
		{
			// gun bullets should harm the player so define hitData.
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = 0;
			hazardHitData.knockBackVelocity = new Point(400, 400);
			hazardHitData.velocityByHitAngle = false;
			
			var gun:Gun = new Gun();
			gun.projectileColor = 0x00ff00;
			gun.projectileLifespan = 1.5;  // how long before projectile is removed.
			gun.velocity = 250;
			gun.offsetX = 77;              // distance projectiles should spawn from center (0,0)
			gun.minimumShotInterval = 1;
			gun.hazardHitData = hazardHitData;
			gun.type = "enemy";
			
			var gunData:GunData = new GunData();
			gunData.gunComponent = gun;
			gunData.x = x;
			gunData.y = y;
			gunData.autoFire = true;   // gun will fire automatically only limited by sleep and gun.minimumShotInterval.
			gunData.asset = super.groupPrefix + "gun.swf";
			
			var entity:Entity = _weaponGroup.loadGun(gunData);
			Spatial(entity.get(Spatial)).rotation = 140;   // manually set the fixed rotation.
		}
		
		private function createEnemyGun(x:Number, y:Number):void
		{
			// gun bullets should harm the player so define hitData.  Made it knock the player straight up in this case for fun.
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = 0;
			hazardHitData.knockBackVelocity = new Point(0, 400);
			hazardHitData.velocityByHitAngle = false;
			
			var gun:Gun = new Gun();
			gun.projectileColor = 0xff0000;
			gun.projectileLifespan = 1.5;  // how long before projectile is removed.
			gun.velocity = 250;
			gun.offsetX = 77;              // distance projectiles should spawn from center (0,0)
			gun.minimumShotInterval = .1;
			gun.hazardHitData = hazardHitData;
			gun.type = "enemy";
			
			var gunData:GunData = new GunData();
			gunData.gunComponent = gun;
			// optionally set a target if gun should follow spatial
			gunData.target = super.player.get(Spatial);
			// gun should target in scene-space since it is targeting the player in the scene
			gunData.targetInLocal = false;
			gunData.x = x;
			gunData.y = y;
			gunData.asset = super.groupPrefix + "gun.swf";
			// gun will fire when clicked and stop firing when released.
			gunData.interactions = [InteractionCreator.DOWN, InteractionCreator.UP];
			
			_weaponGroup.loadGun(gunData);
		}
		
		private function createPlayerGun():void
		{			
			var gun:Gun = new Gun();
			gun.projectileColor = 0x000066;
			gun.projectileLifespan = .75;
			gun.velocity = 800;
			gun.offsetX = 40;
			gun.minimumShotInterval = .1;
			
			var gunData:GunData = new GunData();
			gunData.gunComponent = gun;
			// follow mouse, so target in screen space.
			gunData.target = super.shellApi.inputEntity.get(Spatial);
			gunData.targetInLocal = true;
			gunData.x = 500;
			gunData.y = 500;
			gunData.asset = super.groupPrefix + "playerGun.swf";
			// gun fires with spacebar keydown and stops firing on spacebar keyup.
			gunData.fireKey = Keyboard.SPACE;
			gunData.interactions = [InteractionCreator.KEY_DOWN, InteractionCreator.KEY_UP];
			gunData.allowSleep = false; // no need for sleep as this will be a child of a Character.
			
			if(PlatformUtils.isMobileOS)
			{
				gunData.lockWhenInputInactive = true;
			}
			
			var gunEntity:Entity = _weaponGroup.loadGun(gunData);
			EntityUtils.addParentChild(gunEntity, super.player);
			EntityUtils.followTarget(gunEntity, super.player);
		}
		
		private function weaponLoaded(entity:Entity):void
		{
			var gun:Gun = entity.get(Gun);
			
			// if this is an enemy gun, allow it to be shot.  The ProjectileCollider.isHit or .hits property could then be used in
			//   a different System to allow it to take damage and be destroyed.
			if(gun.type == "enemy")
			{
				entity.add(new ProjectileCollider());
				
				var display:Display = entity.get(Display);
				
				entity.add(MotionUtils.boundsToEdge(display.displayObject, -20));
			}
		}
		
		private function allWeaponsLoaded():void
		{
			trace("all weapons loaded.");
		}
		
		private var _weaponGroup:WeaponGroup;
	}
}