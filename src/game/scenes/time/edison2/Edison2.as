package game.scenes.time.edison2{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Platform;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Bubbles;
	import game.util.CharUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Edison2 extends PlatformerGameScene
	{
		public function Edison2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/edison2/";
			
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
			_events = super.events as TimeEvents;
			
			placeTimeDeviceButton();
			super.shellApi.eventTriggered.add(handleEventTriggered);
			createBubbles();
			
			if(shellApi.checkItemUsedUp(_events.PHONOGRAPH))
			{
				showPhonograph();
			}
			else
			{
				hidePhonograph();
			}
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + _events.PHONOGRAPH)
			{
				if(!super.shellApi.checkHasItem(_events.PHONOGRAPH) && !_returnedBool)
				{
					shellApi.triggerEvent(_events.ITEM_RETURNED_SOUND);
					showPhonograph();	
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
										
					getEntityById("edisonLight").remove(Platform);
					getEntityById("edisonTable").remove(Platform);
					
					var char1:Entity = super.getEntityById("char1");
					CharUtils.setAnim(char1, Score, false, 0, 0, true);
					RigAnimation( CharUtils.getRigAnim( char1) ).ended.add( onCelebrateEnd );
				}
			}
		}
		
		private function onCelebrateEnd( anim:Animation = null ):void
		{
			getEntityById("edisonLight").add(new Platform());
			getEntityById("edisonTable").add(new Platform());
		}
		
		private function showPhonograph():void
		{
			_returnedBool = true;
			var phonograph:MovieClip = this._hitContainer["phonograph"];
			var phonoTimline:Entity = TimelineUtils.convertClip(phonograph,this);
			Timeline(phonoTimline.get(Timeline)).gotoAndPlay("appear");
		}
		private function hidePhonograph():void
		{
			var phonograph:MovieClip = this._hitContainer["phonograph"];
			var phonoTimline:Entity = TimelineUtils.convertClip(phonograph,this);
			Timeline(phonoTimline.get(Timeline)).gotoAndStop("hidden");
		}
		
		private function createBubbles():void
		{
			for (var i:int = 1; i <= NUM_JARS; i++) 
			{
				var jar:MovieClip = this._hitContainer["dot" + i];
				var bubbles:Bubbles = new Bubbles();
				bubbles.init(new RectangleZone(jar.x, jar.y, jar.x + jar.width, jar.y + jar.height));
				EmitterCreator.create(this, _hitContainer, bubbles); 
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
		
		private static const NUM_JARS:Number = 5;
		private var _events:TimeEvents;
		private var _returnedBool:Boolean = false;
	}
}