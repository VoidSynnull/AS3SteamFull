package game.scenes.virusHunter.heart {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.systems.CameraSystem;
	
	import game.components.hit.Zone;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.condoInterior.components.SimpleUpdater;
	import game.scenes.virusHunter.condoInterior.systems.SimpleUpdateSystem;
	import game.scenes.virusHunter.heart.components.AngleHit;
	import game.scenes.virusHunter.heart.components.QuadVirus;
	import game.scenes.virusHunter.heart.components.virusStates.QuadVirusState;
	import game.scenes.virusHunter.heart.components.virusStates.VirusAttackState;
	import game.scenes.virusHunter.heart.components.virusStates.VirusLungeState;
	import game.scenes.virusHunter.heart.components.virusStates.VirusSwingState;
	import game.scenes.virusHunter.heart.creator.VirusCreator;
	import game.scenes.virusHunter.heart.systems.AngleHitSystem;
	import game.scenes.virusHunter.heart.systems.ArmExtendSystem;
	import game.scenes.virusHunter.heart.systems.ArmRestoreSystem;
	import game.scenes.virusHunter.heart.systems.ArmTargetSystem;
	import game.scenes.virusHunter.heart.systems.ArmWaveSystem;
	import game.scenes.virusHunter.heart.systems.ArrhythmiaSystem;
	import game.scenes.virusHunter.heart.systems.ColorBlinkSystem;
	import game.scenes.virusHunter.heart.systems.FatDamageSystem;
	import game.scenes.virusHunter.heart.systems.FatDeathSystem;
	import game.scenes.virusHunter.heart.systems.NerveHitSystem;
	import game.scenes.virusHunter.heart.systems.QuadVirusSystem;
	import game.scenes.virusHunter.heart.systems.RigidArmSystem;
	import game.scenes.virusHunter.heart.systems.VirusTargetSystem;
	import game.scenes.virusHunter.heart.util.QuadVirusUtils;
	import game.scenes.virusHunter.joesCondo.creators.ClipCreator;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.systems.SystemPriorities;
	import game.util.MotionUtils;
	import game.util.SceneUtil;


	public class Heart extends ShipScene {

		private var virusEntity:Entity;
		private var virusInfo:QuadVirus;			// QuadVirus component with some control functions.

		private var virusEvents:VirusHunterEvents;

		private var leftWall:Entity;
		private var rightWall1:Entity;
		private var rightWall2:Entity;
		private var topWall:Entity;
		private var botWall:Entity;

		private var leftZone:Entity;
		private var rightZone:Entity;
		private var topZone:Entity;
		private var botZone:Entity;
		
		private var _shipGroup:ShipGroup;
		
		private var player:Entity;

		// Indicates the path beneath the pulmonary artery? is active. true by default.
		private var usingLowPath:Boolean = false;

		// lungPath needs to swap above and below the player when they pass through the zones on either side.
		private var lungPath:MovieClip;

		// Points at which the virus appears in the scene, along with orientation.
		private var virusPoints:Vector.<Object>;
		private var virusStage:int = 0;				// runs through the virusPoints.

		private var clipCreator:ClipCreator;
		private var virusCreator:VirusCreator;

		private var virusUtils:QuadVirusUtils;

		public function Heart() {
			super();
		}

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			super.groupPrefix = "scenes/virusHunter/heart/";			
			super.init( container );

		} //

		// initiate asset load of scene specific assets.
		override public function load():void {

			super.load();

		} //

		// all assets ready
		override public function loaded():void {

			this.addSystem( new FatDamageSystem(), SystemPriorities.update );
			this.addSystem( new FatDeathSystem(), SystemPriorities.postUpdate );

			// Used to wait for the virus to get fully offscreen.
			this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );
			this.addSystem( new AngleHitSystem(), SystemPriorities.resolveCollisions );

			player = this.getEntityById( "player" );
			this.virusEvents = events as VirusHunterEvents;

			this.addSystem( new ArrhythmiaSystem( virusEvents ), SystemPriorities.update );

			this.virusCreator = new VirusCreator( this );
			this.clipCreator = new ClipCreator( this );

			this.initArrhythmia();
			
			_shipGroup = super.getGroupById( "shipGroup" ) as ShipGroup;
			_shipGroup.createSceneWeaponTargets(super._hitContainer);

			if ( !shellApi.checkEvent( virusEvents.HEART_BOSS_DEFEATED ) ) {

				this.initNerves( true );

				this.initFatGroups();

				// color blink system for virus blink on hit.
				this.addSystem( new ColorBlinkSystem(), SystemPriorities.update );
				this.addSystem( new QuadVirusSystem(), SystemPriorities.update );
				
				this.addSystem( new ArmRestoreSystem(), SystemPriorities.preUpdate );				
				this.addSystem( new ArmExtendSystem(), SystemPriorities.preUpdate );
				this.addSystem( new ArmWaveSystem(), SystemPriorities.preUpdate );
				
				this.addSystem( new RigidArmSystem(), SystemPriorities.postUpdate );
				this.addSystem( new ArmTargetSystem(), SystemPriorities.update );

				makeVirus();

				/**
				 * Converts the player coordinates to target coordinates in the virus' reference frame
				 * so the arms seek to the correct locations.
				 */
				var targetSystem:VirusTargetSystem = new VirusTargetSystem();
				targetSystem.setVirus( virusEntity );
				targetSystem.setTarget( player );
				this.addSystem( targetSystem, SystemPriorities.move );

				this.virusUtils = new QuadVirusUtils( virusEntity, this, player );

				//doVirusStage( 0 );

			} else {

				this.initNerves( false );

				this.destroyFat();			// fat is dead from last time.

				// hit the nerves to open up the muscles.
				this.addSystem( new NerveHitSystem( this._hitContainer ), SystemPriorities.update );

				if ( shellApi.checkEvent( virusEvents.GOT_GOO ) ) {

					if ( (player.get(Spatial) as Spatial).x < 1500 ) {
						expandMuscles();
					}

				} else {

					// player didnt get the shock from before.
					placeGoo();

				} //

				killVirusPoints();

			} // end-if.

			_shipGroup.createOffscreenSpawn(EnemyType.RED_BLOOD_CELL, 6, .5, 40, 140, 5);
			
			initLungPath();

			super.loaded();

			virusCreator = null;
			clipCreator = null;

		} //

		private function makeVirus():void {

			var virusBase:MovieClip = this.getAsset( "quadVirus.swf" ) as MovieClip;
			virusBase.mouseChildren = false;
			virusBase.mouseEnabled = false;

			virusEntity = virusCreator.createVirus( this._hitContainer as MovieClip, virusBase );
			virusInfo = virusEntity.get( QuadVirus );

			virusInfo.onVirusWounded = virusWounded;

			initVirusPoints();

			// wait for the player to see the virus for the opening.
			waitVirusIntro();

		} //

		/**
		 * Whenever the virus is wounded, it runs away to the next stage and changes its attack strategy.
		 */
		private function virusWounded():void {

			SceneUtil.lockInput( this, true );
			MotionUtils.zeroMotion( player );

			// All but the last virus point should have a retreat location.
			var point:Object = virusPoints[ virusStage ];

			if ( virusStage >= 3 ) {
				killVirus();
				return;
			}

			virusInfo.waveArms();

			//virusInfo.onTargetDone = virusReachedTarget;
			virusInfo.doTargetMove( point.retreatX, point.retreatY );
			virusEntity.add( new SimpleUpdater( checkVirusOffscreen ) );

		} //

		private function waitVirusIntro():void {

			virusEntity.add( new SimpleUpdater( waitVirusOnscreen ) );

		} //

		private function waitVirusOnscreen( time:Number ):void {

			var pSpatial:Spatial = player.get( Spatial );
			var vSpatial:Spatial = virusEntity.get( Spatial );
			var dx:Number = vSpatial.x - pSpatial.x;
			var dy:Number = vSpatial.y - pSpatial.y;

			if ( (dx*dx + dy*dy) > 800*800 ) {
				return;
			}

			virusEntity.remove( SimpleUpdater );

			// i put the intro and death scenes in virus utils just to keep the main class from getting
			// so cluttered.
			
			shellApi.triggerEvent( virusEvents.HEART_BOSS_STARTED );
			virusUtils.doVirusIntro( doVirusStage );

		} // waitVirusOnscreen()

		private function checkVirusOffscreen( time:Number ):void {

			var camSys:CameraSystem = this.getSystem( CameraSystem ) as CameraSystem;

			var vSpatial:Spatial = virusEntity.get( Spatial );
			var del:Number = vSpatial.x - ( -camSys.x + camSys.viewportWidth/2 );

			if ( Math.abs(del) < ( camSys.viewportWidth + vSpatial.width/4 ) / 2 ) {
				return;
			}

			del = vSpatial.y - ( -camSys.y + camSys.viewportHeight/4 );
			if ( Math.abs(del) < ( camSys.viewportHeight+vSpatial.height )/2 ) {
				return;
			}

			virusOffscreen();

		} // checkVirusOffscreen()

		private function doVirusStage( stage:int=0 ):void {

			virusStage = stage;
			var point:Object = virusPoints[stage];

			virusInfo.stopMotion();
			virusInfo.setPosition( point.x, point.y, point.rotation );

			var states:Vector.<QuadVirusState> = new Vector.<QuadVirusState>();

			virusInfo.stopArms();			// reset the arms before waving again.
			virusInfo.waveArms();

			// Different virus attacks based on stage.
			if ( stage == 0 ) {

				states.push( new VirusAttackState( virusEntity ) );
				states.push( new VirusSwingState( virusEntity ) );

				virusInfo.doMultiMode( states );

			} else if ( stage == 1 ) {

				states.push( new VirusAttackState( virusEntity ) );
				states.push( new VirusLungeState( virusEntity ) );
				
				virusInfo.doMultiMode( states );

			} else if ( stage == 2 ) {

				states.push( new VirusSwingState( virusEntity ) );
				states.push( new VirusLungeState( virusEntity ) );

				virusInfo.doMultiMode( states );

			} else if ( stage == 3 ) {

				states.push( new VirusLungeState( virusEntity ) );
				states.push( new VirusAttackState( virusEntity ) );
				states.push( new VirusLungeState( virusEntity ) );
				
				virusInfo.doMultiMode( states );

			} //

			virusInfo.hittable = true;

		} // doVirusStage()

		private function killVirus():void {

			// This almost certainly shouldn't be necessary, but since there is some strange bug about,
			// might as well make sure.
			virusInfo.onVirusWounded = null;

			SceneUtil.lockInput( this, false );

			// look for the virus blocking wall and remove it.
			var wall:Entity = this.getEntityById( "virusBlock" + (virusStage+1) );
			if ( wall != null ) {
				this.removeEntity( wall );
			}

			virusInfo.stopMotion();

			virusUtils.doVirusDeathScene( deathComplete );

		} //

		private function deathComplete():void {

			SceneUtil.lockInput( this, false );
			shellApi.triggerEvent( virusEvents.HEART_BOSS_DEFEATED, true );

		} //

		private function virusOffscreen():void {

			var motion:Motion = virusEntity.get( Motion ) as Motion;

			virusInfo.targetMove = false;
			SceneUtil.lockInput( this, false );

			// look for the virus blocking wall and remove it.
			var wall:Entity = this.getEntityById( "virusBlock" + (virusStage+1) );
			if ( wall != null ) {
				this.removeEntity( wall );
			}

			virusEntity.remove( SimpleUpdater );

			doVirusStage( virusStage + 1 );

		} //

		// For now just waiting til virus is offscreen.
		/*private function virusReachedTarget( virus:Entity ):void {

			SceneUtil.lockInput( this, false );
			doVirusStage( virusStage + 1 );

		} //*/

		private function doLowPath( zoneId:String, hitterId:String ):void {

			if ( usingLowPath || hitterId != "player" ) {
				return;
			}

			( leftWall.get( AngleHit ) as AngleHit ).enabled = false;
			( rightWall1.get( AngleHit ) as AngleHit ).enabled = false;
			( rightWall2.get( AngleHit ) as AngleHit ).enabled = false;

			( topWall.get( AngleHit ) as AngleHit ).enabled = true;
			( botWall.get( AngleHit ) as AngleHit ).enabled = true;

			var pDisplay:DisplayObjectContainer = ( player.get( Display ) as Display ).displayObject;

			this._hitContainer.setChildIndex( pDisplay, this._hitContainer.getChildIndex( lungPath ) );

			usingLowPath = true;

		} //

		private function doHighPath( zoneId:String, hitterId:String ):void {

			if ( usingLowPath == false || hitterId != "player" ) {
				return;
			}

			( leftWall.get( AngleHit ) as AngleHit ).enabled = true;
			( rightWall1.get( AngleHit ) as AngleHit ).enabled = true;
			( rightWall2.get( AngleHit ) as AngleHit ).enabled = true;

			( topWall.get( AngleHit ) as AngleHit ).enabled = false;
			( botWall.get( AngleHit ) as AngleHit ).enabled = false;

			var pDisplay:DisplayObjectContainer = ( player.get( Display ) as Display ).displayObject;
			this._hitContainer.swapChildren( lungPath, pDisplay );
			usingLowPath = false;

		} //

		private function initLungPath():void {

			lungPath = this._hitContainer[ "lungPath" ];

			var e:Entity = this.getEntityById( "leftZone" );
			var zone:Zone = e.get( Zone );
			zone.entered.add( doLowPath );

			e = this.getEntityById( "rightZone" );
			zone = e.get( Zone );
			zone.entered.add( doLowPath );
			
			e = this.getEntityById( "topZone" );
			zone = e.get( Zone );
			zone.entered.add( doHighPath );

			e = this.getEntityById( "botZone" );
			zone = e.get( Zone );
			zone.entered.add( doHighPath );

			// STUPID WALLS.

			leftWall = clipCreator.createAngleHit( this._hitContainer["leftBlock"] );

			rightWall1 = clipCreator.createAngleHit( this._hitContainer["rightBlock1"] );
			rightWall2 = clipCreator.createAngleHit( this._hitContainer["rightBlock2"] );

			topWall = clipCreator.createAngleHit( this._hitContainer["topBlock"] );
			botWall = clipCreator.createAngleHit( this._hitContainer["botBlock"] );

			( topWall.get( AngleHit ) as AngleHit ).enabled = false;
			( botWall.get( AngleHit ) as AngleHit ).enabled = false;

			//( leftWall.get( AngleHit ) as AngleHit ).enabled = false;
			//( rightWall1.get( AngleHit ) as AngleHit ).enabled = false;
			//( rightWall2.get( AngleHit ) as AngleHit ).enabled = false;

		} //

		/**
		 * Probably need to combine certain blocks of fat and put them in a masking clip.
		 */
		/*private function initFatGroups():void {

			var i:int = 1;
			var mc:MovieClip = _hitContainer["fatBlock"+i];

			while ( mc != null ) {

				virusCreator.makeVirusFat( mc );

				i++
				mc = _hitContainer[ "fatBlock"+i ];

			} // end-while.

		} //*/

		/**
		 * Fat blocks are stored in subclips with masking.
		 */
		private function initFatGroups():void {

			var i:int = 1;
			var j:int;
			var grp:MovieClip = this._hitContainer[ "fatGroup"+i ];
			var mc:MovieClip;

			while ( grp != null ) {

				j = 1;
				mc = grp[ "fatBlock"+j ];
				while ( mc != null ) {

					virusCreator.makeVirusFat( mc, grp["fatHit"+j] );

					j++;
					mc = grp[ "fatBlock"+j ];

				} // end-while.

				i++;
				grp = this._hitContainer[ "fatGroup"+i ];

			} // end-while( grp )

		} //

		private function destroyFat():void {

			var i:int = 1;
			var grp:MovieClip = this._hitContainer[ "fatGroup"+i ];
			
			while ( grp != null ) {

				this._hitContainer.removeChild( grp );

				i++;
				grp = this._hitContainer[ "fatGroup"+i ];

			} // end-while( grp )

		} //

		private function initNerves( wallsUp:Boolean=false ):void {

			var i:int = 1;
			var mc:MovieClip = this._hitContainer["nerveTarget"+i];

			var deleteNerves:Boolean = (player.get(Spatial) as Spatial).x > 2000;

			var block:Entity;

			while ( mc != null ) {

				if ( deleteNerves ) {

					mc.parent.removeChild( mc );
					this._hitContainer.removeChild( this._hitContainer[ "virusBlock"+i ] );

				} else {

					this.virusCreator.makeNerve( mc, i );

					block = this.clipCreator.createAngleHit( this._hitContainer[ "virusBlock"+i ] );
					( block.get( AngleHit ) as AngleHit ).enabled = wallsUp;

				} //

				i++
				mc = this._hitContainer[ "nerveTarget"+i ];

			} // end-while.

		} //

		private function placeGoo():void {

			var mc:MovieClip = this._hitContainer[ "virusPoint4" ];
			this.addSceneItem( WeaponType.GOO, mc.x, mc.y );

		} //

		private function expandMuscles():void {

			var i:int = 1;
			var mc:MovieClip = this._hitContainer[ "muscle"+i ];

			var block:Entity;
			var hit:AngleHit;

			while ( mc != null ) {

				mc.scaleX = 2.2;

				block = this.getEntityById( "virusBlock"+i );
				if ( block ) {
					( block.get( AngleHit ) as AngleHit ).enabled = true;
				} //

				i++;
				mc = this._hitContainer[ "muscle"+i ];

			} // end-while.

		} // initMuscles()

		private function initArrhythmia():void {

			// one is the hit target, the other is the animated clip.
			this.virusCreator.makeArrhythmia( this._hitContainer[ "arrhythmiaTarget" ], this._hitContainer[ "arrhythmia" ] );

		} //

		/**
		 * Get rid of virus points and virus blocks not being used.
		 */
		private function killVirusPoints():void {
			
			var i:int = 1;
			var mc:MovieClip = this._hitContainer[ "virusPoint"+i ];
			var obj:Object;

			while ( mc != null ) {

				this._hitContainer.removeChild( mc );

				// check for a retreatPoint from this location where the virus will retreat to once injured.
				mc = this._hitContainer[ "retreatPoint"+i ];
				if ( mc != null ) {
					this._hitContainer.removeChild( mc );
				}

				i++;
				mc = this._hitContainer[ "virusPoint"+i ];

			} //

		} //

		private function initVirusPoints():void {

			this.virusPoints = new Vector.<Object>();

			var i:int = 1;
			var mc:MovieClip = this._hitContainer[ "virusPoint"+i ];
			var obj:Object;

			while ( mc != null ) {

				obj = new Object();
				obj.x = mc.x;
				obj.y = mc.y;
				obj.rotation = mc.rotation;

				virusPoints.push( obj );
				this._hitContainer.removeChild( mc );

				// check for a retreatPoint from this location where the virus will retreat to once injured.
				mc = this._hitContainer[ "retreatPoint"+i ];
				if ( mc != null ) {

					obj.retreatX = mc.x;
					obj.retreatY = mc.y;
					this._hitContainer.removeChild( mc );

				}

				i++;
				mc = this._hitContainer[ "virusPoint"+i ];

			} //

			obj = virusPoints[0];
			virusInfo.setPosition( obj.x, obj.y, obj.rotation );

		} // initVirusPoints()

	} // class

} // package