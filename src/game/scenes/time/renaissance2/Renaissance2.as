package game.scenes.time.renaissance2{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.managers.SoundManager;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Platform;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	
	public class Renaissance2 extends PlatformerGameScene
	{
		private var tevents:TimeEvents;
		
		public function Renaissance2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/renaissance2/";

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
			tevents = super.events as TimeEvents;
			super.shellApi.eventTriggered.add(handleEventTriggered);
			super.loaded();
			placeTimeDeviceButton();			
			setupBubbleSound();
			var char:Entity = super.getEntityById("leo");
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( char );
		}
		
		private function setupBubbleSound():void
		{
			var audio:Audio = new Audio();			
			var soundEnt:Entity = EntityUtils.createSpatialEntity(this,_hitContainer["bubblingVial"]);
			soundEnt.add(audio);
			soundEnt.add(new AudioRange(1000, 0.05, 1, Sine.easeIn));
			audio.play(SoundManager.AMBIENT_PATH + "bubbling.mp3", true, [SoundModifier.POSITION]);
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + tevents.NOTEBOOK)
			{
				if(!shellApi.checkHasItem(tevents.NOTEBOOK) && !_returnedBool)
				{
					shellApi.triggerEvent(tevents.ITEM_RETURNED_SOUND);
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
					_returnedBool = true;
					var char:Entity = super.getEntityById("leo");			
					CharUtils.setAnim(char, Score, false, 0, 0, true);
					RigAnimation( CharUtils.getRigAnim( char) ).ended.add( onCelebrateEnd );
					
					getEntityById("rock").remove(Platform);
				}
			}
		}
		
		private function onCelebrateEnd( anim:Animation = null ):void
		{
			getEntityById("rock").add(new Platform());
			var char:Entity = super.getEntityById("leo");
			CharUtils.setAnim(char, Stand, false, 0, 0, true);
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
		private var _returnedBool:Boolean = false;
	}
}