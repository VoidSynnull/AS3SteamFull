package game.scenes.virusHunter.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.systems.MotionSystem;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.components.entity.collider.ItemCollider;
	import game.components.hit.MovieClipHit;
	import game.components.input.Input;
	import game.components.motion.Edge;
	import game.components.motion.MotionControlBase;
	import game.creators.entity.EmitterCreator;
	import game.data.scene.hit.HitData;
	import game.data.scene.hit.HitDataComponent;
	import game.managers.EntityPool;
	import game.scene.template.AudioGroup;
	import game.scene.template.CollisionGroup;
	import game.scene.template.SceneUIGroup;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.GameState;
	import game.scenes.virusHunter.shared.components.Melee;
	import game.scenes.virusHunter.shared.components.SceneWeaponTarget;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.creators.LifeBarCreator;
	import game.scenes.virusHunter.shared.creators.ProjectileCreator;
	import game.scenes.virusHunter.shared.creators.ShipCreator;
	import game.scenes.virusHunter.shared.data.EnemyDataParser;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.scenes.virusHunter.shared.emitters.ShipExhaust;
	import game.scenes.virusHunter.shared.nodes.WhiteBloodCellMotionNode;
	import game.scenes.virusHunter.shared.systems.BacteriaSystem;
	import game.scenes.virusHunter.shared.systems.EnemySpawnSystem;
	import game.scenes.virusHunter.shared.systems.EvoVirusSystem;
	import game.scenes.virusHunter.shared.systems.ProjectileAgeSystem;
	import game.scenes.virusHunter.shared.systems.RedBloodCellSystem;
	import game.scenes.virusHunter.shared.systems.ShipDamageSystem;
	import game.scenes.virusHunter.shared.systems.ShipMotionSystem;
	import game.scenes.virusHunter.shared.systems.VirusSystem;
	import game.scenes.virusHunter.shared.systems.WeaponCollisionSystem;
	import game.scenes.virusHunter.shared.systems.WeaponControlSystem;
	import game.scenes.virusHunter.shared.systems.WeaponInputMapSystem;
	import game.scenes.virusHunter.shared.systems.WeaponSelectionSystem;
	import game.scenes.virusHunter.shared.systems.WhiteBloodCellSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.MovieClipHitSystem;
	import game.systems.hit.ResetColliderFlagSystem;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.ui.ProgressBarSystem;
	import game.ui.hud.Hud;
	import game.util.DataUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;
	
	public class ShipGroup extends DisplayGroup
	{
		public function ShipGroup(container:DisplayObjectContainer=null)
		{
			super(container);
			this.id = "shipGroup";
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{			
			_entityPool = new EntityPool();
			_projectileCreator = new ProjectileCreator(_entityPool, super.parent);
		}
		
		override public function destroy():void
		{			
			super.groupContainer = null;
			super.destroy();
		}
		
		public function setupScene(scene:Scene, shipContainer:DisplayObjectContainer, loadedCallback:Function = null, audioGroup:AudioGroup = null):void
		{
			_targetGroup = scene;
			
			if(PlatformUtils.isMobileOS)
			{
				_targetGroup.ready.addOnce(sceneReady);
			}
			
			// this group should inherit properties of the scene.
			super.groupPrefix = scene.groupPrefix;
			super.container = scene.container;
			super.groupContainer = shipContainer;
			// add a container for all ship particles
			_shipExhaustContainer = new Sprite();
			super.groupContainer.addChild(_shipExhaustContainer);
			_shipExhaustContainer.mouseChildren = false;
			_shipExhaustContainer.mouseEnabled = false;
			// add it as a child group to give it access to systemManager.
			scene.addChildGroup(this);

			_shipCreator = new ShipCreator(scene, audioGroup);
			_enemyCreator = new EnemyCreator(_entityPool, scene, super.groupContainer, audioGroup);
			
			loadEnemyData();
			
			scene.addSystem(new ShipMotionSystem(), SystemPriorities.inputComplete);
			scene.addSystem(new RotateToTargetSystem(), SystemPriorities.move);
			scene.addSystem(new ProjectileAgeSystem(_projectileCreator), SystemPriorities.update);
			scene.addSystem(new WeaponCollisionSystem(_projectileCreator), SystemPriorities.checkCollisions);
			scene.addSystem(new WeaponControlSystem(_projectileCreator, super.groupContainer, this.shellApi.inputEntity.get(Input)), SystemPriorities.update);
			scene.addSystem(new WeaponSelectionSystem(), SystemPriorities.update);
			scene.addSystem(new WeaponInputMapSystem(), SystemPriorities.update);
			scene.addSystem(new MovieClipHitSystem(), SystemPriorities.resolveCollisions);
			scene.addSystem(new ResetColliderFlagSystem(), SystemPriorities.resetColliderFlags);
			scene.addSystem(new ShipDamageSystem(_shipCreator, super.parent as ShipScene), SystemPriorities.checkCollisions);
			
			scene.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);  // maps control input position to motion components.
			scene.addSystem(new MotionSystem(), SystemPriorities.move);						// updates velocity based on acceleration and friction.
			scene.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			scene.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);    // maps input button presses to acceleration.
			scene.addSystem(new MotionTargetSystem(), SystemPriorities.move);
			scene.addSystem(new MotionControlBaseSystem(), SystemPriorities.move);
			scene.addSystem(new NavigationSystem(), SystemPriorities.update);			    // This system moves an entity through a series of points for autopilot.
			scene.addSystem(new DestinationSystem(), SystemPriorities.update);	
			scene.addSystem(new TargetEntitySystem(), SystemPriorities.update);	
			scene.addSystem(new ProgressBarSystem(), SystemPriorities.lowest);
			
			_gameState = new GameState();
			_gameState.maxVirus = 0;
			_gameState.maxRedBloodCells = 0;
			
			var entity:Entity = new Entity();
			entity.add(new Id("gameState"));
			entity.add(_gameState);
			
			super.parent.addEntity(entity);
			
			_loadedCallback = loadedCallback;
		}
		
		public function loadEnemyData():void
		{
			super.shellApi.loadFile(super.shellApi.dataPrefix + "scenes/virusHunter/shared/enemy.xml", parseEnemyData);
		}
		
		public function loadShip(x:Number, y:Number, isPlayer:Boolean = false, id:String = null):void
		{
			super.shellApi.loadFile(super.shellApi.assetPrefix + "scenes/virusHunter/shared/ship.swf", shipLoaded, x, y, isPlayer, id);
			_loading++;
		}
		
		private function parseEnemyData(xml:XML):void
		{
			var enemyDataParser:EnemyDataParser = new EnemyDataParser();
			_enemyCreator.allEnemyData = enemyDataParser.parse(xml);
		}
		
		private function shipLoaded(clip:MovieClip, x:Number, y:Number, isPlayer:Boolean = false, id:String = null):void
		{
			var entity:Entity = _shipCreator.create(super.groupContainer, clip, x, y, _targetGroup.sceneData.bounds, id);
			
			_targetGroup.addEntity(entity);
		
			if(isPlayer)
			{
				InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.KEY_DOWN, InteractionCreator.KEY_UP], clip["selectable"]);
				// add an item collider so this entity can pick up items.
				entity.add(new ItemCollider());
				entity.add(new Player());
				addWeapons(entity, shellApi.getUserField( (shellApi.islandEvents as VirusHunterEvents).WEAPON_FIELD, shellApi.island ));

				var currentDamage:Number = shellApi.getUserField((shellApi.islandEvents as VirusHunterEvents).DAMAGE_FIELD, shellApi.island) as Number;
				if (!DataUtils.isNull(currentDamage))
				{
					var damageTarget:DamageTarget = entity.get(DamageTarget);
					damageTarget.damage = currentDamage;
				}
			}
			else
			{
				addWeapons(entity);
			}
			
			addDamageFactor(entity, EnemyType.ENEMY_HIT, 1);
			
			var lifeBarCreator:LifeBarCreator = new LifeBarCreator(super.parent, super.groupContainer);
			lifeBarCreator.create(entity, "scenes/virusHunter/shared/lifeBar.swf", new Point(0, Edge(entity.get(Edge)).rectangle.top - 20));
			
			_loading--;
			
			if(_loading == 0)
			{
				allShipsLoaded();
			}
		}
		
		private function allShipsLoaded():void
		{
			_loadedCallback();
			_enemyCreator.target = super.shellApi.player.get(Spatial);
				
			//super.parent.addSystem(new ShipGameManagerSystem(_enemyCreator), SystemPriorities.lowest);
			super.parent.addSystem(new EnemySpawnSystem(_enemyCreator), SystemPriorities.lowest);
			super.parent.addSystem(new VirusSystem(_enemyCreator), SystemPriorities.move);
			super.parent.addSystem(new RedBloodCellSystem(_enemyCreator), SystemPriorities.move);
			super.parent.addSystem( new BacteriaSystem( _enemyCreator ), SystemPriorities.move );
			super.parent.addSystem( new EvoVirusSystem( _enemyCreator ), SystemPriorities.move );
			super.parent.addSystem( new WhiteBloodCellSystem( _enemyCreator ), SystemPriorities.move );
		}
		
		private function sceneReady(scene:Group):void
		{
			var hud:Hud = (super.getGroupById( Hud.GROUP_ID ) as Hud)
			hud.ready.addOnce(hudReady);
		}
		
		private function hudReady(hud:Hud):void
		{
			var actionButton:Entity = hud.createActionButton();
			var weaponInputMapSystem:WeaponInputMapSystem = _targetGroup.getSystem(WeaponInputMapSystem) as WeaponInputMapSystem;
			weaponInputMapSystem.actionButtonInteraction = actionButton.get(Interaction);
		}
		
		public function createWhiteBloodCellSwarm(target:Spatial):void
		{
			var spawn:EnemySpawn = createOffscreenSpawn(EnemyType.WHITE_BLOOD_CELL, 12, .1, 300, 300, 0, target);
			spawn.enemyDamage = 0;
		}
		
		public function whiteBloodCellExit():void
		{
			var nodeList:NodeList = _systemManager.getNodeList(WhiteBloodCellMotionNode);
			var node:WhiteBloodCellMotionNode;
			var randomPosition:Point;
			var distanceFromEdge:Number = 1000;
			var sleep:Sleep;
			
			for( node = nodeList.head; node; node = node.next )
			{
				node.whiteBloodCell.state = node.whiteBloodCell.EXIT;
				randomPosition = GeomUtils.getRandomPositionOutside(-distanceFromEdge, -distanceFromEdge, super.shellApi.viewportWidth + distanceFromEdge, super.shellApi.viewportHeight + distanceFromEdge);
				node.target.target = new Spatial(randomPosition.x, randomPosition.y);
				sleep = node.entity.get(Sleep);
				sleep.ignoreOffscreenSleep = false;
			}
		}
		
		public function addDamageFactor(entity:Entity, type:String, factor:Number = 1, maxDamage:Number = 1, damageCooldown:Number = .5):DamageTarget
		{
			var damageTarget:DamageTarget = entity.get(DamageTarget);
			
			if(damageTarget == null)
			{
				damageTarget = new DamageTarget();
				entity.add(damageTarget);
				damageTarget.maxDamage = maxDamage;
				damageTarget.cooldown = damageCooldown;
			}
			
			if(damageTarget.damageFactor == null)
			{
				damageTarget.damageFactor = new Dictionary();
			}
			
			damageTarget.damageFactor[type] = factor;
			
			return(damageTarget);
		}
		
		public function addSpawn(entity:Entity, type:String, max:Number, createRange:Point, minVelocity:Point, maxVelocity:Point, rate:Number = .5, targetOffset:Number = 0):EnemySpawn
		{
			var spawn:EnemySpawn = new EnemySpawn(type, rate);
			spawn.distanceFromAreaEdge = 100;
			spawn.max = max;
			spawn.createRange = createRange;
			spawn.minInitialVelocity = minVelocity;
			spawn.maxInitialVelocity = maxVelocity;
			spawn.targetOffset = targetOffset;
			
			entity.add(spawn);
			
			return(spawn);
		}
		
		public function createOffscreenSpawn(type:String, max:Number, rate:Number = .5, minVelocity:* = 40, maxVelocity:* = 140, targetOffset:Number = 0, target:Spatial = null):EnemySpawn
		{
			if(target == null)
			{
				target = super.shellApi.player.get(Spatial);
			}
			
			var entity:Entity = new Entity();
			entity.add(new Id(String(type)));
			var spawn:EnemySpawn = new EnemySpawn(type, rate, new Rectangle(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight), target);
			spawn.distanceFromAreaEdge = 100;
			spawn.max = max;
			spawn.minInitialVelocity = minVelocity;
			spawn.maxInitialVelocity = maxVelocity;
			spawn.targetOffset = targetOffset;
			
			entity.add(spawn);
			
			var spatial:Spatial = entity.get(Spatial);
			
			if(spatial == null)
			{
				spatial = new Spatial();
				entity.add(spatial);
			}
			
			super.parent.addEntity(entity);
			
			return(spawn);
		}
		
		public function updateOffscreenSpawn(type:Class, max:Number, rate:Number = .5):void
		{
			var entity:Entity = super.parent.getEntityById(String(type));
			var spawn:EnemySpawn = entity.get(EnemySpawn);
			
			spawn.rate = rate;
			spawn.max = max;
		}
		
		public function removeWeapon(ship:Entity, type:String):void
		{
			var displayObject:DisplayObjectContainer = Display(ship.get(Display)).displayObject;
			var weaponEntity:Entity = super.parent.getEntityById(type, ship);
			
			if(ship.get(Player))
			{
				if ( shellApi.getUserField( (shellApi.islandEvents as VirusHunterEvents).WEAPON_FIELD, shellApi.island ) == type )
				{
					shellApi.setUserField( (shellApi.islandEvents as VirusHunterEvents).WEAPON_FIELD, WeaponType.GUN, shellApi.island);
				}
			}
			
			switch(type)
			{
				case WeaponType.GUN :
				case WeaponType.SCALPEL :
				case WeaponType.SHOCK :
				case WeaponType.GOO :
					super.removeEntity(weaponEntity, true);
					break;
				
				case WeaponType.SHIELD :
					displayObject["noShield"].alpha = 1;
					var damageTarget:DamageTarget = ship.get(DamageTarget);
					damageTarget.maxDamage = damageTarget.maxDamage * .5;
					damageTarget.damage = damageTarget.damage * .5;
					break;
				
				case WeaponType.ANTIGRAV :
					displayObject["reactor"].visible = false;
					var motionControlBase:MotionControlBase = ship.get(MotionControlBase);
					motionControlBase.acceleration = 900;
					var motion:Motion = ship.get(Motion);
					motion.maxVelocity = new Point(300, 300);
					
					super.parent.removeEntity(super.parent.getEntityById("exhaust"));
		
					if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
					{
						var emitter:ShipExhaust = new ShipExhaust();
						emitter.init(false);
						EmitterCreator.create(super.parent, _shipExhaustContainer, emitter, 0,  0, ship, "exhaust", ship.get(Spatial));
					}
					break;
			}
		}
		
		public function addWeapon(ship:Entity, type:String, makeActive:Boolean = false):Entity
		{
			var weapon:Weapon = new Weapon();
			weapon.type = type;
			var displayObject:DisplayObjectContainer = Display(ship.get(Display)).displayObject;
			var weaponEntity:Entity;
			var timelineEntity:Entity;
			var tween:Tween = ship.get(Tween);
			
			switch(type)
			{
				case WeaponType.GUN :
					weapon.offsetX = 100;
					weapon.offsetY = -10;
					weapon.selectionRotation = 270;
					weapon.gunBarrels = 2;
					weapon.gunBarrelSeparation = 20;
					
					weaponEntity = _shipCreator.addWeapon(ship, weapon, displayObject[weapon.type], super.shellApi.inputEntity.get(Spatial), makeActive);

					var gunLevel:Number = shellApi.getUserField( (shellApi.islandEvents as VirusHunterEvents).GUN_LEVEL_FIELD, shellApi.island ) as Number;
					if (ship.get(Player) && !DataUtils.isNull(gunLevel))
					{
						_shipCreator.changeGunLevel(ship, gunLevel, true);
					}
					else
					{
						_shipCreator.changeGunLevel(ship, 0, true);
					}
					
					TimelineUtils.convertClip(displayObject[weapon.type].body, _targetGroup, weaponEntity);
				break;
				
				case WeaponType.SCALPEL :
					weapon.offsetX = 100;
					weapon.offsetY = 0;
					weapon.minimumShotInterval = .05;
					weapon.damage = 4;
					weapon.selectionRotation = 90;
					
					weaponEntity = _shipCreator.addWeapon(ship, weapon, displayObject[weapon.type], super.shellApi.inputEntity.get(Spatial), makeActive);
				break;
				
				case WeaponType.SHOCK :
					weapon.offsetX = 100;
					weapon.offsetY = 0;
					weapon.minimumShotInterval = .2;
					weapon.damage = .25;
					weapon.selectionRotation = 0;
					
					weaponEntity = _shipCreator.addWeapon(ship, weapon, displayObject[weapon.type], super.shellApi.inputEntity.get(Spatial), makeActive);
					
					var melee:Melee = weaponEntity.get(Melee);
					melee.alwaysOn = false;
					melee.active = false;
					
					TimelineUtils.convertClip(displayObject[weapon.type].body, _targetGroup, weaponEntity);
				break;
				
				case WeaponType.GOO :
					weapon = new Weapon();
					weapon.offsetX = 100;
					weapon.offsetY = 0;
					weapon.type = WeaponType.GOO;
					weapon.projectileLifespan = .7;
					weapon.projectileColor = 0x00ff00;
					weapon.minimumShotInterval = .07;
					weapon.damage = .005;
					weapon.velocity = 350;
					weapon.selectionRotation = 180;
					
					weaponEntity = _shipCreator.addWeapon(ship, weapon, displayObject[weapon.type], super.shellApi.inputEntity.get(Spatial), makeActive);
					TimelineUtils.convertClip(displayObject[weapon.type].body, _targetGroup, weaponEntity);
				break;
				
				case WeaponType.SHIELD :
					displayObject["noShield"].alpha = 1;
					var damageTarget:DamageTarget = ship.get(DamageTarget);
					damageTarget.maxDamage = damageTarget.maxDamage * 2;
					tween.to(displayObject["noShield"], 2, { alpha : 0 });
				break;
				
				case WeaponType.ANTIGRAV :
					//displayObject["reactor"].visible = true;
					tween.to(displayObject["reactor"], 2, { alpha : 1 });
					var motionControlBase:MotionControlBase = ship.get(MotionControlBase);
					motionControlBase.acceleration = 1200;
					var motion:Motion = ship.get(Motion);
					motion.maxVelocity = new Point(400, 400);
					
					if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
					{
						super.parent.removeEntity(super.parent.getEntityById("exhaust"));
						
						var emitter:ShipExhaust = new ShipExhaust();
						emitter.init(true);
						EmitterCreator.create(super.parent, _shipExhaustContainer, emitter, 0,  0, ship, "exhaust", ship.get(Spatial));
					}
				break;
			}
			
			return(weaponEntity);
		}
			
		private function addWeapons(ship:Entity, activeType:String = null):void
		{
			var displayObject:DisplayObjectContainer = Display(ship.get(Display)).displayObject;
			var gunActive:Boolean = false;
			var scalpelActive:Boolean = false;
			var shockActive:Boolean = false;
			var gooActive:Boolean = false;
			
			switch(activeType)
			{
				case WeaponType.SCALPEL : scalpelActive = true; break;
				case WeaponType.SHOCK : shockActive = true; break;
				case WeaponType.GOO : gooActive = true; break;
				default : gunActive = true;
			}
			
			addWeapon(ship, WeaponType.GUN, gunActive);
			
			if(super.shellApi.checkEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_SCALPEL))
			{
				var scalpel:Entity = addWeapon(ship, WeaponType.SCALPEL, scalpelActive);
				
				if(scalpelActive)
				{
					var audio:Audio = scalpel.get(Audio);
					audio.playCurrentAction("weaponFire");
				}
			}
			else
			{
				displayObject[WeaponType.SCALPEL].visible = false;
			}
			
			if(super.shellApi.checkEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_SHOCK))
			{
				addWeapon(ship, WeaponType.SHOCK, shockActive);
			}
			else
			{
				displayObject[WeaponType.SHOCK].visible = false;
			}
			
			if(super.shellApi.checkEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_GOO))
			{
				addWeapon(ship, WeaponType.GOO, gooActive);
			}
			else
			{
				displayObject[WeaponType.GOO].visible = false;
			}
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
			{
				var emitter:ShipExhaust = new ShipExhaust();
				emitter.init(super.shellApi.checkEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_ANTIGRAV));
				EmitterCreator.create(super.parent, _shipExhaustContainer, emitter, 0,  0, ship, "exhaust", ship.get(Spatial));
			}
			
			if(super.shellApi.checkEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_ANTIGRAV))
			{
				addWeapon(ship, WeaponType.ANTIGRAV);
			}
			else
			{
				displayObject["reactor"].alpha = false;
				var motionControlBase:MotionControlBase = ship.get(MotionControlBase);
				motionControlBase.acceleration = 900;
				var motion:Motion = ship.get(Motion);
				motion.maxVelocity = new Point(300, 300);
			}

			if(super.shellApi.checkEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_SHIELD))
			{
				addWeapon(ship, WeaponType.SHIELD);
			}
			else
			{
				var damageTarget:DamageTarget = ship.get(DamageTarget);
				damageTarget.maxDamage = damageTarget.maxDamage * .5;
			}
		}
		
		public function createSceneWeaponTargets(container:DisplayObjectContainer):void
		{
			var total:Number = container.numChildren;
			var target:MovieClip;
			
			var collisionGroup:CollisionGroup = super.getGroupById("collisionGroup") as CollisionGroup;
			
			for (var n:Number = total - 1; n >= 0; n--)
			{
				target = container.getChildAt(n) as MovieClip;
				
				if (target is MovieClip)
				{
					if(target.name.toLowerCase().indexOf("target") > -1)
					{
						addSceneWeaponTarget(target, collisionGroup.allHitData[target.name]);
					}
				}
			}
		}
		
		private function addSceneWeaponTarget(target:MovieClip, hitData:HitData):void
		{
			var entity:Entity = new Entity();
			var damageTarget:DamageTarget = new DamageTarget();
			
			entity.add(damageTarget);
			entity.add(new MovieClipHit(EnemyType.ENEMY_HIT, "shipMelee"));
			entity.add(new Spatial());
			entity.add(new Display(target));
			entity.add(new Id(target.name));
			entity.add(new Sleep());
			entity.add(new SceneWeaponTarget());
			
			if(hitData != null)
			{
				var component:HitDataComponent = hitData.components["weaponTarget"];
				var weapons:XMLList;
				var weapon:XML;
				
				if(component)
				{
					damageTarget.damageFactor = new Dictionary();
					damageTarget.maxDamage = DataUtils.getNumber(component.xml.maxDamage.toString());
					weapons = component.xml.vulnerable.weapon;

					for (var n:uint = 0; n < weapons.length(); n++)
					{
						weapon = weapons[n] as XML;
						damageTarget.damageFactor[DataUtils.getString(weapon.type.toString())] = DataUtils.getNumber(weapon.factor.toString());
					}
				}
				
				super.parent.addEntity(entity);
			}
		}
		
		public function get gameState():GameState { return(_gameState); }
		public function get enemyCreator():EnemyCreator { return(_enemyCreator); }
		public function get shipCreator():ShipCreator { return(_shipCreator); }
		public function get entityPool():EntityPool { return(_entityPool); }
		public function get shipExhaustContainer():DisplayObjectContainer { return(_shipExhaustContainer); }
		
		static private const VIRUS_CONSUME:String = "consume_virus_L.mp3";
		public static const GROUP_ID:String = "shipGroup";
		private var _loadedCallback:Function;
		private var _loading:Number = 0;
		private var _targetGroup:Scene;
		private var _shipCreator:ShipCreator;
		private var _projectileCreator:ProjectileCreator;
		private var _enemyCreator:EnemyCreator;
		private var _entityPool:EntityPool;
		private var _shipExhaustContainer:DisplayObjectContainer;
		private var _gameState:GameState;
		[Inject]
		public var _systemManager:Engine;
	}
}