package game.scenes.ghd.neonWiener
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ToolTipCreator;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	
	public class Comics extends Popup
	{
		private var _backButton:Entity;
		private var _forwardButton:Entity;
		private var _currentPage:Number = 	0;
		private const MAX_PAGES:Number 	=	3;
		private const CHIME:String		=	"click_crab_01.mp3";
		
		public function Comics( container:DisplayObjectContainer = null )
		{
			super( container );
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
			super.loadFiles([ "comics.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "comics.swf", true ) as MovieClip;
			
			this.letterbox(this.screen.content, new Rectangle(0, 0, 960, 640));
			
			super.loaded();
			setupPages();
		}
		
		private function setupPages():void
		{
			var clip:MovieClip;
			var display:Display;
			var interaction:Interaction;
			var page:Entity;
			
			for( var number:uint = 0; number < MAX_PAGES; number ++ )
			{
				clip = super.screen.content.getChildByName( "p" + number );
				page = EntityUtils.createSpatialEntity( this, clip );
				page.add( new Id( "p" + number ));
				
				if( number > 0 )
				{
					display = page.get( Display );
					display.visible = false;
				}
			}
			
			// BACK AND FORTH BUTTONS
			clip = super.screen.content.getChildByName( "back" );
			_backButton = EntityUtils.createSpatialEntity( this, clip );
			InteractionCreator.addToEntity( _backButton, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( _backButton );
			display = _backButton.get( Display );
			display.visible = false;
			
			interaction = _backButton.get( Interaction );
			interaction.click.add( flipPageBack );
			
			clip = super.screen.content.getChildByName( "forward" );
			_forwardButton = EntityUtils.createSpatialEntity( this, clip );
			InteractionCreator.addToEntity( _forwardButton, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( _forwardButton );
			
			interaction = _forwardButton.get( Interaction );
			interaction.click.add( flipPageForward );
			
			super.open();
		}
		
		private function flipPageForward( button:Entity ):void
		{
			AudioUtils.play( parent, SoundManager.EFFECTS_PATH + CHIME );
			var display:Display;
			var currentPage:Entity;
			var nextPage:Entity;
			
			if( _currentPage + 1 < MAX_PAGES )
			{
				currentPage = getEntityById( "p" + _currentPage );
				_currentPage ++;
				nextPage = getEntityById( "p" + _currentPage );
				
				display = currentPage.get( Display );
				display.visible = false;
				
				display = nextPage.get( Display );
				display.visible = true;
				
				display = _backButton.get( Display );
				if( !display.visible )
				{
					display.visible = true;
				}
			}
			else
			{
				this.close();
			}
		}
		
		private function flipPageBack( button:Entity ):void
		{
			AudioUtils.play( parent, SoundManager.EFFECTS_PATH + CHIME );
			var display:Display;
			var currentPage:Entity;
			var nextPage:Entity;
			
			if( _currentPage - 1 > -1 )
			{
				currentPage = getEntityById( "p" + _currentPage );
				_currentPage --;
				nextPage = getEntityById( "p" + _currentPage );
				
				display = currentPage.get( Display );
				display.visible = false;
				
				display = nextPage.get( Display );
				display.visible = true;
				
				if( _currentPage == 0 )
				{
					display = _backButton.get( Display );
					display.visible = false;
				}
			}
		}
	}
}