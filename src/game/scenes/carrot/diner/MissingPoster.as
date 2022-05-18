package game.scenes.carrot.diner
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterGroup;
	import game.scenes.carrot.CarrotEvents;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	
	public class MissingPoster extends Popup
	{
		public function MissingPoster(container:DisplayObjectContainer=null)
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
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/carrot/diner/missingPopup/";
			super.init(container);
			super.autoOpen = false;
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["missing.swf", "npcs.xml"]);
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.screen = super.getAsset("missing.swf", true) as MovieClip;
			this.letterbox(this.screen.content, new Rectangle(0, 0, 608, 376), false);
			super.loadCloseButton();
			super.loaded();
			
			var events:CarrotEvents = shellApi.islandEvents as CarrotEvents;
			var found:MovieClip = this.screen.content.found;
			
			if(!super.shellApi.checkEvent(events.DESTROYED_RABBOT))
			{
				found.parent.removeChild(found);
			}
			
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup(this, super.screen, super.getData("npcs.xml"), allCharactersLoaded );
		}
		
		private function allCharactersLoaded():void
		{
			for(var i:uint = 1; i <= 4; i++)
			{
				var npc:Entity = super.getEntityById("missing" + i);
				var clip:MovieClip = MovieClip(super.screen.content).getChildByName("char" + i) as MovieClip;
				Display(npc.get(Display)).setContainer(clip);
				CharUtils.freeze(npc);
			}
			
			super.open();
		}
	}
}
