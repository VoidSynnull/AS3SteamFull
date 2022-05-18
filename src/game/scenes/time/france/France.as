package game.scenes.time.france{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.group.TransportGroup;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.time.TimeEvents;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class France extends PlatformerGameScene
	{
		public function France()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/france/";
			
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
			placeTimeDeviceButton();
			setupFrenchTranslations();
			_events = TimeEvents(events);

			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function setupFrenchTranslations():void
		{
			for (var i:int = 1; i <= NUM_SIGNS; i++) 
			{
				var sign:Entity = EntityUtils.createSpatialEntity(this, super._hitContainer["sign" + i]);
				BitmapTimelineCreator.convertToBitmapTimeline(sign);
				sign.get(Timeline).gotoAndStop("french");
				var interaction:Interaction = InteractionCreator.addToEntity(sign, [InteractionCreator.CLICK], super._hitContainer["sign" + i]);
				interaction.click.add(toggleSignTrans);
				ToolTipCreator.addUIRollover(sign,ToolTipType.CLICK);
			}			
		}
		
		private function toggleSignTrans(sign:Entity):void
		{
			var timeline:Timeline = sign.get(Timeline);
			
			if(timeline.currentIndex == 0)
				timeline.gotoAndStop("english");
			else
				timeline.gotoAndStop("french");
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
		private var _events:TimeEvents;
		private static const NUM_SIGNS:Number = 2;
	}
}