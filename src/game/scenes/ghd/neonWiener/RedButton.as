package game.scenes.ghd.neonWiener
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class RedButton extends Popup
	{		
		private const CHIME:String		=	"click_crab_01.mp3";
		
		public function RedButton(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.darkenBackground = true;
			super.autoOpen = false;
			super.groupPrefix = "scenes/ghd/neonWiener/";
			super.init( container );
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "red_button.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "red_button.swf", true ) as MovieClip;
			this.layout.fitUI( super.screen );
			
			super.loaded();
			createButton();
		}
		
		private function createButton():void
		{
			var clip:MovieClip;
			var display:Display;
			var interaction:Interaction;
			var button:Entity;
			
			clip = super.screen.content.getChildByName( "red_button" );
			button = EntityUtils.createSpatialEntity( this, clip );
			TimelineUtils.convertClip( clip, this, button );
			button.add( new Id( "red_button" ));
			
			InteractionCreator.addToEntity( button, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( button );
			
			interaction = button.get( Interaction );
			interaction.click.add( runAnimation );
			
			super.open();
		}
		
		private function runAnimation( button:Entity ):void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + CHIME );
			var timeline:Timeline = button.get( Timeline );
			timeline.gotoAndPlay( 1 );
			timeline.handleLabel( "end", this.close );
		}
	}
}