package game.scenes.myth.hydra
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.game.GameEvent;
	import game.scenes.myth.hydra.components.HydraControlComponent;
	import game.scenes.myth.hydra.components.HydraHeadComponent;
	import game.scenes.myth.hydra.components.HydraNeckComponent;
	import game.scenes.myth.hydra.systems.HydraHeadSystem;
	import game.scenes.myth.shared.MythScene;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;
	
	
	public class Hydra extends MythScene
	{
		private const WATER_DENSITY:Number 	= 1;
//		private const WATER_VISCOSITY:Number = .9;
		private const PLAYER_WEIGHT:Number = .1;
		private const HYDRA_SCALE:String = "hydraScale";
//		private var _audioGroup:AudioGroup
		public var _hydraControlComponent:HydraControlComponent;
		
		public function Hydra()
		{
			super();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/myth/hydra/";
			super.init( container );
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			
			_hydraControlComponent = new HydraControlComponent;		
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			var entity:Entity;
			
			CharUtils.setScale( super.player, .33 );
			
			//var cameraZoom:CameraZoomSystem = super.getSystem( CameraZoomSystem ) as CameraZoomSystem;
			//cameraZoom.scaleTarget = .8;
			
			shellApi.eventTriggered.add( eventTriggers );
			
			if( !super.shellApi.checkEvent( GameEvent.HAS_ITEM + _events.HYDRA_SCALE ))
			{
				setupHydraHeads();
			}
			else
			{
				_hydraControlComponent.defeated = true;
				setupHydraHeads( true );
			}
			
			var hydraSystem:HydraHeadSystem = new HydraHeadSystem( _hydraControlComponent );
			
			addSystem( new HydraHeadSystem( _hydraControlComponent ), SystemPriorities.update );
			addSystem( new ParticleSystem(), SystemPriorities.update );
		
		}
		
		/*******************************
		 * 		 EVENT HANDLERS
		 * *****************************/
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var number:int;
			var entity:Entity;
			
			switch( event ) 
			{
				case _events.HYDRA_DEFEATED:					
					if( !super.shellApi.checkEvent( GameEvent.HAS_ITEM + _events.HYDRA_SCALE ))
					{
							
						
						entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "scale" ]);
						ToolTipCreator.addToEntity( entity );//.addUIRollover( entity, "click" );
						
						InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
						var sceneInteraction:SceneInteraction = new SceneInteraction();
						
						sceneInteraction.reached.removeAll();
						sceneInteraction.reached.add( getScale );
						
						entity.add( sceneInteraction ).add( new Id( "scale" ));
					}
					break;
			}
		}
		
		private function getScale( char:Entity, scale:Entity ):void
		{
			super.shellApi.getItem( HYDRA_SCALE, null, true );
			
			super.removeEntity( scale );
		}
		
		/*******************************
		 * 		   HYDRA BOSS
		 * *****************************/
		private function setupHydraHeads( dead:Boolean = false ):void
		{
			var display:Display;
			var entity:Entity;
			var hit:Entity;
			var headComponent:HydraHeadComponent;
			var number:int;
			var timeline:Timeline;
			var timelineClip:TimelineClip;
			var followTarget:FollowTarget;
			
			var clip:MovieClip;
			var neckComponent:HydraNeckComponent;
			var hitCreator:HitCreator = new HitCreator();
			var angle:Number = - Math.PI / 2;
			
			var sequence:BitmapSequence = BitmapTimelineCreator.createSequence(_hitContainer[ "h" + 0 ]);

			for( number = 0; number < 5; number ++ )
			{	
				hit = getEntityById( "hit" + number );
				Sleep( hit.get( Sleep )).ignoreOffscreenSleep = true;
				
				headComponent = new HydraHeadComponent( hit, number );
				clip = MovieClip( super._hitContainer[ "t" + number ]);
				
				angle += ( Math.PI / 10 );
				
				if( number == 0 || number == 2 )
				{
					neckComponent = new HydraNeckComponent( 6, 55, angle, Math.PI * Math.random(), Math.random() * 10 ); 
				}
				else
				{
					neckComponent = new HydraNeckComponent( 5, 35, angle, Math.PI * Math.random(), Math.random() ); 
				}
				
				neckComponent.anchor = super._hitContainer[ "t" + number ];
				
				entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "b" + number ]);
				
				entity.add( new FollowTarget( hit.get( Spatial )));
				display = entity.get( Display );
				display.alpha = 0;
				headComponent.hitDisplay = display;
				
				entity = super.getEntityById( "h" + number );
				if(!PlatformUtils.inBrowser){
					BitmapTimelineCreator.convertToBitmapTimeline(entity,_hitContainer[ "h" + number ], true, sequence,1);
				}else{
					entity = TimelineUtils.convertClip(_hitContainer["h"+number],this,entity,null,false);
				}
				
				entity.remove(Sleep);
				
				timeline = entity.get(Timeline);
				timeline.reset( false );
				
				if( dead )
				{
					headComponent.state = "kill";
					timeline.gotoAndStop( "dead" );
				}
				
				headComponent.headTimeline = timeline;
				//headComponent.headTimelineClip = timelineClip;
				headComponent.headSpatial = entity.get( Spatial );
				headComponent.headNumber = number;
				
				_audioGroup.addAudioToEntity( hit );
				
				hit.add( headComponent ).add( neckComponent ).add( new AudioRange( 600, 0.1, 2 ));
				hitCreator.addHitSoundsToEntity( hit, _audioGroup.audioData, shellApi );
			}
		}
		
		
		
	}
}