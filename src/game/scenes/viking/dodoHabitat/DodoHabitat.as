package game.scenes.viking.dodoHabitat
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Timer;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Hazard;
	import game.components.hit.Item;
	import game.components.hit.Zone;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Place;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.viking.VikingEvents;
	import game.scenes.viking.shared.DodoGroup;
	import game.scenes.viking.shared.popups.MapPopup;
	import game.systems.hit.HazardHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	public class DodoHabitat extends PlatformerGameScene
	{
		private var vikingEvents:VikingEvents;
		private var dodoGroup:DodoGroup = new DodoGroup();
		
		private var flopTimer:TimedEvent;
		
		public function DodoHabitat()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/dodoHabitat/";
			
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
			
			this.vikingEvents = this.events as VikingEvents;
			
			this.shellApi.eventTriggered.add(this.eventTriggered);
			
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new ThresholdSystem());
			this.addSystem(new HazardHitSystem());
			
			this.setupMapDoor();
			this.setupDodos();
			this.setupDodoZones();
			this.setupFish();
			this.setupLens();
			this.setupBones();
			this.setupCrab();
		}
		
		private function eventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "use_goblet")
			{
				if(!this.shellApi.checkEvent(vikingEvents.CAUGHT_FISH))
				{
					Dialog(this.player.get(Dialog)).sayById("empty");
				}
				else if(!this.shellApi.checkEvent(vikingEvents.PLACED_FISH))
				{
					var spatial:Spatial = this.player.get(Spatial);
					
					if(spatial.x < 1100)
					{
						CharUtils.moveToTarget(this.player, 682, 980, true, this.placeFish, new Point(30, 100));
					}
					else
					{
						Dialog(this.player.get(Dialog)).sayById("lure");
						//Need to lure them away more.
					}
				}
				else
				{
					//Nothing to do here.
					Dialog(this.player.get(Dialog)).sayById("empty");
				}
			}
			else if(event == "gotItem_lens")
			{
				this.removeEntity(this.getEntityById("sparkle"));
			}
		}
		
		private function setupCrab():void
		{
			var clip:MovieClip = this._hitContainer["crab"];
			
			var crab:Entity = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertClip(clip, this, crab);
			Timeline(crab.get(Timeline)).gotoAndStop("inEnd");
			crab.add(new Tween());
			
			var interaction:Interaction = InteractionCreator.addToEntity(crab, [InteractionCreator.CLICK]);
			interaction.click.add(this.crabClicked);
			
			ToolTipCreator.addToEntity(crab);
		}
		
		private function crabClicked(crab:Entity):void
		{
			//var crab:Entity = this.getEntityById("crab");
			var timeline:Timeline = crab.get(Timeline);
			if(timeline.currentFrameData.label == "inEnd")
			{
				timeline.gotoAndPlay("outStart");
				timeline.handleLabel("walkStart", this.crabWalkStart);
			}
		}
		
		private function crabWalkStart():void
		{
			var crab:Entity = this.getEntityById("crab");
			var tween:Tween = crab.get(Tween);
			var spatial:Spatial = crab.get(Spatial);
			
			var x:Number = Utils.randNumInRange(1000, 1785);
			
			tween.to(spatial, Math.abs(spatial.x - x) / 100, {x:x, onComplete:crabWalkEnd});
		}
		
		private function crabWalkEnd():void
		{
			var crab:Entity = this.getEntityById("crab");
			var timeline:Timeline = crab.get(Timeline);
			timeline.gotoAndPlay("idleStart");
		}
		
		private function setupDodoZones():void
		{
			var index:int;
			
			if(!this.shellApi.checkEvent(vikingEvents.PLACED_FISH))
			{
				for(index = 1; index <= 5; ++index)
				{
					var dodoZone:Entity =this.getEntityById("dodoZone" + index);
					
					var zone:Zone = dodoZone.get(Zone);
					zone.shapeHit = false;
					zone.pointHit = true;
					zone.entered.add(this.dodoZoneEntered);
					zone.exitted.add(this.dodoZoneExited);
				}
			}
			else
			{
				for(index = 1; index <= 5; ++index)
				{
					this.removeEntity(this.getEntityById("dodoZone" + index));
				}
			}
		}
		
		private function dodoZoneEntered(zoneID:String, colliderID:String):void
		{
			if(colliderID == "player")
			{
				var index:int = int(zoneID.slice(8));
				var dodo:Entity = this.getEntityById("dodo" + index);
				SkinUtils.setSkinPart(dodo, SkinUtils.FACIAL, "comic_dodo2");
				
				Timer(dodo.get(Timer)).addTimedEvent(new TimedEvent(0.25, 0, Command.create(dodoChirp, dodo)));
			}
		}
		
		private function dodoChirp(dodo:Entity):void
		{
			var audio:Audio = dodo.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "turkey_call_0" + Utils.randInRange(1, 6) + ".mp3", false, [SoundModifier.EFFECTS]);
		}
		
		private function dodoZoneExited(zoneID:String, colliderID:String):void
		{
			if(colliderID == "player")
			{
				var index:int = int(zoneID.slice(8));
				var dodo:Entity = this.getEntityById("dodo" + index);
				SkinUtils.setSkinPart(dodo, SkinUtils.FACIAL, "comic_dodo");
				
				Timer(dodo.get(Timer)).timedEvents.length = 0;
			}
		}
		
		private function setupBones():void
		{
			var bones:Entity = this.getEntityById("boneInteraction");
			
			if(!this.shellApi.checkEvent(vikingEvents.PLACED_FISH))
			{
				var sceneInteraction:SceneInteraction = bones.get(SceneInteraction);
				sceneInteraction.approach = false;
				sceneInteraction.triggered.add(this.onBonesClicked);
				
				Display(bones.get(Display)).alpha = 0;
			}
			else
			{
				this.removeEntity(bones);
			}
		}
		
		private function onBonesClicked(...args):void
		{
			Dialog(this.player.get(Dialog)).sayById("hungry");
		}
		
		private function setupDodos():void
		{
			var offsets:Array = [80, 60, 10, 300, 300];
			var offsetChangeTimes:Array = [0.5, 1, 1, 2, 2];
			
			var index:int;
			
			if(this.shellApi.checkEvent(vikingEvents.PLACED_FISH))
			{
				for(index = 5; index > 0; --index)
				{
					this.removeEntity(this.getEntityById("dodo" + index));
				}
			}
			else
			{
				for(index = 5; index > 0; --index)
				{
					var target:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["dodoTarget" + index]);
					var dodo:Entity = this.getEntityById("dodo" + index);
					dodo.add(new Audio());
					dodo.add(new Timer());
					dodoGroup.clusterDodo(this, dodo, target, offsets[index - 1], offsetChangeTimes[index - 1]);
					dodo.add(new Hazard(600, 600));
					
					ToolTipCreator.removeFromEntity(dodo);
				}
			}
		}
		
		private function setupLens():void
		{
			var sparkle:DisplayObject = this._hitContainer["sparkle"];
			
			var lens:Entity = this.getEntityById("lens");
			if(lens)
			{
				var entity:Entity = EntityUtils.createSpatialEntity(this, sparkle);
				TimelineUtils.convertClip(this._hitContainer["sparkle"], this, entity);
				
				Display(lens.get(Display)).moveToBack();
				if(!this.shellApi.checkEvent(vikingEvents.PLACED_FISH))
				{
					lens.remove(Item);
				}
			}
			else
			{
				sparkle.parent.removeChild(sparkle);
			}
		}
		
		private function setupFish():void
		{
			var clip:MovieClip = this._hitContainer["fish"];
			var fish:Entity = EntityUtils.createMovingEntity(this, clip);
			TimelineUtils.convertClip(clip, this, fish, null, false);
			
			var display:Display = fish.get(Display);
			display.visible = false;
			display.moveToBack();
			Display(fish.get(Display)).visible = false;
		}
		
		private function placeFish(...args):void
		{
			this.shellApi.completeEvent(VikingEvents(events).PLACED_FISH);
			
			SkinUtils.setSkinPart(this.player, SkinUtils.ITEM, "comic_goblet", false);
			
			this.removeEntity(this.getEntityById("boneInteraction"));
			
			SceneUtil.lockInput(this);
			CharUtils.setAnim(this.player, Place);
			CharUtils.setDirection(this.player, true);
			var timeline:Timeline = this.player.get(Timeline);
			timeline.handleLabel("trigger", this.placedFish);
			
			var lens:Entity = this.getEntityById("lens");
			lens.add(new Item());
		}
		
		private function placedFish():void
		{
			var fish:Entity = this.getEntityById("fish");
			Display(fish.get(Display)).visible = true;
			Timeline(fish.get(Timeline)).play();
			fish.add(new SpatialAddition());
			
			this.flopTimer = SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 0, makeFlop));
			
			var wave:WaveMotion = new WaveMotion();
			wave.add(new WaveMotionData("rotation", 20, 5, "sin", 0, true));
			wave.add(new WaveMotionData("y", 10, 10, "sin", 0, true));
			fish.add(wave);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, this.clusterDodos));
		}
		
		private function makeFlop():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wet_flop_impact_0" + Utils.randInRange(1, 5) + ".mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function clusterDodos():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "dodo_bird_swarm_01_loop.mp3", 1, true, [SoundModifier.EFFECTS]);
			
			SkinUtils.emptySkinPart(this.player, SkinUtils.ITEM, false);
			
			SceneUtil.setCameraTarget(this, this.getEntityById("dodo1"));
			
			dodoGroup.clusterAllDodos(this, this.getEntityById("fish"), 100, 0.5, true);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, this.moveFishOffScreen));
		}
		
		private function moveFishOffScreen():void
		{
			CharUtils.setDirection(this.player, false);
			
			var fish:Entity = this.getEntityById("fish");
			Motion(fish.get(Motion)).velocity.x = -250;
			fish.remove(Sleep);
			
			var threshold:Threshold = new Threshold("x", "<");
			threshold.threshold = -200;
			
			threshold.entered.addOnce(this.removeFishAndDodos);
			fish.add(threshold);
			
			SceneUtil.setCameraTarget(this, fish);
		}
		
		private function removeFishAndDodos():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "dodo_bird_swarm_01_loop.mp3");
			
			var timedEvents:Vector.<TimedEvent> = SceneUtil.getTimer(this).timedEvents;
			timedEvents.splice(timedEvents.indexOf(this.flopTimer), 1);
			
			for(var index:int = 5; index > 0; --index)
			{
				this.removeEntity(this.getEntityById("dodo" + index));
				this.removeEntity(this.getEntityById("dodoZone" + index));
			}
			this.removeEntity(this.getEntityById("fish"));
			
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, this.player);
			Dialog(this.player.get(Dialog)).sayById("finished");
			
		}
		
		private function setupMapDoor():void
		{
			var door:Entity = super.getEntityById("doorMap");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			var interaction:Interaction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			interaction.click = new Signal();
			interaction.click.add(openMap);			
		}
		
		private function openMap(door:Entity):void
		{
			var mapPopup:MapPopup = new MapPopup(overlayContainer);
			addChildGroup(mapPopup);
		}
	}
}