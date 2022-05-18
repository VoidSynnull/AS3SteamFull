package game.scenes.time.everest2{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.MotionBounds;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.particles.emitter.Snow;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.util.CharUtils;
	import game.util.PerformanceUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.counters.Random;
	
	public class Everest2 extends PlatformerGameScene
	{
		public function Everest2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/everest2/";
			
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
			
			if(super.shellApi.checkItemUsedUp(_events.GOGGLES))
			{
				var char1:Entity = getEntityById("char1");
				var char2:Entity = getEntityById("char2");
				
				removeEntity(char1);
				removeEntity(char2);
				_returnedBool = true;
			}
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH)
				createSnowEmitter();
			
			var fallDoor:Entity = super.getEntityById("door3");
			Sleep(fallDoor.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(fallDoor.get(Sleep)).sleeping = false;
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + _events.GOGGLES)
			{
				if(!super.shellApi.checkHasItem(_events.GOGGLES) && !_returnedBool)
				{
					shellApi.triggerEvent(_events.ITEM_RETURNED_SOUND);
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
					_returnedBool = true;
					moveNPCs();
				}
			}
		}
		
		private function moveNPCs():void
		{
			var char1:Entity = getEntityById("char1");
			var char2:Entity = getEntityById("char2");
			
			// add googles to char1
			SkinUtils.setSkinPart(char1, SkinUtils.FACIAL, "hillary");
			
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( char1 );
			charGroup.addFSM( char2 );
			
			CharacterMotionControl(char1.get(CharacterMotionControl)).maxVelocityX = 250;
			MotionBounds(char1.get(MotionBounds)).box.top = -300;
			CharacterMotionControl(char2.get(CharacterMotionControl)).maxVelocityX = 250;
			MotionBounds(char2.get(MotionBounds)).box.top = -300;
			
			// remove interactions from the characters
			SceneInteraction(char1.get(SceneInteraction)).reached.removeAll();
			SceneInteraction(char2.get(SceneInteraction)).reached.removeAll();
			
			var totalNavPoints:uint = 6;
			var path:Vector.<Point> = new Vector.<Point>();
			var navClip:MovieClip;
			
			for(var i:uint = 1; i <= totalNavPoints; i++)
			{
				navClip = this._hitContainer["nav" + i];
				path.push(new Point(navClip.x, navClip.y));
			}
			
			
			CharUtils.followPath(char1, path, finishedPath);
			CharUtils.followPath(char2, path, finishedPath);
		}
		
		private function finishedPath(entity:Entity):void
		{
			removeEntity(entity);
		}
		
		private function createSnowEmitter():void
		{			
			var snow:Snow = new Snow();
			snow.init(new Random(20, 25), new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight));
			EmitterCreator.createSceneWide(this, snow);
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
		private var _events:TimeEvents;
	}
}