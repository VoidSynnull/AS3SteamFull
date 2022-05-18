package game.scenes.time.france2{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Platform;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class France2 extends PlatformerGameScene
	{
		public function France2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/france2/";
			
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
			tEvents = super.events as TimeEvents;
			super.shellApi.eventTriggered.add(handleEventTriggered);
			placeTimeDeviceButton();
			setupFrenchTranslations();
			
			if(shellApi.checkItemUsedUp(tEvents.STATUETTE))
			{
				showStatue();
			}
			else
			{
				hideStatue();
			}
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + tEvents.STATUETTE)
			{
				if(!super.shellApi.checkHasItem(tEvents.STATUETTE) && !_returnedBool)
				{	
					shellApi.triggerEvent(tEvents.ITEM_RETURNED_SOUND);
					showStatue();					
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
										
					getEntityById("molding").remove(Platform);
					
					var char1:Entity = super.getEntityById("char1");
					CharUtils.setAnim(char1, Score, false, 0, 0, true);
					RigAnimation( CharUtils.getRigAnim( char1) ).ended.add( onCelebrateEnd );
				}
			}
		}
		
		private function onCelebrateEnd( anim:Animation = null ):void
		{
			getEntityById("molding").add(new Platform());
			CharUtils.setAnim(getEntityById("char1"), Stand);
			CharUtils.setAnim(getEntityById("char2"), Stand);
		}
		
		private function showStatue():void
		{
			_returnedBool = true;
			CharUtils.setAnim(getEntityById("char1"), Stand, false, 0, 0, true);
			CharUtils.setAnim(getEntityById("char2"), Stand, false, 0, 0, true);
			
			var clip:MovieClip = this._hitContainer["statue"];
			var clipTimeline:Entity = TimelineUtils.convertClip(clip,this);
			Timeline(clipTimeline.get(Timeline)).gotoAndPlay("appear");
		}
		private function hideStatue():void
		{
			var clip:MovieClip = this._hitContainer["statue"];
			var clipTimeline:Entity = TimelineUtils.convertClip(clip,this);
			Timeline(clipTimeline.get(Timeline)).gotoAndPlay("hidden");
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
		
		private var tEvents:TimeEvents;
		private static const NUM_SIGNS:Number = 2;
		private var _returnedBool:Boolean = false;
	}
}