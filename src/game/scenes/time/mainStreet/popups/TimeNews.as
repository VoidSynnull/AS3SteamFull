package game.scenes.time.mainStreet.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterGroup;
	import game.ui.popup.Popup;
	import game.util.CharUtils;

	
	public class TimeNews extends Popup
	{
		public function TimeNews(container:DisplayObjectContainer=null)
		{
			super(container);
		}
	
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/time/mainStreet/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["timeNews.swf","npcs.xml"]);
		}
		
		// all assets ready
		override public function loaded():void
		{				
			super.screen = super.getAsset("timeNews.swf", true) as MovieClip;
			
			this.layout.centerUI(this.screen.content);
			
			setupNpc();
			super.loadCloseButton();
			super.loaded();		
		}
		
		public function setupNpc():void
		{
			//load head and start npc talking, opens puzzle after he's done
			// load the characters into the the groupContainer.
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup(this, super.screen.content.headMount, super.getData("npcs.xml"), allCharactersLoaded );
		}
		
		protected function allCharactersLoaded():void
		{
			CharUtils.freeze(this.getEntityById("doc"));
			super.open();
		}
		
		override public function close(removeOnClose:Boolean=true, onCloseHandler:Function=null):void
		{
			shellApi.triggerEvent("closePaper");
			super.close(removeOnClose,onCloseHandler);
		}
	}
}