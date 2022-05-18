package game.scenes.con1.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Sleep;
	import game.creators.ui.ToolTipCreator;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	
	public class Instructions extends Popup
	{
		private var _instructions:Array;
		private var currentPage:uint = 0;
		private const PAGE:String = "paper_flap_01.mp3";
		private const VOLUME_MODIFIER:int = 3;
		private var _scaleX:Number;
		private var _scaleY:Number;
		
		public function Instructions(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/con1/shared/";
			super.init( container );
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "instructions.swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "instructions.swf", true ) as MovieClip;
			
			this.loadCloseButton();
			super.loaded();
			
			_instructions = new Array();
			_instructions.push( "page1", "page2" );
			
			var asset:String;
			
			_scaleX = this.shellApi.viewportWidth / 960;
			_scaleY = this.shellApi.viewportHeight / 640;
			
			for each( asset in _instructions )
			{
				var clip:MovieClip = this.screen.getChildByName( asset );
				clip.x *= _scaleX;
				clip.y *= _scaleY;
				BitmapUtils.createBitmapSprite( clip );
			}
			
			addInteraction( _instructions[ currentPage ], pageFlip );
		}
		
		private function addInteraction( asset:String, handler:Function ):void
		{
			var clip:MovieClip = this.screen.getChildByName( asset );
			var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( asset )).add( new Sleep( false, false ));
			
			ToolTipCreator.addToEntity( entity ); 
			
			var interaction:Interaction = InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			interaction.click.addOnce( handler );
		}
		
		private function pageFlip( entity:Entity ):void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + PAGE, VOLUME_MODIFIER );
			ToolTipCreator.removeFromEntity( entity );
			
			var display:Display = entity.get( Display );
			display.visible = false;
			
			var interaction:Interaction;
			
			var sleep:Sleep = entity.get( Sleep );
			sleep.sleeping = true;
			
			if( currentPage < 1 )
			{
				currentPage++;
				
				addInteraction( _instructions[ currentPage ], pageFlip );
				entity = getEntityById( _instructions[ currentPage ]);
				interaction = entity.get( Interaction );
					
				interaction.click.addOnce( pageFlip );
			}
			
			else
			{
				this.close();
			}
		}
	}
}