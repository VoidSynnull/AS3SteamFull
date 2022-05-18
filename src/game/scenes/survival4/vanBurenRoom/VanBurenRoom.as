package game.scenes.survival4.vanBurenRoom
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.SleepingSitUp;
	import game.data.animation.entity.character.Sword;
	import game.data.animation.entity.character.Tremble;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.particles.emitter.PoofBlast;
	import game.scene.template.ItemGroup;
	import game.components.hit.HitTest;
	import game.systems.hit.HitTestSystem;
	import game.scenes.survival4.Survival4Events;
	import game.scenes.survival4.shared.Survival4Scene;
	import game.systems.entity.character.states.CharacterState;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class VanBurenRoom extends Survival4Scene
	{
		public function VanBurenRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival4/vanBurenRoom/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var survival:Survival4Events;
		
		private const CAMERA_RIGHT:Number = 2900;
		private const SLEEP:String = "sleeping_01_loop.mp3";
		private const ALERT:String = "caught.mp3";
		private const OPEN_DOOR:String = "compartment_open_01.mp3";
		private const HOOK_KEY:String = "key_jingle_01.mp3";
		
		private var vanBuren:Entity;
		private var key:Entity;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			survival = events as Survival4Events;
			shellApi.eventTriggered.add(onEventTriggered);
			
			setUpAlerts();
			setUpVanBurensDoor();
			setUpVanBuren();
			setUpKey();
			setUpSoftHits();
		}
		
		private function setUpSoftHits():void
		{
			var softHits:Entity = getEntityById("softPlatform");
			softHits.add(new HitTest(puff));
		}
		
		private function puff(entity:Entity, hitId:String):void
		{
			var hit:Entity = getEntityById(hitId);
			var spatial:Spatial = hit.get(Spatial);
			var poof:PoofBlast = new PoofBlast();
			poof.init(10, 5, 0xA49B94);
			EmitterCreator.create(this, _hitContainer, poof, spatial.x, spatial.y + spatial.height / 2);
			trace("poof");
		}
		
		private function setUpKey():void
		{
			var clip:MovieClip = _hitContainer["key"];
			var frontClip:MovieClip = _hitContainer["frontChain"];
			if(shellApi.checkHasItem(survival.ARMORY_KEY))
			{
				_hitContainer.removeChild(clip);
				_hitContainer.removeChild(frontClip);
				_hitContainer.removeChild(_hitContainer["keyClick"]);
			}
			else
			{
				key = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				DisplayUtils.moveToTop(frontClip);
				var front:Entity = EntityUtils.createSpatialEntity(this, frontClip, _hitContainer);
				var follow:FollowTarget = new FollowTarget(key.get(Spatial));
				follow.offset = new Point(0, -45);
				front.add(follow).add(new Id("keyFront"));
				
				clip = _hitContainer["keyClick"];
				var click:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				click.add(new Id(clip.name));
				var interaction:Interaction = InteractionCreator.addToEntity(click, ["click"], clip);
				interaction.click.add(cantReach);
				ToolTipCreator.addToEntity(click);
				Display(click.get(Display)).alpha = 0;
			}
		}
		
		private function cantReach(key:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("cant_reach");
		}
		
		private function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == survival.USE_SPEAR)
			{
				if(key != null)
				{
					if(closeToEntity(key))
						useSpear();
					else
						Dialog(player.get(Dialog)).sayById("no_use");
				}
				else
					Dialog(player.get(Dialog)).sayById("no_use");
			}
			else if(event == _events.USE_FULL_PITCHER || event == _events.USE_ARMORY_KEY || event == _events.USE_EMPTY_PITCHER || event == _events.USE_TAINTED_MEAT || event == _events.USE_TROPHY_ROOM_KEY )
			{
				player.get(Dialog).sayById("no_use");
			}
		}
		
		private var distanceCheck:Number = 300;
		private function closeToEntity(entity:Entity):Boolean
		{
			var entitySpatial:Spatial = entity.get(Spatial);
			var playerSpatial:Spatial = player.get(Spatial);
			var entityPos:Point = new Point(entitySpatial.x, entitySpatial.y);
			var playerPos:Point = new Point(playerSpatial.x, playerSpatial.y);
			if(Point.distance(entityPos, playerPos) < distanceCheck)
				return true;
			return false;
		}
		
		private function useSpear():void
		{
			SceneUtil.lockInput(this);
			var destination:Destination = CharUtils.moveToTarget(player, 2400, 550, true, reachForKey, new Point(25, 50));
			destination.validCharStates = new Vector.<String>();
			destination.validCharStates.push(CharacterState.STAND);
		}
		
		private function reachForKey(...args):void
		{
			AudioUtils.play(this,SoundManager.EFFECTS_PATH+HOOK_KEY);
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "survival_4_spear",false);
			CharUtils.setAnim(player, Sword);
			CharUtils.setDirection(player, true);
			Timeline(player.get(Timeline)).handleLabel("hold", holdStill);
		}
		
		private function holdStill():void
		{
			var time:Timeline = player.get(Timeline);
			time.gotoAndStop(time.currentIndex);
			
			var spatial:Spatial = player.get(Spatial);
			
			TweenUtils.entityTo(key, Spatial, 2, {x:spatial.x + 50, y:spatial.y + 25, ease:Linear.easeNone, onComplete:getKey});
		}
		
		private function getKey():void
		{
			var itemGroup:ItemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			itemGroup.showAndGetItem(survival.ARMORY_KEY, null, returnControls);
			removeEntity(key);
			key = null;
			removeEntity(getEntityById("keyFront"));
			removeEntity(getEntityById("keyClick"));
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM, false);
		}
		
		private function returnControls(...args):void
		{
			SceneUtil.lockInput(this, false);
			FSMControl(player.get(FSMControl)).active = true;
		}
		
		private function setUpVanBuren():void
		{
			vanBuren = getEntityById("van buren");
			vanBuren.add(new Audio()).add( new AudioRange(2000, 0, 1, Quad.easeIn)).remove(Sleep);
			Audio(vanBuren.get(Audio)).play(SoundManager.EFFECTS_PATH+SLEEP,true, SoundModifier.POSITION);
		}
		
		private function setUpVanBurensDoor():void
		{
			var clip:MovieClip = _hitContainer["roomDoor"];
			var door:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			door.add(new Id(clip.name));
			TimelineUtils.convertClip(clip, this, door, null, false);
			var time:Timeline = door.get(Timeline);
			
			var openDoorClip:MovieClip = _hitContainer["openDoor"];
			
			if(shellApi.checkEvent(survival.OPENED_VAN_BURENS_DOOR))
			{
				removeEntity(getEntityById("doorWall"));
				_hitContainer.removeChild(openDoorClip);
				time.gotoAndStop("opened");
			}
			else
			{
				time.handleLabel("opened", Command.create(openedDoor, time));
				var camera:Camera = shellApi.camera.camera;
				camera.resize(camera.viewport.width, camera.viewport.height, shellApi.viewportWidth, camera.area.height);
				
				door = EntityUtils.createSpatialEntity(this, openDoorClip, _hitContainer);	
				door.add(new Id(openDoorClip.name));
				Display(door.get(Display)).alpha = 0;
				var interaction:Interaction = InteractionCreator.addToEntity(door, ["click"], openDoorClip);
				interaction.click.add(openDoor);
				ToolTipCreator.addToEntity(door, ToolTipType.EXIT_RIGHT);
			}
		}
		
		private function openDoor(door:Entity):void
		{
			Timeline(getEntityById("roomDoor").get(Timeline)).play();
			AudioUtils.play(this,SoundManager.EFFECTS_PATH+OPEN_DOOR);
		}
		
		private function openedDoor(timeline:Timeline):void
		{
			timeline.gotoAndStop(timeline.currentIndex);
			shellApi.completeEvent(survival.OPENED_VAN_BURENS_DOOR);
			removeEntity(getEntityById("doorWall"));
			removeEntity(getEntityById("openDoor"));
			var camera:Camera = shellApi.camera.camera;
			camera.resize(camera.viewport.width, camera.viewport.height, CAMERA_RIGHT, camera.area.height);
		}
		
		private function setUpAlerts():void
		{
			addSystem(new HitTestSystem());
			getEntityById("hardFloor1Alert").add(new HitTest(alert, true));
			getEntityById("hardFloor2Alert").add(new HitTest(alert, true));
		}
		
		private function alert(...args):void
		{
			SceneUtil.setCameraTarget(this, vanBuren,false,.1);
			SceneUtil.lockInput(this);
			SceneUtil.addTimedEvent(this, new TimedEvent(.5,1, wakeUpVanBuren));
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1, alertSounded));
		}
		
		private function wakeUpVanBuren():void
		{
			Audio(vanBuren.get(Audio)).stop(SoundManager.EFFECTS_PATH+SLEEP,"effects");
			AudioUtils.play(this,SoundManager.MUSIC_PATH+ALERT);
			CharUtils.setAnim(vanBuren, SleepingSitUp);
		}
		
		override public function alertSounded():void
		{
			if(shellApi.checkHasItem(survival.ARMORY_KEY))
			{
				shellApi.removeItem(survival.ARMORY_KEY);
				var itemGroup:ItemGroup = getGroupById("itemGroup") as ItemGroup;
				itemGroup.takeItem(survival.ARMORY_KEY, "van buren");
			}
			SceneUtil.setCameraTarget(this, player);
			CharUtils.setAnim(player, Tremble);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, popup));
		}
		
		private function popup():void
		{
			SceneUtil.lockInput(this, false);
			var popup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			popup.configData("mvbPopup.swf", "scenes/survival4/shared/mvbPopup/");
			popup.updateText("You woke up Myron Van Buren! Try to avoid making noise.", "Try Again");
			popup.removed.add(retry);
			addChildGroup(popup);
		}
		
		private function retry(...args):void
		{
			shellApi.loadScene( VanBurenRoom);
		}
	}
}