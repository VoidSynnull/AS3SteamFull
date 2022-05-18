package game.scenes.con3.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.PerformanceMonitor;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.scene.template.AudioGroup;
	import game.scenes.con3.Con3Events;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	
	public class PortalGroup extends Group
	{
		public function PortalGroup()
		{
			super();
			super.id = GROUP_ID;
		}

		public function createPortal( group:Scene, container:DisplayObjectContainer ):void
		{
			// TODO link up bow-and-arrow stuff
			_audioGroup = group.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			_container = container;
			_group = group;
			_events = new Con3Events();
			
			var clip:MovieClip = _container[ "portal" ];
			
			portal = EntityUtils.createMovingTimelineEntity( this, clip );
			portal.add( new Id( "portal" ));
			var display:Display = portal.get( Display );
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH )
			{
				BitmapUtils.convertContainer( display.displayObject.ring );
			}
			
			// SETUP LIGHT FLASH
			var lightOverlaySprite:Sprite = new Sprite();
			lightOverlaySprite.mouseEnabled = false;
			lightOverlaySprite.mouseChildren = false;
			lightOverlaySprite.graphics.clear();
			lightOverlaySprite.graphics.beginFill( 0xFFFFFF, 1 );
			lightOverlaySprite.graphics.drawRect( 0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			_group.overlayContainer.addChild( lightOverlaySprite );
			
			display = new Display( lightOverlaySprite );
			display.isStatic = true;
			display.alpha = 0;
			
			lightOverlay = new Entity();
			lightOverlay.add( new Spatial());
			lightOverlay.add( display );
			lightOverlay.add( new Sleep( true, true ));
			lightOverlay.add( new Id( "lightOverlay" ));
			
			_group.addEntity( lightOverlay );
		}
		
		public function portalTransitionIn( transitionInHandler:Function, transitionOutHandler:Function, closePortalEvent:String ):void
		{			
			// START TRANSITION IN
			_transitionInHandler = transitionInHandler;
			_transitionOutHandler = transitionOutHandler;
			_closePortalEvent = closePortalEvent;
			
			var timeline:Timeline = portal.get( Timeline );
			Sleep( lightOverlay.get( Sleep )).sleeping = false;
			
			AudioUtils.play( _group, SoundManager.EFFECTS_PATH + "electric_zap_03.mp3", 1, false );
			AudioUtils.play( _group, SoundManager.EFFECTS_PATH + "electric_zap_05.mp3", 1, false );
			
			timeline.play();
			timeline.labelReached.add( portalHandler );
		}
		
		private function portalHandler( label:String ):void
		{
			var timeline:Timeline = portal.get( Timeline );
			var tween:Tween = lightOverlay.get( Tween );
			if( !tween )
			{
				tween = new Tween();
				lightOverlay.add( tween );
			}
			
			var display:Display = lightOverlay.get( Display );
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH && label.indexOf( FLASH ) > -1 )
			{
				tween.to( display, .25, { alpha : 1, onComplete : overlayOut });
			}
			
			// start_pull
			if( label == "start_pull" )
			{
				AudioUtils.play( _group, SoundManager.EFFECTS_PATH + "energy_hum_02_loop.mp3", 1, true );
				if( _transitionInHandler )
				{
					_transitionInHandler();
				}
			}
			
			// loop
			if( label == "check_loop" )
			{
				if( !shellApi.checkEvent( _closePortalEvent ))
				{
					timeline.gotoAndPlay( "loop" );
				}
			}
			
			if( label == "ending" )
			{
				timeline.stop();
				AudioUtils.stop( _group, SoundManager.EFFECTS_PATH + "energy_hum_02_loop.mp3" );
				AudioUtils.stop( _group, SoundManager.EFFECTS_PATH + "electric_zap_03.mp3" );
				AudioUtils.stop( _group, SoundManager.EFFECTS_PATH + "electric_zap_05.mp3" );
				if( _transitionOutHandler )
				{
					_transitionOutHandler();
				}
			}
		}
		
		private function overlayOut():void
		{
			var tween:Tween = lightOverlay.get( Tween );
			var display:Display = lightOverlay.get( Display );
			
			tween.to( display, .25, { alpha : 0 });
		}
		
		private function closePortal():void
		{
			shellApi.completeEvent( _events.PLAYER_THROUGH_PORTAL );
		}
		
		public var portal:Entity;
		public var lightOverlay:Entity;
		
		private var _transitionInHandler:Function;
		private var _transitionOutHandler:Function;
		private var _closePortalEvent:String;
		
		private var _audioGroup:AudioGroup;
		private var _container:DisplayObjectContainer;
		private var _events:Con3Events;
		private var _group:Scene;
		
		private const FLASH:String					= "flash";
		public static const GROUP_ID:String 		= "portalGroup";
	}
}