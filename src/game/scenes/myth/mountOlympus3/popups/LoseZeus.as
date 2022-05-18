package game.scenes.myth.mountOlympus3.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scenes.myth.mountOlympus2.MountOlympus2;
	import game.scenes.myth.mountOlympus3.MountOlympus3;
	import game.ui.popup.Popup;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	
	public class LoseZeus extends Popup
	{
		public function LoseZeus( container:DisplayObjectContainer=null )
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/mountOlympus3/";
			super.init( container );
			super.autoOpen = false;
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "loseZeus.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "loseZeus.swf", true ) as MovieClip;
			DisplayUtils.convertToBitmapSprite( super.screen, null, 2 );
			
			super.layout.centerUI( super.screen.content );
			
			MovieClip( MovieClip( super.screen.content ).getChildByName( "bg" )).width = super.shellApi.viewportWidth;
			MovieClip( MovieClip( super.screen.content ).getChildByName( "bg" )).height = super.shellApi.viewportHeight;
			
			super.loaded();
			super.open();
			
			MovieClip( super.screen.content ).alpha = 0;
			
			setButtons( "tryAgain" );
			setButtons( "giveUp" );
		
			SceneUtil.addTimedEvent( this, new TimedEvent( DELAY, 1, easeOutOfAlpha ));
		}
		
		private function easeOutOfAlpha():void
		{
			var clip:MovieClip = MovieClip( super.screen.content );
			
			clip.alpha += .1;
			if( MovieClip( super.screen.content ).alpha < 1 )
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( DELAY, 1, easeOutOfAlpha ));
			}
		}
		
		private function setButtons( name:String ):void
		{
			var clip:MovieClip;
			var entity:Entity;
			var timeline:Timeline;
			var interaction:Interaction;
			
			clip = MovieClip( MovieClip( super.screen.content ).getChildByName( name ));
			entity = ButtonCreator.createButtonEntity( clip, this );
			entity.add( new Id( name ));
			
			interaction = entity.get( Interaction );
			interaction.over.add( Command.create( setState, OVER ));
			interaction.up.add( Command.create( setState, UP ));
			interaction.down.add( Command.create( setState, DOWN ));
			interaction.out.add( Command.create( setState, UP ));
			interaction.click.add( Command.create( setState, GO ));
			
			timeline = entity.get( Timeline );
			timeline.gotoAndStop( 0 );
		}
		
		private function setState( entity:Entity, state:String ):void
		{
			if( state != GO )
			{
				var timeline:Timeline = entity.get( Timeline );
				timeline.gotoAndStop( state );
			}
			else
			{
				if( entity.get( Id ).id == "tryAgain" )
				{
					super.shellApi.loadScene( MountOlympus3, 870, 1147 );
				}
				else
				{
					super.shellApi.loadScene( MountOlympus2, 258, 1165 );
				}
			}
		}
		
		private const DELAY:Number = .1;
		
		private const GO:String = "go";
		private const OVER:String = "_over";
		private const UP:String = "_up";
		private const DOWN:String = "_down";
	}
}