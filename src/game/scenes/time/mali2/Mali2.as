package game.scenes.time.mali2{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	
	
	public class Mali2 extends PlatformerGameScene
	{
		public var tEvents:TimeEvents;
		
		public function Mali2()
		{
			super();
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/mali2/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			tEvents = shellApi.islandEvents as TimeEvents;
			super.shellApi.eventTriggered.add( handleEventTriggered );
			super.loaded();
			placeTimeDeviceButton();
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == tEvents.MALIDOCS_OPENPUZZLE)
			{
				showPuzzle();
			}
		}
		
		private function showPuzzle():void
		{
			var popup:MaliDocs = super.addChildGroup( new MaliDocs( super.overlayContainer )) as MaliDocs;
			popup.id = "maliDocs";
			
			popup.complete.addOnce( Command.create( handleClosePuzzle, popup ));
		}
		
		private function handleClosePuzzle( popup:MaliDocs ):void
		{
			popup.close();
			// npc says things, gives decalration to player
			var char:Entity = super.getEntityById("char1");
			if(shellApi.checkEvent( GameEvent.GOT_ITEM+tEvents.DECLARATION ))
			{
				(char.get(Dialog) as Dialog).sayById("docTalk6");
			}
			else
			{
				(char.get(Dialog) as Dialog).sayById("docTalk7");
			}
		}

		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(events).TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		
		private var timeButton:Entity;
	}
}