package game.scenes.viking.shared.popups
{
	import com.greensock.easing.Back;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.sampler.getSize;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.motion.Threshold;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.display.BitmapWrapper;
	import game.data.ui.TransitionData;
	import game.managers.ads.AdManager;
	import game.scenes.map.map.components.Bird;
	import game.scenes.map.map.components.MapCloud;
	import game.scenes.map.map.systems.BirdSystem;
	import game.scenes.viking.VikingEvents;
	import game.scenes.viking.VikingScene;
	import game.scenes.viking.adStreet2.AdStreet2;
	import game.scenes.viking.dodoHabitat.DodoHabitat;
	import game.scenes.viking.embedsCamp.EmbedsCamp;
	import game.scenes.viking.fortress.Fortress;
	import game.scenes.viking.jungle.Jungle;
	import game.scenes.viking.waterfall.Waterfall;
	import game.scenes.viking.waterfall2.Waterfall2;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.IslandBlockPopup;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.TimelineUtils;
	import game.util.Utils;
	import game.utils.AdUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class MapPopup extends Popup
	{
		private var _events:VikingEvents = new VikingEvents();
		private var _sequences:Vector.<BitmapSequence> = new Vector.<BitmapSequence>;
		
		private var _currentPath:Vector.<Point> = new <Point>[];
		private var _location:String;
		private var _destination:String;
		private var _returning:Boolean = false;
		private var _pathStep:BitmapWrapper;
		private var _stepNumber:int = 0;
		
		private const LABEL:String			= 	"Label";
		private const CAMP:String			=	"EmbedsCamp";
		private const DODO:String			= 	"DodoHabitat";
		private const FORTRESS:String		=	"Fortress";
		private const JUNGLE:String			=	"Jungle";
		private const WATERFALL:String 		=	"Waterfall";
		
		
		private const campToJungle:Vector.<Point> = new <Point>[ new Point( 408, 482 ), new Point( 428, 475 ), new Point( 446, 465 )
			, new Point( 466, 455 ), new Point( 489, 454 ), new Point( 512, 454 )
			, new Point( 526, 440 ), new Point( 536, 425 ), new Point( 557, 417 )
			, new Point( 581, 413 ), new Point( 598, 398 ), new Point( 611, 382 )
			, new Point( 627, 367 ), new Point( 640, 351 )];
		private const campToDodo:Vector.<Point> = new <Point>[ new Point( 408, 482 ), new Point( 428, 475 ), new Point( 446, 465 )
			, new Point( 466, 455 ), new Point( 489, 454 ), new Point( 512, 454 )
			, new Point( 526, 440 ), new Point( 536, 425 ), new Point( 557, 417 )
			, new Point( 581, 413 ), new Point( 598, 398 ), new Point( 611, 382 )
			, new Point( 627, 367 ), new Point( 640, 351 )
			, new Point( 598, 347 ), new Point( 573, 346 ), new Point( 549, 341 )
			, new Point( 522, 335 ), new Point( 497, 325 ), new Point( 470, 320 )
			, new Point( 444, 329 ), new Point( 418, 334 ), new Point( 394, 325 )
			, new Point( 376, 312 ), new Point( 357, 301 ), new Point( 342, 288 )];
		private const campToWaterfall:Vector.<Point> = new <Point>[ new Point( 408, 482 ), new Point( 428, 475 ), new Point( 446, 465 )
			, new Point( 466, 455 ), new Point( 489, 454 ), new Point( 512, 454 )
			, new Point( 526, 440 ), new Point( 536, 425 ), new Point( 557, 417 )
			, new Point( 581, 413 ), new Point( 598, 398 ), new Point( 611, 382 )
			, new Point( 627, 367 ), new Point( 640, 351 )
			, new Point( 598, 347 ), new Point( 573, 346 ), new Point( 549, 341 )
			, new Point( 522, 335 ), new Point( 497, 325 ), new Point( 470, 320 )
			, new Point( 444, 329 ), new Point( 418, 334 ), new Point( 394, 325 )
			, new Point( 376, 312 ), new Point( 357, 301 ), new Point( 342, 288 )
			, new Point( 332, 256 ), new Point( 348, 242 ), new Point( 370, 230 )
			, new Point( 396, 224 ), new Point( 423, 230 ), new Point( 446, 235 )
			, new Point( 474, 233 ), new Point( 473, 215 ), new Point( 453, 206 )
			, new Point( 426, 199 ), new Point( 400, 192 )];
		private const campToFortress:Vector.<Point> = new <Point>[ new Point( 408, 482 ), new Point( 428, 475 ), new Point( 446, 465 )
			, new Point( 466, 455 ), new Point( 489, 454 ), new Point( 512, 454 )
			, new Point( 526, 440 ), new Point( 536, 425 ), new Point( 557, 417 )
			, new Point( 581, 413 ), new Point( 598, 398 ), new Point( 611, 382 )
			, new Point( 627, 367 ), new Point( 640, 351 )
			, new Point( 598, 347 ), new Point( 573, 346 ), new Point( 549, 341 )
			, new Point( 522, 335 ), new Point( 497, 325 ), new Point( 470, 320 )
			, new Point( 444, 329 ), new Point( 418, 334 ), new Point( 394, 325 )
			, new Point( 376, 312 ), new Point( 357, 301 ), new Point( 342, 288 )
			, new Point( 332, 256 ), new Point( 348, 242 ), new Point( 370, 230 )
			, new Point( 396, 224 ), new Point( 423, 230 ), new Point( 446, 235 )
			, new Point( 474, 233 ), new Point( 473, 215 ), new Point( 453, 206 )
			, new Point( 426, 199 ), new Point( 400, 192 ), new Point( 405, 175 )
			, new Point( 430, 168 ), new Point( 455, 168 ), new Point( 475, 182 )
			, new Point( 492, 194 ), new Point( 518, 195 ), new Point( 543, 195 )];
		
		private const jungleToDodo:Vector.<Point> = new <Point>[ new Point( 598, 347 ), new Point( 573, 346 ), new Point( 549, 341 )
			, new Point( 522, 335 ), new Point( 497, 325 ), new Point( 470, 320 )
			, new Point( 444, 329 ), new Point( 418, 334 ), new Point( 394, 325 )
			, new Point( 376, 312 ), new Point( 357, 301 ), new Point( 342, 288 )];
		private const jungleToWaterfall:Vector.<Point> = new <Point>[ new Point( 598, 347 ), new Point( 573, 346 ), new Point( 549, 341 )
			, new Point( 522, 335 ), new Point( 497, 325 ), new Point( 470, 320 )
			, new Point( 444, 329 ), new Point( 418, 334 ), new Point( 394, 325 )
			, new Point( 376, 312 ), new Point( 357, 301 ), new Point( 342, 288 )
			, new Point( 332, 256 ), new Point( 348, 242 ), new Point( 370, 230 )
			, new Point( 396, 224 ), new Point( 423, 230 ), new Point( 446, 235 )
			, new Point( 474, 233 ), new Point( 473, 215 ), new Point( 453, 206 )
			, new Point( 426, 199 ), new Point( 400, 192 )];
		private const jungleToFortress:Vector.<Point> = new <Point>[new Point( 598, 347 ), new Point( 573, 346 ), new Point( 549, 341 )
			, new Point( 522, 335 ), new Point( 497, 325 ), new Point( 470, 320 )
			, new Point( 444, 329 ), new Point( 418, 334 ), new Point( 394, 325 )
			, new Point( 376, 312 ), new Point( 357, 301 ), new Point( 342, 288 )
			, new Point( 332, 256 ), new Point( 348, 242 ), new Point( 370, 230 )
			, new Point( 396, 224 ), new Point( 423, 230 ), new Point( 446, 235 )
			, new Point( 474, 233 ), new Point( 473, 215 ), new Point( 453, 206 )
			, new Point( 426, 199 ), new Point( 400, 192 ), new Point( 405, 175 )
			, new Point( 430, 168 ), new Point( 455, 168 ), new Point( 475, 182 )
			, new Point( 492, 194 ), new Point( 518, 195 ), new Point( 543, 195 )];
		
		private const dodoToWaterfall:Vector.<Point> = new <Point>[ new Point( 332, 256 ), new Point( 348, 242 ), new Point( 370, 230 )
			, new Point( 396, 224 ), new Point( 423, 230 ), new Point( 446, 235 )
			, new Point( 474, 233 ), new Point( 473, 215 ), new Point( 453, 206 )
			, new Point( 426, 199 ), new Point( 400, 192 )];
		private const dodoToFortress:Vector.<Point> = new <Point>[ new Point( 332, 256 ), new Point( 348, 242 ), new Point( 370, 230 )
			, new Point( 396, 224 ), new Point( 423, 230 ), new Point( 446, 235 )
			, new Point( 474, 233 ), new Point( 473, 215 ), new Point( 453, 206 )
			, new Point( 426, 199 ), new Point( 400, 192 ), new Point( 405, 175 )
			, new Point( 430, 168 ), new Point( 455, 168 ), new Point( 475, 182 )
			, new Point( 492, 194 ), new Point( 518, 195 ), new Point( 543, 195 )];
		
		private const waterfallToFortress:Vector.<Point> = new <Point>[ new Point( 405, 175 ), new Point( 430, 168 ), new Point( 455, 168 )
			, new Point( 475, 182 ), new Point( 492, 194 ), new Point( 518, 195 )
			, new Point( 543, 195 )];
		
		public function MapPopup(container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "MapPopup";
			this.groupPrefix 		= "scenes/viking/shared/popups/";
			this.screenAsset 		= "mapPopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= false;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, this.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Back.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Back.easeIn);
			this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function destroy():void
		{
			for each( var sequence:BitmapSequence in this._sequences )
			{
				sequence.destroy();
				sequence = null;
			}
			
			this._sequences = null;
			
			super.destroy();
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			if( !shellApi.checkEvent( _events.RIVER_COMPLETED ) || shellApi.checkItemEvent( _events.MEDAL_VIKING ))
			{
				super.loaded();
				var scene:VikingScene = parent as VikingScene;
				if( PlatformUtils.isDesktop && shellApi.checkEvent( "octavian_ran_away" ) && IslandBlockPopup.checkIslandBlock( super.shellApi ))
				{
					var blockPopup:IslandBlockPopup = super.addChildGroup( new IslandBlockPopup( "scenes/viking/", scene.overlayContainer )) as IslandBlockPopup;	
				}
					
				else
				{
					this.letterbox(this.screen.content, new Rectangle(0, 0, 960, 640), false);
					
					if( !this.getSystem( ThresholdSystem ))
					{
						this.addSystem( new ThresholdSystem());
					}
					
					this.addSystem( new BirdSystem());
					setupDynamicMap();
					setupBirds();
					setupClouds();
					setupAnimationLoops();
				}
			}
			else
			{
				this.transitionOut = null;
				shellApi.triggerEvent(_events.BLOCK_MAP);
				close();
			}
		}
		
		override public function open( handler:Function = null ):void
		{			
			super.open( dimBackground );
		}
		
		private function dimBackground():void
		{
			var screenEffects:ScreenEffects = new ScreenEffects();
			_darkBG = screenEffects.createBox( shellApi.viewportWidth, shellApi.viewportHeight, 0x000000 );
			
			var shadeEntity:Entity = new Entity( "darken" );
			var display:Display = new Display( _darkBG, super.groupContainer );
			display.alpha = 0;
			display.moveToBack();
			shadeEntity.add( new Spatial( 0, 0 ));
			shadeEntity.add( display );
			
			addEntity( shadeEntity );
			
			var tween:Tween = new Tween();
			tween.to( display, 2, { alpha : .5 });
			shadeEntity.add( tween );
			super.loadCloseButton();
		}
		
		//		private function finalizeMap( ...args ):void
		//		{
		//			var area:Entity;
		//			var areas:Vector.<Entity> = new <Entity>[ getEntityById( CAMP )
		//													, getEntityById( DODO )
		//													, getEntityById( FORTRESS )
		//													, getEntityById( JUNGLE )
		//													, getEntityById( WATERFALL )];
		//			var interaction:Interaction;
		//			
		//			for each( area in areas )
		//			{
		//				interaction = area.get( Interaction );
		//				interaction.down.add( tweenOnLabel );
		//				interaction.over.add( tweenOnLabel );
		//				interaction.out.add( tweenOffLabel );
		//				interaction.up.add( tweenOffLabel );
		//			}
		//			
		//		}
		
		// CREATE / BITMAP DYNAMIC ASSETS
		private function setupDynamicMap():void
		{
			var area:MovieClip;
			var areaButton:Entity;
			var areas:Vector.<MovieClip>;
			var button:Button;
			var clip:MovieClip;
			var clips:Vector.<MovieClip>;
			var entity:Entity;
			var labelEntity:Entity;
			var number:int;
			var placement:Point;
			var placements:Vector.<Point>;
			var sequence:BitmapSequence;
			var spatial:Spatial;
			var timeline:Timeline;
			var wrapper:BitmapWrapper;
			
			// BACKGROUND ASSETS
			clips = new <MovieClip>[ screen.content[ "farBack" ], screen.content[ "midBack" ], screen.content[ "foreground" ]];
			
			for each( clip in clips )
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality );
			}
			
			// ALWAYS ON
			clips = new <MovieClip>[ screen.content[ "ripple1" ], screen.content[ "ripple2" ]
				, screen.content[ "ripple3" ], screen.content[ "ripple4" ]
				, screen.content[ "falls" ], screen.content[ "river" ], screen.content[ "sail" ]];
			
			for each( clip in clips )
			{
				sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).play();
				Display(entity.get(Display)).disableMouse();
				
				_sequences.push( sequence );
			}
			
			// TOGGLE ON/OFF ASSETS	
			clips = new <MovieClip>[ screen.content[ "bouldersFallen" ], screen.content[ "rockRipple" ]
				, screen.content[ "ripple5" ], screen.content[ "ripple6" ]
				, screen.content[ "ripple7" ]];
			
			// RIVER FLOODED?
			if( !shellApi.checkEvent( _events.PEAK_EXPLODED ))
			{
				screen.content.removeChild( screen.content[ "waterFill" ]);
				for each( clip in clips )
				{
					screen.content.removeChild( clip );
				}
			}
			else
			{
				screen.content.removeChild( screen.content[ "boulders" ]);
				for each( clip in clips )
				{
					sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
					entity = EntityUtils.createSpatialEntity( this, clip );
					entity.add( new Id( clip.name ));
					
					BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
					Timeline( entity.get( Timeline )).playing = true;
					
					this._sequences.push( sequence );
				}
			}
			
			// OCTAVIAN's TREE
			clip = screen.content[ "tree" ];
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( clip.name ));
			
			sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
			Timeline( entity.get( Timeline )).playing = true;
			
			this._sequences.push( sequence );
			
			// TREE CHOPPED DOWN?
			if( shellApi.checkEvent( _events.OCTAVIAN_FREED ))
			{				
				Timeline( entity.get( Timeline )).gotoAndStop( "down" );
			}
			
			//GUY SLEEPING?
			if(shellApi.checkEvent(_events.OCTAVIAN_RAN_AWAY))
			{
				clip = screen.content[ "sleep" ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				
				sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).playing = true;
				
				this._sequences.push( sequence );
			}
			else
			{
				screen.content.removeChild( screen.content[ "sleep" ]);
			}
			
			// DODO TRINKET GRABBED?
			if( shellApi.checkHasItem( _events.LENS ))
			{
				screen.content.removeChild( screen.content[ "dodoSparkle" ]);				
			}
			else
			{
				clip = screen.content[ "dodoSparkle" ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				
				TimelineUtils.convertClip( clip, this, entity );
			}
			
			// SHIP UNCOVERED?
			if( shellApi.checkHasItem( _events.AXE ))
			{
				screen.content.removeChild( screen.content[ "sandMound" ]);
			}
			
			var interaction:Interaction;
			areas = new <MovieClip>[ screen.content[ CAMP ]
				, screen.content[ DODO ]
				, screen.content[ FORTRESS ]
				, screen.content[ JUNGLE ]
				, screen.content[ WATERFALL ]];
			
			for each( area in areas )
			{
				areaButton = ButtonCreator.createButtonEntity( area, this, handleZoneClick );
				clip = screen.content[ area.name + LABEL ];
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				labelEntity = EntityUtils.createSpatialEntity( this, clip );
				labelEntity.add( new Id( area.name + LABEL ));
				
				if( PlatformUtils.isDesktop )
				{
					interaction = areaButton.get( Interaction );
					interaction.down.add( tweenOnLabel );
					interaction.over.add( tweenOnLabel );
					interaction.out.add( tweenOffLabel );
					interaction.up.add( tweenOffLabel );
				}
				else
				{
					var display:Display = labelEntity.get( Display );
					display.alpha = 1;
				}
			}
			
			placements = new <Point>[ new Point( 264, 190 ), new Point( 270, 188 ), new Point( 280, 187 )
				, new Point( 290, 178 ), new Point( 295, 178 ), new Point( 297, 178 )
				, new Point( 303, 176 ), new Point( 308, 175 ), new Point( 273, 122 )
				, new Point( 282, 120 ), new Point( 285, 120 )];
			
			number = 0;
			for each( placement in placements )
			{
				number++;
				addMist( placement, number );
			}
			
			clip = screen.content[ "marker" ];
			
			switch( shellApi.sceneName )
			{
				case "AdStreet1":
					spatial = getEntityById( JUNGLE ).get( Spatial );
					_location = JUNGLE;
					break;
				
				case "AdStreet2":
					spatial = getEntityById( CAMP ).get( Spatial );
					_location = CAMP;
					break;
				
				case "Beach":
					spatial = getEntityById( JUNGLE ).get( Spatial );
					_location = JUNGLE;
					break;
				
				//		case "CommonRoom":
				//			spatial = getEntityById( JUNGLE ).get( Spatial );
				//			break;
				
				case "DiningHall":
					spatial = getEntityById( FORTRESS ).get( Spatial );
					_location = FORTRESS;
					break;
				
				case "Peak":
					spatial = getEntityById( WATERFALL ).get( Spatial );
					_location = WATERFALL;
					break;
				
				case "Pen":
					spatial = getEntityById( FORTRESS ).get( Spatial );
					_location = FORTRESS;
					break;
				
				case "ThroneRoom":
					spatial = getEntityById( FORTRESS ).get( Spatial );
					_location = FORTRESS;
					break;
				
				case "Waterfall2":
					spatial = getEntityById( WATERFALL ).get( Spatial );
					_location = WATERFALL;
					break;
				
				default:
					spatial = getEntityById( shellApi.sceneName ).get( Spatial );
					_location = shellApi.sceneName;
					break;
			}
			
			if( spatial )
			{
				clip.x = spatial.x;
				clip.y = spatial.y;
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
			}
			else
			{
				screen.content.removeChild( clip );
			}
			
			// LABELS
			if( PlatformUtils.isDesktop )
			{
				var label:Entity;
				var labels:Vector.<Entity> = new <Entity>[ getEntityById( CAMP + LABEL )
					, getEntityById( DODO + LABEL )
					, getEntityById( FORTRESS + LABEL )
					, getEntityById( JUNGLE + LABEL )
					, getEntityById( WATERFALL + LABEL )];
				
				for each( label in labels )
				{
					display = label.get( Display );
					display.alpha = 0;
					
					label.add( new Tween());
				}
			}
			
			// setup path entity
			clip = screen.content[ "path" ];
			_pathStep = DisplayUtils.convertToBitmapSprite( clip, null );
		}
		
		// label handlers
		private function tweenOnLabel( button:Entity ):void
		{
			var id:Id = button.get( Id );
			var labelEntity:Entity = getEntityById( id.id + LABEL );
			var display:Display = labelEntity.get( Display );
			var tween:Tween = labelEntity.get( Tween );
			
			tween.to( display, .5, { alpha : 1 });
		}
		
		private function tweenOffLabel( button:Entity ):void
		{
			var id:Id = button.get( Id );
			var labelEntity:Entity = getEntityById( id.id + LABEL );
			var display:Display = labelEntity.get( Display );
			var tween:Tween = labelEntity.get( Tween );
			
			tween.to( display, .5, { alpha : 0 });
		}
		
		// HANDLE LOCATION CLICKS
		private function handleZoneClick( entity:Entity ):void
		{
			var name:String = entity.get( Id ).id;
			SceneUtil.lockInput( this );
			
			if( name.indexOf( CAMP ) > -1 )
			{
				_destination = CAMP;
			}
			else if( name.indexOf( DODO ) > -1 )
			{
				_destination = DODO;
			}
			else if( name.indexOf( FORTRESS ) > -1 )
			{
				_destination = FORTRESS;
			}
			else if( name.indexOf( JUNGLE ) > -1 )
			{
				_destination = JUNGLE;
			}
			else if( name.indexOf( WATERFALL ) > -1 )
			{
				_destination = WATERFALL;
			}
			
			var marker:Entity = getEntityById( "marker" );			
			var tween:Tween = new Tween();
			marker.add( tween );
			tween.to( marker.get( Display ), .3, { alpha : 0, onComplete : nextFootPrint });
			
			// ANYTHING THAT GOES TO/FROM EMBED'S CAMP
			if( _destination == JUNGLE && _location == CAMP )
			{ 
				_currentPath = this.campToJungle;
			}
			else if( _destination == CAMP && _location == JUNGLE )
			{
				_currentPath = this.campToJungle;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
			else if( _destination == DODO && _location == CAMP )
			{ 
				_currentPath = this.campToDodo;
			}
			else if( _destination == CAMP && _location == DODO )
			{ 
				_currentPath = this.campToDodo;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
			else if( _destination == WATERFALL && _location == CAMP )
			{ 
				_currentPath = this.campToWaterfall;
			}
			else if( _destination == CAMP && _location == WATERFALL )
			{ 
				_currentPath = this.campToWaterfall;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
			else if( _destination == FORTRESS && _location == CAMP )
			{ 
				_currentPath = this.campToFortress;
			}
			else if( _destination == CAMP && _location == FORTRESS )
			{ 
				_currentPath = this.campToFortress;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
				// ANYTHING THAT GOES TO/FROM JUNGLE'S CAMP
			else if( _destination == DODO && _location == JUNGLE )
			{ 
				_currentPath = this.jungleToDodo;
			}
			else if( _destination == JUNGLE && _location == DODO )
			{ 
				_currentPath = this.jungleToDodo;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
			else if( _destination == WATERFALL && _location == JUNGLE )
			{ 
				_currentPath = this.jungleToWaterfall;
			}
			else if( _destination == JUNGLE && _location == WATERFALL )
			{ 
				_currentPath = this.jungleToWaterfall;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
			else if( _destination == FORTRESS && _location == JUNGLE )
			{ 
				_currentPath = this.jungleToFortress;
			}
			else if( _destination == JUNGLE && _location == FORTRESS )
			{ 
				_currentPath = this.jungleToFortress;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
				// ANYTHING THAT GOES TO/FROM DODO
			else if( _destination == WATERFALL && _location == DODO )
			{ 
				_currentPath = this.dodoToWaterfall;
			}
			else if( _destination == DODO && _location == WATERFALL )
			{ 
				_currentPath = this.dodoToWaterfall;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
				
			else if( _destination == FORTRESS && _location == DODO )
			{ 
				_currentPath = this.dodoToFortress;
			}
			else if( _destination == DODO && _location == FORTRESS )
			{ 
				_currentPath = this.dodoToFortress;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
				// ANYTHING FROM WATERFALL
			else if( _destination == FORTRESS && _location == WATERFALL )
			{ 
				_currentPath = this.waterfallToFortress;
			}
			else if( _destination == WATERFALL && _location == FORTRESS )
			{ 
				_currentPath = this.waterfallToFortress;
				_stepNumber = _currentPath.length - 1;
				_returning = true;
			}
				// SAME PLACE
			else if( _destination == _location )
			{
				reachNextScene();
			}
		}
		
		private function nextFootPrint():void
		{
			if(( _stepNumber < _currentPath.length && !_returning )|| ( _stepNumber >= 0 && _returning ))
			{
				var sprite:Sprite = new Sprite();
				var bitmap:Bitmap = new Bitmap( _pathStep.data );
				var nextStep:Point = _currentPath[ _stepNumber ];
				
				sprite.addChild( bitmap );
				sprite.x = nextStep.x;
				sprite.y = nextStep.y;
				screen.content[ "mist" ].addChild( sprite );
				
				if( !_returning )
				{
					_stepNumber ++;
				}
				else
				{
					_stepNumber --;
				}
				
				SceneUtil.addTimedEvent( this, new TimedEvent( .2, 1, nextFootPrint ));
			}
			else
			{
				moveMarker();
			}
		}
		
		private function moveMarker():void
		{
			var marker:Entity = getEntityById( "marker" );
			
			var spatial:Spatial = getEntityById( _destination ).get( Spatial );
			var markerSpatial:Spatial = marker.get( Spatial );
			var tween:Tween = marker.get( Tween );
			
			markerSpatial.x = spatial.x;
			markerSpatial.y = spatial.y;
			
			tween.to( marker.get( Display ), .3, { alpha : 1, onComplete : reachNextScene });
		}
		
		private function reachNextScene():void
		{
			var playerX:Number = NaN;
			var playerY:Number = NaN;
			var direction:String = null;
			var scene:*;
			var noAd:Boolean = AdUtils.noAds(this);
			
			switch( _destination )
			{
				case CAMP:
					if(noAd)
						scene = EmbedsCamp;
					else
						scene = AdStreet2;
					
					break;
				
				case DODO:
					scene = DodoHabitat;
					break;
				
				case FORTRESS:
					scene = Fortress;
					break;
				
				case JUNGLE:
					scene = Jungle;
					playerX = 100;
					playerY = 1032;
					direction = "right";
					break;
				
				case WATERFALL:
					if( shellApi.checkEvent( _events.PEAK_EXPLODED ))
						scene = Waterfall2;
					else
						scene = Waterfall;
			}
			
			shellApi.loadScene( scene, playerX, playerY, direction );
		}
		
		// ADD MIST EMMITERS
		private function addMist( placement:Point, number:int ):void
		{
			var emitter2D:Emitter2D = new Emitter2D();
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( new Blob( 3, 0xC8E6EE ));
			
			// DASH LINES PULLING IN	
			emitter2D = new Emitter2D();
			emitter2D.counter = new Steady( 3 );
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 20 ));
			emitter2D.addInitializer( new Position( new PointZone( placement )));
			emitter2D.addInitializer( new Lifetime( 1 ));
			emitter2D.addInitializer( new Velocity( new LineZone( new Point( 0, 0 ), new Point( 0, -20 ))));
			
			emitter2D.addAction( new ScaleImage( 1, 2 ));
			emitter2D.addAction( new Fade( .75, 0 ));		
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			
			EmitterCreator.create( this, screen.content[ "mist" ], emitter2D, 0, 0, null, "mistEmitter" + number );
		}
		
		private function setupBirds():void
		{
			var birdNumber:int;
			var birdEntity:Entity;
			var clip:MovieClip;
			var container:DisplayObjectContainer = screen.content;
			var locationEntity:Entity;
			var locationNumber:int;
			var shape:Shape;
			var sprite:Sprite;
			
			for( locationNumber = 1; locationNumber < 7; locationNumber ++ )
			{
				clip = screen.content[ "location" + locationNumber ];
				locationEntity = EntityUtils.createSpatialEntity( this, clip );
				locationEntity.add( new Id( clip.name ));
				
				for( birdNumber = 1; birdNumber < 4; birdNumber++ )
				{
					sprite 		= new Sprite();
					sprite.mouseChildren 	= false;
					sprite.mouseEnabled 	= false;
					screen.content.addChildAt( sprite, screen.content.numChildren );
					
					birdEntity = EntityUtils.createSpatialEntity( this, sprite );
					birdEntity.add( new Id( "bird" + birdNumber ));
					
					var bird:Bird = new Bird( locationEntity, Utils.randNumInRange( 3, 5 ), Utils.randNumInRange( .05, .5 ), 100 - ( birdNumber * 10 ));
					bird.flockTime = Utils.randNumInRange( 1, 7 );
					birdEntity.add( bird );
					
					shape = new Shape();
					shape.graphics.lineStyle( 1.5, 0xfff3e6 );
					shape.graphics.lineTo( -7, 0 );
					sprite.addChild( shape );
					bird.wing1 = shape;
					
					shape = new Shape();
					shape.graphics.lineStyle( 1.5, 0xfff3e6 );
					shape.graphics.lineTo( -7, 0 );
					shape.scaleX = -1;
					sprite.addChild( shape );
					bird.wing2 = shape;
					
					var spatial:Spatial = birdEntity.get( Spatial );
					spatial.x = Utils.randNumInRange( 300, 350 );
					spatial.y = Utils.randNumInRange( 300, 350 );
				}
			}
		}
		
		private function setupClouds():void
		{
			var clip:DisplayObjectContainer;
			var cloudShadow:DropShadowFilter 	= new DropShadowFilter(15, 100, 0x000000, 0.05, 8, 8, 1, 1);
			var cloudOutline:DropShadowFilter 	= new DropShadowFilter(0, 0, 0x000000, 1, 2, 2, 1, 3);
			var display:Display;
			var entity:Entity;
			var innerNumber:int;
			var motion:Motion;
			var number:int;
			var partNumber:int;
			var part:DisplayObject;
			var spatial:Spatial;
			var threshold:Threshold;
			
			for( number = 1; number < 6; number++ )
			{
				clip = screen.content[ "cloud" + number ];
				clip.filters = [ cloudShadow, cloudOutline ];
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				
				BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality);
				
				entity = EntityUtils.createMovingEntity( this, clip );
				
				display = entity.get( Display );
				display.alpha = 0.75;
				entity.add( new MapCloud());
				
				spatial = entity.get( Spatial );
				spatial.x = Utils.randNumInRange( 0, shellApi.viewportWidth );
				
				for( partNumber = 1; partNumber <= 3; partNumber++ )
				{
					part = display.displayObject.getChildByName( "part" + partNumber );
					part.x = Utils.randNumInRange(-75,75);
					part.y = Utils.randNumInRange(-10,10);
					part.scaleX = Utils.randNumInRange(0.6,1.0);
					part.scaleY = part.scaleX * Utils.randNumInRange(0.6,1.0);
				}
				
				motion = entity.get( Motion );
				motion.velocity.x = -(Utils.randNumInRange( 40, 60 ));
				
				threshold = new Threshold( "x", "<" );
				threshold.threshold = -spatial.width * 1.1;
				threshold.entered.add( Command.create( resetCloud, entity ));
				entity.add( threshold );
			}
		}
		
		private function resetCloud( entity:Entity ):void
		{
			var spatial:Spatial = entity.get( Spatial );
			spatial.x = shellApi.viewportWidth + spatial.width * 1.1;
			spatial.y = Utils.randNumInRange( spatial.height*2.5, shellApi.viewportHeight - spatial.height*2.5 );
		}
		
		
		private function setupAnimationLoops():void
		{
			// timeline all animations
			var tree:Entity;
			var boat:Entity;
			var clip:MovieClip;
			var sequence:BitmapSequence;		
			
			// blue-Green trees
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				clip = screen.content["palm1"];
				sequence = BitmapTimelineCreator.createSequence(clip,true,PerformanceUtils.defaultBitmapQuality+.2);
			}
			for(var i:int = 1; i < 8; i++ )
			{
				clip = screen.content["palm"+i];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					tree = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,sequence,PerformanceUtils.defaultBitmapQuality+.2);
					Timeline(tree.get(Timeline)).play();
					this.addEntity(tree);
				}else{
					tree = EntityUtils.createMovingTimelineEntity(this, clip, null, true);
				}
				Display(tree.get(Display)).disableMouse();
			}
			// green trees
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				clip = screen.content["palm8"];
				sequence = BitmapTimelineCreator.createSequence(clip,true,PerformanceUtils.defaultBitmapQuality+.2);
			}
			for(i = 8; i < 16; i++ )
			{
				clip = screen.content["palm"+i];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					tree = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,sequence,PerformanceUtils.defaultBitmapQuality+.2);
					Timeline(tree.get(Timeline)).play();
					this.addEntity(tree);
				}else{
					tree = EntityUtils.createMovingTimelineEntity(this, clip, null, true);
				}
				Display(tree.get(Display)).disableMouse();
			}
		}
	}
}