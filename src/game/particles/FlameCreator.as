package game.particles
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.BlurFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.BitmapTimeline;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMaster;
	import game.creators.entity.BitmapTimelineCreator;
	import game.scene.template.AudioGroup;
	import game.components.particles.Flame;
	import game.systems.particles.FlameSystem;
	import game.util.BitmapUtils;
	import game.util.ColorUtil;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;

	/**
	 * Creates standard flames, managing which type of flames are created based on platform.
	 * On Desktop dynamic flames managed by the FlameSystem are created.
	 * On Mobile timeline driven flames are created, which share a bitmap sequence.
	 * Flames cans be arranged in scene to accommodate the dynamic approach, the creator handles swapping assets when necessary.
	 * @author Bard McKinley
	 * 
	 */
	public class FlameCreator
	{
		public function FlameCreator()
		{
		}
		
		/**
		 * Setup creator, loads assets if necessary (based on Platform).
		 * Handler is called once laoding is complete.
		 *  
		 * @param group
		 * @param clipToReplace - used for timeline flames, applies attributes of clipToReplace and to flame timeline prior to bitmapping.
		 * @param colors - Array of hex colors, if supplied will not extract colors from clipToReplace, otherwise colors will be extracted from clipToReplace.
		 * @param completeHandler - called once setup is complete.
		 */
		public function setup( group:Group, clipToReplace:MovieClip = null, colors:Array = null, completeHandler:Function = null ):void
		{
			if( PlatformUtils.isMobileOS )	// if mobile use bitmap timeline
			{
				this.loadTimelineFlame( group, clipToReplace, colors, completeHandler );
				//group.addSystem( new BitmapSequenceSystem() );	// NOTE :: generally this should be already be added to group
			}
			else
			{
				group.addSystem( new FlameSystem() );
				if( completeHandler != null )
				{
					completeHandler();
				}
			}
		}
		
		public function destroy():void
		{
			if( _bitmapSequence != null )
			{
				_bitmapSequence.destroy();
			}
			_bitmapSequence = null
			_timeline = null;
		}
		
		/**
		 * Create a flame, check performance to Platform to detemrine which type of flame to create, dynamic or timeline.
		 * Dynamic is made for Desktop, timeline is made for Mobile.
		 * @param group
		 * @param clipToReplace - clip the flame will be created form or replace (in case of timeline flame the clip is replaced)
		 * @param addAudio - if true audio will be setup automatically
		 * @return 
		 */
		public function createFlame( group:Group, clipToReplace:MovieClip, addAudio:Boolean = false ):Entity
		{
			if( PlatformUtils.isMobileOS )	// if mobile use bitmap timeline
			{
				return createTimelineFlame( group, clipToReplace, null, null, addAudio );
			}
			else
			{
				return createDynamicFlame( group, clipToReplace, null, null, addAudio ); 
			}
		}
		
		/**
		 * Creates a 'dynamic' flame that is managed by the FlameSystem. 
		 * @param group
		 * @param clip
		 * @param parentEntity
		 * @param colors
		 * @param addAudio
		 * @return 
		 * 
		 */
		private function createDynamicFlame( group:Group, clip:DisplayObjectContainer, parentEntity:Entity = null, colors:Array = null, addAudio:Boolean = false ):Entity
		{
			var numFlames:int = clip.numChildren;
			var entity:Entity;
			var flameClip:MovieClip;
			var madeBase:Boolean = false
			
			var i:uint = numFlames - 1;
			while( clip.numChildren > 0 )
			{	
				flameClip = clip.getChildAt( 0 ) as MovieClip;
				if( !madeBase )
				{
					madeBase = true;
					if( parentEntity == null )	{ parentEntity = EntityUtils.createSpatialEntity( group, clip ); }
					parentEntity.add( new Id( "flame" ));
					parentEntity.add( new Flame( flameClip, false ));	// NOTE :: on construction clip is being removed from its parent
					
					if( addAudio )
					{
						addFlameAudio( group, parentEntity, clip.scaleX );
					}
				}
				else
				{
					entity = new Entity();
					entity.add( new Flame( flameClip, true ));			// NOTE :: on construction clip is being removed from its parent
					EntityUtils.addParentChild( entity, parentEntity );
					entity.managedSleep = false;
					group.addEntity(entity);
				}
			}
			return parentEntity;
		}
		
		/**
		 * Create a 'dynamic' flame by loading the necessary swf and having it replace provided container.
		 * @param group
		 * @param flameContainer
		 * @param colors
		 * @return 
		 * 
		 */
		private function createDynamicFlameFromSwf( group:Group, flameContainer:DisplayObjectContainer, colors:Array = null, handler:Function = null ):Entity
		{
			var entity:Entity = EntityUtils.createSpatialEntity( group, flameContainer );
			group.addEntity( entity );
			group.shellApi.loadFile( group.shellApi.assetPrefix + FLAME_DYNAMIC_PATH, Command.create( onDynamicFlameLoaded, entity, colors, handler ) );
			return entity;
		}

		/**
		 * Create a flame that uses a bitmap sequence.
		 * Applies the attributes of the clip being replace to the bitmp sequence.
		 * Maintains a single reference to a bitmap sequence, if different sequences are required create a new FlameCreator for each.
		 * @param group
		 * @param clipToReplace
		 * @param entity
		 * @param colors
		 * @param addAudio
		 * @return 
		 * 
		 */
		private function createTimelineFlame( group:Group, clipToReplace:DisplayObjectContainer = null, entity:Entity = null, colors:Array = null, addAudio:Boolean = false  ):Entity
		{
			if( entity == null )
			{
				entity = EntityUtils.createSpatialEntity( group, clipToReplace );
				entity.add( new Id( "flame" ));
			}
			
			if( _bitmapSequence == null )
			{
				group.shellApi.loadFile( group.shellApi.assetPrefix + FLAME_DYNAMIC_PATH, Command.create( onTimelineFlameLoaded, colors, entity, clipToReplace ) );
			}
			else
			{
				entity.add( _bitmapSequence );
				var timeline:Timeline = _timeline.duplicate();
				entity.add( timeline );
				entity.add( new TimelineMaster() );
				timeline.reset();
				
				var display:Display = entity.get( Display );
				DisplayUtils.removeAllChildren( display.displayObject );
				
				var bitmapContainer:Bitmap = new Bitmap( null, "auto", true );
				display.displayObject.addChild( bitmapContainer );
				display.alpha = clipToReplace.alpha;
				MovieClip(display.displayObject).filters = new Array();	// remove any filters (should be applied during bitmap sequence creation)
				
				entity.add( new BitmapTimeline( bitmapContainer ) );	
				
				if( addAudio )
				{
					addFlameAudio( group, entity, clipToReplace.scaleX );
				}
			}

			return entity;
		}
		
		/**
		 * Loads swf containing timeline driven flame, on load is converted to a bitmap sequence.
		 * Applies attributes of the clipToReplace to the bitmap sequence.
		 * @param group
		 * @param clipToReplace
		 * @param colors
		 * @param loadHandler
		 * 
		 */
		private function loadTimelineFlame( group:Group, clipToReplace:MovieClip = null, colors:Array = null, loadHandler:Function = null ):void
		{
			group.shellApi.loadFile( group.shellApi.assetPrefix + FLAME_TIMELINE_PATH, Command.create( onTimelineFlameLoaded, colors, null, clipToReplace, loadHandler ) );
		}

		private function onTimelineFlameLoaded( clip:MovieClip, colors:Array = null, entity:Entity = null, clipToReplace:MovieClip = null, loadHandler:Function = null ):void
		{
			if( _bitmapSequence == null )
			{
				// get colors  TODO :: still needs work
				if( colors == null )
				{
					colors = getFlameColors( clipToReplace );
				}
				
				// apply color
				clip = clip.content;
				if( colors )
				{
					applyColors( clip, colors );
				}
				
				// Apply filters
				var buffer:int;
				var filters:Array = clipToReplace.filters;
				var filterMultiplier:int = 2;	// NOTE :: The filters set in teh fla tend to be too small when put rhough this process.  Not sure why though. - bard
				for (var i:int = 0; i < filters.length; i++) 

				{
					if( filters[i] is GlowFilter || filters[i] is BlurFilter || filters[i] is DropShadowFilter )
					{
						filters[i].blurX *= filterMultiplier;
						filters[i].blurY *= filterMultiplier;
						buffer = Math.max( buffer, Math.max( filters[i].blurX, filters[i].blurY ) );
					}

				}
				clip.filters = filters;
	
				_bitmapSequence = BitmapTimelineCreator.createSequence( clip );
				_timeline = new Timeline();
				TimelineUtils.parseMovieClip( _timeline, clip );
				if( entity != null )
				{
					createTimelineFlame( entity.group, clipToReplace, entity, colors );
				}
				
				if( loadHandler != null )
				{
					loadHandler();
				}
			}
		}
		
		private function getFlameColors( clip:MovieClip ):Array
		{
			var colors:Array;
			var bitmapData:BitmapData;
			for (var i:int = 0; i < clip.numChildren; i++) 

			{
				bitmapData = BitmapUtils.createBitmapData(clip);
				var color:Number = bitmapData.getPixel( bitmapData.width/2, bitmapData.height/2 );
				if( colors == null ) { colors = new Array(); }
				colors.push( color );
				bitmapData.dispose();
			}
			return colors;
		}
		
		private function addFlameAudio( group:Group, entity:Entity, scale:Number ):void
		{
			entity.add( new AudioRange( AUDIO_RANGE_DEFAULT * scale, 0.01, 1 ) );
			AudioGroup(group.getGroupById( AudioGroup.GROUP_ID )).addAudioToEntity( entity );
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( RANDOM );
		}
		
		private function applyColors( clip:MovieClip, colors:Array ):void
		{
			if ( colors != null && colors.length == 2 )
			{
				var numChildren:int = clip.numChildren;
				var childClip:MovieClip; 
				for (var i:int = 0; i < numChildren; i++) 

				{

					childClip = clip.getChildAt(i) as MovieClip;
					if( i < 5 )
					{
						ColorUtil.colorize( childClip.color, colors[0] );
					}
					else
					{
						ColorUtil.colorize( childClip.color, colors[1] );
					}

				}
			}
		}

		private function onDynamicFlameLoaded( asset:DisplayObjectContainer, entity:Entity, colors:Array = null, handler:Function = null ):void
		{
			// apply loaded asset 
			var display:Display = entity.get(Display);
			DisplayUtils.swap( display.displayObject, asset );
			display.displayObject = asset;
			
			createDynamicFlame( entity.group, display.displayObject, entity, colors );
			if( handler != null )
			{
				handler();
			}
		}

		private const AUDIO_RANGE_DEFAULT:int = 1000;
		private const RANDOM:String = "random";
		
		private var _bitmapSequence:BitmapSequence;
		private var _timeline:Timeline;
		private const FLAME_TIMELINE_PATH:String = "particles/flameTimeline.swf";
		private const FLAME_DYNAMIC_PATH:String = "particles/flameDynamic.swf";
	}
}