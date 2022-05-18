package game.scenes.myth.grove
{
	import com.greensock.easing.Sine;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.OriginPoint;
	import game.components.entity.Sleep;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.WaveMotionData;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.particles.FlameCreator;
	import game.scenes.myth.grove.components.GraffitiComponent;
	import game.scenes.myth.grove.components.LavaComponent;
	import game.scenes.myth.grove.popups.Graffiti;
	import game.scenes.myth.grove.systems.LavaSystem;
	import game.scenes.myth.shared.Athena;
	import game.scenes.myth.shared.Fountain;
	import game.scenes.myth.shared.MythScene;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.MovingHitSystem;
	import game.systems.hit.WaterHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Grove extends MythScene
	{
		public function Grove()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/grove/";
			
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
			_openAthena = false;
			
			super.loaded();
			setupTorches();
			if( PerformanceUtils.determineQualityLevel() > PerformanceUtils.QUALITY_MEDIUM )
			{
				setupFountains();
			}
			setupLavaPlatforms();
			setupButterflies();
			
			var clip:MovieClip;
			var display:Display;
			var entity:Entity;
			var number:Number;
			var interaction:Interaction;
			var spatial:Spatial;
			var sceneInteraction:SceneInteraction;
			var wrapper:BitmapWrapper;
			var sprite:Sprite;
			var position:Point = new Point();
			
			super.shellApi.eventTriggered.add( eventTriggers );
			
			var satyrEntity:Entity = super.getEntityById( "satyr" );
			CharUtils.setPartColor( satyrEntity, CharUtils.LEG_BACK, 0x7D66AE );
			CharUtils.setPartColor( satyrEntity, CharUtils.LEG_FRONT, 0x7D66AE );
			
			if( super.shellApi.checkEvent( _events.ZEUS_APPEARS_TREE ))
			{
				entity = super.getEntityById( "oliveInteraction" );
				Interaction( entity.get( Interaction )).click.add( athenaPopup );
				entity.remove( SceneInteraction );

				for( number = 0; number < 3; number ++ )
				{					
					clip = _hitContainer[ "graffiti" + number ];
					position.x = clip.x;
					position.y = clip.y;
					
					if( !super.shellApi.checkEvent( _events.CLEANED_GRAFFITI_ + number ))
					{
						if( PlatformUtils.isDesktop )
						{
							entity = EntityUtils.createSpatialEntity( this, clip );
						}
						else
						{
							wrapper = DisplayUtils.convertToBitmapSprite( clip );	
							entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
						}
						entity.add( new Id( "graffiti" + number )).add( new GraffitiComponent( number ));
						ToolTipCreator.addToEntity( entity );
						
						InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
						sceneInteraction = new SceneInteraction();
						entity.add( sceneInteraction );
						
						sceneInteraction.reached.add( graffitiPopup );
						
						if( number == 2 )
						{
							sceneInteraction.offsetY = 300;
						}
					}
					
					else
					{
						_hitContainer.removeChild( clip );
					}
				}
			}
			else
			{
				removeEntity( super.getEntityById( "oliveInteraction" ));
				
				var threshold:Threshold = new Threshold( "x", ">" );
				threshold.threshold = Spatial(satyrEntity.get(Spatial)).x + 200;
				threshold.entered.add( offLimits );
				player.add( threshold );
				sceneInteraction = satyrEntity.get(SceneInteraction);
				sceneInteraction.offsetY += 25;
				sceneInteraction.reached.add(reachedSatyr);
			}
			
			var water:Entity = super.getEntityById("water");
			water.add( new Sleep(false, true));
			
			addSystem( new MovingHitSystem(), SystemPriorities.move );
			addSystem( new ThresholdSystem(), SystemPriorities.update );
			addSystem( new WaveMotionSystem(), SystemPriorities.move );
			addSystem( new ParticleSystem(), SystemPriorities.update );
			addSystem( new LavaSystem(), SystemPriorities.lowest );
			
			var waterHit:WaterHitSystem = getSystem( WaterHitSystem ) as WaterHitSystem;
			if( !waterHit )
			{
				waterHit = new WaterHitSystem();
				addSystem( waterHit, SystemPriorities.moveComplete );
			}
		}
		
		override public function destroy():void
		{
			_flameCreator.destroy();
			super.destroy();
		}
		
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			switch( event )
			{
				case GameEvent.GOT_ITEM + _events.SILVER_DRACHMA:
					SceneUtil.lockInput( this, false );
					break;
			}
		}
		/*******************************
		 * 		  BUTTERFLIES
		 * *****************************/
		private function setupButterflies():void 
		{			
			for ( var i:int = 0; i < 2; i ++ )
			{
				var tween:Tween = new Tween();
				var clip:MovieClip = _hitContainer[ "b" + ( i + 1 )];
				var butterfly:Entity = EntityUtils.createMovingEntity( this, clip );
			
				BitmapTimelineCreator.createSequence( clip );
				
				var spatial:Spatial = butterfly.get( Spatial );
				var origin:OriginPoint = new OriginPoint( spatial.x, spatial.y );
				butterfly.add( tween ).add( origin).add( new SpatialAddition() ).add( new WaveMotion());				
				moveButterfly( butterfly );
			}
		}
		
		private function moveButterfly( butterfly:Entity ):void 
		{
			var spatial:Spatial = butterfly.get( Spatial );
			var motion:Motion = butterfly.get( Motion );
			var origin:OriginPoint = butterfly.get( OriginPoint );
			var tween:Tween = butterfly.get( Tween );
			var wave:WaveMotion = butterfly.get( WaveMotion );
			wave.data = new Vector.<WaveMotionData>;
			
			wave.add( new WaveMotionData( "x", Math.random() * 15, Math.random() / 10 ));
			wave.add( new WaveMotionData( "y", Math.random() * 15, Math.random() / 10 ));	
			
			var goalX:Number = ( Math.random() * 200 ) + origin.x - 100;
			var goalY:Number = ( Math.random() * 200 ) + origin.y - 100;
			var duration:Number = ( Math.random() * 3 ) + 7; 				
			
			butterfly.add( wave );						
			tween.to( spatial, duration, { x: goalX,y: goalY, ease:Sine.easeInOut,onComplete: moveButterfly, onCompleteParams:[ butterfly ]}); 	
		}
		
		/*******************************
		 * 		  QUEST ZONE
		 * *****************************/
		private function offLimits( ...args ):void
		{
			SceneUtil.lockInput(this);
			var satyr:Entity = super.getEntityById( "satyr" );
			var sceneInteraction:SceneInteraction = satyr.get(SceneInteraction);
			sceneInteraction.activated = true;
		}
		
		private function reachedSatyr( ...args ):void
		{
			SceneUtil.lockInput(this, false);
		}
		
		/*******************************
		 *  		ATHENA
		 ******************************/
		
		private function athenaPopup( interactionEntity:Entity ):void
		{
			if( !_openAthena )
			{
				_openAthena = true;
				var popup:Athena = super.addChildGroup( new Athena( super.overlayContainer )) as Athena;
				popup.closeClicked.add( resetPopup );
				popup.id = "athena";
			}
		}
		
		private function resetPopup( ...args ):void
		{
			_openAthena = false;
		}
				
		/*******************************
		 * 			FLAMES
		 * *****************************/
		
		private function setupTorches():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, super._hitContainer[ "flame" + 1 ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var i:uint = 1;
			for( i = 1; i < 6; i ++ )
			{
				clip = super._hitContainer[ "flame" + i ];
				_flameCreator.createFlame( this, clip, true );
			}
		}
		
		/*******************************
		 * 		    FOUNTAINS
		 * *****************************/
		private function setupFountains():void
		{
			var entity:Entity;
			var number:int;
			var audio:Audio;
			var audioRange:AudioRange;
			var fountain:Fountain;
			var spawnNumber:int = 20;
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Blob( 8 ));
			
			for ( number = 1; number < 3; number++ ) 
			{
				audioRange = new AudioRange( 600, .01, 1 );
				fountain = new Fountain();
			
				fountain.init( bitmapData, spawnNumber, -180, 155, 420 );
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "fountain" + number ] );
				EmitterCreator.create( this, _hitContainer[ "fountain" + number ], fountain, 0, 0, entity );
				entity.add( audioRange ).add( new Id( "fountain" + number ));
				_audioGroup.addAudioToEntity( entity );
				
				audio = entity.get( Audio );
				audio.playCurrentAction( RANDOM );
			}
		}
		
		/*******************************
		 * 	      LAVA PLATFORMS
		 * *****************************/
		private function setupLavaPlatforms():void
		{
			var number:int;
			var entity:Entity;
			var plug:Entity;
			var lava:LavaComponent;
			var blobs:Emitter2D;
			var audio:Audio;
			var audioRange:AudioRange;
			var spawnNumber:int  = 40;
			var clip:MovieClip = _hitContainer[ "plug" ];
			var lavaClip:MovieClip;// = _hitContainer[ "lava" ];
			var bitmapData:BitmapData;
			var movingPlatform:Entity;
			
			var wrapper:BitmapWrapper;
			var displayObjectBounds:Rectangle;
			var offsetMatrix:Matrix;
			var bitmap:Bitmap;
			var sprite:Sprite;
			var blobClip:MovieClip;
			var spatial:Spatial;
			
			for( number = 1; number < 3; number ++ )
			{
				blobClip = _hitContainer[ "blobs" + number ];
				
				// MOVING PLATFORMS
				wrapper = convertToBitmapSprite( clip );
				displayObjectBounds = clip.getBounds( clip );
				offsetMatrix  = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
				sprite = new Sprite();
				
				bitmapData = new BitmapData( clip.width, clip.height, true, 0x000000 );
				bitmapData.draw( wrapper.data );
				bitmap = new Bitmap( bitmapData, "auto", true );
				bitmap.transform.matrix = offsetMatrix;
				sprite.addChild( bitmap );
				
				plug = EntityUtils.createSpatialEntity( this, sprite, _hitContainer );
				DisplayUtils.convertToBitmap( clip );
				movingPlatform = super.getEntityById( "mp" + number );		
				Display( movingPlatform.get( Display )).alpha = 0;
				plug.add( new FollowTarget( movingPlatform.get( Spatial )));
				
				audioRange = new AudioRange( 1000, .01, 2 );
				
				
				// LAVA
				lavaClip = _hitContainer[ "lava" + number ];
				entity = EntityUtils.createSpatialEntity( this, lavaClip );
				lava = new LavaComponent( lavaClip, plug.get( Spatial ));
				entity.add( lava ).add( new Id( "lava" + number )).add( audioRange );
				_audioGroup.addAudioToEntity( entity );
				
				audio = entity.get( Audio );
				audio.playCurrentAction( RANDOM );
				
				// BLOBS
				if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )
				{
					bitmapData = BitmapUtils.createBitmapData(new Blob( 10, 0x5E6A4E ));
					blobs = new Emitter2D();
					
					blobs.counter = new Steady( spawnNumber );
					
					// when using a BitmapRender you use SharedImage or SharedImages, since each particle is being draw to bitmap it only needs to be rendered once.
					blobs.addInitializer( new BitmapImage( bitmapData, true, 2 * spawnNumber ));
					blobs.addInitializer( new Lifetime( 1, 2 )); 
			//		blobs.addInitializer( new AlphaInit( .8, .9 ));
					blobs.addInitializer( new Velocity( new LineZone( new Point( -50, 50 ), new Point( 50, 100 ))));
					
					lava.position = new Position( new EllipseZone( new Point( 0, 0 ), 50, 10 ));
					blobs.addInitializer( lava.position );
					
					blobs.addAction( new Age( Quadratic.easeOut ));
					blobs.addAction( new Move());
					blobs.addAction( new ScaleImage( 1.5, .75 ));
					blobs.addAction( new RandomDrift( 50, 100 ));
					blobs.addAction( new Accelerate( 0, 90 ));
			//		blobs.addAction( new Fade( .75, 0 ));
					
					EmitterCreator.create( this, blobClip, blobs, 0, 0, entity );
					entity.add(new Sleep());
				}
			}
		}
		
		/*******************************
		 * 		      GRAFFITI
		 * *****************************/
	  	private function graffitiPopup( character:Entity, interactionEntity:Entity ):void
	  	{
			var graffiti:GraffitiComponent = interactionEntity.get( GraffitiComponent );
			
			if( graffiti.active )
			{
				graffiti.active = false;
				
				var popup:Graffiti = super.addChildGroup( new Graffiti( graffiti.number, super.overlayContainer )) as Graffiti;
				popup.id = "graffiti" + graffiti.number;
				popup.complete.add( Command.create( fadeGraffiti, popup ));
				popup.closeClicked.add( Command.create( reactivateGraffiti, interactionEntity ));
			}
		}
		
		private function reactivateGraffiti( popup:Graffiti, interactionEntity:Entity ):void
		{
			var graffiti:GraffitiComponent = interactionEntity.get( GraffitiComponent );
			graffiti.active = true;
		}
		
		private function fadeGraffiti( popup:Graffiti ):void
		{
			popup.close();
			SceneUtil.lockInput( this );
			
			var grafNum:int = popup.getNumber();
			var entity:Entity = super.getEntityById( "graffiti" + grafNum );
			var tween:Tween = new Tween();
			var display:Display = entity.get( Display );
			
			tween.to( display, 2, { alpha : 0, onComplete : Command.create( graffitiCleaned, entity )});
			entity.add( tween );
			
			super.shellApi.triggerEvent( _events.CLEANED_GRAFFITI_ + grafNum, true );
		}
		
		private function graffitiCleaned( entity:Entity ):void
		{
			super.removeEntity( entity );
			SceneUtil.lockInput( this, false );
			
			if( super.shellApi.checkEvent( _events.CLEANED_ALL_GRAFFITI ))
			{
				var worker:Entity = super.getEntityById( "youngGuy" );
				var dialog:Dialog = worker.get( Dialog );
				dialog.setCurrentById( "cleaned_all_graffiti" );
					
				var interaction:Interaction = worker.get( Interaction );
				interaction.click.dispatch( worker ); 
			}
		}
		
		private const RANDOM:String	= "random";
		
		private var _flameCreator:FlameCreator;
		private var _openAthena:Boolean;
	}
}
