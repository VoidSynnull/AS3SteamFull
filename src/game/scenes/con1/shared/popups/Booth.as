package game.scenes.con1.shared.popups
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.game.GameEvent;
	import game.scenes.con1.Con1Events;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.osflash.signals.Signal;
	
	public class Booth extends Popup
	{
		private var _assembledItems:Array;
		private var _boothTools:Array;
		private var _boothFunctions:Array;
		private var _finishedJetpack:Array;
		private var _instructions:Array;
		private var _rawItems:Array;
		private var _rawFunctions:Array;
		
		private const STRAPS_ACTION:uint = 0;
		private const GLUE_STRAPS_ACTION:uint = 1;
		private const BOTTLES_ACTION:uint = 2;
		private const GLUE_BOTTLES_ACTION:uint = 3;
		private const GEARS_ACTION:uint = 4;
		private const PAINT_ACTION:uint = 5;
		
		private var currentPage:uint = 0;
		private var puzzleStarted:Boolean = false;
		private var action:Number = 0;
		
		public function Booth( container:DisplayObjectContainer = null )
		{
			super( container );
			fail = new Signal( Booth, String );
			victory = new Signal( Booth );
		}
	
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.init( container );
			
			this.hideSceneWhenOpen = true;
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= true;
			
			this.groupPrefix = "scenes/con1/shared/";
			this.screenAsset = "booth.swf";
			
			this.load();
			
			_events = parent.shellApi.islandEvents as Con1Events;
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			this.letterbox(this.screen.content, new Rectangle(0, 0, 960, 640));
			
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
			{
				PARTICLE_NUMBER = 8;
				CLOUD_NUMBER = 8;
			}
			
			_assembledItems = new Array();
			_assembledItems.push( "strapsOn", "glueStraps", "bottlesOn", "glueGears", "gearsOn" );
			
			_finishedJetpack = new Array();
			_finishedJetpack.push( "paintSplatter", "jetpack" );
			
			_boothTools = new Array();
			_boothTools.push( "paint", "glue" );
			
			_boothFunctions = new Array();
			_boothFunctions.push( addPaint, addGlue );
			
			_instructions = new Array();
			_instructions.push( "page1", "page2" );
			
			_rawItems = new Array();
			_rawItems.push( _events.BOTTLES, _events.WATCH_PARTS, _events.BACKPACK_STRAPS, _events.JETPACK_INSTRUCTIONS );
			
			_rawFunctions = new Array();
			_rawFunctions.push( attachBottles, attachGears, attachStraps, launchInstructions );
			
			setupAspectRatio();
		}
		
		private function setupAspectRatio():void
		{
			//_scaleX = this.shellApi.viewportWidth / ScreenManager.GAME_WIDTH;
			//_scaleY = this.shellApi.viewportHeight / ScreenManager.GAME_HEIGHT;
			//var entity:Entity;
			//var clip:MovieClip;
			
			//clip = this.screen.getChildByName( "background" );
			//clip.x *= _scaleX;
			//clip.y *= _scaleY;
			
			var asset:String;
			for each( asset in _assembledItems )
			{				
				optimize( asset );
				setAlpha( asset, 0 );
			}
			for each( asset in _finishedJetpack )
			{
				optimize( asset );
				setAlpha( asset, 0 );
			}
			for each( asset in _boothTools )
			{
				optimize( asset );
			}
			for each( asset in _rawItems )
			{
				checkInventory( asset );
			}
						
			if( shellApi.checkEvent( GameEvent.HAS_ITEM + _events.JETPACK_INSTRUCTIONS ))
			{
				for each( asset in _instructions )
				{
					optimize( asset );
				}
				
				addInteraction( _instructions[ currentPage ], pageFlip );
			}
			else
			{
				for each( asset in _instructions )
				{
					removeAsset( asset );
				}
				failState( "noInstructions" );
			}
		}
		
		private function pageFlip( entity:Entity ):void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + PAGE, VOLUME_MODIFIER );
			ToolTipCreator.removeFromEntity( entity );
			
			var display:Display = entity.get( Display );
			display.visible = false;
			
			var interaction:Interaction;
			
			var sleep:Sleep = entity.get( Sleep );
			sleep.sleeping = true;
		
			if( currentPage < 1 )
			{
				currentPage++;
				
				if( !puzzleStarted )
				{
					addInteraction( _instructions[ currentPage ], pageFlip );
				}
				else
				{
					entity = getEntityById( _instructions[ currentPage ]);
					interaction = entity.get( Interaction );
					
					interaction.click.addOnce( pageFlip );
				}
			}
			else if( !puzzleStarted )
			{
				puzzleStarted = true;
				startPuzzle();
			}
			else
			{
				entity = getEntityById( _events.JETPACK_INSTRUCTIONS );
				interaction = entity.get( Interaction );
				
				interaction.click.addOnce( launchInstructions );
			}
		}
		
		private function startPuzzle():void
		{
			var number:uint;
			loadCloseButton();
			
			// Add interactions to all pieces available
			for( number = 0; number < _boothTools.length; number ++ )
			{
				addInteraction( _boothTools[ number ], _boothFunctions[ number ]);
			}
			
			for( number = 0; number < _rawItems.length; number ++ )
			{
				addInteraction( _rawItems[ number ], _rawFunctions[ number ]);
			}
		}
		
		/**
		 * UTILITIES
		 */
		private function addInteraction( asset:String, handler:Function ):void
		{
			var clip:DisplayObject = this.screen.content.getChildByName( asset );
			var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( asset )).add( new Sleep( false, false ));
			
			ToolTipCreator.addToEntity( entity ); 
			
			var interaction:Interaction = InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			interaction.click.addOnce( handler );
		}
		
		private function checkInventory( asset:String ):void
		{
			if( shellApi.checkEvent( GameEvent.HAS_ITEM + asset ))
			{
				optimize( asset );
			}
			else
			{
				removeAsset( asset );
			}
		}
		
		private function optimize( asset:String ):void
		{
			var clip:MovieClip = this.screen.content.getChildByName( asset );
			var sprite:Sprite = this.createBitmapSprite(clip);
			sprite.name = clip.name;
		}
		
		private function removeAsset( asset:String ):void
		{
			var clip:DisplayObject = this.screen.content.getChildByName( asset );
			
			this.screen.content.removeChild( clip );
		}
		
		private function setAlpha( asset:String, alpha:Number, incrementAction:Boolean = false ):void
		{
			var clip:DisplayObject = this.screen.content.getChildByName( asset );
			clip.alpha = alpha;
			
			if( incrementAction )
			{
				action ++;
			}
		}
		
		/**
		 * JETPACK ASSEMBLY
		 */
		private function addPaint( entity:Entity ):void
		{
			var asset:String;
			var clip:MovieClip;
			
			if( action == PAINT_ACTION )
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + PAINT, VOLUME_MODIFIER, true );
				
				sprayPaint( "orangeSpray", 0xCC6600, new LineZone( new Point( -150, 230 ), new Point( -120, 240 )));
				sprayPaint( "greenSpray", 0x509C3D, new LineZone( new Point( -50, 250 ), new Point( -20, 240 )));
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, causeCloud ));
				SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, paintJetpack ));
			}
			else
			{
				this.close( false, failState );
			}
		}
		
		private function causeCloud():void
		{
			var emitter:Emitter2D = new Emitter2D();
			emitter.counter = new TimePeriod( CLOUD_NUMBER, 2 );
			
			emitter.addInitializer( new ImageClass( Blob, [ 25, 0x7B5B3D ], true ));
			emitter.addInitializer( new Lifetime( 1, 1.2 )); 
			emitter.addInitializer( new Position( new EllipseZone( new Point( 0,0 ), 140, 140 )));
			
			emitter.addAction( new Age( Quadratic.easeOut ));
			emitter.addAction( new Move());
			emitter.addAction( new ScaleImage( .2, 3 ));
			emitter.addAction( new Fade( 1, .5 ));
			
			var id:String = "cloud";
			
			var orangePaint:Entity = EmitterCreator.create( this, this.screen.content.getChildByName( id ), emitter, 0, 0, null, id );
			var asset:String;
				
			SceneUtil.addTimedEvent( this, new TimedEvent( 4, 1, endPaint ));
		}
		
		private function paintJetpack():void
		{
			var asset:String;
			AudioUtils.stop( this, SoundManager.EFFECTS_PATH + PAINT );
						
			for each( asset in _finishedJetpack )
			{
				setAlpha( asset, 1 );
			}
			
			for each( asset in _assembledItems )
			{
				removeAsset( asset );
			}
		}
		
		private function addGlue( entity:Entity ):void
		{
			var clip:MovieClip;
			
			if( action == GLUE_STRAPS_ACTION )
			{
				setAlpha( "glueStraps", 1, true );
				
				var interaction:Interaction = entity.get( Interaction );
				interaction.click.addOnce( addGlue );
				
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + GLUE, VOLUME_MODIFIER );
			}
			else if( action == GLUE_BOTTLES_ACTION )
			{
				setAlpha( "glueGears", 1, true );
				
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + GLUE, VOLUME_MODIFIER );
			}
			else
			{
				this.close( false, failState );
			}
		}
		
		private function attachStraps( entity:Entity ):void
		{
			if( action == STRAPS_ACTION )
			{
				removeEntity( entity );
				setAlpha( "strapsOn", 1, true );
				
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + STRAPS, VOLUME_MODIFIER );
			}
			else
			{
				this.close( false, failState );
			}
		}
		
		private function attachBottles( entity:Entity ):void
		{
			if( action == BOTTLES_ACTION )
			{
				removeEntity( entity );
				setAlpha( "bottlesOn", 1, true );
				
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + BOTTLES, VOLUME_MODIFIER );
			}
			else
			{
				this.close( false, failState );
			}
		}
		
		private function attachGears( entity:Entity ):void
		{
			if( action == GEARS_ACTION )
			{
				removeEntity( entity );
				setAlpha( "gearsOn", 1, true );
				
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + GEARS, VOLUME_MODIFIER );
			}
			else
			{
				this.close( false, failState );
			}
		}
		
		private function launchInstructions( entity:Entity ):void
		{
			var asset:String;
			var display:Display;
			var interaction:Interaction;
			var sleep:Sleep;
			
			currentPage = 0;
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + PAGE, VOLUME_MODIFIER );
			
			for each( asset in _instructions ) 
			{
				entity = getEntityById( asset );
				
				if( asset == "page1" )
				{
					interaction = entity.get( Interaction );
					interaction.click.addOnce( pageFlip );
				}
				
				display = entity.get( Display );
				sleep = entity.get( Sleep );
				
				display.visible = true;
				sleep.sleeping = false;
			}
		}
		
		// CREATE GREEN AND ORANGE SPRAY PAINT EMITTERS AND HAVE THEM MAKE SPRAY NOISE
		private function sprayPaint( id:String, color:uint, lineZone:LineZone ):void
		{
			var emitter:Emitter2D = new Emitter2D();
			emitter.counter = new TimePeriod( PARTICLE_NUMBER, 2 );
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Blob(12, color));
			
			emitter.addInitializer( new BitmapImage( bitmapData, true ));
			emitter.addInitializer( new Lifetime( 1, 1.2 )); 
			emitter.addInitializer( new Velocity( lineZone ));
			emitter.addInitializer( new Position( new EllipseZone( new Point( 0,0 ), 2, 2 )));
			
			emitter.addAction( new Age( Quadratic.easeOut ));
			emitter.addAction( new Move());
			emitter.addAction( new ScaleImage( .2, 3 ));
			emitter.addAction( new Fade( 1, .5 ));
			var accelerate:Accelerate = new Accelerate( 2, 5 );
			emitter.addAction( accelerate );
			
			var orangePaint:Entity = EmitterCreator.create( this, this.screen.content.getChildByName( id ), emitter, 0, 0, null, id );
		}
		
		/**
		 * VICTORY OR DEFEAT
		 */
		private function failState( dialogId:String = "basicFail" ):void
		{
			if( action == GLUE_STRAPS_ACTION || action == GLUE_BOTTLES_ACTION )
			{
				dialogId = "stickingFail";
			}
			
			fail.dispatch( this, dialogId );
			this.remove();
		}
		
		private function endPaint():void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + EVENT, VOLUME_MODIFIER + 1 );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create( close, false, victoryState )));
		}
		
		private function victoryState():void
		{
			shellApi.removeItem(_events.BACKPACK_STRAPS);
			shellApi.removeItem(_events.BOTTLES);
			shellApi.removeItem(_events.WATCH_PARTS);
			victory.dispatch( this );
			this.remove();
		}
		
		public var fail:Signal;
		public var victory:Signal;
		private var _events:Con1Events;
		private var _scaleX:Number;
		private var _scaleY:Number;
		
		private const VOLUME_MODIFIER:int = 3;
		
		private const EVENT:String = "event_01.mp3";
		private const GEARS:String = "metal_bounce_01.mp3";
		private const STRAPS:String = "cloth_flap_02.mp3";
		private const BOTTLES:String = "ls_hollow_plastic_02.mp3";
		private const GLUE:String = "squish_04.mp3";
		private const PAINT:String = "spray_foam_01_loop.mp3";
		private const PAGE:String = "paper_flap_01.mp3"
		
		private var PARTICLE_NUMBER:int = 20;
		private var CLOUD_NUMBER:int = 25;
	}
}