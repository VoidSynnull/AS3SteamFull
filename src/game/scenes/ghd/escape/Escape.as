package game.scenes.ghd.escape
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.display.BitmapWrapper;
	import game.scene.template.AudioGroup;
	import game.scene.template.CutScene;
	import game.scenes.ghd.GalacticHotDogEvents;
	import game.scenes.ghd.neonWiener.Comics;
	import game.scenes.ghd.neonWiener.NeonWiener;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	
	public class Escape extends CutScene
	{
		private var _ship:Entity;
		private var _takenOff:Boolean 		=		false;
		private var _startedEscape:Boolean 	= 		false;
		private var _fighters:Entity;
		
		private const ZAP:String					= 		"electric_zap_03.mp3";
		private const ZAP_2:String					=		"electric_zap_06.mp3";
		private const ZAP_3:String					=		"electric_zap_05.mp3";
		
		private const POWER_ON:String				=		"power_on_07b.mp3";
		private const WARP:String					=		"warp_zap.mp3";
		private const LASER:String					=		"laser";
		private const JACK:String					=		"jack";
		private const CONTAINER:String				=		"Container";
		
		public function Escape()
		{
			super();
			configData( "scenes/ghd/escape/", GalacticHotDogEvents( events ).READY_FOR_CONTEST );
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
			// TODO :: Why is the event here? Why not in the Neon Weiner scene? - bard
			shellApi.completeEvent( GalacticHotDogEvents( events ).COOKED_DOG );
			
			for( var number:int = 1; number < 4; number ++ )
			{
				var jack:Entity = Children(sceneEntity.get(Children)).getChildByName("jack" + number);
				var laser:Entity = Children(jack.get(Children)).getChildByName("laser");
				var timeline:Timeline = jack.get(Timeline);
				timeline.handleLabel( "shoot", Command.create( shootLaser, laser ), false );
				timeline.gotoAndPlay(( number * 3 ) + 1 );
			}
			
			start();
		}
			
		// HANDLE SCENE TIMELINE
		override public function onLabelReached( label:String ):void
		{
			var spatial:Spatial;
			var tween:Tween;
			
			if( label == "startShrinkShip" && _ship )
			{
				spatial = _ship.get( Spatial );
				spatial.scaleY = .3;
				spatial.scaleX = -.3;
				
				tween = new Tween();
				tween.to( spatial, 1, { scaleY : 0, scaleX : 0 });
				_ship.add( tween );
			}
			
			if( label == "startShrinkFighters" && _fighters )
			{
				spatial = _fighters.get( Spatial );
				
				tween = new Tween();
				tween.to( spatial, 2.5, { scaleY : 0, scaleX : 0 });
				_fighters.add( tween );
			}
			
			if( label == "power_on" )
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + POWER_ON );
			}
			
			if( label.indexOf( "warp" ) > -1 )
			{
				if( !_takenOff )
				{
					_takenOff = true;
				}
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + WARP );
			}
			
			if( label.indexOf( "blastA" ) > -1 )
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + ZAP_2 );
			}
			
			if( label.indexOf( "blastB" ) > -1 )
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + ZAP_3 );
			}
			
			if( label.indexOf( "startEscape" ) > -1 )
			{
				_startedEscape = true;
			}
		}
		
		// RESET LASERS
		private function shootLaser( laser:Entity ):void
		{
			var timeline:Timeline = laser.get( Timeline );
			timeline.gotoAndPlay( 0 );
			
			if( !_takenOff && _startedEscape )
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + ZAP );
			}
		}
		
		override public function end():void
		{
			super.end();
			SceneUtil.lockInput( this, false );
			var popup:Comics = super.addChildGroup( new Comics( super.overlayContainer )) as Comics;
			popup.id = "comics";
			popup.removed.add( loadNeonWiener );
		}
		
		private function loadNeonWiener( popup:Comics ):void
		{
			shellApi.loadScene( NeonWiener );
		}
	}
}