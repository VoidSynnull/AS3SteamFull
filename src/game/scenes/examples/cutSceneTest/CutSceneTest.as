package game.scenes.examples.cutSceneTest
{
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.data.animation.AnimationData;
	import game.data.animation.AnimationSequence;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Tremble;
	import game.scene.template.CharacterGroup;
	import game.scene.template.CutScene;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.woods.Woods;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	
	public class CutSceneTest extends CutScene
	{
		private const CRASH_LANDING:String = "crash_landing.mp3";
		
		public function CutSceneTest()
		{
			super();
			configData("scenes/survival1/crashLanding/", Survival1Events(events).CRASH_LANDING);
		}
		
		override public function loaded():void
		{
			super.loaded();
			var sequence:AnimationSequence = new AnimationSequence(Grief, Grief);
			sequence.add( new AnimationData( Tremble, 60 ) );
			sequence.add( new AnimationData( Grief ) );
			//setUpCharacter(screen.blimp.player_container, sequence);
		}
		
		public function onPlayerLoaded():void
		{
			super.onPlayerLoaded();
			
			Spatial(player.get(Spatial)).y -= 25;
			
			CharUtils.setDirection( player, true );
			Timeline( player.get(Timeline) ).labelReached.add( onAnimEnd );
			
			AudioUtils.play( this, SoundManager.MUSIC_PATH + CRASH_LANDING );
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "thunder_clap_01.mp3" );
			AudioUtils.play( this, SoundManager.AMBIENT_PATH + "strong_winds_01.mp3", .5, true );
			
			super.groupReady();
		}
		
		private function onAnimEnd( label:String ):void
		{
			if( label == "ending" )
			{
				var spatial :Spatial = player.get(Spatial);
				spatial.scaleX *= -1;
			}
		}
		
		override public function onLabelReached(label:String):void
		{
			if( label.indexOf("lightning") == 0 )
			{
				var number:int = Math.round( Math.random() * 3 ) + 1;
				
				trace( number );
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "thunder_clap_0" + number + ".mp3" );
			}
			
			if( label == "surge" )
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "lightning_strike_02.mp3" );
			}
			
			if( label == "gotHit" )
			{
				shellApi.triggerEvent( "crash_landing", true );
				CharUtils.getTimeline( player ).labelReached.remove(onAnimEnd);
				removeEntity( player );
				removeGroup( super.getGroupById( CharacterGroup.GROUP_ID ), true );
			}
			
			if( label == "ending" )
			{
				super.shellApi.completeEvent(completeEvent);
				shellApi.loadScene( Woods, 850, 443, "right" );
			}
		}
	}
}