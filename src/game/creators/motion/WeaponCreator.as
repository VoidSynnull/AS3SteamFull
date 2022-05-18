package game.creators.motion
{
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Sleep;
	import game.components.motion.RotateControl;
	import game.components.motion.TargetSpatial;
	import game.scene.template.AudioGroup;
	import game.scene.template.GunData;
	import game.components.hit.Gun;
	import game.components.hit.WeaponControl;
	import game.components.hit.WeaponControlInput;
	import game.components.hit.WeaponSlots;

	public class WeaponCreator
	{
		public function WeaponCreator(projectileCreator:ProjectileCreator)
		{
		}
						
		public function makeGun(entity:Entity, data:GunData, audioGroup:AudioGroup = null):void
		{
			if(data.allowSleep)
			{
				entity.add(new Sleep(!data.makeActive, data.ignoreOffscreenSleep));
			}
			
			var gun:Gun = data.gunComponent;
			var weaponControl:WeaponControl = new WeaponControl();
			
			if(gun.type == null)
			{
				gun.type = "gun";
			}
			
			weaponControl.lockWhenInputInactive = data.lockWhenInputInactive;
			
			if(data.fireKey)
			{
				entity.add(new WeaponControlInput(data.fireKey));
			}
			
			weaponControl.fire = data.autoFire;
			
			entity.add(gun);
			
			if(data.target != null)
			{
				var rotateControl:RotateControl = new RotateControl();
				rotateControl.origin = entity.get(Spatial);
				rotateControl.targetInLocal = data.targetInLocal;
				rotateControl.ease = .8;
				entity.add(rotateControl);
				entity.add(new TargetSpatial(data.target));
			}
			
			entity.add(weaponControl);
			entity.add(new Id(gun.type));
			
			if(data.interactions != null)
			{
				InteractionCreator.addToEntity(entity, data.interactions);
			}
			
			// if an entity will use several weapons...
			if(data.addToSlot)
			{
				var weaponSlots:WeaponSlots = entity.get(WeaponSlots);
				
				if(weaponSlots == null)
				{
					weaponSlots = new WeaponSlots();
					entity.add(weaponSlots);
				}
				
				weaponSlots.slots[gun.type] = entity;
	
				if(data.makeActive)
				{
					weaponSlots.active = entity;
					gun.state = gun.ACTIVE;
				}
				else
				{
					gun.state = gun.INACTIVE;
				}
			}
			else
			{
				gun.state = gun.ACTIVE;
			}
			
			if(audioGroup) 
			{ 
				audioGroup.addAudioToEntity(entity); 
			}
		}
		
		private var _projectileCreator:ProjectileCreator;
	}
}