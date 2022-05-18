package game.scenes.survival5.baseCamp
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.DepthChecker;
	import game.components.entity.Dialog;
	import game.components.entity.Hide;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.EntityIdList;
	import game.components.input.Input;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.game.GameEvent;
	import game.scene.template.AudioGroup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival2.shared.components.Hookable;
	import game.scenes.survival5.shared.Survival5Scene;
	import game.scenes.survival5.shared.whistle.ListenerData;
	import game.scenes.survival5.shared.whistle.WhistleListener;
	import game.scenes.survival5.underground.Underground;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class BaseCamp extends Survival5Scene
	{
		private var _birdX:Number;
		private var _birdY:Number;
		private static const SPARKLE:String = "Sparkle";
		private static const RANDOM:String 	= "random";
		
		public function BaseCamp()
		{
			super();
			whistleListeners.push( 
				new ListenerData( "dog", caughtByDog, 375
								, new Rectangle( 1450, 500, 1300, 1100 ), 4, 1
								, new Point( 1800, 1230 )
								, new Point( 2680, 1150 ))
				, new ListenerData( "buren", caughtByDog, 375
								, new Rectangle( 0, 500, 1150, 1100 ), 4, 1
								, new Point( -100, 1120 )
								, new Point( 740, 1180 )));
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival5/baseCamp/";
			
			super.init(container);
		}
		
		override protected function addBaseSystems():void
		{
			super.addSystem( new WaveMotionSystem());
			super.addBaseSystems();
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
			addWoodPeckers();
			
			var threshold:Threshold = new Threshold( "y", ">" );
			threshold.threshold = 1700;
			threshold.entered.addOnce( loadUnderground );
			player.add( threshold );	
			player.add( new Hide());		
			
			setUpWhistle();
		}
		
		/**
		 * 
		 * SETUP WOODPECKERS
		 * 	ATTACH THEM TO THEIR NEST PLATFORM HITS, GIVE AUDIO, 
		 * 
		 */
		private function addWoodPeckers():void
		{
			player.remove(DepthChecker);
			var animatedHit:TriggerHit;
			var clip:MovieClip;
			var entity:Entity;
			var number:int;
			var platformEntity:Entity;

			var audioGroup:AudioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			
			for( number = 1; number < 3; number ++ )
			{
				clip = _hitContainer[ "woody" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				TimelineUtils.convertClip( _hitContainer[ "woody" + number ], this, entity );
				
				audioGroup.addAudioToEntity( entity );
			}		
			
			_birdX = clip.x;
			_birdY = clip.y;
			
			for( number = 1; number < 3; number ++ )
			{
				platformEntity = getEntityById( "woodyHit" + number );
				animatedHit = new TriggerHit( null );
				animatedHit.triggered = new Signal();
				switch( number )
				{
					case 1:
						entity = getEntityById( "woody1" );
						break;
					default:
						entity = getEntityById( "woody2" );
						break;
				}
				
				animatedHit.triggered.add( Command.create( disturbedWoodpecker, platformEntity, entity ));
				platformEntity.add( animatedHit );
			}
		}
		
		/**
		 * 
		 * STEPPED ON NEST AND FREAKED OUT BIRDS FAIL LOGIC
		 * 
		 */
		private function disturbedWoodpecker( platformEntity:Entity, bird:Entity ):void
		{
			var audio:Audio = bird.get( Audio );
			var id:Id = platformEntity.get( Id );
			var timeline:Timeline = bird.get( Timeline );
			var spatial:Spatial = bird.get( Spatial );
			var spatialAddition:SpatialAddition;
			var wave:WaveMotion;
			var waveData:WaveMotionData;
			var hunter:Entity;
			var destination:Destination;
			var targetX:Number = 350;
			var targetY:Number = 1075;
			
			if( timeline.currentIndex < timeline.getLabelIndex( "noticed" ) || timeline.currentIndex > timeline.getLabelIndex( "resetTrigger" ))
			{
				wave = new WaveMotion();
				waveData = new WaveMotionData( "y", 8, .2 );
				spatial.y -= 10;
				wave.data.push( waveData );
				
				bird.add( wave );
				
				spatialAddition = bird.get( SpatialAddition );
				if( !spatialAddition )
				{
					spatialAddition = new SpatialAddition();
					bird.add( spatialAddition );
				}
				audio.playCurrentAction( RANDOM );
				
				timeline.gotoAndPlay( "noticed" );
				timeline.handleLabel( "land", Command.create( bufferFrame, bird, platformEntity ), false );//, "triggerLoop" ));
				
				if( id.id == "woodyHit1" )
				{
					hunter = getEntityById( "buren" );
				}
				else
				{
					hunter = getEntityById( "dog" );
					targetX = 1940;
					targetY = 1160;
				}
				
				var input:Input = shellApi.inputEntity.get(Input);
				// DON'T DO THIS AFTER COMPLETED THE ISLAND
				if( shellApi.checkEvent( _events.ISLAND_INCOMPLETE ) && !input.lockInput )
				{
					setPlayerCaught( false );
					SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create( moveInHunter, hunter, targetX, targetY )));
				}
			}
		}
		
		/**
		 * 
		 * VB AND DOG RESPONSE TO BIRD PANIC
		 * 
		 */
		private function moveInHunter( hunter:Entity, targetX:Number, targetY:Number ):void
		{
			var whistleListener:WhistleListener;
			var motionControl:CharacterMotionControl;
			
			SceneUtil.setCameraTarget( this, hunter );
			whistleListener = hunter.get( WhistleListener );
			whistleListener.inspecting = true;
			
			motionControl = hunter.get( CharacterMotionControl );
			motionControl.maxVelocityX = INVESTIGATE_SPEED;
			
			setSpotState( hunter );
			CharUtils.moveToTarget( hunter, targetX, targetY, false, caughtInTree );
		}
		
		private function caughtInTree( hunter:Entity ):void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, caughtByBirds ));
		}
		
		private function caughtByBirds():void
		{
			SceneUtil.lockInput( this, false );
			var failPopup:DialogPicturePopup = new DialogPicturePopup( overlayContainer );
			failPopup.updateText( "You were caught! You'll need to be more careful.", "Try Again" );
			failPopup.configData( "dogPopup.swf", SHARED_PREFIX );
			failPopup.popupRemoved.addOnce(reloadScene);
			addChildGroup( failPopup );
		}
		
		private function bufferFrame( bird:Entity, platformEntity:Entity ):void
		{
			var timeline:Timeline = bird.get( Timeline );
			var id:Id = bird.get( Id );
			var entityList:EntityIdList = platformEntity.get( EntityIdList );
			if( entityList.entities.length > 0 )
			{
				timeline.handleLabel( "land", Command.create( resetBirdAnimation, bird, platformEntity ));
			}
			else
			{
				var spatialAddition:SpatialAddition = bird.get( SpatialAddition );
				spatialAddition.y = 0;
				
				var spatial:Spatial = bird.get( Spatial );
				if( id.id == "woody1" )
				{
					spatial.y = 854.75;	
				}
				else
				{
					spatial.y = 763.7;
				}
				
				var audio:Audio = bird.get( Audio );
				audio.stopAll( "effects" );
				
				bird.remove( WaveMotion );
			}
		}
		
		private function resetBirdAnimation( bird:Entity, platformEntity:Entity ):void
		{
			var timeline:Timeline = bird.get( Timeline );

			timeline.gotoAndPlay( "triggerLoop" );
			timeline.handleLabel( "checkLand", Command.create( bufferFrame, bird, platformEntity ));
		}
		
			// WHISTLE LOGIC, COURTESY OF SCOTT G.
		private function setUpWhistle():void
		{
			var clip:MovieClip = _hitContainer[ _events.WHISTLE ];
			if( !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.WHISTLE ))
			{
				var whistle:Entity = EntityUtils.createSpatialEntity( this, clip );
				whistle.add( new Id( _events.WHISTLE ));
				whistle.add( new Edge( clip.x, clip.y, clip.width, clip.height ));
				
				var spatial:Spatial = whistle.get( Spatial );
				var hookable:Hookable = new Hookable();
				InteractionCreator.addToEntity( whistle, [ InteractionCreator.CLICK ]);
				
				var interaction:Interaction = whistle.get( Interaction );
				interaction.click.add( tooRisky );
				
				hookable.bait = "any";
				hookable.remove = true;

				hookable.reeled.add( getWhistle );
				hookable.reeling.add( hookedWhistle );
				whistle.add( hookable ).add( new Motion );
				ToolTipCreator.addToEntity( whistle );
				
				clip = _hitContainer[ _events.WHISTLE + SPARKLE ];
				var glint:Entity = EntityUtils.createSpatialEntity( this, clip );
				TimelineUtils.convertClip( clip, this, glint );
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ _events.WHISTLE ]);
				_hitContainer.removeChild( _hitContainer[ _events.WHISTLE + SPARKLE ]);
				
			}
		}
		
		private function tooRisky( whistle:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "too_risky" );
		}
		
		private function hookedWhistle( hookableEntity:Entity, hookEntity:Entity ):void
		{
			var spatial:Spatial = hookableEntity.get( Spatial );
			var hookSpatial:Spatial = hookEntity.get( Spatial );
			var edge:Edge = hookableEntity.get( Edge );
			
			spatial.x = hookSpatial.x + edge.rectangle.width * .5;
			SceneUtil.lockInput( this );
			removeEntity( getEntityById( _events.WHISTLE + SPARKLE ));
		}
		
		private function getWhistle( hookableEntity:Entity, hookEntity:Entity ):void
		{
			SceneUtil.lockInput( this, false );
			shellApi.getItem( _events.WHISTLE, null, true );
		}
		
		private function loadUnderground():void
		{
			shellApi.loadScene( Underground )
		}
	}
}