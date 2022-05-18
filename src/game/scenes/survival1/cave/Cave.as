package game.scenes.survival1.cave
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.Item;
	import game.components.hit.Zone;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.WaveMotionData;
	import game.data.sound.SoundModifier;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.cave.particles.CaveDrip;
	import game.scenes.survival1.cave.particles.CaveSnow;
	import game.scenes.survival1.cave.particles.CaveSplash;
	import game.scenes.survival1.cave.turnToTarget.TurnToTarget;
	import game.scenes.survival1.cave.turnToTarget.TurnToTargetSystem;
	import game.scenes.survival1.shared.SurvivalScene;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class Cave extends SurvivalScene
	{
		private var hiddenParts:Array = [CharUtils.BODY_PART, CharUtils.PANTS_PART, CharUtils.SHIRT_PART,
										CharUtils.OVERPANTS_PART, CharUtils.OVERSHIRT_PART, CharUtils.HEAD_PART,
										CharUtils.MARKS_PART, CharUtils.MOUTH_PART, CharUtils.FACIAL_PART,
										CharUtils.PACK, CharUtils.HAIR, CharUtils.ARM_BACK, CharUtils.ARM_FRONT,
										CharUtils.LEG_BACK, CharUtils.LEG_FRONT, CharUtils.FOOT_BACK,
										CharUtils.FOOT_FRONT, CharUtils.ITEM, CharUtils.HAND_BACK,
										CharUtils.HAND_FRONT];
		
		private var bear:Entity;
		private var bearMouth:Entity;
		private var bat:Entity;
		
		private var _events:Survival1Events;
		
		/*
		The sleeping bear aka Grizzilla, Bringer of Death being awakened can be caused by the FirePopup being
		opened or walking through the bear zone. This should only be triggered once, so this prevents the other
		action from firing the bear again.
		*/
		private var grizzillaBringerOfDeathAwakened:Boolean = false;
		
		public function Cave()
		{
			super();
		}
		
		override public function destroy():void
		{
			//Manual destruction of Emitter2D ParticleEvent listeners and Signals.
			for(var i:int = 0; i < 7; i++)
			{
				var entity:Entity = this.getEntityById("caveDrip" + i);
				
				CaveDrip(Emitter(entity.get(Emitter)).emitter).destroy();
			}
			
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival1/cave/";
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
			
			this._events = this.events as Survival1Events;
			this.shellApi.eventTriggered.add(this.onEventTriggered);
			
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new TurnToTargetSystem());
			
			this.setupHillsideDoor();
			this.setupDrips();
			this.setupSnow();
			this.setupBear();
			this.setupBat();
			this.setupEyeZones();
			this.setupBearZone();
			this.setupKindling();
		}
		
		private function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == this._events.FIRE_AWAKENED_BEAR)
			{
				this.onGrizzillaBringerOfDeathAwakened();
			}
		}
		
		private function setupHillsideDoor():void
		{
			var entity:Entity = this.getEntityById("doorHillside");
			entity.get(SceneInteraction).reached.addOnce(playGrowlAudio);
		}
		
		private function playGrowlAudio(player:Entity, door:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "bear_growl_02.mp3");
		}
		
		private function setupDrips():void
		{
			var splashWidth:int = 200;
			var zones:Array = [new Rectangle(110, 500, splashWidth, 350),
								new Rectangle(470, 300, splashWidth, 560),
								new Rectangle(933, 110, splashWidth, 432),	// has splash
								new Rectangle(1140, 110, splashWidth, 432),	// has splash
								new Rectangle(1270, 90, splashWidth, 715),	// has splash
								new Rectangle(1470, 80, splashWidth, 465),	// has splash
								new Rectangle(1940, 110, splashWidth, 680),
								new Rectangle(2280, 45, splashWidth, 740)];
			
			var rates:Array = [0.1, 0.1, 0.2, 0.2, 0.2, 0.2, 0.1, 0.1];
			
			for(var i:int = 0; i < zones.length; i++)
			{
				var zone:Rectangle = zones[i];
				
				var particles:CaveDrip = new CaveDrip( zone, rates[i], i);
				particles.deadParticle.add(playDripAudio);
				var entity:Entity = EmitterCreator.create(this, this._hitContainer, particles, zone.x, zone.y, null, "caveDrip" + i);
				
				if( i > 1 && i < 6 )
				{
					var splash:CaveSplash = new CaveSplash( new Point(zone.x, zone.bottom) );
					entity = EmitterCreator.create(this, this._hitContainer, splash, zone.x, zone.bottom, null, null, null, false);
					entity.add(new Id("caveSplash" + i));
				}
			}
		}
		
		private function playDripAudio(caveDrip:CaveDrip):void
		{
			var index:uint = caveDrip.index;
		
			if( index > 1 && index < 6 )
			{
				var entity:Entity = this.getEntityById("caveSplash" + index);
			
				var emitter:Emitter = entity.get(Emitter);
				emitter.start = true;
				emitter.emitter.start();
			}
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "drip_0" + Utils.randInRange(1, 3) + ".mp3", 1, false, SoundModifier.EFFECTS);
		}
		
		private function setupSnow():void
		{
			var entity:Entity = EmitterCreator.create(this, this._hitContainer, new CaveSnow());
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = 2150;
			spatial.y = 40;
		}
		
		private function setupBear():void
		{
			this.bear = EntityUtils.createDisplayEntity(this, this._hitContainer["bear"]);
			TimelineUtils.convertClip(this._hitContainer["bear"], this, this.bear, null, false);
			
			var timeline:Timeline = this.bear.get(Timeline);
			timeline.handleLabel("startMouth", this.startMouth);
			timeline.handleLabel("roarEnd", this.openBearPopup);
			
			this.bearMouth = EntityUtils.createDisplayEntity(this, this._hitContainer["bear"]["mouth"]);
			TimelineUtils.convertClip(this._hitContainer["bear"]["mouth"], this, this.bearMouth, null, false);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "large_animal_snore_03.mp3", 1, true);
		}
		
		private function startMouth():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "bear_roar_01.mp3");
			
			this.bearMouth.get(Timeline).play();
		}
		
		private function openBearPopup():void
		{
			SceneUtil.lockInput(this, false);
			
			//this.addChildGroup(new BearPopup(this.overlayContainer));
			var bearPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			bearPopup.updateText("you woke a hibernating bear!", "try again");
			bearPopup.configData("bearPopup.swf", "scenes/survival1/cave/bearPopup/");
			bearPopup.removed.add(restart);
			addChildGroup(bearPopup);
		}
		
		private function restart(group:Group):void
		{
			shellApi.loadScene(Cave);
		}
		
		private function setupBat():void
		{
			this.bat = EntityUtils.createMovingEntity(this, this._hitContainer["bat"]);
			this.bat.add(new SpatialAddition());
			this.bat.add(new Id("bat"));
			this.bat.add(new ZoneCollider());
			this.bat.add(new TurnToTarget(this.player.get(Spatial), "x", -100));
			
			EntityUtils.followTarget(this.bat, this.player, 0.025, new Point(100, 0), false, new <String>["x"]);
			
			var wings:Entity = TimelineUtils.convertClip(this._hitContainer["bat"]["wings"], this, null, this.bat);
			
			var wave:WaveMotion = new WaveMotion();
			wave.data.push(new WaveMotionData("y", 4, 0.2));
			this.bat.add(wave);
		}
		
		private function setupEyeZones():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var eyeZone:Entity = this.getEntityById("eyeZone" + i);
				
				var zone:Zone = eyeZone.get(Zone);
				zone.entered.add(Command.create(this.setParts, true));
				zone.exitted.add(Command.create(this.setParts, false));
			}
		}
		
		private function setParts(zoneID:String, colliderID:String, visible:Boolean):void
		{
			var display:Display;
			
			if(colliderID == "player")
			{
				for each(var partName:String in this.hiddenParts)
				{
					var partEntity:Entity = CharUtils.getPart(this.player, partName);
					display = partEntity.get(Display);
					
					if(visible)
					{
						var skinPart:SkinPart = SkinUtils.getSkinPart(this.player, partName);
						if(skinPart)
						{
							if(!skinPart.hidden) display.visible = visible;
						}
						else
						{
							display.visible = visible;
						}
					}
					else
					{
						display.visible = visible;
					}
				}
				
				var mouthPart:SkinPart = SkinUtils.getSkinPart(this.player, SkinUtils.MOUTH);
				mouthPart.lock = !visible;
			}
			else if(colliderID == "bat")
			{
				display = this.bat.get(Display);
				display.displayObject["body"].visible 	= visible;
				display.displayObject["wings"].visible 	= visible;
			}
		}
		
		private function setupKindling():void
		{
			var dryKindling:Entity = this.getEntityById("dryKindling");
			if( dryKindling )
			{
				DisplayUtils.moveToOverUnder( EntityUtils.getDisplayObject( dryKindling), EntityUtils.getDisplayObject( super.player), false );
			}
		}
		
		private function setupBearZone():void
		{
			var bearZone:Entity = this.getEntityById("bearZone");
			bearZone.get(Zone).entered.addOnce(onGrizzillaBringerOfDeathAwakened);
		}
		
		private function onGrizzillaBringerOfDeathAwakened(zoneID:String = null, colliderID:String = null):void
		{
			if(this.grizzillaBringerOfDeathAwakened) return;
			this.grizzillaBringerOfDeathAwakened = true;
			
			//Lock input and pan to Grizzilla in all his glory!
			SceneUtil.lockInput(this);
			this.shellApi.camera.target = new Spatial(1325, 660);
			this.shellApi.camera.jumpToTarget = false;
			this.shellApi.camera.rate = 0.05;
			
			/*
			If the bear is triggered, prevent the player from being able to pick up the item.
			The item can be picked up after successfully going over the bear.
			*/
			var dryKindling:Entity = this.getEntityById("dryKindling");
			if(dryKindling) dryKindling.remove(Item);
			
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "large_animal_snore_03.mp3");
			AudioUtils.play(this, SoundManager.MUSIC_PATH + "danger.mp3");
			
			this.bear.get(Timeline).play();
		}
	}
}