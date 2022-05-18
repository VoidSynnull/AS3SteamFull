package game.scenes.virusHunter.hand
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.systems.CameraZoomSystem;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.hit.Zone;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.character.LookData;
	import game.scenes.clubhouse.clubhouse.Clubhouse;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.bloodStream.BloodStream;
	import game.scenes.virusHunter.hand.components.HandState;
	import game.scenes.virusHunter.hand.systems.HandManagerSystem;
	import game.scenes.virusHunter.hand.systems.HandTargetSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.components.Ship;
	import game.scenes.virusHunter.shared.components.Weapon;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.systems.SystemPriorities;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class Hand extends ShipScene
	{
		public function Hand()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.minCameraScale = .8;
			super.groupPrefix = "scenes/virusHunter/hand/";
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
			super.loaded();
			
			_events = this.events as VirusHunterEvents;
			
			_shipGroup = super.getGroupById( "shipGroup" ) as ShipGroup;
			_shipGroup.createSceneWeaponTargets( super._hitContainer );
			
			_handState = new HandState();
			_handStateEntity = new Entity();
			_handStateEntity.add( _handState );
			super.addEntity( _handStateEntity );
			
			var handManagerSystem:HandManagerSystem = new HandManagerSystem( this, _shipGroup.enemyCreator );
			handManagerSystem._removeSplinter.add( removeSplinter );
			handManagerSystem._loseWeapon.add( loseWeapons );
			handManagerSystem._lostWeapons.addOnce( analyzeShip );
			
			super.addSystem( handManagerSystem, SystemPriorities.lowest );
			super.addSystem( new HandTargetSystem( this, _events ), SystemPriorities.checkCollisions );
			super.addSystem( new TweenSystem(), SystemPriorities.update );
			super.addSystem( new ThresholdSystem());
			
			for( var number:int = 1; number < 5; number ++ )
			{
				var entity:Entity = TimelineUtils.convertClip( super._hitContainer[ "bloodFlow" + number + "Art" ], this );
				entity.add( new Id( "bloodFlow" + number + "Art" ));
			}
			
			sceneSetup();
			setupBloodStreamDoor();
		}
		private function setupBloodStreamDoor():void
		{
			// override door's interaction
			var door:Entity = this.getEntityById("doorBloodStream");
			SceneInteraction(door.get(SceneInteraction)).reached = new Signal();
			SceneInteraction(door.get(SceneInteraction)).reached.add(enterBloodStream);
		}
		private function enterBloodStream(...p):void
		{
			shellApi.loadScene(game.scenes.virusHunter.bloodStream.BloodStream);
		}
		override protected function allShipsLoaded():void
		{
			super.allShipsLoaded();
			
			_ship = super.getEntityById( "player" );
			
			var killCount:KillCount = new KillCount();
			killCount.count[ EnemyType.WHITE_BLOOD_CELL ] = 0;
			killCount.count[ EnemyType.BACTERIA ] = 0;
			super.shellApi.player.add( killCount );	
			
			var damageTarget:DamageTarget = _ship.get( DamageTarget );
			damageTarget.damage = 0;
		}
		
		/*********************************************************************************
		 * SCENE SETUP
		 */
		private function resetScene():void
		{
			super.shellApi.completeEvent( _events.GOT_ANTIGRAV );
			super.shellApi.completeEvent( _events.GOT_GOO );
			super.shellApi.completeEvent( _events.GOT_SCALPEL );
			super.shellApi.completeEvent( _events.GOT_SHIELD );
			super.shellApi.completeEvent( _events.GOT_SHOCK );
			super.shellApi.removeEvent( _events.SPLINTER_REMOVED );
			super.shellApi.removeEvent( _events.ATTACKED_BY_WBC );
		}
		private function resetCuts():void
		{
			for( var number:int = 1; number < 5; number ++ )
			{
				super.shellApi.removeEvent( _events.CLOGGED_HAND_CUT_ + number )
			}
		}
		
		private function sceneSetup():void
		{
		//	resetScene();
		//	resetCuts();
			var number:int;
			var timeline:Timeline;
			var entity:Entity;
			var damageTarget:DamageTarget;
			var spawnEntity:Entity
			
			if( !super.shellApi.checkEvent( _events.ATTACKED_BY_WBC ))
			{
				for( number = 1; number < 5; number ++ )
				{
					super.removeEntity( super.getEntityById( "bloodFlow" + number + "Target" ));
					super.removeEntity( super.getEntityById( "bloodFlow" + number ));
					
					MovieClip( super._hitContainer[ "bloodFlow" + number + "Art" ]).visible = false;
				}
				
				spawnEntity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "bacteriaSpawn" ]);
				spawnEntity.add( new Id( EnemyType.BACTERIA )); 
				_shipGroup.addSpawn( spawnEntity, EnemyType.BACTERIA, 10, new Point( -5, 5 ), new Point( -10, 10 ), new Point( -10, 10 ) );
				
				for( number = 1; number < 6; number ++ )
				{
					spawnEntity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "wBCSpawn" + number ]);
					spawnEntity.add( new Id( EnemyType.WHITE_BLOOD_CELL + number ));
					_shipGroup.addSpawn( spawnEntity, EnemyType.WHITE_BLOOD_CELL, number, new Point( -2, 2 ), new Point( 10, 0 ), new Point( 20, 10 ) );
				}
				
				var zone:Entity = super.getEntityById( "zone" );
				Zone( zone.get( Zone )).entered.addOnce( setupBattle );
				
				var splinter:Entity = EntityUtils.createMovingEntity( this, super._hitContainer[ "splinter" ]);
				splinter.add( new Id( "splinter" )).add( new ShakeMotion()).add( new Sleep());
			}
				
			else
			{
				if( !super.shellApi.checkEvent( _events.HAND_HEMORRHAGES_CURED ))
				{
					alertSecondary();
				}
				
				for(  number = 1; number < 5; number ++ )
				{
					if( !super.shellApi.checkEvent( _events.CLOGGED_HAND_CUT_ + number ))
					{
						entity = super.getEntityById( "bloodFlow" + number + "Target" );
						_shipGroup.addSpawn( entity, EnemyType.RED_BLOOD_CELL, 12, new Point( 80, 40 ), new Point( 0, 40 ), new Point( 0, 140 ), .5 );
						damageTarget = entity.get( DamageTarget );
						damageTarget.reactToInvulnerableWeapons = false;
					}
					else
					{
						_counter++;
						super.removeEntity( super.getEntityById( "bloodFlow" + number + "Target" ));
						super.removeEntity( super.getEntityById( "bloodFlow" + number ));
						timeline = super.getEntityById( "bloodFlow" + number  + "Art" ).get( Timeline );
						timeline.gotoAndPlay( "end" );
					}
				}
				
				super.removeEntity( super.getEntityById( "zone" ));
				
				MovieClip( super._hitContainer[ "splinter" ]).visible = false;
				
				super.shellApi.eventTriggered.add( cureCut );
			}
		}
		
		
		/*********************************************************************************
		 * SECONDARY OBJECTIVE
		 */
		private function alertSecondary():void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, Command.create( super.playMessage, "hand_secondary", false, "hand_secondary", "drLang" )));
		}
		
		private function cureCut( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			trace( event );
			_counter++;
			if( _counter == 4 )
			{
				super.playMessage( "hand_resolved", false, "hand_resolved", "drLang" );
				super.shellApi.completeEvent( _events.HAND_HEMORRHAGES_CURED );
			}
		}
		
		/*********************************************************************************
		 * BATTLE SETUP
		 */
		private function setupBattle( zoneId:String, entityId:String ):void
		{
			var slots:WeaponSlots = this.shellApi.player.get(WeaponSlots);
			//var weapons:Array = [WeaponType.GUN, WeaponType.GOO, WeaponType.SCALPEL, WeaponType.SHOCK];
			
			for(var i:String in slots.slots)
			{
				var weaponEntity:Entity = slots.slots[i];
				
				if(weaponEntity)
				{
					var weapon:Weapon = weaponEntity.get(Weapon);
					
					if(weapon)
					{
						weapon.damage = 0;
					}
				}
			}
			
			var target:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "wBCTarget" ]);
			target.add( new Id( "wBCTarget" ));
			
			_handState.state = _handState.BATTLE;
			
			MotionUtils.zeroMotion( shellApi.player );
			
			super.lockControls( true );
			
			var cameraZoom:CameraZoomSystem = super.getSystem( CameraZoomSystem ) as CameraZoomSystem;
			cameraZoom.scaleTarget = .8;
			
			super.shellApi.triggerEvent( _events.FIGHTING_INFECTION );
		}
		
		/*********************************************************************************
		 * SPLINTER
		 */
		private function removeSplinter( ):void
		{
			var splinter:Entity = super.getEntityById( "splinter" );
			shakeSplinter();
			
			ShakeMotionSystem( super.addSystem( new ShakeMotionSystem() )).configEntity( splinter );
		}
		
		private function shakeSplinter( ):void
		{
			var shake:ShakeMotion = super.getEntityById( "splinter" ).get( ShakeMotion );
			shake.shakeZone = new RectangleZone( -10, -10, 10, 10 );
			
			var motion:Motion = shellApi.player.get( Motion );
			motion.pause = true;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, pullSplinter ));
			
			super.shellApi.triggerEvent( _events.SPLINTER_REMOVED, true );
		}
		
		private function pullSplinter( ):void
		{
			var splinter:Entity = super.getEntityById( "splinter" );
			var tween:Tween = new Tween();
			
			tween.to( Spatial( super.getEntityById( "splinter" ).get( Spatial )), 5, { x : 3210, y : 430, onComplete : killSplinter });
			splinter.add( tween ).remove( ShakeMotion );
		}
		
		private function killSplinter( ):void
		{
			super.getEntityById( "splinter" ).remove( ShakeMotion );
			super.removeEntity( super.getEntityById( "splinter" ));
		}
		
		/*********************************************************************************
		 * LOSE WEAPONS
		 */
		private function loseWeapons( weaponType:String ):void
		{
			var url:String;
			
			switch( weaponType )
			{
				case WeaponType.SHIELD:
					url = "shield.swf";
					super.playMessage( "shield_offline", false, "shield_offline", "drLang" );
					break;
				case WeaponType.SHOCK:
					url = "shock.swf";
					super.playMessage( "shock_offline", false, "shock_offline", "drLang" );
					break;
				case WeaponType.SCALPEL:
					url = "scalpel.swf";
					super.playMessage( "scalpel_offline", false, "scalpel_offline", "drLang" );
					break;
				case WeaponType.GOO:
					url = "goo.swf";
					super.playMessage( "goo_offline", false, "goo_offline", "drLang" );
					break;
				case WeaponType.ANTIGRAV:
					url = "antiGrav.swf";
					super.playMessage( "antiGrav_offline", false, "antiGrav_offline", "drLang" );
					break;
			}
			var number:int = Math.abs( Math.random() + 1 );
			super.shellApi.triggerEvent( _events.PART_STOLEN_ + number );
			super.shellApi.loadFile( super.shellApi.assetPrefix + "scenes/" + super.shellApi.island + "/items/" + url, stealWeapon, weaponType );
		}
		
		private function stealWeapon( asset:MovieClip, weaponType:String ):void
		{
			var weapon:Entity = EntityUtils.createSpatialEntity( this, asset, super._hitContainer );
			var offsetX:int = -20;
			var offsetY:int = -10;	
			
			var spatial:Spatial = weapon.get( Spatial );
			
			if( weaponType == WeaponType.SCALPEL )
			{
				spatial.scaleY = -1;
			}
			
			var threshold:Threshold = new Threshold( "x", "<" );
			threshold.threshold = 2000;
			threshold.entered.addOnce( Command.create( killWeapon, weapon, weaponType ));
			weapon.add( threshold );
			weapon.add( _handState.motion );
			EntityUtils.positionByEntity( weapon, super.shellApi.player );
			
			spatial.x = _handState.spatial.x + offsetX;
			spatial.y = _handState.spatial.y + offsetY;
			
			super.shellApi.removeEvent( _events.GOT_ + weaponType );
			_shipGroup.removeWeapon( super.shellApi.player, weaponType );
		}
		
		private function killWeapon( weapon:Entity, weaponType:String ):void
		{
			if(weapon)
			{
				switch( weaponType )
				{
					case WeaponType.SHIELD:
						_handState.state = _handState.STEAL_SHOCK;
						break;
					case WeaponType.SHOCK:
						_handState.state = _handState.STEAL_SCALPEL;
						break;
					case WeaponType.SCALPEL:
						_handState.state = _handState.STEAL_GOO;
						break;
					case WeaponType.GOO:
						_handState.state = _handState.STEAL_ANTIGRAV;
						break;
					case WeaponType.ANTIGRAV:
						_handState.state = _handState.ROBBED;
						break;
				}
				super.removeEntity( weapon );
			}
		}
		
		/*********************************************************************************
		 * SHIP DIALOG
		 */
		private function analyzeShip():void
		{	
			super.playMessage( "wbc_theft", true, "wbc_theft", "player" );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 6, 1, shipResponse ));
			
			for( var number:int = 1; number < 6; number ++ )
			{
				super.removeEntity( super.getEntityById( EnemyType.WHITE_BLOOD_CELL + number ));
			}
			
			super.shellApi.completeEvent( _events.ATTACKED_BY_WBC );
			super.removeEntity( super.getEntityById( "zone" ));
		}
		
		private function shipResponse():void
		{
			super.playMessage( "wbc_theft_2", false, "wbc_theft_2", "drLang" );
			super._bodyMap.get( Timeline ).paused = false;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 18, 1, regainControl ));
		}
		
		private function regainControl():void
		{
			super._bodyMap.get( Timeline ).gotoAndStop( "open" );
			super.playMessage( "wbc_theft_3", true, "wbc_theft_3", "player" );
			
			super.lockControls( false );
			var motion:Motion = shellApi.player.get( Motion );
			motion.pause = false;
			
			var damageTarget:DamageTarget = _ship.get( DamageTarget );
			damageTarget.damage = 0;
			
			var weaponEntity:Entity = getEntityById( WeaponType.GUN, shellApi.player );
			var sleep:Sleep = weaponEntity.get( Sleep );
			var weapon:Weapon = weaponEntity.get( Weapon );
			
			var ship:Ship = shellApi.player.get( Ship );
			var weaponSlots:WeaponSlots = shellApi.player.get( WeaponSlots );
			weaponSlots.active = weaponEntity;
			
		//	ship.locked = true;
			
			shellApi.setUserField( _events.DAMAGE_FIELD, 0, shellApi.island );
			shellApi.setUserField( _events.WEAPON_FIELD, weapon.type, shellApi.island );
			shellApi.profileManager.save();
			
			weapon.state = weapon.EXPAND;
			sleep.sleeping = false;
			ship.unlock = true;
		}	
		
		private var _events:VirusHunterEvents;
		private var _look:LookData;
		private var _counter:int = 0;
		
		private var _ship:Entity;
		private var _shipGroup:ShipGroup;
		private var _handState:HandState;
		private var _handStateEntity:Entity;
	}
}