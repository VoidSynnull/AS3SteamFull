package game.scenes.virusHunter.shared.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.EntityType;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.audio.HitAudio;
	import game.components.entity.Parent;
	import game.components.entity.Sleep;
	import game.components.hit.Hazard;
	import game.components.hit.MovieClipHit;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.IKControl;
	import game.components.motion.IKSegment;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.RotateControl;
	import game.components.motion.TargetEntity;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.managers.EntityPool;
	import game.particles.emitter.Burst;
	import game.scene.template.AudioGroup;
	import game.scenes.virusHunter.shared.components.Bacteria;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemyEye;
	import game.scenes.virusHunter.shared.components.EnemyGroup;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.EvoVirus;
	import game.scenes.virusHunter.shared.components.RedBloodCell;
	import game.scenes.virusHunter.shared.components.Virus;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	import game.scenes.virusHunter.shared.components.WhiteBloodCell;
	import game.scenes.virusHunter.shared.data.EnemyData;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.PickupType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shipDemo.components.OverlordEnemy;
	import game.scenes.virusHunter.shipDemo.components.PointValue;
	import game.scenes.virusHunter.shipDemo.components.SeekerEnemy;
	import game.scenes.virusHunter.shipDemo.components.ShooterEnemy;
	import game.scenes.virusHunter.shipDemo.components.SnakeEnemy;
	import game.scenes.virusHunter.shipDemo.components.SpinnerEnemy;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;

	public class EnemyCreator
	{
		public function EnemyCreator(pool:EntityPool, group:Group, container:DisplayObjectContainer, audioGroup:AudioGroup = null)
		{
			_pool = pool;
			_group = group;
			_container = container;
			_audioGroup = audioGroup;
			
			_total = new Dictionary();
			_pickupCreator = new PickupCreator(group, container);
		}
		
		public function createFromData(enemyData:EnemyData, x:Number, y:Number, randomPosition:Point, parent:Entity = null, childNumber:int = 0):Entity
		{
			var motion:Motion;
			var spatial:Spatial;
			var sleep:Sleep;
			var hit:MovieClipHit;
			var typeComponent:*;
			var entity:Entity = _pool.request(enemyData.type);
			var init:Boolean = false;
			var damageTarget:DamageTarget;
			var hazard:Hazard;
			var velocity:Point;
			var ikSegment:IKSegment;
			var ikControl:IKControl;
			var parentIkSegment:IKSegment;
			var weapon:Weapon;
			
			if(!_total[enemyData.type]) { _total[enemyData.type] = 0; }
			_total[enemyData.type]++;
			
			hit = new MovieClipHit(EnemyType.ENEMY_HIT, "ship", "shipMelee");
			
			var aimTarget:Spatial = this.target;
			
			if(parent)
			{
				aimTarget = parent.get(Spatial);
			}
			
			if(entity == null)
			{
				init = true;
				entity = new Entity();
				motion = new Motion();
				motion.friction 	= new Point(enemyData.friction, enemyData.friction);
				motion.minVelocity 	= new Point(0, 0);
				motion.maxVelocity = new Point(enemyData.maxVelocity, enemyData.maxVelocity);
				sleep = new Sleep();
				sleep.useEdgeForBounds = true;
				sleep.ignoreOffscreenSleep = enemyData.ignoreOffscreenSleep;
				spatial = new Spatial();
				spatial.scale = enemyData.scale;
				hazard = new Hazard();
				damageTarget = new DamageTarget();
				damageTarget.damageFactor = new Dictionary();
				damageTarget.damageFactor[WeaponType.GUN] = 1;
				damageTarget.damageFactor[WeaponType.SCALPEL] = 1;
				damageTarget.hitParticleColor1 = 0x33d1eff;
				damageTarget.hitParticleColor2 = 0xffffffff;
				damageTarget.hitParticleVelocity = .8;
				
				_group.shellApi.loadFile(_group.shellApi.assetPrefix + enemyData.asset, assetLoaded, entity, _container);
				
				entity.add(spatial);
				entity.add(new Id(enemyData.type + enemyData.level));
				entity.add(new Audio());
				entity.add(new AudioRange(600, 0.01, 1));
				entity.add(new HitAudio());
				if(_audioGroup) { _audioGroup.addAudioToEntity(entity); }
				entity.add(sleep);
				entity.add(motion);
				entity.add(new Edge(200, 200, 200, 200));
				entity.add(damageTarget);
				entity.add(new EntityType(enemyData.type));
				entity.add(hit);
				entity.add(hazard);
				entity.add(new PointValue(enemyData.value));
				
				if(enemyData.followTarget)
				{
					var motionControlBase:MotionControlBase = new MotionControlBase();
					motionControlBase.acceleration = enemyData.acceleration;
					motionControlBase.freeMovement = true;
					motionControlBase.accelerate = true;
					
					entity.add(motionControlBase);
					entity.add(new MotionTarget());
					entity.add(new TargetEntity(0, 0, aimTarget, false));
				}
				
				if(enemyData.faceTarget)
				{
					entity.add(new TargetSpatial(aimTarget));
					
					var rotateControl:RotateControl = new RotateControl();
					rotateControl.origin = spatial;
					//rotateControl.cameraOffset = true;
					//rotateControl.velocity = 400;
					rotateControl.ease = enemyData.rotationEasing;
					entity.add(rotateControl);
				}
				
				_group.addEntity(entity);
			}
			else
			{
				motion = entity.get(Motion);
				sleep = entity.get(Sleep);
				sleep.sleeping = false;
				entity.ignoreGroupPause = false;
				sleep.ignoreOffscreenSleep = enemyData.ignoreOffscreenSleep;
				spatial = entity.get(Spatial);
				entity.add(hit);
				/*
				hit = entity.get(MovieClipHit);
				hit.isHit = false;
				hit._colliderId = null;
				*/
				hazard = entity.get(Hazard);
				if( !hazard )
				{
					hazard = new Hazard();
					entity.add( hazard );
				}
				damageTarget = entity.get(DamageTarget);
				damageTarget.damage = 0;
				damageTarget.isTriggered = false;
				damageTarget.isHit = false;
			}

			spatial.x = x;
			spatial.y = y;
			
			damageTarget.maxDamage = enemyData.maxDamage;
			hazard.damage = enemyData.impactDamage;
			
			switch(enemyData.type)
			{
				case EnemyType.VIRUS :
					typeComponent = new Virus();
					Virus(typeComponent).alwaysAquire = true;
					break;
				
				case EnemyType.EVO_VIRUS :
					typeComponent = new EvoVirus();
					EvoVirus(typeComponent).alwaysAquire = true;
					break;
				
				case EnemyType.OVERLORD :
					typeComponent = new OverlordEnemy();
					
					if(enemyData.level == 4 && init)
					{
						typeComponent.state = typeComponent.ATTACK;
						typeComponent.attackDistance = enemyData.attackDistance;

						weapon = new Weapon();
						weapon.offsetX = 175 * (-enemyData.scale * .5);
						weapon.offsetY = -40 * enemyData.scale;
						weapon.type = WeaponType.ENEMY_GUN;
						weapon.projectileLifespan = 6;
						weapon.projectileColor = 0xff0000;
						weapon.minimumShotInterval = 1;
						weapon.damage = enemyData.projectileDamage;
						weapon.velocity = 200;
						weapon.gunBarrels = 6;
						weapon.projectileSize = 8;
						weapon.gunBarrelAngleSeparation = 60;
						
						addWeapon(entity, weapon);
						
						hit.shapeHit = true;
					}
					
					break;
				
				case EnemyType.SEEKER_WAVE :
					var waveMotionData:WaveMotionData = new WaveMotionData();
					waveMotionData.magnitude = 50;
					waveMotionData.rate = .05;
					if(parent == null)
					{
						waveMotionData.radians = 0;
					}
					else
					{
						waveMotionData.radians = .75 * (childNumber + 1);//Math.PI / (enemyData.children - childNumber);
					}
					
					MotionUtils.addWaveMotion(entity, waveMotionData);

				case EnemyType.SEEKER_LINE :
				case EnemyType.SEEKER :
					typeComponent = new SeekerEnemy();
					typeComponent.lifetime = enemyData.lifetime;
					
					if(randomPosition.x < 0 || randomPosition.x > _group.shellApi.camera.viewportWidth)
					{
						if(parent == null)
						{
							spatial.y = -_group.shellApi.camera.y + Utils.randInRange(-150, 150);
						}
						else
						{
							spatial.y = parent.get(Spatial).y;
						}
						
						if(randomPosition.x < 0)
						{
							motion.velocity.x = enemyData.maxVelocity;
						}
						else
						{
							motion.velocity.x = -enemyData.maxVelocity;
						}
						
						if(enemyData.type == EnemyType.SEEKER_WAVE)
						{
							waveMotionData.property = "y";
						}
					}
					else
					{
						if(parent == null)
						{
							spatial.x = -_group.shellApi.camera.x + Utils.randInRange(-150, 150);
						}
						else
						{
							spatial.x = parent.get(Spatial).x;
						}
						
						if(randomPosition.y < 0)
						{
							motion.velocity.y = enemyData.maxVelocity;
						}
						else
						{
							motion.velocity.y = -enemyData.maxVelocity;
						}
						
						if(enemyData.type == EnemyType.SEEKER_WAVE)
						{
							waveMotionData.property = "x";
						}
					}
					break;
				
				case EnemyType.SHOOTER :
					typeComponent = new ShooterEnemy();
					typeComponent.attackDistance = enemyData.attackDistance;
					typeComponent.baseAcceleration = enemyData.acceleration;
					typeComponent.baseMaxVelocity = enemyData.maxVelocity;
					//var displayObject:DisplayObjectContainer = Display(ship.get(Display)).displayObject;
					
					weapon = new Weapon();
					weapon.offsetX = 175 * (enemyData.scale * .5);
					weapon.offsetY = -40 * enemyData.scale;
					weapon.type = WeaponType.ENEMY_GUN;
					weapon.projectileLifespan = 3;
					weapon.projectileColor = 0xffcc00;
					weapon.minimumShotInterval = .25 * (7 - enemyData.level);
					weapon.damage = enemyData.projectileDamage;
					weapon.velocity = 200;
					weapon.gunBarrels = 2;
					weapon.gunBarrelSeparation = 80 * enemyData.scale;
					
					addWeapon(entity, weapon);
					break;
				
				case EnemyType.SNAKE :
					typeComponent = new SnakeEnemy();
					typeComponent.state = SnakeEnemy(typeComponent).AQUIRE;
					
					/*
					ikControl = entity.get(IKControl);
					
					if(ikControl == null)
					{
						ikSegment = new IKSegment(50);
						ikControl = new IKControl();
						ikControl.head = ikSegment;
						entity.add(ikControl);
						entity.add(ikSegment);
					}
					ikSegment.spatial = spatial;
					*/
					//entity.add(typeComponent);  // must add this here for children to access
					//addChildEnemies(entity, enemyData.children, enemyData, x, y, randomPosition);
					break;
				
				case EnemyType.SNAKE_SEGMENT :
				case EnemyType.SNAKE_TAIL :
					typeComponent = new SnakeEnemy();
					typeComponent.state = SnakeEnemy(typeComponent).AQUIRE;
					
					var easeRates:Array = [.04, .036, .03, .023];
					//var easeRates:Array = [.09, .08, .07, .04];
					
					if(init)
					{
						entity.add(new FollowTarget(parent.get(Spatial), easeRates[enemyData.level - 1], false));
						
						if(enemyData.level == 4 && enemyData.type == EnemyType.SNAKE_TAIL)
						{
							typeComponent.state = typeComponent.ATTACK;
							typeComponent.attackDistance = enemyData.attackDistance;
							
							weapon = new Weapon();
							weapon.offsetX = 175 * (-enemyData.scale * .5);
							weapon.offsetY = -40 * enemyData.scale;
							weapon.type = WeaponType.ENEMY_GUN;
							weapon.projectileLifespan = 6;
							weapon.projectileColor = 0xff0000;
							weapon.minimumShotInterval = (6 - enemyData.level);
							weapon.damage = enemyData.projectileDamage;
							weapon.velocity = 200;
							weapon.gunBarrels = 6;
							weapon.projectileSize = 8;
							weapon.gunBarrelAngleSeparation = 60;
							
							addWeapon(entity, weapon);
							entity.add(new TargetEntity(0, 0, aimTarget, false));
						}
					}
					
					var parentSnake:SnakeEnemy = parent.get(SnakeEnemy);
					parentSnake.next = entity;
					
					/*
					ikSegment = entity.get(IKSegment);
					parentIkSegment = parent.get(IKSegment);
					
					if(ikSegment == null)
					{
						ikSegment = new IKSegment(50);
						entity.add(ikSegment);
					}
					ikSegment.previous = parentIkSegment;
					ikSegment.spatial = spatial;
					parentIkSegment.next = ikSegment;
					*/
					//var targetEntity:TargetEntity = entity.get(TargetEntity);
					//targetEntity.target = parent.get(Spatial);
					break;
				
				case EnemyType.SPINNER :
					typeComponent = new SpinnerEnemy();
					typeComponent.attackDistance = enemyData.attackDistance;
					typeComponent.baseAcceleration = enemyData.acceleration;
					typeComponent.baseMaxVelocity = enemyData.maxVelocity;
					motion.rotationMaxVelocity = 400;
					motion.rotationFriction = 100;
					break;
				
				case EnemyType.WHITE_BLOOD_CELL :
					typeComponent = new WhiteBloodCell();
					WhiteBloodCell(typeComponent).alwaysAquire = true;
					break;
			}
			
			entity.add(typeComponent);
			
			if(parent == null && enemyData.children > 0)
			{
				var pickupType:String = PickupType.UPGRADE;
				var playerDamageTarget:DamageTarget = _group.shellApi.player.get(DamageTarget);
				var weaponSlots:WeaponSlots = _group.shellApi.player.get(WeaponSlots);
				var gun:Weapon = Entity(weaponSlots.slots[WeaponType.GUN]).get(Weapon);
				
				if(playerDamageTarget.damage > playerDamageTarget.maxDamage * .5 || Math.random() > .7)
				{
					pickupType = PickupType.HEALTH;
				}
				else if(gun.level == gun.maxLevel || Math.random() > .85)
				{
					pickupType = PickupType.BOMB;
				}
								
				entity.add(new EnemyGroup(enemyData.children + 1, pickupType));
				addChildEnemies(entity, enemyData.children, enemyData, x, y, randomPosition);
			}
			else if(parent)
			{
				entity.add(parent.get(EnemyGroup));
			}
			/*
			if(init && enemyData.level == 4)
			{
				var lifeBarCreator:LifeBarCreator = new LifeBarCreator(_group, _container);
				lifeBarCreator.create(entity, "scenes/virusHunter/shared/enemyLifeBar.swf");
			}
			*/
			
			_audioGroup.addAudioToEntity(entity, "enemy");
			
			return(entity);
		}
				
		public function addEnemyEye(parent:Entity, eyeDisplay:MovieClip, follow:Boolean = true):void
		{
			if(parent && eyeDisplay)
			{
				var entity:Entity = new Entity();
				entity.add(new Spatial(0, 0));
				entity.add(new Display(eyeDisplay.pupil));
				entity.add(new EnemyEye());
				entity.add(parent.get(DamageTarget));
				entity.add(new Id("enemyEye"));
				
				if(follow)
				{
					entity.add(new TargetSpatial(this.target));
					var rotateControl:RotateControl = new RotateControl();
					rotateControl.origin = parent.get(Spatial);
					rotateControl.targetInLocal = false;
					rotateControl.ease = .2;
					entity.add(rotateControl);
				}
				
				EntityUtils.addParentChild(entity, parent);
				
				_group.addEntity(entity);
			}
		}
		
		public function addChildEnemies(parent:Entity, total:Number, enemyData:EnemyData, x:Number, y:Number, randomPosition:Point):void
		{
			var childX:Number;
			var childY:Number;
			var childEnemyData:EnemyData;
			var type:String;
			var previous:Entity = parent;
			
			for(var n:uint = 0; n < total; n++)
			{
				switch(enemyData.type)
				{
					case EnemyType.SEEKER_LINE :
					case EnemyType.SEEKER_WAVE :
						if(randomPosition.x < 0 || randomPosition.x > _group.shellApi.camera.viewportWidth)
						{
							if(randomPosition.x > 0)
							{
								childX = x + 80 * (n + 1);
							}
							else
							{
								childX = x - 80 * (n + 1);
							}
						}
						else
						{
							if(randomPosition.y > 0)
							{
								childY = y + 80 * (n + 1);
							}
							else
							{
								childY = y - 80 * (n + 1);
							}
						}
						
						createFromData(enemyData, childX, childY, randomPosition, parent, n);
					break;
					
					case EnemyType.SNAKE :
						childX = x;
						childY = y;
						
						if(n == total - 1)
						{
							type = EnemyType.SNAKE_TAIL;
						}
						else
						{
							type = EnemyType.SNAKE_SEGMENT;
						}
						
						childEnemyData = allEnemyData[type][enemyData.level];
						//childEnemyData.faceTarget = true;
						//childEnemyData.followTarget = true;
	
						previous = createFromData(childEnemyData, childX, childY, randomPosition, previous, n);
					break;
				}
			}
		}
		
		public function create(type:String, asset:String, x:Number, y:Number, minVelocity:* = null, maxVelocity:* = null, targetOffset:Number = 0, ignoreOffscreenSleep:Boolean = false, alwaysAquire:Boolean = false, aimTarget:Spatial = null, damage:Number = NaN):Entity
		{
			var motion:Motion;
			var spatial:Spatial;
			var sleep:Sleep;
			var hit:MovieClipHit;
			var typeComponent:*;
			var entity:Entity;
			var init:Boolean = false;
			var damageTarget:DamageTarget;
			var hazard:Hazard;
			var velocity:Point;
			var timeline:Timeline;
			
			if(type != EnemyType.VIRUS || type != EnemyType.EVO_VIRUS)
			{
				entity = _pool.request(type);
			}
			
			if(!_total[type]) { _total[type] = 0; }
			
			_total[type]++;
			
			if(aimTarget == null) { aimTarget = this.target; }
			
			if(entity == null)
			{
				init = true;
				entity = new Entity();
				
				hit = new MovieClipHit(EnemyType.ENEMY_HIT, "ship", "shipMelee");
				
				motion = new Motion();
				sleep = new Sleep();
				sleep.useEdgeForBounds = true;
				sleep.ignoreOffscreenSleep = ignoreOffscreenSleep;
				spatial = new Spatial();
				hazard = new Hazard();
				damageTarget = new DamageTarget();
				damageTarget.damageFactor = new Dictionary();
				damageTarget.damageFactor[WeaponType.GUN] = 1;
				damageTarget.damageFactor[WeaponType.SCALPEL] = 1;
				
				entity.add(spatial);
				entity.add(new Id(type));
				entity.add(sleep);
				entity.add(motion);
				entity.add(new Edge(200, 200, 200, 200));
				entity.add(new Audio());
				entity.add(new AudioRange(600, 0.01, 1));
				entity.add(new HitAudio());
				if(_audioGroup) { _audioGroup.addAudioToEntity(entity); }
				entity.add(damageTarget);
				entity.add(new EntityType(type));
				entity.add(hit);
				entity.add(hazard);

				_group.addEntity(entity);
			}
			else
			{
				motion = entity.get(Motion);
				sleep = entity.get(Sleep);
				sleep.sleeping = false;
				entity.ignoreGroupPause = false;
				sleep.ignoreOffscreenSleep = ignoreOffscreenSleep;
				spatial = entity.get(Spatial);
				hit = entity.get(MovieClipHit);
				if( hit )
				{
					hit.isHit = false;
					hit._colliderId = null;
				}
				else
				{
					hit = new MovieClipHit(EnemyType.ENEMY_HIT, "ship", "shipMelee");
					entity.add( hit );
				}
				timeline = entity.get( Timeline );
				if( timeline )
				{
					timeline.gotoAndPlay( "idle" );
				}
				hazard = entity.get(Hazard);
				damageTarget = entity.get(DamageTarget);
				damageTarget.damage = 0;
				damageTarget.isTriggered = false;
				damageTarget.isHit = false;
			}
			
			velocity = new Point(0, 0);
			
			if(minVelocity is Point && maxVelocity is Point)
			{
				velocity.x = Utils.randInRange(minVelocity.x, maxVelocity.x);
				velocity.y = Utils.randInRange(minVelocity.y, maxVelocity.y);
			}
			else
			{
				var randomVelocity:Number = Utils.randInRange(minVelocity, maxVelocity);
				var dx:Number = aimTarget.x - x;
				var dy:Number = aimTarget.y - y;
				var angle:Number = Math.atan2(dy, dx) + (targetOffset - Math.random() * (targetOffset * 2));
				spatial.rotation = angle * (180 / Math.PI);
				velocity.x = Math.cos(angle) * randomVelocity;
				velocity.y = Math.sin(angle) * randomVelocity;
			}
			
			spatial.x = x;
			spatial.y = y;
			motion.velocity = velocity.clone();
			
			switch(type)
			{
				case EnemyType.VIRUS :
					damageTarget.maxDamage = 1;
					hazard.damage = .2;
					
					var virus:Virus = new Virus();
					virus.state = virus.SEEK;
					virus.alwaysAquire = alwaysAquire;
					
					entity.add(virus);
					
					if(asset == null)
					{
						asset = "scenes/virusHunter/shared/virus.swf";
					}
					break;
				
				case EnemyType.EVO_VIRUS :
					damageTarget.maxDamage = 4;
					hazard.damage = .5;
					
					var evoVirus:EvoVirus = new EvoVirus();
					evoVirus.state = evoVirus.SEEK;
					evoVirus.alwaysAquire = alwaysAquire;
					
					entity.add(evoVirus);
					
					if(asset == null)
					{
						asset = "scenes/virusHunter/shared/evoVirus.swf";
					}
					break;
				
				case EnemyType.RED_BLOOD_CELL :
					damageTarget.maxDamage = 1;
					damageTarget.reactToInvulnerableWeapons = false;
					damageTarget.hitParticleColor1 = 0x33330000;
					damageTarget.hitParticleColor2 = 0xffff0000;
					hazard.damage = 0;
					createRedBloodCell(entity, init);
					
					if(asset == null)
					{
						asset = "scenes/virusHunter/shared/redBloodCell.swf";
					}
					break;
				
				case EnemyType.BACTERIA :
					damageTarget.maxDamage = 1;
					hazard.damage = 0;
					createBacteria(entity, init);
					
					if(asset == null)
					{
						asset = "scenes/virusHunter/shared/bacteria.swf";
					}
					break;
				
				case EnemyType.WHITE_BLOOD_CELL :
					damageTarget.maxDamage = 3;
					
					if(isNaN(damage)) { damage = .2; }
					
					hazard.damage = damage;
					var whiteBloodCell:WhiteBloodCell = new WhiteBloodCell();
					whiteBloodCell.state = whiteBloodCell.SEEK;
					whiteBloodCell.alwaysAquire = alwaysAquire;
					
					if(randomVelocity)
					{
						whiteBloodCell.aquireVelocity = randomVelocity;
					}
					
					entity.add(whiteBloodCell);
					
					if(asset == null)
					{
						asset = "scenes/virusHunter/shared/whiteBloodCell.swf";
					}
					break;
			}
			
			if(init)
			{
				entity.add(new TargetSpatial(aimTarget));		
				_group.shellApi.loadFile(_group.shellApi.assetPrefix + asset, assetLoaded, entity, _container);
			}
			
			return(entity);
		}
				
		public function createRedBloodCell(entity:Entity, init:Boolean):void
		{
			var motion:Motion = entity.get(Motion);
			var spatial:Spatial = entity.get(Spatial);
			var redBloodCell:RedBloodCell = new RedBloodCell();
			redBloodCell.angle = Math.random()*2*Math.PI;
			redBloodCell.turnSpeed = Math.random()*0.1 + 0.05;
			redBloodCell.radius = 4;
			redBloodCell.state = redBloodCell.FLOAT;
			
			motion.rotationVelocity = Math.random()*200 - 100;
			
			entity.add(redBloodCell);
			
			spatial.rotation = Math.random()*360;
			spatial.scaleX = spatial.scaleY = Math.random()*0.25 + 0.75;
		}
				
		public function createBacteria(entity:Entity, init:Boolean):void
		{
			var motion:Motion = entity.get(Motion);
			var spatial:Spatial = entity.get(Spatial);
			var bacteria:Bacteria = new Bacteria();
			bacteria.state = bacteria.FLOAT;
			
			motion.rotationVelocity = Math.random()*200 - 100;
			
			entity.add(bacteria);
						
			spatial.rotation = Math.random()*360;
			spatial.scaleX = spatial.scaleY = Math.random()*0.25 + 0.75;
		}
		
		public function addWeapon(enemy:Entity, weapon:Weapon, displayObject:DisplayObjectContainer = null, aimTarget:Spatial = null/*, makeActive:Boolean = false*/):Entity
		{
			var entity:Entity = new Entity();	
			var spatial:Spatial = enemy.get(Spatial);
			var display:Display = new Display();
			display.isStatic = true;
			//var sleep:Sleep = new Sleep();
			//sleep.ignoreOffscreenSleep = true;
			
			if(aimTarget)
			{
				var rotateControl:RotateControl = new RotateControl();
				rotateControl.origin = enemy.get(Spatial);
				rotateControl.targetInLocal = true;
				//rotateControl.velocity = 400;
				rotateControl.ease = .2;
				entity.add(rotateControl);
				entity.add(new TargetSpatial(aimTarget));
				display.displayObject = displayObject;
				display.isStatic = false;
				spatial = new Spatial(0, 0);
			}
			
			//var shipId:Id = ship.get(Id);
			
			entity.add(display);
			entity.add(weapon);
			entity.add(new EntityType(weapon.type));
			entity.add(spatial);
			entity.add(new WeaponControl());
			entity.add(new Id(weapon.type));
			//entity.add(sleep);
			
			//InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN]);
			
			EntityUtils.addParentChild(entity, enemy, true);
			
			var weaponSlots:WeaponSlots = enemy.get(WeaponSlots);
			
			if(weaponSlots == null)
			{
				weaponSlots = new WeaponSlots();
				enemy.add(weaponSlots);
			}
			
			weaponSlots.active = entity;
			weapon.state = weapon.ACTIVE;
			
			_audioGroup.addAudioToEntity(entity);
			/*
			var weaponSlots:WeaponSlots = ship.get(WeaponSlots);
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
				var hit:MovieClipHit = new MovieClipHit("ship");
				hit.shapeHit = false;
				
				entity.add(hit);
				entity.add(new Melee());
			}
			*/
			return(entity);
		}
		
		public function releaseEntity(entity:Entity, releaseToPool:Boolean = true):void
		{
			var sleep:Sleep = entity.get(Sleep);
			if( sleep )
			{
				sleep.sleeping = true;
				entity.ignoreGroupPause = true;
				sleep.ignoreOffscreenSleep = true;
			}
			
			var id:Id = entity.get(Id);
			//var idString:String = ( id != null ) ? id.id : entity.name;
			var type:EntityType = entity.get(EntityType);
			var released:Boolean = false;
			
			if(releaseToPool) 
			{ 
				//if(_pool.release(entity, idString))
				if(_pool.release(entity, id.id))
				{
					released = true;
				}
			}
			else
			{
				released = true;
				_group.removeEntity(entity);
			}
			
			if(released)
			{
				var parent:Parent = entity.get(Parent);
				
				if(parent)
				{
					var spawn:EnemySpawn = parent.parent.get(EnemySpawn);
					
					if(spawn)
					{
						spawn.totalFromThisSpawn--;
					}
				}
				
				_total[type.type]--;
			}
		}
		
		private function assetLoaded(clip:MovieClip, entity:Entity, container:DisplayObjectContainer):void
		{
			if(!_group)
				return;
			container.addChild(clip);
			entity.add(new Display(clip));
			
			var follow:Boolean = true;
			
			if(entity.get(RotateControl))
			{
				follow = false;
			}
			
			if(entity.get(OverlordEnemy) && !clip.eye)
			{
				addEnemyEye(entity, clip.eye1);
				addEnemyEye(entity, clip.eye2);
				addEnemyEye(entity, clip.eye3);
			}
			else if(clip.eye)
			{
				addEnemyEye(entity, clip.eye, follow);
			}
			
			if(clip.legs)
			{
				TimelineUtils.convertClip(clip.legs, _group, entity);
			}
			
			var type:String = entity.get(EntityType).type;
			if(type == EnemyType.VIRUS || type == EnemyType.EVO_VIRUS || type == EnemyType.WHITE_BLOOD_CELL || type == EnemyType.BACTERIA )
			{
				TimelineUtils.convertClip( clip.content, _group, entity );
			}
						
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
		}
		
		public function getTotal(type:String = null):int 
		{ 
			if(type == null)
			{
				var grandTotal:int = 0;
				
				for each(var typeTotal:int in _total)
				{
					grandTotal += typeTotal;
				}
				
				return(grandTotal);
			}
			else
			{
				return(_total[type]);
			}
		}
		
		public function createDelayedEnemyExplosion(x:Number, y:Number, parent:Entity = null):void
		{
			SceneUtil.addTimedEvent(_group, new TimedEvent(.25, 1, Command.create(createEnemyExplosion, x, y, parent)));
		}
		
		public function createEnemyExplosion(x:Number = 0, y:Number = 0, parent:Entity = null):void
		{
			if(parent != null)
			{
				var spatial:Spatial = parent.get(Spatial);
				
				x = spatial.x;
				y = spatial.y;
			}
			
			var emitter:Burst = new Burst();
			emitter.init(2, 0x33ffcc00, 0xffff6600);
			
			var entity:Entity = EmitterCreator.create(_group, _container, emitter);	
			entity.get(Spatial).x = x;
			entity.get(Spatial).y = y;
			
			var parentAudio:Audio = parent.get(Audio);
			var audio:Audio = new Audio();
			audio.allEventAudio = parentAudio.allEventAudio;
			_group.shellApi.setupEventTrigger(audio);
			entity.add(audio);
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			
			entity.add(sleep);
			Emitter(entity.get(Emitter)).remove = true;
			
			if(parent != null)
			{
				playAudio(entity);
			}
			
			if(!parent.get(EnemyGroup))
			{
				
			}
		}
		
		public function createRandomPickup(x:Number, y:Number, arcade:Boolean = true):void
		{
			var playerDamageTarget:DamageTarget = _group.shellApi.player.get(DamageTarget);
			var weaponSlots:WeaponSlots = _group.shellApi.player.get(WeaponSlots);
			var gun:Weapon = Entity(weaponSlots.slots[WeaponType.GUN]).get(Weapon);
			var pickupType:String = PickupType.UPGRADE;
			var chance:Number = .7;
			
			if(!arcade)
			{
				if(gun.level == gun.maxLevel && playerDamageTarget.damage == 0)
				{
					return;
				}
				else
				{
					chance = .7;
				}
			}
									
			if(Math.random() > chance || playerDamageTarget.damage > playerDamageTarget.maxDamage * .5)
			{
				if(playerDamageTarget.damage > playerDamageTarget.maxDamage * .5)
				{
					pickupType = PickupType.HEALTH;
				}
				else if((gun.level == gun.maxLevel || Math.random() > .85) && arcade)
				{
					pickupType = PickupType.BOMB;
				}
				
				_pickupCreator.create(x, y, pickupType, arcade);
			}
		}
		
		private function playAudio(entity:Entity):void
		{
			var audio:Audio = entity.get(Audio);
			var actions:Dictionary;
			var soundData:SoundData;
			
			if(audio)
			{
				actions = audio.currentActions;
				soundData = actions["die"];
				//audio.remove = true;
				
				if(soundData != null)
				{			
					audio.play(soundData.asset, false, [SoundModifier.EFFECTS, SoundModifier.POSITION, SoundModifier.FADE]);
					//audio.fade(soundData.asset, 0);
				}
			}
		}
		
		public var target:Spatial;
		public var allEnemyData:Dictionary;
		private var _pool:EntityPool;
		private var _group:Group;
		private var _container:DisplayObjectContainer;
		private var _total:Dictionary;
		private var _audioGroup:AudioGroup;
		private var _pickupCreator:PickupCreator;
	}
}