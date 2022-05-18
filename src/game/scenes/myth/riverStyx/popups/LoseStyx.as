package game.scenes.myth.riverStyx.popups
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
	import game.particles.FlameCreator;
	import game.scenes.myth.hadesPit2.HadesPit2;
	import game.scenes.myth.riverStyx.RiverStyx;
	import game.ui.popup.Popup;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	
	public class LoseStyx extends Popup
	{
		public function LoseStyx( container:DisplayObjectContainer=null )
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
			super.groupPrefix = "scenes/myth/riverStyx/";
			super.init( container );
			super.autoOpen = false;
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "loseStyx.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "loseStyx.swf", true ) as MovieClip;
			DisplayUtils.convertToBitmapSprite( super.screen, null, 2 );
			
			super.layout.centerUI( super.screen.content );
			
			var clip:MovieClip = super.screen.content.getChildByName( "bg" );
			clip.width = super.shellApi.viewportWidth;
			clip.height = super.shellApi.viewportHeight;

			super.loaded();
			super.open();
			
			MovieClip( super.screen.content ).alpha = 0;

			setButtons( "tryAgain" );
			setButtons( "giveUp" );
			super.shellApi.triggerEvent( "styx_loss" );
			
			setupTorches();
			
			SceneUtil.addTimedEvent( this, new TimedEvent( DELAY, 1, easeOutOfAlpha ));
		}
		
		private function easeOutOfAlpha():void
		{
			var clip:MovieClip = super.screen.content;
			
			clip.alpha += .1;
			if( clip.alpha < 1 )
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
			
			clip = super.screen.content.getChildByName( name );
			
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
					parent.shellApi.loadScene( RiverStyx, 80, 380, "right" );
				}
				else
				{
					parent.shellApi.loadScene( HadesPit2, 258, 1378 );
				}
			}
		}
		
		private function setupTorches():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, super.screen.content.getChildByName( "flame" ), null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var asset:MovieClip = super.screen.content.getChildByName( "flame" );
			var clip:MovieClip;
			var i:uint = 1;
			
			_flameCreator.createFlame( this, asset, true );
		}
		
		
		private const DELAY:Number = .1;
		
		private const GO:String = "go";
		private const OVER:String = "_over";
		private const UP:String = "_up";
		private const DOWN:String = "_down";
		private var _flameCreator:FlameCreator;
	}
}