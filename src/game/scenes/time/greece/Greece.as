package game.scenes.time.greece{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.group.TransportGroup;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Score;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class Greece extends PlatformerGameScene
	{
		public var _events:TimeEvents;	
		private var vase:Entity;
		private var timeButton:Entity;
		private var itemReturned:Boolean = false;

		public function Greece()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			this.groupPrefix = "scenes/time/greece/";
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
			_events = this.events as TimeEvents;			
			setupGreekTranslations();			
			setupHiddenVase();
			placeTimeDeviceButton();
			this.shellApi.eventTriggered.add(eventTriggers);
			
			if( this.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = this.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + _events.GOLDEN_VASE)
			{
				if( !itemReturned && !shellApi.checkHasItem(_events.GOLDEN_VASE))
				{
					vaseAppear();
					shellApi.triggerEvent(_events.ITEM_RETURNED_SOUND);
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
										
					var char1:Entity = this.getEntityById("char1");
					var char2:Entity = this.getEntityById("char2");	
					CharUtils.setAnim(char1, Score, false, 0, 0, true);
					CharUtils.setAnim(char2, Score, false, 0, 0, true);
				}
			}
		}
		
		private function setupGreekTranslations():void
		{ 
			var textcount:uint = 4;
			for(var i:uint=1; i<=textcount; i++)
			{
				var text:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["sign" + i]);
				BitmapTimelineCreator.convertToBitmapTimeline(text);
				
				var interaction:Interaction = InteractionCreator.addToEntity(text,[InteractionCreator.CLICK],this._hitContainer["sign"+i]);
				interaction.click.add(toggleTextTrans);
				ToolTipCreator.addUIRollover(text,ToolTipType.CLICK);
			}
		}
		
		private function toggleTextTrans(text:Entity):void
		{
			var txt:Timeline = (text.get(Timeline)as Timeline);
			if(txt.currentIndex == 0)
			{
				(text.get(Timeline)as Timeline).gotoAndStop("english");
			}
			else
			{
				(text.get(Timeline)as Timeline).gotoAndStop("greek");
			}		
		}
		
		private function setupHiddenVase():void
		{
			if(shellApi.checkItemUsedUp(_events.GOLDEN_VASE))	
			{
				vaseVisible();
			}
			else
			{
				hideVase();
			}
		}
		
		private function hideVase():void
		{
			vase = TimelineUtils.convertClip(this._hitContainer["vase"],this);
			(vase.get(Timeline)as Timeline).gotoAndStop("hidden");
		}
		
		private function vaseVisible():void
		{
			itemReturned = true;
			vase = TimelineUtils.convertClip(this._hitContainer["vase"],this);
			(vase.get(Timeline)as Timeline).gotoAndStop("visible");
		}
		
		private function vaseAppear():void
		{
			itemReturned = true;
			vase = TimelineUtils.convertClip(this._hitContainer["vase"],this);
			(vase.get(Timeline)as Timeline).gotoAndPlay("appear");
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(_events.TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
	}
}











