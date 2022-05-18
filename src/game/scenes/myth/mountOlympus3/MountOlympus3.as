package game.scenes.myth.mountOlympus3
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.systems.CameraZoomSystem;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.entity.Dialog;
	import game.components.entity.EntityPoolComponent;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.Player;
	import game.components.hit.Hazard;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.TargetSpatial;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Soar;
	import game.data.display.BitmapWrapper;
	import game.data.ui.ToolTipType;
	import game.managers.EntityPool;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.myth.MythEvents;
	import game.scenes.myth.mountOlympus2.MountOlympus2;
	import game.scenes.myth.mountOlympus3.bossStates.BoltsState;
	import game.scenes.myth.mountOlympus3.bossStates.ChargeState;
	import game.scenes.myth.mountOlympus3.bossStates.DefeatState;
	import game.scenes.myth.mountOlympus3.bossStates.GustState;
	import game.scenes.myth.mountOlympus3.bossStates.MoveState;
	import game.scenes.myth.mountOlympus3.bossStates.OrbsState;
	import game.scenes.myth.mountOlympus3.bossStates.ZeusState;
	import game.scenes.myth.mountOlympus3.components.Bolt;
	import game.scenes.myth.mountOlympus3.components.FlightComponent;
	import game.scenes.myth.mountOlympus3.components.Gust;
	import game.scenes.myth.mountOlympus3.components.Orb;
	import game.scenes.myth.mountOlympus3.components.ZeusBoss;
	import game.scenes.myth.mountOlympus3.nodes.CloudCharacterStateNode;
	import game.scenes.myth.mountOlympus3.nodes.ZeusStateNode;
	import game.scenes.myth.mountOlympus3.playerStates.CloudAttack;
	import game.scenes.myth.mountOlympus3.playerStates.CloudCharacterState;
	import game.scenes.myth.mountOlympus3.playerStates.CloudHurt;
	import game.scenes.myth.mountOlympus3.playerStates.CloudStand;
	import game.scenes.myth.mountOlympus3.popups.LoseZeus;
	import game.scenes.myth.mountOlympus3.systems.BoltSystem;
	import game.scenes.myth.mountOlympus3.systems.FlightSystem;
	import game.scenes.myth.mountOlympus3.systems.GustSystem;
	import game.scenes.myth.mountOlympus3.systems.OrbSystem;
	import game.scenes.myth.shared.components.Cloud;
	import game.scenes.myth.shared.components.CloudMass;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.CloudSystem;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.CharacterMovementSystem;
	import game.systems.hit.HazardHitSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.ui.hud.Hud;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;

	public class MountOlympus3 extends PlatformerGameScene
	{
		public function MountOlympus3()
		{
			super();
		}
		
		override public function destroy():void
		{	
			_entityPool.destroy();
			_sacredItems = null;
			_zeus = null;
			super.destroy()
		}

		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{	
			super.groupPrefix = "scenes/myth/mountOlympus3/";
			super.init(container);
		}
			
		// all assets ready
		override public function loaded():void
		{
			_events = new MythEvents();
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			
			CharUtils.stateDrivenOff( player, 0 );
			
			shellApi.eventTriggered.add( eventTriggers );
			shellApi.defaultCursor = ToolTipType.TARGET;	
			
			var cameraZoom:CameraZoomSystem = super.getSystem( CameraZoomSystem ) as CameraZoomSystem;
			cameraZoom.scaleTarget = .65;
			
			_zeus = getEntityById( "zeus" );

			setupSacredItems();	// create sacred items that get removed on zeus defeat
			makeBolts();	// make bolts before settting zeus & player
//			setupZeus();	
//			setupPlayer();
			
			// remove unnecessary systems
			removeSystemByClass( CharacterMovementSystem );
			
			var hud:Hud = super.getGroupById( Hud.GROUP_ID ) as Hud;
			hud.disableButton( Hud.INVENTORY );
			hud.disableButton( Hud.COSTUMIZER );
			
			// add necessary systems
			addSystem( new RotateToTargetSystem());
			addSystem( new ThresholdSystem(), SystemPriorities.update );
			addSystem( new FollowTargetSystem());
			addSystem( new MotionTargetSystem());
			addSystem( new WaveMotionSystem());
			addSystem( new FlightSystem() );
			addSystem( new HazardHitSystem() );
			addSystem( new MotionControlBaseSystem() );
			addSystem( new MoveToTargetSystem( super.shellApi.viewportWidth, super.shellApi.viewportHeight ) );
		}

		private function showPopup():void
		{
			var popup:LoseZeus = super.addChildGroup( new LoseZeus( super.overlayContainer )) as LoseZeus;
			popup.id = "lose_zeus";
		}

		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			switch( event )
			{ 
				case _events.ZEUS_DOWNED:
					zeusDefeated();
					break;
				
				case _events.RETURN_ITEMS:
					SceneUtil.lockInput( this, true, false );
					shellApi.triggerEvent( "boss_win_get_items" );
					shellApi.removeEvent( "zeus_steal_finished" );
					// make player happy looking
					SkinUtils.setSkinPart( super.player, SkinUtils.MOUTH, "1", false );
					
					// start returning scared items
					EntityUtils.setSleep( _sacredItems, false );
					var audio:Audio = _sacredItems.get( Audio );
					audio.playCurrentAction( SPAWN );
					returnSacredItems();
					break;
		
				case _events.ZEUS_LOSE:		
					showPopup();
					break;
			}
		}
		
		private function setupSacredItems():void
		{
			var clip:MovieClip = _hitContainer[ "items" ];
			_sacredItems = EntityUtils.createMovingEntity( this, clip);
			BitmapTimelineCreator.convertToBitmapTimeline( _sacredItems, clip, true, null, PerformanceUtils.defaultBitmapQuality * 2 );
			_sacredItems.add( new Id( "sacred_items" ))
			_sacredItems.add( new Tween());
			_sacredItems.add( new Sleep( true, true ) );
			
			_audioGroup.addAudioToEntity( _sacredItems );
			
			var display:Display = _sacredItems.get( Display );
			display.moveToFront();
		}
		
		/**********************************
		 * 			CREATE BOLTS
		 * *******************************/
		
		private function makeBolts():void
		{
			var bolt:Bolt;
			var entity:Entity;
			var playerComponent:Player = super.player.get( Player );
			var maxPlayerBolts:int = 15;
			var maxBossBolts:int = 12;
			
			// create entity pool
			_entityPool = new EntityPool();
			_entityPool.setSize( Bolt.PLAYER_BOLT, maxPlayerBolts );
			_entityPool.setSize( Bolt.BOSS_BOLT, maxBossBolts );
			
			// get original bolt and make BitmapData
			var wrapper:BitmapWrapper = super.convertToBitmapSprite( _hitContainer[ "bolt" ] as MovieClip, null, false );
			var wrapperDuplicate:BitmapWrapper;
			
			// BOLTS FOR PLAYER
			var i:uint;
			for( i = 0; i < maxPlayerBolts; i++ )
			{
				wrapperDuplicate = wrapper.duplicate();
				entity = EntityUtils.createMovingEntity( this, wrapperDuplicate.sprite, _hitContainer );
				
				bolt = new Bolt();
				bolt.speed = 800;
				bolt.state = Bolt.OFF;
				bolt.radiusFromSource = 100;
				bolt.isEnemy = false;
				bolt.damage = 2;
				
				entity.add( new Id( Bolt.PLAYER_BOLT + "_" + i ))
				entity.add( bolt );
				entity.add( new Sleep(true, true) );
				entity.add( playerComponent );	// differentiates as player bolt
				_audioGroup.addAudioToEntity( entity );
				
				_entityPool.release( entity, Bolt.PLAYER_BOLT );	//add entity into pool
			}
			
			// BOLTS FOR ZEUS
			for ( i = 0; i < maxBossBolts; i++ ) 
			{
				wrapperDuplicate = wrapper.duplicate();
				entity = EntityUtils.createMovingEntity( this, wrapperDuplicate.sprite, _hitContainer );
				
				bolt = new Bolt();
				bolt.index = i;
				bolt.speed = 400;
				bolt.state = Bolt.OFF;
				bolt.radiusFromSource = 100;
				bolt.isEnemy = true;
				
				entity.add( new Id( Bolt.BOSS_BOLT + "_" + i ))
				entity.add( bolt );
				entity.add( new Sleep(true, true) );
				entity.add( new Hazard(0,0,false) );	// differentiates as player bolt
				_audioGroup.addAudioToEntity( entity );
				
				//if( i == 0 )	{ boss.firstBolt = entity; }	// TODO :: kind oof a hack, should use entityPool
				_entityPool.release( entity, Bolt.BOSS_BOLT );
			}
			
			// wrap in component and add to entities
			super.player.add( new EntityPoolComponent( _entityPool ) );
			_zeus.add( new EntityPoolComponent( _entityPool ) );
			
			setupZeus();	
		}
		
		/**********************************
		 * 			SETUP ZEUS
		 * *******************************/
		private function setupZeus():void
		{	
			var boss:ZeusBoss;
			var bossStates:Vector.<Class>;
			var clip:MovieClip;
			var creator:FSMStateCreator = new FSMStateCreator();
			var display:Display;
			var displayObjectBounds:Rectangle;
			var edge:Edge = new Edge();
			var electrify:ElectrifyComponent;
			var entity:Entity;
			var filters:Array; 
			var follow:FollowTarget;
			var fsm:FSMControl;
			var gust:Gust;
			var lifeBar:Entity;
			var number:int;
			var offsetMatrix:Matrix;
			var orb:Orb;
			var sleep:Sleep;
			var sparkNumber:int;
			var spatial:Spatial;
			var shockEntity:Entity;
			var sprite:Sprite;
			var startX:Number;
			var startY:Number;
			var wrapper:BitmapWrapper;
			
			_zeus.add( new Sleep( false, true ));
			_zeus.add( new Motion());
			_zeus.add( new Tween());
			_zeus.add( new TargetSpatial(super.player.get(Spatial)) );
			CharUtils.setAnim( _zeus, Soar );
			
			// remove uncessary components, make non-interactible
			_zeus.remove( SceneInteraction );
			_zeus.remove( Interaction );
			ToolTipCreator.removeFromEntity( _zeus );
			_zeus.remove( CharacterMotionControl );
			display = _zeus.get( Display );
			MovieClip(display.displayObject).mouseEnabled = false;
			MovieClip(display.displayObject).mouseChildren = false;
			
			
			// add movement components
			var motionControlBase:MotionControlBase = new MotionControlBase();	// variables are set within MoveState
			motionControlBase.freeMovement = true; 	// allow movement along both axises
			_zeus.add( motionControlBase );
			_zeus.add( new Navigation() );
			var motionControl:MotionControl = new MotionControl();
			motionControl.lockInput = true;
			_zeus.add( motionControl );
			
			// make player the motion target
			var motionTarget:MotionTarget = new MotionTarget();
			motionTarget.targetSpatial = super.player.get( Spatial );
			_zeus.add(motionTarget);
			
			// make life bar
			lifeBar = EntityUtils.createSpatialEntity( this, _hitContainer[ "bar" ]);
			follow = new FollowTarget();
			follow.target = _zeus.get( Spatial );
			follow.offset = new Point( -70, 100 );
			lifeBar.add( follow );
			
			// prep boss states
			boss = new ZeusBoss( lifeBar, SEQUENCES, SEQUENCES_LEVELS, ZEUS_HEALTH );
			_zeus.add( boss );		
			electrify = new ElectrifyComponent();
			electrify.on = false;
			
			_zeus.add( electrify );
			
			_audioGroup.addAudioToEntity( _zeus );
			
			// ZEUS ELECTRIFY
			for( number = 0; number < 10; number ++ )
			{
				sprite = new Sprite();
				startX = Math.random() * 60 - 60;
				startY = Math.random() * 60 - 140;				
				sprite.graphics.lineStyle( 1, 0xFFFFFF );
				sprite.graphics.moveTo( startX, startY );
				electrify.sparks.push( sprite );
				electrify.lastX.push( startX );
				electrify.lastY.push( startY );
				electrify.childNum.push( display.displayObject.numChildren );
				display.displayObject.addChildAt( sprite, display.displayObject.numChildren );
			}		
			
			bossStates = new Vector.<Class>();
			bossStates.push( MoveState, GustState, BoltsState, OrbsState, ChargeState, DefeatState );			
			_zeus.add( new FSMControl(super.shellApi));
			_zeus.add( new FSMMaster());
			creator.createStateSet( bossStates, _zeus, ZeusStateNode ); 			
			
			fsm = _zeus.get(FSMControl);
			fsm.setState( ZeusState.MOVE );
			
			/// ORBS
			wrapper = this.convertToBitmapSprite( _hitContainer[ "orb" ], null, false );
			var maxBossOrbs:int = 6;
			for( number = 0; number < maxBossOrbs; number++ )
			{
				entity = EntityUtils.createMovingEntity( this, wrapper.duplicate().sprite, _hitContainer );
				entity.add( new Id( "orb_" + number ));	
				display = entity.get( Display );
				orb = new Orb();
				orb.owner = this.getEntityById( "zeus" );
				orb.orbitTarget = orb.owner.get(Spatial);
				orb.startOrbitStep = Math.PI / 3;
				orb.radius = 140;
				orb.state = Orb.OFF;	
				entity.add( orb );
				
				entity.add( new Sleep(true, true) );
				
				electrify = new ElectrifyComponent();
				shockEntity = EntityUtils.createSpatialEntity( this, clip );
				electrify.shockDisplay = shockEntity.get( Display );
				electrify.on = false;
				electrify.shockDisplay.alpha = 1;
				entity.add( electrify )
				
				var hazard:Hazard = new Hazard();
				hazard.velocityByHitAngle = true;
				hazard.velocity = new Point( 100, 100 );
				hazard.interval = .1;
				hazard.coolDown = .2;
				hazard.active = false;
				entity.add( hazard );
				
				entity.add( new Tween());
				_audioGroup.addAudioToEntity( entity );
				
				if( number == 0 )
				{ 
					boss.orbEntity = entity;
				}		
			}
			
			// GUST
			entity = EntityUtils.createMovingEntity( this, hitContainer[ "gust" ]);
			entity.add( new Id( "gust" ));
			
			gust = new Gust();
			gust.active = true;
			gust.curID = 0;
			gust.lifeTime = 5;
			gust.speed = 400;
			gust.owner = _zeus;
			gust.ownerSpatial = _zeus.get( Spatial );
			entity.add( gust );
			sleep = new Sleep( true, true );
			entity.add( sleep );
			
			boss.gust = gust;
			boss.gustSleep = sleep;
			boss.gustDisplay = entity.get( Display );
			
			_audioGroup.addAudioToEntity( entity );
			
			setupPlayer();
		}
		
		/**********************************
		 * 			SETUP PLAYER
		 * *******************************/
		private function setupPlayer():void
		{
			// apply parts & remove special abilities
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "poseidon" );
			SkinUtils.setSkinPart( player, SkinUtils.HAIR, "hades" );
			
			// remove special abilities
			player.remove( SpecialAbilityControl );
			this.removeSystemByClass( SpecialAbilityControlSystem );
			
			// add clouds
			makePlayerClouds();
			
			// add flight movement
			player.add( new FlightComponent );

			// add Cloud States
			var fsm:FSMControl = player.get(FSMControl);
			
			player.remove( CharacterMovement );	// remove standard character movement 
			
			// reset any motion
			MotionUtils.zeroMotion( player );
			addSystem( new OrbSystem(), SystemPriorities.move );	
			addSystem( new GustSystem(), SystemPriorities.render );
			addSystem( new BoltSystem() );
			addSystem( new CloudSystem() );
			addSystem( new ElectrifySystem(), SystemPriorities.render );
			
			super.loaded();
			fsm.removeAll();
			var creator:FSMStateCreator = new FSMStateCreator();
			var playerStates:Vector.<Class> = new <Class>[ CloudAttack, CloudHurt, CloudStand ];
			creator.createStateSet( playerStates, player, CloudCharacterStateNode ); 
			
			fsm.setState( CloudCharacterState.STAND );
		}
		
		private function makePlayerClouds():void
		{
			var playerSpatial:Spatial = super.player.get( Spatial );
			var playerEdge:Edge = super.player.get(Edge);
			
			var number:int;
			var entity:Entity;
			var followTarget:FollowTarget;
			var waveMotionData:WaveMotionData;
			
			var spatial:Spatial;
			var cloud:Cloud;
			
			var randX:Number = 0;
			var randY:Number = 0;			
			
			var wrapper:BitmapWrapper = this.convertToBitmapSprite( _hitContainer[ "cloud" ] as MovieClip, null, false );
			var wrapperCopy:BitmapWrapper;

			var swirlOffset:Number;
			var cloudMass:CloudMass = new CloudMass();
			
			// create cloud Entities
			for( number = 0; number < cloudMass.maxClouds; number++ )
			{
				wrapperCopy = wrapper.duplicate();	
				entity = EntityUtils.createMovingEntity( this, wrapperCopy.sprite, _hitContainer );
				entity.add( new Id( "cloud" +  number ));
				cloud = new Cloud();
				entity.add( cloud )
				followTarget = new FollowTarget( super.player.get( Spatial ));
				followTarget.offset = new Point( 0, playerEdge.rectangle.bottom );
				entity.add( followTarget );
				
				spatial = entity.get(Spatial);
				if( number < cloudMass.startClouds )	// starter clouds for player
				{
					cloud.state = cloud.GATHER;
					cloud.attached = true;
					MotionUtils.zeroMotion( entity );
					randX = GeomUtils.randomInRange( playerSpatial.x - 30, playerSpatial.x + 30 );
					randY = GeomUtils.randomInRange( playerSpatial.y - 10, playerSpatial.y + 10 ) + playerEdge.rectangle.bottom;
					
					spatial.x = randX;
					spatial.y = randY;
					
					cloudMass.clouds.push( cloud );
				}
				else									// scatter remaining clouds across scene
				{
					cloud.state = cloud.SPAWN;
					cloud.attached = false;
					spatial.x = ( Math.random() * 1000 ) + 500;
					spatial.y = ( Math.random() * 200 ) + 400;
					
					followTarget.rate = 0;	// set rate to zero so it doesn't follow
				}
				
				if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH )
				{
					swirlOffset = GeomUtils.randomInRange( 1.0, 1.6 );
					MotionUtils.addWaveMotion( entity, new WaveMotionData("x", (( Math.random() * 3 ) + 3 ) * swirlOffset, 0.2), this );
				}
			}
			
			super.player.add( cloudMass );
			CharUtils.stateDrivenOn( player );
		}

		/**********************************
		 * 			VICTORY
		 * *******************************/
		private function zeusDefeated():void
		{
			SceneUtil.lockInput( this, true, false );
			FlightComponent( super.player.get( FlightComponent ) ).active;
			CloudMass( super.player.get( CloudMass ) ).invincible = true;
			FlightComponent( super.player.get( FlightComponent ) ).active = false;
			
			SceneUtil.setCameraTarget( this, _zeus );
			CharUtils.setAnim( _zeus, Hurt );
			CharUtils.getTimeline( _zeus ).handleLabel( Animation.LABEL_ENDING, dramaticPause );
		}
		
		private function dramaticPause():void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, triggerVictory ));
		}
		
		private function triggerVictory():void
		{
			var dialog:Dialog = _zeus.get( Dialog );
			dialog.sayById( _events.ZEUS_DEFEAT );
			dialog.complete.addOnce( setCamPlayer );

			CharUtils.setAnim( _zeus, Soar, true );
			CharUtils.getTimeline( _zeus ).gotoAndStop( 3 );
			
			var cameraZoom:CameraZoomSystem = super.getSystem( CameraZoomSystem ) as CameraZoomSystem;
			cameraZoom.scaleTarget = 1;
		}
		
		private function setCamPlayer( ...p ):void
		{
			SceneUtil.setCameraTarget( this, super.player );
		}
		
		private function returnSacredItems():void
		{
			var timeline:Timeline = _sacredItems.get( Timeline );
			
			// reposition & scale item
			EntityUtils.positionByEntity( _sacredItems, super.player );
			var startPosition:Point = EntityUtils.getPosition( _sacredItems );
			_sacredItems.get( Spatial ).scale = 0.01;
			startPosition.y -= 150;
			
			// increment item
			_itemIndex++;
			
			switch( _itemIndex )
			{
				case 1:		
					timeline.gotoAndStop( "Pearl" );
					EntityUtils.position( _sacredItems, startPosition.x, startPosition.y );
					growItem();
					break;
				case 2:		
					timeline.gotoAndStop( "Ring" );
					startPosition.x += 150;
					EntityUtils.position( _sacredItems, startPosition.x, startPosition.y );
					growItem();
					break;
				case 3:		
					timeline.gotoAndStop( "Scale" );
					startPosition.x -= 150;
					EntityUtils.position( _sacredItems, startPosition.x, startPosition.y );
					growItem();
					break;
				case 4:		
					timeline.gotoAndStop( "Hair" );
					startPosition.x += 100;
					EntityUtils.position( _sacredItems, startPosition.x, startPosition.y );
					growItem();
					break;
				case 5:		
					timeline.gotoAndStop( "Flower" );
					startPosition.x -= 100;
					EntityUtils.position( _sacredItems, startPosition.x, startPosition.y );
					growItem();
					break;
				default:
					super.removeEntity( _sacredItems );
					SceneUtil.addTimedEvent(this,new TimedEvent(1.5, 1, concludeScene));
			}
		}
		
		private function growItem():void
		{
			TweenUtils.entityTo( _sacredItems, Spatial, .4, { scale : 1, ease : Quad.easeInOut, onComplete:moveItem} );		
		}
		
		private function moveItem():void
		{
			var playerSp:Spatial = super.player.get( Spatial );
			TweenUtils.entityTo( _sacredItems, Spatial, .3, { x : playerSp.x , y : playerSp.y, scale : 0.01, ease : Quad.easeInOut, onComplete : returnSacredItems} );	
		}
		
		private function concludeScene():void
		{
			shellApi.completeEvent(_events.RETURNED_ITEMS);
			shellApi.takePhoto( "11744", delaySceneEnd )
		}
		
		private function delaySceneEnd(...p):void
		{
			SceneUtil.delay( this, 1.6, loadMountOlympus2 );
		}

		private function loadMountOlympus2():void 
		{
			trace("MOUNT OLYMPUS 3 SCENE IS OVER");
			shellApi.loadScene( MountOlympus2 );
		}
		
		private static const SPAWN:String = "spawn";
		
		// zeus variables
		private const SEQUENCE0:Vector.<String> = new <String>[ ZeusState.BOLT, ZeusState.GUST ];
		private const SEQUENCE1:Vector.<String> = new <String>[ ZeusState.ORBS, ZeusState.BOLT, ZeusState.GUST ];
		private const SEQUENCE2:Vector.<String> = new <String>[ ZeusState.CHARGE, ZeusState.ORBS, ZeusState.BOLT ];
		private const SEQUENCE3:Vector.<String> = new <String>[ ZeusState.CHARGE, ZeusState.ORBS ];
		
		public const SEQUENCES:Vector.<Vector.<String>> = new <Vector.<String>>[ SEQUENCE0, SEQUENCE1, SEQUENCE2, SEQUENCE3 ];
		public const SEQUENCES_LEVELS:Vector.<int> = new <int>[ 60, 30, 8 ];
		public const ZEUS_HEALTH:int = 100;
		
		private var _audioGroup:AudioGroup;
		private var _events:MythEvents;
		private var _itemIndex:int = 0;
		private var _sacredItems:Entity;
		private var _zeus:Entity;
		private var _entityPool:EntityPool;
	}
}