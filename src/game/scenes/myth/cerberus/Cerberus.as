package game.scenes.myth.cerberus
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.TransportGroup;
	
	import game.components.entity.Dialog;
	import game.components.hit.Door;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.timeline.TimelineMaster;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Push;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.scenes.myth.cerberus.components.CerberusControlComponent;
	import game.scenes.myth.cerberus.components.CerberusHeadComponent;
	import game.scenes.myth.cerberus.components.CerberusSnoreComponent;
	import game.scenes.myth.cerberus.systems.CerberusSnoreSystem;
	import game.scenes.myth.cerberus.systems.CerberusSystem;
	import game.scenes.myth.shared.Mirror;
	import game.scenes.myth.shared.MythScene;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Cerberus extends MythScene
	{
		public function Cerberus()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/cerberus/";
			
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
			var clip:MovieClip;
			var entity:Entity;
			
			super.shellApi.triggerEvent( _events.SAW_CERBERUS, true);

			super.shellApi.eventTriggered.add( eventTriggers );
			_control = new CerberusControlComponent();
			
			addSystem( new CerberusSystem( _control ), SystemPriorities.move );
			addSystem( new CerberusSnoreSystem( _control ), SystemPriorities.update );
			
			if( !super.shellApi.checkEvent( _events.SAW_CERBERUS ))
			{
				super.shellApi.triggerEvent( _events.SAW_CERBERUS, true );
			}
			
			clip = _hitContainer[ "boulder" ];
			
			if( !shellApi.checkEvent( _events.HADES_THRONE_OPEN ))
			{	
		//		DisplayUtils.convertToBitmapSpriteBasic( clip, null, 2 );
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "boulder" ));
			
				_audioGroup.addAudioToEntity( entity );
				
				entity = super.getEntityById( "doorThrone" );
				SceneInteraction( entity.get( SceneInteraction )).reached.removeAll();
				SceneInteraction( entity.get( SceneInteraction )).reached.add( doorReached );	
			}
			
			else
			{	
				_hitContainer.removeChild( clip );
				super.removeEntity( getEntityById( "hercsBoulder" ));
			}
			
			setupHeads();
			
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM)
				{
					var transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				}
				if(transportGroup)
				{
					transportGroup.transportIn( player );
				}
				else
				{
					this.shellApi.removeEvent(_events.TELEPORT);
					this.shellApi.triggerEvent(_events.TELEPORT_FINISHED);
				}
				if( super.shellApi.checkEvent( _events.TELEPORT_HERC ))
				{
					if(transportGroup) transportGroup.transportIn( super.getEntityById( "herc" ), false);
					super.shellApi.removeEvent( _events.TELEPORT_HERC );
				}
			}
			else
			{
				_control.playerDisplay = player.get( Display );
			}
		}
		
		private function doorReached( char:Entity, door:Entity ):void
		{
			// lock controls
			SceneUtil.lockInput( this );
			
			if( shellApi.checkEvent( _events.HADES_THRONE_OPEN ))
			{
				// open
				Door( door.get( Door )).open = true;
			}
			else
			{
				// not open
				Dialog( char.get( Dialog )).sayById( "rocks_blocking" );
				Dialog( char.get( Dialog )).complete.add( unlockInput );
			}
		}
		
		private function unlockInput( dialogData:DialogData = null ):void
		{
			SceneUtil.lockInput( this, false, false );
		}
		
		private function moveBoulder( dialogData:DialogData ):void
		{
			var tween:Tween = new Tween();
			var entity:Entity = super.getEntityById( "herc" );
			
			CharUtils.setDirection( entity, true );
			var spatial:Spatial = entity.get( Spatial );
			
			var animations:Vector.<Class> = new Vector.<Class>;
			animations.push( Push );
			
			CharUtils.setAnimSequence( entity, animations, true );			
			tween.to( spatial, 5, { x : spatial.x + 300, onComplete : goAhead });
			entity.add( tween );
			
			entity = super.getEntityById( "boulder" );
			spatial = entity.get( Spatial );
			
			
			startSmoke();
			shellApi.triggerEvent( "move_boulder" );
			shellApi.triggerEvent( _events.HADES_THRONE_OPEN, true );
			tween = new Tween();
			tween.to( spatial, 5, { x : spatial.x + 300 });
			entity.add( tween );
		}
		
		private function startSmoke():void
		{
			var entity:Entity = super.getEntityById( "boulder" );
			var emitter:Emitter2D = new Emitter2D();
			
			emitter.counter = new Random( 20, 30 );
			emitter.addInitializer( new ImageClass( Blob, [10, 0xEEEEEE], true ) );
			emitter.addInitializer( new AlphaInit( .3, .5 ));
			emitter.addInitializer( new Lifetime( .5, 1 )); 
			emitter.addInitializer( new Velocity( new LineZone( new Point( -75, -10), new Point( 75, -15 ))));
			emitter.addInitializer( new Position( new EllipseZone( new Point( 0, 0 ), 50, 2 )));
			
			emitter.addAction( new Age( Quadratic.easeOut ));
			emitter.addAction( new Move());
			emitter.addAction( new RandomDrift( 100, 0 ));
			emitter.addAction( new ScaleImage( .7, 1.5 ));
			emitter.addAction( new Fade( .7, 0 ));
			emitter.addAction( new Accelerate( 0, -10 ));
			
			EmitterCreator.create( this, super._hitContainer[ "smokeContainer" ], emitter, 20, 0, null, "smokeEmitter", entity.get( Spatial ) );
		}
		
		private function goAhead():void
		{
			var entity:Entity = super.getEntityById( "herc" );
			var dialog:Dialog = entity.get( Dialog );

			super.removeEntity( super.getEntityById( "smokeEmitter" ));
			
			dialog.sayById( "go_ahead" );
			dialog.complete.addOnce( returnControl );
		}
		
		private function returnControl( ...args ):void
		{
			SceneUtil.setCameraTarget( this, player );
			SceneUtil.lockInput( this, false );
		}
		
		/*******************************
		 * 		 EVENT HANDLERS
		 * *****************************/
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var spatial:Spatial;// = player.get( Spatial );
			var entity:Entity;
			
			if( event == _events.SOOTHING_MELODY )
			{
				spatial = player.get( Spatial );
				if( spatial.x > 920 )
				{
					super.shellApi.triggerEvent( "closer_to_the_beast" );
				}
				else
				{
					_control.isSoothed = true;
				}
			}
			
			if( event == _events.SLEEPING_CERBERUS )
			{
				if( !super.shellApi.checkEvent( GameEvent.HAS_ITEM + _events.CERBERUS_WHISKER ))
				{
					entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "whisker" ]);
					ToolTipCreator.addToEntity( entity );
					
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					var sceneInteraction:SceneInteraction = new SceneInteraction();
					
					sceneInteraction.reached.removeAll();
					sceneInteraction.reached.add( getWhisker );
					
					entity.add( sceneInteraction ).add( new Id( "whisker" ));
				}
			}
			
			if( event == _events.USE_MIRROR )
			{
				_control.teleporting = true;				
				showPopup(); 
			}
			
			if( event == _events.NOT_APHRODITE || event == _events.NOT_HADES || event == _events.NOT_POSEIDON || event == _events.NOT_ZEUS )
			{
				entity = super.getEntityById( "herc" );
				var dialog:Dialog = entity.get( Dialog );
				
				dialog.sayById( event + "_text" )
			}
			
			if( event == _events.TELEPORT_FINISHED )
			{
				if( super.shellApi.checkEvent( _events.HERCULES_UNDERGROUND ))
				{
					if( !shellApi.checkEvent( _events.HADES_THRONE_OPEN ))
					{
						_control.playerDisplay = player.get( Display );
						CharUtils.setDirection( player, true );
						entity = super.getEntityById( "herc" );
						
						SceneUtil.lockInput( this );
						SceneUtil.setCameraTarget( this, entity );
						
						dialog = entity.get( Dialog );
						dialog.say( "open_path" );
						dialog.complete.addOnce( moveBoulder );	
					}
				}
				super.shellApi.removeEvent( _events.TELEPORT_FINISHED );
			}
		}
		
		private function showPopup():void
		{
			var popup:Mirror = super.addChildGroup( new Mirror( super.overlayContainer, true )) as Mirror;
			popup.id = "mirror";
		}
		
		
		private function getWhisker( char:Entity, whisker:Entity ):void
		{
			super.shellApi.getItem( WHISKER, null, true );
			
			super.removeEntity( super.getEntityById( "whisker" ));
		
			super.removeEntity( whisker );
		}
		
		/*******************************
		 * 		 CERBERUS BOSS
		 * *****************************/
		private function setupHeads():void
		{
			var number:int;
			var hit:Entity;
			var entity:Entity;
			var headEntity:Entity;
			var neckEntity:Entity;
			var display:Display;
			var zeeDisplay:Display;
			
			var snore:CerberusSnoreComponent;
			var cerberus:CerberusHeadComponent;
			
			var spatial:Spatial;
			var zeeSpatial:Spatial;
			var timeline:Timeline;
			var timelineClip:TimelineClip;
			var clip:MovieClip;
			var zClip:MovieClip;
			var creator:HitCreator = new HitCreator();
			var hazardHitData:HazardHitData;
			var zeeNumber:Number;
			var zee:Entity;
			
			for( number = 1; number < 4; number ++ )
			{
				cerberus = new CerberusHeadComponent( Math.random() * 40 );
				headEntity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "head" + number ]);
				headEntity.add( new Id( "head" + number ));
				
