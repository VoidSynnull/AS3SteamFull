package game.scenes.time.lab{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.TransportGroup;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Door;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Push;
	import game.managers.ads.AdManager;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.TimeEvents;
	import game.scenes.time.adStreet.AdStreet;
	import game.scenes.time.desolation.Desolation;
	import game.scenes.time.future.Future;
	import game.scenes.time.lab.components.PushComponent;
	import game.scenes.time.lab.system.PushSystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	import game.managers.interfaces.IAdManager;
	
	public class Lab extends PlatformerGameScene
	{
		public function Lab()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/lab/";
			//			super.showHits = true;
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
			tEvents = events as TimeEvents;
			placeTimeDeviceButton();
			super.shellApi.eventTriggered.add(handleEventTriggered);
			_transportGroup = super.addChildGroup( new TransportGroup() ) as TransportGroup;
			setupTimeMachine();
			setupPlugSlide();
			setupRedLight();
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == tEvents.TIMEMACHINE_POWERED)
			{
				machinePoweredUp = true;
				plugMotion.acceleration = new Point(0,0);
				plugMotion.velocity = new Point(0,0);
				var plugGlow:Entity = getEntityById("plugGlow");
				Timeline(plugGlow.get(Timeline)).gotoAndPlay("start");
				powerUpTimeMachine();
				shellApi.triggerEvent("timeMachine_beeps");
			}
			if(event == "pose")
			{
				var char:Entity = getEntityById("char1");
				CharUtils.setAnim(char,Proud);
			}
		}
		
		private function powerUpComment(...p):void
		{
			var char:Entity = getEntityById("char2");
			Dialog(char.get(Dialog)).sayById("need_power");			
		}
		
		private function setupTimeMachine():void
		{
			var machine:MovieClip = super._hitContainer["machineGlow"] as MovieClip;
			machineEnt = TimelineUtils.convertClip(machine,this);			
			var door:Entity = super.getEntityById("door2");
			// replace door interaction
			SceneInteraction(door.get(SceneInteraction)).reached.removeAll();
			SceneInteraction(door.get(SceneInteraction)).reached.add(doorReached);
			Timeline(machineEnt.get(Timeline)).gotoAndStop("start");				
		}
		
		private function powerUpTimeMachine():void
		{		
			var door:Entity = super.getEntityById("door2");
			Timeline(machineEnt.get(Timeline)).gotoAndPlay("activate");
		}
		
		private function doorReached(char:Entity, door:Entity):void
		{
			if(machinePoweredUp)
			{
				var adManager:IAdManager = shellApi.adManager;
				var noAd:Boolean = AdUtils.noAds(this);
				// activate correct door destination
				if(shellApi.checkEvent(tEvents.TIME_REPAIRED))
				{		
					_transportGroup.targetScene = Future;
				}
				else if (noAd)
				{
					_transportGroup.targetScene = Desolation;
				}
				else
				{
					_transportGroup.targetScene = AdStreet;
				}
				
				_transportGroup.transportOut(player);
				
				if(adManager && noAd)
				{
					adManager.doorReached(char, door);
				}
			}
			else
			{
				powerUpComment();
				// do nothing
			}
		}
		
		private function setupRedLight():void
		{
			var lightClip:MovieClip = super._hitContainer["redLight"] as MovieClip;	
			var lightTimeline:Entity = TimelineUtils.convertClip(lightClip,this);
			if(shellApi.checkEvent(tEvents.TIME_REPAIRED))
			{
				Timeline(lightTimeline.get(Timeline)).gotoAndStop("off");		
			}
			else
			{
				Timeline(lightTimeline.get(Timeline)).gotoAndPlay("on");		
			}
		}
		
		private function setupPlugSlide():void
		{
			addSystem(new PushSystem(),SystemPriorities.update);
			// animation
			plugClip = super._hitContainer["plugSlider"] as MovieClip;	
			slidingPlug = EntityUtils.createMovingEntity(this,plugClip);
			plugSpatial = slidingPlug.get(Spatial);
			plugMotion = slidingPlug.get(Motion);
			var plugGlow:Entity = TimelineUtils.convertClip(plugClip.getChildByName("plugGlow")as MovieClip,this);
			plugGlow.add(new Id("plugGlow"));
			Timeline(plugGlow.get(Timeline)).gotoAndStop("start");			
			// moving platform
			plugPlat = getEntityById("plugPlat");
			plugPlat.add(new FollowTarget(plugSpatial,1));
			// push zone
			var hitZone:Entity = super.getEntityById("zone1");
			hitZone.get(Zone).inside.add(startPush);
			hitZone.add(new FollowTarget(plugSpatial,1));
			// component
			var push:PushComponent = new PushComponent();
			push.startX = plugSpatial.x;
			push.endX = 1746;
			push.endReached.addOnce(finishPlug);
			push.pushZone = hitZone;
			slidingPlug.add(push);
		}
		
		//plug it in, plug it in
		private function finishPlug():void
		{
			CharacterMotionControl(player.get(CharacterMotionControl)).maxVelocityX = 800;
			CharUtils.getRigAnim(player).manualEnd = true;
			shellApi.triggerEvent(tEvents.TIMEMACHINE_POWERED);
			var hit:Entity = super.getEntityById("zone1");
			var zone:Zone = hit.get(Zone);
			zone.inside.removeAll();
			SceneUtil.lockInput(this,false,false);
		}
		
		private function startPush(zoneId:String, characterId:String ):void
		{
			// slow player
			CharacterMotionControl(player.get(CharacterMotionControl)).maxVelocityX = 100;
			Motion(player.get(Motion)).velocity.x = 100;
			CharUtils.setAnim(player,Push,false,100);
			var push:PushComponent = slidingPlug.get(PushComponent);
			push.pushing = true;
			SceneUtil.lockInput(this,true,true);
			//sound
			shellApi.triggerEvent("powerPlugDrag");
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
		
		private var machinePoweredUp:Boolean = false;
		private var plugClip:MovieClip;
		private var slidingPlug:Entity;
		private var plugPlat:Entity;
		private var plugMotion:Motion;
		private var plugSpatial:Spatial;
		
		public var tEvents:TimeEvents;
		private var _transportGroup:TransportGroup;
		private var machineEnt:Entity;
	}
}