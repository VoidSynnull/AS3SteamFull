package game.scenes.time.adDeadEnd
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.TransportGroup;
	
	import game.data.TimedEvent;
	import game.scenes.time.TimeEvents;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.util.SceneUtil;
	
	public class AdDeadEnd extends PlatformerGameScene
	{
		public function AdDeadEnd()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/adDeadEnd/";
			
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
			super.loaded();
			var _events:TimeEvents = super.events as TimeEvents;
			placeTimeDeviceButton();
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				Display( player.get( Display )).alpha = 0;
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player );
			}
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(events).TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton());
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		private var timeButton:Entity;
	}
}


