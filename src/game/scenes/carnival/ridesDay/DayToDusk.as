package game.scenes.carnival.ridesDay
{
	{
		import flash.display.DisplayObjectContainer;
		import flash.display.MovieClip;
		
		import ash.core.Entity;
		
		import engine.components.Id;
		
		import game.components.timeline.Timeline;
		import game.scenes.carnival.CarnivalEvents;
		import game.scenes.carnival.midwayEvening.MidwayEvening;
		import game.ui.popup.Popup;
		import game.util.TimelineUtils;
		
		public class DayToDusk extends Popup
		{
			private var carnivalEvents:CarnivalEvents;
			private var content:MovieClip;
			private var cutScene:Entity;
			
			public function DayToDusk(container:DisplayObjectContainer=null)
			{
				super(container);
			}
			
			override public function init(container:DisplayObjectContainer = null):void
			{
				super.groupPrefix = "scenes/carnival/ridesDay/";
				super.screenAsset = "dayToDusk.swf";
				
				super.darkenBackground = true;
				super.init(container);
				load();
			}
			
			override public function loaded():void
			{
				super.loaded();
				content = screen.content as MovieClip;
				setUp();
			}
			
			private function setUp():void
			{
				super.shellApi.setFPS(31);
				var clip:MovieClip = content["cutScene"];
				cutScene = new Entity();
				cutScene = TimelineUtils.convertClip(clip, this, cutScene);
				
				super.addEntity(cutScene);
				cutScene.get(Timeline).gotoAndPlay(1);
				cutScene.get(Timeline).handleLabel("end", moveToNextScene);
			}
			
			private function moveToNextScene():void {
				//super.handleCloseClicked();
				super.shellApi.setFPS(60);
				super.shellApi.removeEvent(carnivalEvents.SET_DAY);
				super.shellApi.removeEvent(carnivalEvents.SET_NIGHT);
				super.shellApi.removeEvent(carnivalEvents.SET_MORNING);
				super.shellApi.completeEvent(carnivalEvents.SET_EVENING);
				super.shellApi.loadScene(MidwayEvening, 50, 1950);
			}
			
			override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
			{
				super.close();
				//super.handleCloseClicked();
			}
		}
	}
}

