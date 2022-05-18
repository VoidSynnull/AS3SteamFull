package game.scenes.ghd.mushroom2
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	
	import game.components.entity.Dialog;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.animation.entity.character.DanceMoves01;
	import game.data.animation.entity.character.PushMedium;
	import game.data.animation.entity.character.Stand;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.scenes.ghd.shared.MushroomGroup;
	import game.scenes.ghd.shared.mushroomBouncer.MushroomBouncer;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class Mushroom2 extends GalacticHotDogScene
	{
		private var _humphree:Entity;
		private const TRIGGER:String		=	"trigger";
		
		public function Mushroom2()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/mushroom2/";
			
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
			mushroomGroup.createMushrooms( this, this._hitContainer, [ 6, 7 ], [ 1, 2, 4, 6 ]);
			mushroomGroup.setupEyes( this, this._hitContainer );
			
			this.player.add(new MushroomBouncer());
			
			setupSnare();
		}
		
		private function setupSnare():void
		{
			var clip:MovieClip;
			var dialog:Dialog;
			var display:Display;
			var entity:Entity;
			var sequence:BitmapSequence;
			var timeline:Timeline;
			var audioGroup:AudioGroup = this.getGroupById(AudioGroup.GROUP_ID) as AudioGroup;
			
			clip = _hitContainer[ "humphreeSnare" ];
			clip.gotoAndStop(1);
			entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			sequence = BitmapTimelineCreator.createSequence( clip, true, 2 );
			
			BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
			entity.add( new Id( "humphreeSnare" ));
			audioGroup.addAudioToEntity( entity );
			display = entity.get( Display );
			timeline = entity.get( Timeline );
			timeline.playing = false;
			
			if( !shellApi.checkEvent( _events.RECOVERED_HUMPHREE ))
			{
				display.moveToFront();
				_humphree = getEntityById( "humphree" );
				
				display = player.get( Display );
				display.moveToFront();
				
				dialog = _humphree.get( Dialog );
				dialog.complete.addOnce( getInPlace );
			}
			else
			{
				timeline.gotoAndStop( "down" );
			}
		}
		
		private function getInPlace( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this );
			CharUtils.setAnim( _humphree, Stand, false, 0, 0, true );
			CharUtils.moveToTarget( player, 755, 560, true, pullRoots );
		}
		
		private function pullRoots( player:Entity ):void
		{
			CharUtils.setDirection( player, false );
			CharUtils.setAnim( player, PushMedium );
			
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "ending", ripOut );
		}
		
		private function ripOut():void
		{
			var entity:Entity = getEntityById( "humphreeSnare" );
			var timeline:Timeline = entity.get( Timeline );
			timeline.play();
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( TRIGGER );
			timeline.handleLabel( "down", humphreeFree );
		}
		
		private function humphreeFree():void
		{
			CharUtils.moveToTarget( _humphree, 920, 560, true, danceOff );
		}
		
		private function danceOff( humphree:Entity ):void
		{
			CharUtils.setAnim( _humphree, DanceMoves01 );
			var timeline:Timeline = _humphree.get( Timeline );
			timeline.handleLabel( "ending", backToTheShip );
		}
		
		private function backToTheShip():void
		{
			CharUtils.setDirection( player, true );
			
			var dialog:Dialog = _humphree.get( Dialog );
			dialog.sayById( "free" );
			dialog.complete.add( humphreeRunOff );
		}
		
		private function humphreeRunOff( dialogData:DialogData ):void
		{
			CharUtils.moveToTarget( _humphree, 1460, 560, true, removeHumphree )
		}
		
		private function removeHumphree( humphree:Entity ):void
		{
			removeEntity( _humphree );
			shellApi.completeEvent( _events.RECOVERED_HUMPHREE );
			SceneUtil.lockInput( this, false );
		}
	}
}