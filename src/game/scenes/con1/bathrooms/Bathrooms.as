package game.scenes.con1.bathrooms
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.transitions.Tween;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Soar;
	import game.data.animation.entity.character.Stand;
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.ToolTipType;
	import game.scene.template.ItemGroup;
	import game.scenes.con1.shared.Poptropicon1Scene;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	public class Bathrooms extends Poptropicon1Scene
	{
		public function Bathrooms()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con1/bathrooms/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var npcsInLine:Array = ["spFan", "sfFan", "shFan", "viking1", "viking2", "friend"];
		//private var costumeChecks:Array = [null, gotMask, wearingPendant, null, null, dressedLikeWizard];
		
		private var npcStartDialog:Array = ["move", "trade", "cut", "time", "thor"];
		
		private var npcCompleteDialog:Array = ["to the sky", "zazzleblax", "powerful", "noon", "bucky lucas"];
		
		private var currentLinePosition:int = -1;
		
		private var lastEntityInLine:Entity;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			addSystem(new ThresholdSystem());
			addSystem(new WaveMotionSystem());
			
			setUpNpcs();
			setUpBathroom();
		}
		
		override public function handleEventTrigger(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event.indexOf(_events.PASSED) != -1)
			{
				var npcName:String = event.slice(0,event.length-_events.PASSED.length);
				
				if(npcsInLine.indexOf(npcName) > currentLinePosition)
				{
					returnControls();
					return;
				}
				
				var npc:Entity = getEntityById(npcName);
				passNpcInLine(npcName);
				
				if(npcName == "friend")
					exitNPC(npc);
				else
				{
					if(npcName == "spFan")
					{
						SkinUtils.setSkinPart(npc, SkinUtils.FACIAL, "poptropicon_steam01");
						SkinUtils.setSkinPart(npc, SkinUtils.PACK, "poptropicon_jetpack");
						SkinUtils.setSkinPart(npc, SkinUtils.OVERSHIRT, "poptropicon_steam01");
						SkinUtils.setSkinPart(npc, SkinUtils.OVERPANTS, "poptropicon_steam01");
						Dialog(npc.get(Dialog)).complete.addOnce(Command.create(flyOffAfterDialog, npc));
					}
					else
						stepAsside(npc);
				}
			}
			
			if(event.indexOf(_events.QUEST_ACCEPTED))
			{
				npcName = event.slice(0,event.length-_events.QUEST_ACCEPTED.length);
				if(npcName == "spFan")
				{
					shellApi.getItem(_events.JETPACK_INSTRUCTIONS,null,true);
				}
			}
			
			if(event.indexOf(_events.GIVE) != -1)
			{
				var itemId:String = event.slice(_events.GIVE.length);
				if(itemId == _events.FREMULON_MASK)
					giveItem(itemId, "sfFan");
				if(itemId == _events.JETPACK)
					giveItem(itemId, "spFan");
			}
			
			if(event == _events.JERK_LEAVES_BATHROOMS)
			{
				jerkLeaves(getEntityById("friend"),getEntityById("bathroomDoor"));
			}			
		}
		
		private function setUpBathroom():void
		{
			var clip:MovieClip = _hitContainer["bathroomDoor"];
			var bathroomDoor:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			bathroomDoor.add(new Id(clip.name)).add(new SceneInteraction());
			BitmapTimelineCreator.convertToBitmapTimeline(bathroomDoor, clip);
			
			InteractionCreator.addToEntity(bathroomDoor, ["click"],EntityUtils.getDisplayObject(bathroomDoor));
			var interaction:SceneInteraction = bathroomDoor.get(SceneInteraction);
			if(shellApi.checkEvent("spFan"+_events.PASSED))
				interaction.reached.add(goInBathroom);
			interaction.offsetX = 50;
			interaction.minTargetDelta = new Point(25, 100);
			interaction.autoSwitchOffsets = false;
			interaction.ignorePlatformTarget = true;
			
			var data:WaveMotionData = new WaveMotionData("rotation", 0,.5);
			var wave:WaveMotion = new WaveMotion();
			wave.add(data);
			bathroomDoor.add(wave);
			ToolTipCreator.addToEntity(bathroomDoor,ToolTipType.CLICK, null, new Point(0, -clip.height / 2));
			
			if(shellApi.checkEvent("viking2"+_events.QUEST_COMPLETE))
			{
				var jerk:Entity = getEntityById("friend");
				ToolTipCreator.removeFromEntity(jerk);
				if(shellApi.checkHasItem(_events.MJOLNIR))
				{
					removeEntity(jerk);
					interaction.reached.removeAll();
					interaction.reached.add(noReason);
				}
				else
					DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(jerk), EntityUtils.getDisplayObject(bathroomDoor), false);
			}
			
			clip = _hitContainer["bathroomBack"];
			var bathroom:Entity = EntityUtils.createSpatialEntity(this, BitmapUtils.createBitmapSprite(clip), _hitContainer);
			var follow:FollowTarget = new FollowTarget(bathroomDoor.get(Spatial));
			follow.properties = new <String>["rotation", "x", "y"];
			bathroom.add(follow);
			Display(bathroom.get(Display)).moveToBack();
			_hitContainer.removeChild(clip);
			// this is to prevent large cosutumes from being seen behind the door
			clip = _hitContainer["bathroomMask"];
			var bathroomMask:Entity = EntityUtils.createSpatialEntity(this, BitmapUtils.createBitmapSprite(clip), _hitContainer);
			follow = new FollowTarget(bathroomDoor.get(Spatial));
			follow.properties = new <String>["rotation", "x", "y"];
			bathroomMask.add(new Id(clip.name)).add(follow);
			Display(bathroomMask.get(Display)).alpha = 0;
			_hitContainer.removeChild(clip);
		}
		
		private function goInBathroom(entity:Entity, door:Entity):void
		{
			CharUtils.setDirection(entity, false);
			openDoor(door, true, enterJerk);
			SceneUtil.lockInput(this);
		}
		
		private function openDoor(door:Entity, open:Boolean, onComplete:Function):void
		{
			var time:Timeline = door.get(Timeline);
			time.reverse = !open;
			if(open)
			{
				time.handleLabel("ending",Command.create(onComplete, door));
				time.play();
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "bathroom_unlocked_01.mp3");
			}
			else
			{
				time.gotoAndPlay(time.currentIndex - 1);
				time.handleLabel("unlock",Command.create(onComplete, door));
			}
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "bathroom_bathroom_door_close_01.mp3");
		}
		
		private function enterJerk(door:Entity):void
		{
			var time:Timeline = door.get(Timeline);
			time.gotoAndStop(time.currentIndex);
			var jerk:Entity = getEntityById("friend");
			CharUtils.moveToTarget(jerk,700,1025,true,Command.create(jerkOutOfBathroom, door));
		}
		
		private function jerkOutOfBathroom(jerk:Entity, door:Entity):void
		{
			CharUtils.setDirection(player, true);
			Dialog(jerk.get(Dialog)).sayById("cutter");
			Display(jerk.get(Display)).moveToFront();
		}	
		
		private function jerkLeaves(jerk:Entity, door:Entity):void
		{
			if(jerk == null)
				return;
			exitNPC(jerk);
			SceneUtil.addTimedEvent(this,new TimedEvent(2, 1, Command.create(closeDoor, door)));
		}
		
		private function closeDoor(door:Entity):void
		{
			CharUtils.setDirection(player, false);
			var spatial:Spatial = door.get(Spatial);
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(player), EntityUtils.getDisplayObject(door), false);
			openDoor(door, false, lockDoor);
			CharUtils.setAnim(player, Stand);
			TweenUtils.entityTo(player, Spatial, 1, {x:spatial.x, y:spatial.y - spatial.height / 4});
		}
		
		private function lockDoor(door:Entity):void
		{
			var time:Timeline = door.get(Timeline);
			time.gotoAndStop(time.currentIndex);
			
			var tween:Tween = new Tween(WaveMotion(door.get(WaveMotion)).data[0], "magnitude",Linear.easeInOut,0,5,1.5,true); 
			tween.start();
			
			var display:DisplayObjectContainer = EntityUtils.getDisplayObject(player);
			display.mask = EntityUtils.getDisplayObject(getEntityById("bathroomMask"));
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,Command.create(openBathroomDoor, door)));
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "rustle_trash_01.mp3",1,true);
		}
		
		private function openBathroomDoor(door:Entity):void
		{
			WaveMotion(door.get(WaveMotion)).data[0].magnitude = 0;
			Spatial(door.get(Spatial)).rotation = 0;
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "rustle_trash_01.mp3");
			openDoor(door, true, getOutOfBathroom);
		}
		
		private function getOutOfBathroom(door:Entity):void
		{
			openDoor(door, false, outOfBathroom);
			var display:Display = EntityUtils.getDisplay(player);
			display.displayObject.mask = null;
			display.moveToFront();
			CharUtils.stateDrivenOn(player);
		}
		
		private function outOfBathroom(door:Entity):void
		{
			var time:Timeline = door.get(Timeline);
			time.gotoAndStop(time.currentIndex);
			SceneUtil.lockInput(this, false);
			
			var interaction:SceneInteraction = door.get(SceneInteraction);
			interaction.reached.removeAll();
			interaction.reached.add(noReason);
			
			shellApi.getItem(_events.MJOLNIR, null, true);
		}
		
		private function noReason(player:Entity, door:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("never");
		}
		
		private function setUpNpcs():void
		{
			for(var i:int = 0; i < npcsInLine.length; i++)
			{
				var npcName:String = npcsInLine[i];
				var npc:Entity = getEntityById(npcName);
				
				var interaction:SceneInteraction = npc.get(SceneInteraction);
				interaction.offsetX = 75;
				
				if(shellApi.checkEvent(npcName+_events.PASSED))
				{
					Spatial(npc.get(Spatial)).x += 150;
					if(npcName == "spFan")
						removeEntity(npc);
				}
				else
				{
					if(npcName == "shFan")
						interaction.reached.add(checkForAmulet);
					currentLinePosition = i;
				}
			}
			setPositionInLine();
		}
		
		private function checkForAmulet(entity:Entity, npc:Entity):void
		{
			var dialog:Dialog = npc.get(Dialog);
			if(SkinUtils.hasSkinValue(player, SkinUtils.OVERSHIRT, "poptropicon_hero2"))
			{
				dialog.setCurrentById("shFan"+_events.QUEST_COMPLETE);
				shellApi.completeEvent("shFan"+_events.QUEST_COMPLETE);
			}
			dialog.sayCurrent();
		}
		
		private function setPositionInLine():void
		{
			if(currentLinePosition >= 0)
			{
				lastEntityInLine = getEntityById(npcsInLine[currentLinePosition]);
				var threshold:Threshold = player.get(Threshold);
				if(threshold == null)
				{
					threshold = new Threshold("x", "<");
					player.add(threshold);
				}
				threshold.entered.removeAll();
				threshold.entered.add(Command.create(youShallNotPass, lastEntityInLine));
				threshold.target = lastEntityInLine.get(Spatial);
			}
			else
				player.remove(Threshold);
		}
		
		private function youShallNotPass(entity:Entity):void
		{
			var stopAtX:Number = entity.get(Spatial).x;
			
			CharUtils.moveToTarget(player, stopAtX, 1050);// prevent player from continuing to walk to next npc if they clicked on one
			
			lockControls();
			
			var dialog:Dialog = entity.get(Dialog);
			dialog.sayById("no cutting");
			dialog.complete.addOnce(Command.create(getBack, stopAtX));
		}
		
		private function getBack(dialog:DialogData, backPosition:Number):void
		{
			var destination:Destination = CharUtils.moveToTarget(player, backPosition + 100, 1050,false, returnControls);
			destination.ignorePlatformTarget = true;
		}
		
		private function lockControls(...args):void
		{
			SceneUtil.lockInput(this);
		}
		
		private function returnControls(...args):void
		{
			SceneUtil.lockInput(this, false);
		}
		
		private function stepAsside(npc:Entity):void
		{
			var spatial:Spatial = npc.get(Spatial);
			CharUtils.moveToTarget(npc, spatial.x + 150, spatial.y,true, returnControls, new Point(25, 100));
		}
		
		private function giveItem(itemId:String, npcId:String):void
		{
			if(shellApi.checkEvent(npcId+_events.PASSED))
				return;
			if(shellApi.checkEvent(npcId+_events.QUEST_ACCEPTED))
			{
				SceneUtil.lockInput(this);
				shellApi.completeEvent(npcId+_events.QUEST_COMPLETE);
				var spatial:Spatial = getEntityById(npcId).get(Spatial);
				var destination:Destination = CharUtils.moveToTarget(player, spatial.x + 75, spatial.y, true, Command.create(giveItemToFan, itemId, npcId));
				destination.validCharStates = new <String>["stand"];
				destination.ignorePlatformTarget = true;
			}
			else
				Dialog(player.get(Dialog)).sayById("no_use");
		}
		
		private function giveItemToFan(entity:Entity, itemId:String, fanId:String):void
		{
			var itemGroup:ItemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			itemGroup.takeItem(itemId, fanId, "", null, Command.create(putOnPart, fanId));
			shellApi.removeItem(itemId);
		}
		
		private function putOnPart(fanId:String):void
		{
			var fan:Entity = getEntityById(fanId);
			Dialog(fan.get(Dialog)).sayById(fanId+_events.QUEST_COMPLETE);
			shellApi.triggerEvent(fanId+_events.PASSED, true);
		}
		
		private function passNpcInLine(npcName:String):void
		{
			if(npcsInLine.indexOf(npcName) > currentLinePosition)
				return;
			--currentLinePosition;
			setPositionInLine();
		}
		
		private function flyOffAfterDialog(dialog:DialogData, npc:Entity):void
		{
			flyOff(npc);
		}
		
		private function flyOff(npc:Entity):void
		{
			Sleep(npc.get(Sleep)).ignoreOffscreenSleep = true;
			TweenUtils.entityTo(npc,Spatial,5,{x:0, y:0, ease:Quad.easeIn,onComplete:Command.create(flewOff, npc)});
			CharUtils.setDirection(npc, false);
			CharUtils.setAnim(npc, Soar);
		}
		
		private function flewOff(entity:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("darn");
			entityLeaves(entity);
			SceneInteraction(getEntityById("bathroomDoor").get(SceneInteraction)).reached.add(goInBathroom);
		}
		
		private function exitNPC(npc:Entity, complete:Function = null):void
		{
			// stoping animation sequence so that the npc is free to move and not get interupted by animation sequence
			var animSequencer:AnimationSequencer = AnimationControl(npc.get(AnimationControl)).getEntityAt(0).get( AnimationSequencer );
			if ( animSequencer )
				animSequencer.interruptSequence();
			
			Sleep(npc.get(Sleep)).ignoreOffscreenSleep = true;
			
			var spatial:Spatial = getEntityById("door1").get(Spatial);
			CharUtils.moveToTarget(npc, spatial.x, spatial.y,true,entityLeaves);
			CharacterMotionControl(npc.get(CharacterMotionControl)).maxVelocityX = 300;
		}
		
		private function entityLeaves(entity:Entity):void
		{
			if(Id(entity.get(Id)).id == "friend")
			{
				if(!shellApi.checkEvent("viking2"+_events.QUEST_COMPLETE))
					shellApi.completeEvent(_events.FRIEND_GOES_HOME);
			}
			returnControls();// making sure no perma lock funny business happens
			removeEntity(entity);
		}
	}
}