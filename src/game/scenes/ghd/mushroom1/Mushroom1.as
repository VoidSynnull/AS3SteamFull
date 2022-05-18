package game.scenes.ghd.mushroom1
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.scenes.ghd.shared.MushroomGroup;
	import game.scenes.ghd.shared.mushroom.Mushroom;
	import game.scenes.ghd.shared.mushroomBouncer.MushroomBouncer;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class Mushroom1 extends GalacticHotDogScene
	{
		private const EYES:String 		= 	"eyes";
		private const TRIGGER:String	=	"trigger";
		private const SPLAT:String		=	"splat_01.mp3";
		private var _ready:Boolean = false;
	
		public function Mushroom1()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/mushroom1/";
			
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
			
			this.shellApi.setUserField(_events.PLANET_FIELD, _events.MUSHROOM, this.shellApi.island, true);
			
			
			var mushroomGroup:MushroomGroup = this.addChildGroup(new MushroomGroup()) as MushroomGroup;
			mushroomGroup.createMushrooms( this, this._hitContainer, [ 1, 7 ], [ 3, 4, 5, 7, 8 ]);
			mushroomGroup.setupEyes( this, this._hitContainer );
			
			this.player.add(new MushroomBouncer());
			var display:Display =  getEntityById( "mushroom8" ).get( Display );
			display.moveToFront();
			
			_hitContainer.setChildIndex( _hitContainer[ "mushroom8Roots" ], _hitContainer.numChildren - 1 );
			
			if( !shellApi.checkEvent( _events.KNOW_HOW_TO_FLIP_MUSHROOMS ))
			{
				SceneUtil.lockInput( this );
				var spatial:Spatial = player.get( Spatial );
				_hitContainer.setChildIndex( _hitContainer[ "mothra" ], _hitContainer.numChildren - 1 );
				
				CharUtils.moveToTarget( player, spatial.x + 100, spatial.y, true, spotMothra);
				setupMothra();
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ "mothra" ]);
			}
		}
		
		// CHICKATA INTRO SEQUENCE
		private function setupMothra():void
		{
			var clip:MovieClip;
			var mothra:Entity;
			var mothraSequence:BitmapSequence;
			var timeline:Timeline;
			
			var audioGroup:AudioGroup = this.getGroupById(AudioGroup.GROUP_ID) as AudioGroup;
			
			clip = _hitContainer[ "mothra" ];
			clip.gotoAndStop(1);
			mothra = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			mothraSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			BitmapTimelineCreator.convertToBitmapTimeline( mothra, clip, true, mothraSequence, PerformanceUtils.defaultBitmapQuality );
			mothra.add( new Id( "mothra" ));
			
			var display:Display =  getEntityById( "mothra" ).get( Display );
			display.moveToFront();
			audioGroup.addAudioToEntity( mothra );
			
			timeline = mothra.get( Timeline );
			timeline.playing = true;
			timeline.handleLabel( "squat", checkSceneReady, false );
			timeline.handleLabel( "fart", playFartAudio );
			timeline.handleLabel( "done", flipMushroom );
			timeline.handleLabel( "splatonground", playSlapAudio ); 
			timeline.handleLabel( "flying", exitStageRight );
		}
		
		private function spotMothra( player:Entity ):void
		{
			SceneUtil.setCameraTarget( this, getEntityById( "mothra" ));
			_ready = true;
		}
		
		private function checkSceneReady():void
		{
			var mothra:Entity = getEntityById( "mothra" );
			var timeline:Timeline = mothra.get( Timeline );
			if( !_ready )
			{
				timeline.gotoAndPlay( "idle" );
			}
		}
		
		private function playFartAudio():void
		{
			var audio:Audio = getEntityById( "mothra" ).get( Audio );
			audio.playCurrentAction( TRIGGER );
		}
		
		private function playSlapAudio():void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + SPLAT );
		}
		
		private function flipMushroom():void
		{
			var mushroom:Mushroom = getEntityById( "mushroom8" ).get( Mushroom );
			mushroom.isFacingLeft = !mushroom.isFacingLeft;
		}
		
		private function exitStageRight():void
		{
			var motion:Motion = new Motion();
			motion.velocity.x = 400;
			motion.velocity.y = -10;
			
			getEntityById( "mothra" ).add( motion );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, grossOut ));
		}
		
		private function grossOut():void
		{
			SceneUtil.setCameraTarget( this, player );
			var dialog:Dialog = player.get( Dialog );
			dialog.say( "eww" );
			dialog.complete.addOnce( mothraGone );
		}
		
		private function mothraGone( dialogData:DialogData ):void 
		{
			removeEntity( getEntityById( "mothra" ));
			SceneUtil.lockInput( this, false );
		}
	}
}