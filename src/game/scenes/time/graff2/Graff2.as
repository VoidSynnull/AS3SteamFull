package game.scenes.time.graff2{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.managers.SoundManager;
	
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.scenes.time.TimeEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Flies;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	public class Graff2 extends PlatformerGameScene
	{
		private var tEvents:TimeEvents;
		
		public function Graff2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/graff2/";
			
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
			
			if(super.shellApi.checkItemUsedUp(tEvents.DECLARATION))
			{
				equipDeclaration();
				hideNpc();
			}
			setUpFlies();
			placeTimeDeviceButton();
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == tEvents.RETURNED + tEvents.DECLARATION && !_returnedBool)
			{
				equipDeclaration();
				shellApi.triggerEvent(tEvents.ITEM_RETURNED_SOUND);
				if(timeButton){
					timeButton.get(TimeDeviceButton).flashButton();
				}
				moveNpc();
			}
		}
		
		// add flies as particls
		private function setUpFlies():void
		{
			var fly:Flies = new Flies();
			var fliesEnt:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["fliesLoc"]);		
			fly.init(new Point(1381,635));
			EmitterCreator.create(this,this._hitContainer,fly,0,0,fliesEnt);			
			// make fly noise
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "insect_flies_01_L.mp3", true, SoundModifier.POSITION);			
			fliesEnt.add(audio);
			fliesEnt.add(new AudioRange(600, 0.01, 1, Quad.easeIn));
		}
		
		private function equipDeclaration():void
		{
			_returnedBool = true;
			var char:Entity = super.getEntityById("char1");			
			SkinUtils.setSkinPart(char, SkinUtils.ITEM, "scroll" );
		}
		
		private function moveNpc():void
		{
			var char:Entity = super.getEntityById("char1");
			
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( char );
			
			// remove interactions from the characters
			SceneInteraction(char.get(SceneInteraction)).reached.removeAll();
			//CharacterMotionControl(char.get(CharacterMotionControl)).maxVelocityX = 200;
			var totalNavPoints:uint = 4;
			var path:Vector.<Point> = new Vector.<Point>();
			var navClip:MovieClip;
			
			for(var i:uint = 1; i <= totalNavPoints; i++)
			{
				navClip = this._hitContainer["nav" + i];
				path.push(new Point(navClip.x, navClip.y));
			}
			CharUtils.followPath(char, path, finishedPath);
		}
		
		private function finishedPath(entity:Entity):void
		{
			hideNpc();
		}
		
		private function hideNpc():void
		{
			var char:Entity = super.getEntityById("char1");
			removeEntity(char);
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