//				var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
				_audioGroup.addAudioToEntity( headEntity );
				headEntity.add( new AudioRange( 500, .1, 1 ));
				
				timeline = new Timeline();
				headEntity.add( timeline ).add(new TimelineMaster());
				
				timelineClip = new TimelineClip();
				timelineClip.mc = super._hitContainer[ "head" + number ];
				headEntity.add(timelineClip);
				
				TimelineUtils.parseMovieClip( timeline, timelineClip.mc );
				timelineClip.mc.gotoAndStop( 1 );
				
				// neck
				display = headEntity.get( Display );
				clip = display.displayObject.getChildByName( "neck" );
				neckEntity = EntityUtils.createSpatialEntity( this, clip );
				cerberus.neckSpatial = neckEntity.get( Spatial );
				
				// blinks
				display = neckEntity.get( Display );
				clip = display.displayObject.getChildByName( "blink" );
				entity = EntityUtils.createSpatialEntity( this, clip );
				timeline = new Timeline();
				entity.add( timeline ).add(new TimelineMaster());
				
				timelineClip = new TimelineClip();
				timelineClip.mc = clip;
				entity.add(timelineClip);
				
				TimelineUtils.parseMovieClip( timeline, timelineClip.mc );
				timelineClip.mc.gotoAndStop( 1 );				
				cerberus.blinkTimeline = timeline;
				cerberus.blinkSpatial = entity.get( Spatial );
				
				// hit clip
				clip = display.displayObject.getChildByName( "hit" );
				entity = EntityUtils.createSpatialEntity( this, clip );
				
				hazardHitData = new HazardHitData();
				hazardHitData.knockBackCoolDown = .75;
				hazardHitData.knockBackVelocity = new Point(400, 400);
				hazardHitData.velocityByHitAngle = true;
				creator.makeHit( entity, HitType.HAZARD, hazardHitData, this );
				cerberus.hit = entity;
				cerberus.hitDisplay = entity.get( Display );
				cerberus.hitDisplay.visible = false;
				
				// face
				clip = display.displayObject.getChildByName( "faces" );
				entity = EntityUtils.createSpatialEntity( this, clip );
				timeline = new Timeline();
				
				entity.add( timeline ).add(new TimelineMaster());
				timelineClip = new TimelineClip();
				timelineClip.mc = clip;
				entity.add(timelineClip);
				cerberus.faceSpatial = entity.get( Spatial );
				cerberus.faceTimeline = timeline;
				
				
				TimelineUtils.parseMovieClip( timeline, timelineClip.mc );
				timelineClip.mc.gotoAndStop( 1 );
				
				for( zeeNumber = 1; zeeNumber < 11; zeeNumber ++ )
				{
					snore = new CerberusSnoreComponent();
					clip = display.displayObject.getChildByName( "faces" ).getChildByName( "z" + zeeNumber );
		//			DisplayUtils.convertToBitmapSpriteBasic( clip, null, 2 );
					
					entity = EntityUtils.createSpatialEntity( this, clip );
					entity.add( new Id( "snore" + ( zeeNumber - 1 ) + "." + number )).add( new Tween());
					spatial = entity.get( Spatial );
					zeeDisplay = entity.get( Display );
					
					zeeDisplay.alpha = 0;
					snore.zeeStarterX = spatial.x;
					snore.zeeStarterY = spatial.y;
					snore.headNumber = number;
					snore.counter = zeeNumber * 20;
					
					entity.add( snore );
				}
				
				cerberus.rotation = Spatial( headEntity.get( Spatial )).rotation; 
				headEntity.add( cerberus );
			}
		}
		
		private static const WHISKER:String = "cerberusWhisker";
		private var _control:CerberusControlComponent;
	}
}