package game.scenes.examples.characterPopup
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterGroup;
	import game.ui.popup.Popup;
	
	public class CharacterPopupScreen extends Popup
	{
		private var _player2:Entity;
		
		public function CharacterPopupScreen(container:DisplayObjectContainer=null)
		{
			super(container);
		}
				
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.config( null, null, true );
			
			super.groupPrefix = "scenes/examples/characterPopup/popup/";
			super.screenAsset = "characterPopupScreen.swf";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.loadFiles([this.screenAsset, "npcs.xml"], false, true, this.loaded );
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.preparePopup();

			// this loads the standard close button
			super.loadCloseButton();
			
			// this centers the movieclip 'content' within examplePopup.swf.  For wide layouts this will center horizontally, for tall layouts vertically.
			super.layout.centerUI(super.screen.content);

			// add CharacterGroup to create the npcs 
			var charGroup:CharacterGroup = new CharacterGroup();
			charGroup.setupGroup( this, super.screen, super.getData("npcs.xml"), allCharactersLoaded );
			
			// create an additional npc that uses the player's look
			_player2 = charGroup.createNpcPlayer( null, null, new Point( MovieClip(super.screen).width/2, MovieClip(super.screen).height/2) );
		}

		private function allCharactersLoaded():void
		{
			// once characters are complete we signal that teh popup is ready
			super.groupReady();
		}
	}
}