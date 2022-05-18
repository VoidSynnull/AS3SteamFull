package game.scenes.virusHunter.foreArm
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.systems.CameraZoomSystem;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.motion.Threshold;
	import game.components.hit.Mover;
	import game.components.hit.Radial;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.components.entity.OriginPoint;
	import game.scenes.virusHunter.foreArm.components.BossSpawn;
	import game.scenes.virusHunter.foreArm.components.Cut;
	import game.scenes.virusHunter.foreArm.components.ForeArmState;
	import game.scenes.virusHunter.foreArm.popups.GymPopup;
	import game.scenes.virusHunter.foreArm.popups.VictoryPopup;
	import game.scenes.virusHunter.foreArm.systems.ForeArmBossSystem;
	import game.scenes.virusHunter.foreArm.systems.ForeArmTargetSystem;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.JoesHealth;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class ForeArm extends ShipScene
	{
		public function ForeArm()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.minCameraScale = .75;
			super.groupPrefix = "scenes/virusHunter/foreArm/";
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
			
			_events = super.events as VirusHunterEvents;
			_total = new Dictionary();
			_cuts = new Vector.<Entity>;
			
			_foreArmState = new ForeArmState();
			_foreArmStateEntity = new Entity();
			_foreArmStateEntity.add( _foreArmState );
			
			super.addEntity( _foreArmStateEntity );
			
			_shipGroup = super.getGroupById("shipGroup") as ShipGroup;
			_shipGroup.createSceneWeaponTargets(super._hitContainer);
			
			var foreArmTargetSystem:ForeArmTargetSystem = new ForeArmTargetSystem( this, _shipGroup );
			foreArmTargetSystem._triggerVictoryPopup.add( triggerVictoryPopup );
			foreArmTargetSystem._triggerShockSpawn.add( bossDefeated );
				
			super.addSystem( new ForeArmBossSystem(), SystemPriorities.lowest );
			super.addSystem( foreArmTargetSystem, SystemPriorities.checkCollisions );
			super.addSystem( new ThresholdSystem() );
			super.addSystem( new TweenSystem(), SystemPriorities.update );
			
			// moving this setup here out of allShipsLoaded
			_ship = super.getEntityById( "player" );
			
			var killCount:KillCount = new KillCount();
			killCount.count[ "virus_spawn" ] = 0;
			killCount.count[ "calcium" ] = 0;
			
			super.shellApi.player.add( killCount );
			
			setupScene();
		}
		/*
		override protected function allShipsLoaded():void
		{
			super.allShipsLoaded();
			
			_ship = super.getEntityById( "player" );
			
			var killCount:KillCount = new KillCount();
			killCount.count[ "virus_spawn" ] = 0;
			killCount.count[ "calcium" ] = 0;
			
			super.shellApi.player.add( killCount );
			
			setupScene();
		}
		*/
		/*********************************************************************************
		 * SCENE SETUP
		 */
		private function setupScene():void
		{
			var entity:Entity;
			var timeline:Timeline;
			var target:DamageTarget;
			
			setupCalcifications();
			setupBloodFlow();
			
			for( var number:int  = 1; number < 3; number ++ )
			{
				entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "enemySpawn" + number + "Art" ]);
				entity.add( new Id( "enemySpawn" + number + "Art" )).add( new Audio()).add( new AudioRange(600, 0.01, 1));
			
				TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( entity )).content, this, entity );
				timeline = entity.get( Timeline );
				timeline.labelReached.add( Command.create( bossSpawnHandler, entity ));
				timeline.paused = true;
				
				Sleep( entity.get( Sleep )).ignoreOffscreenSleep = true;
				Sleep( entity.get( Sleep )).sleeping = false;
				
				entity.add(new Audio());
				entity.add(new AudioRange(600, 0.01, 1));
				
				entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "muscle" + number + "Art" ]);
				entity.add( new Id( "muscle" + number + "Art" ));
				
				TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( entity )), this, entity );
				timeline = entity.get( Timeline );
				timeline.labelReached.add( Command.create( muscleHandler, entity ));	
				timeline.paused = true;
				
				entity.add(new Audio());
				entity.add(new AudioRange(600, 0.01, 1));
				
				entity = super.getEntityById( "nerve" + number + "Target" );
				target = entity.get( DamageTarget );
				target.reactToInvulnerableWeapons = false;
			}
			
			// remove muscle lock until triggered
			entity = super.getEntityById( "musclesLocked" );
			entity.remove( Radial );
			
			if( !super.shellApi.checkEvent( _events.ARM_BOSS_DEFEATED ))
			{
				var threshold:Threshold = new Threshold( "x", ">" );
				threshold.threshold = 1400;
				threshold.entered.addOnce( virusAttack );
			
				_ship.add( threshold );
			}	
			else
			{
				for( number = 1; number < 3; number ++ )
				{
					timeline = super.getEntityById( "enemySpawn" + number + "Art" ).get( Timeline );
					timeline.gotoAndStop( "endDestroy" );
					super.removeEntity( super.getEntityById( "enemySpawn" + number + "Target" ));
					super.removeEntity( super.getEntityById( "enemySpawn" + number ));
					
					this.removeEntity(this.getEntityById("nerve" + number + "Target"));
				}
				
				if(!super.shellApi.checkEvent(VirusHunterEvents(super.events).GOT_SHOCK))
				{
					super.addSceneItem(WeaponType.SHOCK, 420, 420);
				}
			}
			
			if( !super.shellApi.checkEvent( _events.CALCIFCATION_REMOVED ))
			{
				alertSecondary();
			}
		}
		
		/*********************************************************************************
		 * SECONDARY OBJECTIVE
		 */
		private function alertSecondary():void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, Command.create( super.playMessage, "arm_secondary", false, "arm_secondary", "drLang" )));
		}
		
		private function regainControl():void
		{			
			SceneUtil.setCameraTarget( this, _ship );	
			super.lockControls(false);
		}
		
		private function setupCalcifications():void
		{
			var calc:Entity;
			var timeline:Timeline;
			var killCount:KillCount = super.shellApi.player.get( KillCount );
			
			for( var number:int = 1; number < 7; number ++ )
			{
				calc = EntityUtils.createSpatialEntity( this, super._hitContainer[ "calc" + number + "Art" ]);
				calc.add( new Id( "calc" + number + "Art" )).add( new Audio());
				
				if( !super.shellApi.checkEvent( _events.DESTROYED_CALCIFICATION_ + number ))
				{
					TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( calc )), this, calc );
					timeline = calc.get( Timeline );
					timeline.labelReached.add( Command.create( calcificationHandler, calc ));
				}
				else 
				{
					killCount.count[ "calcium" ] ++;
					super.removeEntity( super.getEntityById( "calc" + number + "Art" ));
					super.removeEntity( super.getEntityById( "calc" + number ));
					super.removeEntity( super.getEntityById( "calc" + number + "Target" ));
				}
			}
		}
		
		private function calcificationHandler( label:String, calc:Entity ):void
		{
			var timeline:Timeline = calc.get( Timeline );
			
			switch( label )
			{
				case "endIdle":
					timeline.gotoAndPlay( "idle" );
					break;
				case "endBreak":
					timeline.labelReached.removeAll();
					timeline.paused = true;
					super.shellApi.triggerEvent( _events.DESTROYED_CALCIFICATION_ + removeCalcTag( Id( calc.get( Id )).id ), true );
					break;
			}
		}
		
		/*********************************************************************************
		 * SETUP BLOODFLOW
		 */
		private function setupBloodFlow():void
		{
			trace("ForeArm :: Setting up blood flow.");
			
			var target:Entity;
			var art:Entity;
			var mover:Mover;
			
			var choice:Number;
			var flag:Boolean;
			
			var damageTarget:DamageTarget;
			var timeline:Timeline;
			var sleep:Sleep;
			
			for( var number:int = 1; number < 8; number ++ )
			{		
				art = EntityUtils.createSpatialEntity( this, super._hitContainer[ "bloodFlow" + number + "Art" ]);
				art.add( new Id( "bloodFlow" + number + "Art" ));
				TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( art )), this, art );
			
				sleep = art.get( Sleep );
				sleep.sleeping = false;
				sleep.ignoreOffscreenSleep = true;
				
				Display( art.get( Display )).visible = false;
				target = super.getEntityById( "bloodFlow" + number + "Target" );
				target.remove( DamageTarget );
			}
			
			if( !super.shellApi.checkEvent( _events.ARM_BOSS_DEFEATED ))
			{
				while( _chosenNumbers.length < 3 )
				{
					flag = false;
					choice = Math.round( Math.random() * 6 ) + 1;	
					
					for( var check:int = 0; check < _chosenNumbers.length; check ++ )
					{
						if( choice == _chosenNumbers[ check ] )
						{
							flag = true;
						}
					}
					
					if( !flag )
					{
						_chosenNumbers.push( choice );
					}
				}
				
				for( check = 0; check < 3; check ++ )
				{
					damageTarget = new DamageTarget();
					damageTarget.maxDamage = 2;
					damageTarget.damageFactor = new Dictionary();
					damageTarget.damageFactor[ WeaponType.GOO ] = 1;
					damageTarget.reactToInvulnerableWeapons = false;
					
					art = super.getEntityById( "bloodFlow" + _chosenNumbers[ check ] + "Art" );
					Display( art.get( Display )).visible = true;
					
					mover = new Mover();
					mover.acceleration = new Point( -400, 150 );
					
					super.getEntityById( "bloodFlow" + _chosenNumbers[ check ]).add( mover );
					
					target = super.getEntityById( "bloodFlow" + _chosenNumbers[ check ] + "Target" );
					target.add( new Cut() ).add( damageTarget );
					_shipGroup.addSpawn( target, EnemyType.RED_BLOOD_CELL, 3, new Point(80, 40), new Point(-30, -40), new Point(40, 30), .5 ); 
				
					_cuts[ check ] = target;
				}
				
				// remove the unused targets
				for( number = 1; number < 8; number ++ )
				{
					target = super.getEntityById( "bloodFlow" + number + "Target" );
					damageTarget = target.get( DamageTarget );
					if(! damageTarget )
					{
						super.removeEntity( target );
					}
				}
			}
			else
			{
				for( number = 1; number < 8; number ++ )
				{
					art = super.getEntityById( "bloodFlow" + number + "Art" );
					
					if( super.shellApi.checkEvent( _events.CLOGGED_FOREARM_CUT_ + number ))
					{
						Display( art.get( Display )).visible = true;
						timeline = art.get( Timeline );
						timeline.gotoAndStop( "closed" );
					}
				
					super.removeEntity( super.getEntityById( "bloodFlow" + number + "Target" ));
				}
			}
		}
		
		/*********************************************************************************
		 * TIMELINE HANDLERS
		 */
		private function bossSpawnHandler( label:String, art:Entity ):void
		{
			var timeline:Timeline = art.get( Timeline );
			var bossSpawn:BossSpawn = art.get( BossSpawn );
			var entity:Entity;
			
			switch( label )
			{
				case "endIntro":
					timeline.paused = true;
					break;
				
				case "switchSpawnState":;
					bossSpawn.bossState = bossSpawn.ALIVE;
					entity = _shipGroup.enemyCreator.create( EnemyType.EVO_VIRUS, null, bossSpawn.spawnX, bossSpawn.spawnY, new Point( 0, 0 ), new Point( 10, 10 ), 0, true, true );
					Spatial( entity.get( Spatial )).rotation = bossSpawn.rotation;
					
					if( entity.get( Timeline ))
					{	
						Timeline( entity.get( Timeline )).gotoAndPlay( "idle" );
					}
					
					EntityUtils.addParentChild(entity, art);
					break;
				
				case "endHit":
					timeline.gotoAndStop( "endIntro" );
					bossSpawn.bossState = bossSpawn.ALIVE;
					break;
				
				case "endDefeat":
					super.shellApi.player.get( KillCount ).count[ "virus_spawn" ] ++;
					break;
				
				case "endDestroy":
					timeline.paused = true;
					
					if( super.shellApi.player.get( KillCount ).count[ "virus_spawn" ] >= _foreArmState.TOTAL_SPAWNS )
					{
						_foreArmState.state = _foreArmState.SPAWNS_KILLED;
						super.playMessage( "sample_taken", false, "sample_taken" );
						_shockSpawn = art;
						var spawnPoint:OriginPoint = new OriginPoint( bossSpawn.spawnX, bossSpawn.spawnY );
						_shockSpawn.add( spawnPoint );
					}
					
					art.remove( BossSpawn );
					timeline.labelReached.removeAll();
					break;
			}
		}
		
		private function muscleHandler( label:String, muscle:Entity ):void
		{
			var timeline:Timeline = muscle.get( Timeline );
			
			switch( label )
			{
				case "closed":
					timeline.paused = true;
					break;
				
				case "reopened":
					timeline.paused = true;
					break;
			}
		}
		
		/*********************************************************************************
		 * BOSS INTRO
		 */
		private function virusAttack():void
		{
			super.lockControls(true);
			
			if( super._dialogWindow.isOpened )
			{
				super._dialogWindow.messageComplete.addOnce( alertVirusAttack );
			}
			else 
			{
				alertVirusAttack();
			}
		}
		
		private function alertVirusAttack():void
		{
			super.playMessage( "virus_attack", false, "virus_attack" );
			super._dialogWindow.messageComplete.addOnce( triggerGymPopup );
		}
		
		private function constrictMuscles():void
		{
			var entity:Entity;
			var timeline:Timeline;
			
			for( var number:int = 1; number < 3; number ++ )
			{
				entity = super.getEntityById( "muscle" + number + "Art" );
				
				timeline = entity.get( Timeline );
				timeline.paused = false;
				
				super.shellApi.triggerEvent( _events.MUSCLE_EXPAND );
			}
			
			entity = super.getEntityById( "musclesLocked" );
			entity.add( new Radial() );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, showFirstBossSpawn ));
		}
		
		private function showFirstBossSpawn():void
		{
			super.shellApi.loadFile( super.shellApi.assetPrefix + "scenes/" + super.shellApi.island + "/shared/joeLifeBar.swf", setupJoesHealth );
			
			var cameraZoom:CameraZoomSystem = super.getSystem( CameraZoomSystem ) as CameraZoomSystem;
			cameraZoom.scaleTarget = .75;
			
			var enemySpawn:Entity = super.getEntityById( "enemySpawn1Art" );
			SceneUtil.setCameraTarget( this, enemySpawn );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, showFirstCut ));
		}
		
		private function showFirstCut():void
		{
			SceneUtil.setCameraTarget( this, _cuts[ 0 ]);
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, showSecondCut ));
		}
		
		private function showSecondCut():void
		{
			SceneUtil.setCameraTarget( this, _cuts[ 1 ]);
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, showThirdCut ));
		}
		
		private function showThirdCut():void
		{
			SceneUtil.setCameraTarget( this, _cuts[ 2 ]);
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, showSecondBossSpawn ));
		}
		
		private function showSecondBossSpawn():void
		{
			var enemySpawn:Entity = super.getEntityById( "enemySpawn2Art" );
			SceneUtil.setCameraTarget( this, enemySpawn );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, enterBossSpawn ));
		}
		
		private function enterBossSpawn():void
		{
			var enemySpawn:Entity;
			var timeline:Timeline;
			var sound:String;
			var audio:Audio;
			
			for( var number:int = 1; number < 3; number ++ )
			{
				enemySpawn = super.getEntityById( "enemySpawn" + number + "Art" );
				timeline = enemySpawn.get( Timeline );
				timeline.paused = false;
			}
			
			sound = BOSS_SPAWN;
			audio = enemySpawn.get(Audio);
			
			if( audio == null )
			{
				audio = new Audio();
				
				enemySpawn.add(audio);
			}
			
			audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 5, 1, startBattle ));
			SceneUtil.addTimedEvent( this, new TimedEvent( 6.5, 1, regainControl ));
		}
		
		/*********************************************************************************
		 * BOSS BATTLE
		 */
		private function startBattle():void
		{				
			var art:Entity;
			var target:Entity;
			var bossSpawn:BossSpawn;
			var joe:Entity = super.getEntityById( "joe" );
			
			
			// add necessary components to joes healthbar to get picked up by the system
			var healthBar:JoesHealth = new JoesHealth();
			joe.add( healthBar );

			var spatial:Spatial;
			
			_foreArmState.state = _foreArmState.BATTLE;
			var enemySpawn:EnemySpawn;
			
			for( var number:int = 1; number < 3; number ++ )		
			{
				art = super.getEntityById( "enemySpawn" + number + "Art" );
				target = super.getEntityById( "enemySpawn" + number + "Target" );
				
				enemySpawn = new EnemySpawn();
				
				spatial = art.get( Spatial );
				bossSpawn = new BossSpawn();
				
				if( number == 1 )
				{
					bossSpawn.spawnX = 2295;
					bossSpawn.spawnY = 435;
				 	bossSpawn.rotation = 99;
				}
				
				else
				{
					bossSpawn.spawnX = 1300;
					bossSpawn.spawnY = 1050;
					bossSpawn.rotation = -72.1
				}
				
				art.add( bossSpawn ).add( new Children());
				Sleep( art.get( Sleep )).ignoreOffscreenSleep = true;
				Sleep( art.get( Sleep )).sleeping = false;
			}
		}
		
		/*********************************************************************************
		 * BOSS VICTORY
		 */
		private function bossDefeated( ):void
		{
			super.lockControls( true );
			var origin:OriginPoint = _shockSpawn.get( OriginPoint );
			super.addSceneItem( WeaponType.SHOCK, origin.x, origin.y );
		
			super.shellApi.triggerEvent( _events.ARM_BOSS_DEFEATED, true );
			
			for( var number:int = 0; number < 3; number ++ )
			{
				super.shellApi.completeEvent( _events.CLOGGED_FOREARM_CUT_ + _chosenNumbers[ number ]);
			}
			
			SceneUtil.setCameraTarget( this, _shockSpawn);
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, regainControl ));
		}
		
		/*********************************************************************************
		 * CRAMP POPUP
		 */
		private function triggerGymPopup():void
		{
			var popup:GymPopup = super.addChildGroup( new GymPopup( super.overlayContainer )) as GymPopup;
			popup.closeSignal.add( closePopup );
			popup.id = "gymPopup";
		}
		
		private function closePopup(...args):void
		{
			var popup:Popup = super.getGroupById( "gymPopup" ) as Popup;
			popup.close();	
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, constrictMuscles ));
		}
		
		/*********************************************************************************
		 * VICTORY POPUP
		 */
		public function triggerVictoryPopup():void
		{
			var popup:VictoryPopup = super.addChildGroup( new VictoryPopup( super.overlayContainer )) as VictoryPopup;
			popup.closeSignal.add( closeVictoryPopup );
			popup.id = "victoryPopup";
		}
		
		private function closeVictoryPopup(...args):void
		{
			var popup:Popup = super.getGroupById( "victoryPopup" ) as Popup;
			popup.close();
			
			this.shellApi.triggerEvent(this._events.MUSCLE_CONTRACT);
		}
		
		/*********************************************************************************
		 * UTILS
		 */
		private function setupJoesHealth( asset:MovieClip ):void
		{
			var joe:Entity = EntityUtils.createSpatialEntity( this, asset.content, super.overlayContainer );
			joe.add( new Id( "joe" ));
			
			var spatial:Spatial = joe.get( Spatial );
			
			spatial.x = super.shellApi.viewportWidth - ( spatial.width );
			spatial.y = super.shellApi.viewportHeight - ( spatial.height + 50 );
		}
		
		private function removeCalcTag(id:String):String
		{
			var index:Number = id.indexOf("Art");
			
			return( id.slice( 4, index ));
		}
		
		private function removeArt( id:String ):String 
		{
			var index:Number = id.indexOf("Art");
			
			return( id.slice( 0, index ));
		}
		
		public var calcCount:int;
		
		static private const BOSS_SPAWN:String = "infection.mp3";
		private var _cuts:Vector.<Entity>;
		private var _chosenNumbers:Vector.<Number> = new Vector.<Number>;
		private var _shockSpawn:Entity; 
		
		private var _events:VirusHunterEvents;
		
		private var _ship:Entity;
		private var _shipGroup:ShipGroup;
		private var _total:Dictionary;
		
		private var _foreArmState:ForeArmState;
		private var _foreArmStateEntity:Entity;
	}
}