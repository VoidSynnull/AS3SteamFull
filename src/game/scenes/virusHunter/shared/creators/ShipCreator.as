package game.scenes.virusHunter.shared.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.EntityType;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.components.motion.Edge;
	import game.components.audio.HitAudio;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.entity.Sleep;
	import game.components.motion.TargetSpatial;
	import game.components.entity.character.Player;
	import game.components.entity.collider.BitmapCollider;
	import game.components.hit.CurrentHit;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.motion.RotateControl;
	import game.components.hit.MovieClipHit;
	import game.scene.template.AudioGroup;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Melee;
	import game.scenes.virusHunter.shared.components.Ship;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	import game.scenes.virusHunter.shared.components.WeaponControlInput;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shipDemo.GameHud;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;

	public class ShipCreator
	{
		public function ShipCreator(group:Group, audioGroup:AudioGroup = null)
		{
			_group = group;
			_audioGroup = audioGroup;
		}
		
		public function create(container:DisplayObjectContainer, clip:MovieClip, x:Number, y:Number, bounds:Rectangle, id:String = null):Entity
		{
			var entity:Entity = new Entity();		
			var spatial:Spatial = new Spatial(x, y);			
			var motion:Motion = new Motion();
			motion.friction 	= new Point(0, 0);
			motion.minVelocity 	= new Point(0, 0);
			motion.maxVelocity 	= new Point(400, 400);
			
			var motionControlBase:MotionControlBase = new MotionControlBase();
			motionControlBase.acceleration = 1200;
			motionControlBase.stoppingFriction = 500;
			motionControlBase.accelerationFriction = 200;
			//motionControlBase.maxVelocityByTargetDistance = 500;
			motionControlBase.freeMovement = true;
			
			var edge:Edge = new Edge();
			edge.unscaled.setTo(-50, -50, 100, 100);
			
			var damageTarget:DamageTarget = new DamageTarget();
			damageTarget.damageFactor = new Dictionary();
			damageTarget.damageFactor[WeaponType.ENEMY_GUN] = 1;
			damageTarget.maxDamage = 4;
			damageTarget.cooldown = .5;
			damageTarget.reactToInvulnerableWeapons = false;
			
			var movieClipHit:MovieClipHit = new MovieClipHit("ship");
			clip.mouseEnabled = false;
			movieClipHit.hitDisplay = clip["hit"];
			movieClipHit.hitDisplay.mouseEnabled = false;
			
			var display:Display = new Display(clip, container);
			
			entity.add(damageTarget);
			entity.add(edge);
			entity.add(spatial);
			entity.add(display);
			entity.add(motion);
			entity.add(new MotionControl());
			entity.add(new MotionTarget());
			entity.add(new Navigation());
			entity.add(new RadialCollider());
			var bitmapCollider:BitmapCollider = new BitmapCollider();
			bitmapCollider.addAccelerationToVelocityVector = true;
			entity.add(bitmapCollider);
			entity.add(new SceneCollider());
			entity.add(new ZoneCollider());
			entity.add(movieClipHit);
			entity.add(new MotionBounds(bounds));
			entity.add(new Audio());
			entity.add(new HitAudio());
			entity.add(new CurrentHit());
			entity.add(motionControlBase);
			entity.add(new Ship());
			entity.add(new WeaponSlots());
			entity.add(new WeaponControlInput(Keyboard.SPACE));
			entity.add(new Tween());
			
			if(id != null) { entity.add(new Id(id)); }
			
			/*
			var platformCollider:PlatformCollider = new PlatformCollider();
			entity.add(platformCollider);
			*/
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			entity.add(sleep);
			
			container.addChild(clip);
			
			if(_audioGroup) { _audioGroup.addAudioToEntity(entity); }
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
			{
				addEyes(entity, clip["bioSuit"]["leftPupil"]);
				addEyes(entity, clip["bioSuit"]["rightPupil"]);
			}
			
			return(entity);
		}
		
		private function addEyes(parent:Entity, pupil:MovieClip):void
		{
			var entity:Entity = new Entity();
			entity.add(new Spatial(pupil.x, pupil.y));
			entity.add(new Display(pupil));
			entity.add(new Id("playerEye"));
			
			entity.add(new TargetSpatial(_group.shellApi.inputEntity.get(Spatial)));
			var rotateControl:RotateControl = new RotateControl();
			rotateControl.origin = parent.get(Spatial);
			rotateControl.targetInLocal = true;
			rotateControl.ease = .2;
			entity.add(rotateControl);
			
			EntityUtils.addParentChild(entity, parent);
			
			_group.addEntity(entity);
		}
		
		public function changeGunLevel(ship:Entity, direction:Number, setLevel:Boolean = false):void
		{
			var weaponSlots:WeaponSlots = ship.get(WeaponSlots);
			var gun:Weapon = Entity(weaponSlots.slots[WeaponType.GUN]).get(Weapon);
			var level:int;
			
			if(setLevel)
			{
				level = direction;
			}
			else
			{
				level = gun.level + direction;
			}
			
			if(level <= gun.maxLevel && level > -1)
			{
				gun.level = level;
				
				if(ship.get(Player))
				{
					_group.shellApi.setUserField("gunLevel", level, _group.shellApi.island);
				}
				
				var lifespan:Array = [1.5, 1.5, 1.5, 1.5, 1.5];
				var color:Array = [0xfff300, 0xffcc33, 0xfff300, 0x99ffff, 0xffffff];
				var shotInterval:Array = [.3, .25, .2, .2, .2];
				var damage:Array = [1, 1.2, 1.5, 2, 2.5];
				var velocity:Array = [600, 600, 600, 600, 600];
				var size:Array = [3, 4, 5, 6, 7];
				
				gun.projectileLifespan = lifespan[level];
				gun.projectileColor = color[level];
				gun.projectileSize = size[level];
				gun.minimumShotInterval = shotInterval[level];
				gun.damage = damage[level];
				gun.velocity = velocity[level];
				
				var hud:GameHud = _group.getGroupById("gameHud") as GameHud;
				
				if(hud)
				{
					hud.shipLevelDisplay.text = String(level + "/" + gun.maxLevel);
				}
			}
		}
		
		public function addWeapon(ship:Entity, weapon:Weapon, displayObject:DisplayObjectContainer, target:Spatial, makeActive:Boolean = false):Entity
		{
			var entity:Entity = new Entity();	
			var spatial:Spatial = new Spatial(0, 0);
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			var rotateControl:RotateControl = new RotateControl();
			rotateControl.origin = ship.get(Spatial);
			rotateControl.targetInLocal = true;
			//rotateControl.velocity = 400;
			rotateControl.ease = .8;
			
			var weaponControl:WeaponControl = new WeaponControl();
			
			// must click to aim on touchscreen.
			if(PlatformUtils.isMobileOS)
			{
				weaponControl.lockWhenInputInactive = true;
			}
			
			entity.add(weapon);
			entity.add(new EntityType(weapon.type));
			entity.add(spatial);
			entity.add(new Display(displayObject));
			entity.add(rotateControl);
			entity.add(new TargetSpatial(target));
			entity.add(weaponControl);
			entity.add(new Id(weapon.type));
			entity.add(sleep);
			
			InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN]);
			
			EntityUtils.addParentChild(entity, ship, true);
			
			var weaponSlots:WeaponSlots = ship.get(WeaponSlots);
			
			if(weaponSlots == null)
			{
				weaponSlots = new WeaponSlots();
				ship.add(weaponSlots);
			}
			
			weaponSlots.slots[weapon.type] = entity;
			
			weapon.activeX = displayObject["body"].x;
			weapon.activeY = displayObject["body"].y;
			
			if(makeActive)
			{
				weaponSlots.active = entity;
				weapon.state = weapon.ACTIVE;
				sleep.sleeping = false;
			}
			else
			{
				rotateControl.manualTargetRotation = weapon.selectionRotation;
				displayObject["body"].x = 0;
				displayObject["body"].y = 0;
				Display(entity.get(Display)).visible = false;
				weapon.state = weapon.INACTIVE;
				sleep.sleeping = true;
			}
			
			if(weapon.type == WeaponType.SCALPEL || weapon.type == WeaponType.SHOCK)
			{
				var hit:MovieClipHit = new MovieClipHit("shipMelee");
				hit.shapeHit = false;
				var melee:Melee = new Melee();
				melee.range = 150;
				
				if(weapon.type == WeaponType.SHOCK)
				{
					melee.range = 100;
				}
				
				entity.add(hit);
				entity.add(melee);
			}
			
			_audioGroup.addAudioToEntity(entity);
			
			return(entity);
		}
		
		private var _group:Group;
		private var _audioGroup:AudioGroup;
	}
}