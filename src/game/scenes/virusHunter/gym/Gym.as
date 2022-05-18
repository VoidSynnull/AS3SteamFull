package game.scenes.virusHunter.gym
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.Emitter;
	import game.components.motion.WaveMotion;
	import game.components.entity.Dialog;
	import game.components.motion.MotionTarget;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.WeightLifting;
	import game.data.game.GameEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	public class Gym extends PlatformerGameScene
	{
		private var _events:VirusHunterEvents;
		
		private var band:Entity;
		private var weight:Sprite;
		private var weightIndex:int;
		
		public function Gym()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/gym/";
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
			_events = this.events as VirusHunterEvents;
			
			this.addSystem(new BitmapSequenceSystem());
			
			setupMusic();
			setupTreadmills();
			setupWeight();
			setupBuoys();
			setupBubblers();
			setupLockers();
			setupBand();
		}
		
		private function setupMusic():void
		{
			var music:Entity = new Entity();
			this.addEntity(music);
				
			music.add(new Spatial(708, 240));
			music.add(new AudioRange(2400, 0, 1, Quad.easeIn));
			music.add(new Id("technoMusic"));
				
			var audio:Audio = new Audio();
			audio.play(SoundManager.MUSIC_PATH + "Techno_Jam_Filtered.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC]);
			music.add(audio);
		}
		
		private function setupTreadmills():void
		{
			for(var i:uint = 1; i <= 2; i++)
			{
				var treadmill:Entity = new Entity();
				this.addEntity(treadmill);
				
				treadmill.add(new Id("treadmill" + i));
				treadmill.add(new AudioRange(400, 0, 0.5));
				
				switch(i)
				{
					case 1: treadmill.add(new Spatial(360, 465)); break;
					case 2: treadmill.add(new Spatial(570, 465)); break;
				}
				
				var audio:Audio = new Audio();
				audio.play(SoundManager.EFFECTS_PATH + "treadmill_servo_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
				treadmill.add(audio);
			}
		}
		
		private function setupWeight():void
		{
			this.weight = this.convertToBitmapSprite(this._hitContainer["weight"]).sprite;
			this.weightIndex = this.weight.parent.getChildIndex(this.weight);
			SceneInteraction(this.getEntityById("interaction2").get(SceneInteraction)).reached.add(handleWeightClick);
		}
		
		private function handleWeightClick(player:Entity, weight:Entity):void
		{
			var audio:Audio = this.player.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "lift_up_01.mp3", false, SoundModifier.EFFECTS);
			
			CharUtils.setAnim(this.player, WeightLifting);
			
			var hand:Entity = CharUtils.getPart(this.shellApi.player, CharUtils.HAND_FRONT);
			var display:Display = hand.get(Display);
			display.displayObject.addChildAt(this.weight, 0);
			
			this.weight.x = -40;
			this.weight.y = 0;
			this.weight.scaleX = this.weight.scaleY = 2.7;
			
			var timeline:Timeline = this.player.get(Timeline);
			timeline.handleLabel("end", handleLift);
		}
		
		private function handleLift():void
		{
			var audio:Audio = this.player.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "lift_up_01.mp3", false, SoundModifier.EFFECTS);
			
			this.weight.x = 737.9;
			this.weight.y = 492.1;
			this.weight.scaleX = this.weight.scaleY = 1;
			this._hitContainer.addChildAt(this.weight, this.weightIndex);
		}
		
		private function setupBuoys():void
		{
			this.addSystem(new WaveMotionSystem());
			
			for(var i:uint = 1; i <= 5; i++)
			{
				var sprite:Sprite = this.convertToBitmapSprite(this._hitContainer["buoy" + i]).sprite;
				var buoy:Entity = EntityUtils.createSpatialEntity(this, sprite);
				
				var wave:WaveMotion = new WaveMotion();
				var waveData:WaveMotionData = new WaveMotionData();
				waveData.property = "y";
				waveData.magnitude = 3;
				waveData.rate = Utils.randNumInRange(0.05, 0.075);
				wave.data.push(waveData);
				
				buoy.add(wave);
				buoy.add(new SpatialAddition());
			}
		}
		
		private function setupBubblers():void
		{
			for(var i:uint = 1; i <= 2; i++)
			{
				var clip:MovieClip = this._hitContainer["bubbler" + i];
				
				var bubbler:Entity = ButtonCreator.createButtonEntity(clip, this, null, null, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.OUT]);
				
				var bubblerEmitter:Bubbler = new Bubbler();
				var spout:Entity = EmitterCreator.create(this, clip, bubblerEmitter, 13, 8, null, "spout" + i, null, false);
				
				var emitter:Emitter = spout.get(Emitter);
				
				var interaction:Interaction = bubbler.get(Interaction);
				interaction.down.add(Command.create(bubblerDown, emitter));
				interaction.up.add(Command.create(bubblerUp, emitter));
				interaction.out.add(Command.create(bubblerUp, emitter));
			}
		}
		
		private function bubblerDown(bubbler:Entity, emitter:Emitter):void
		{
			emitter.start = true;
			emitter.emitter.counter.resume();
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_fountain_01_L.mp3", 1, true, SoundModifier.EFFECTS);
		}
		
		private function bubblerUp(bubbler:Entity, emitter:Emitter):void
		{
			emitter.emitter.counter.stop();
			
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "water_fountain_01_L.mp3");
		}
		
		private function setupLockers():void
		{
			for(var i:uint = 3; i <= 11; i++)
			{
				var locker:Entity = this.getEntityById("interaction" + i);
				
				var sleep:Sleep = locker.get(Sleep);
				sleep.sleeping = true;
				sleep.useEdgeForBounds = true;
				locker.add(new Edge(100, 100, 100, 100));
				
				var interaction:SceneInteraction = locker.get(SceneInteraction);
				interaction.approach = false;
				interaction.triggered.add(handleLockerClick);
				
				locker.add(new Audio());
				
				var clip:MovieClip = this._hitContainer["interaction" + i];
				TimelineUtils.convertClip(clip, this, locker);
				Timeline(locker.get(Timeline)).gotoAndStop("begin");
			}
		}
		
		private function handleLockerClick(player:Entity, locker:Entity):void
		{
			locker.get(Audio).play(SoundManager.EFFECTS_PATH + "metal_panel_open_0" + Utils.randInRange(1, 3) + ".mp3", false, SoundModifier.EFFECTS);
			locker.get(Timeline).gotoAndPlay("begin");
		}
		
		private function setupBand():void
		{
			this.band = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer["band"]);
			this.band.get(Display).moveToBack();
			this.addEntity(this.band);
			
			if(!this.shellApi.checkEvent(GameEvent.GOT_ITEM + _events.RESISTANCE_BAND))
			{
				this.band.add(new Audio());
				this.band.add(new Id("band"));
				this.band.get(Timeline).gotoAndStop("begin");
				
				SceneInteraction(super.getEntityById("interaction1").get(SceneInteraction)).reached.addOnce(handleBandClick);
			}
			else
			{
				this.removeEntity(this.getEntityById("interaction1"));
				this.band.get(Timeline).gotoAndStop("removed");
			}
		}
		
		private function handleBandClick(character:Entity, interaction:Entity):void
		{
			this.removeEntity(interaction);
			this.band.get(Audio).play(SoundManager.EFFECTS_PATH + "rope_strain_04.mp3", false, SoundModifier.EFFECTS);
			
			SceneUtil.lockInput(this);
			CharUtils.setAnim(this.player, PointItem);
			
			var timeline:Timeline = this.band.get(Timeline);
			timeline.gotoAndPlay("begin");
			
			timeline.handleLabel("break", handleBandBreak);
			timeline.handleLabel("end", handleBandEnd);
		}
		
		private function handleBandBreak():void
		{
			var audio:Audio = this.band.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "rope_snap_01.mp3", false, SoundModifier.EFFECTS);
		}
		
		private function handleBandEnd():void
		{
			var employee:Entity = this.getEntityById("employee");
			Sleep(employee.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(employee.get(Sleep)).sleeping = false;
			
			var spatial:Spatial = player.get(Spatial);
			var destination:Destination = CharUtils.followEntity(employee, this.player, new Point(250, 50));
			destination.nextReachAsFinal = true;
			destination.onFinalReached.addOnce(handlePath);
			
			Display(employee.get(Display)).moveToFront();
		}
		
		private function handlePath(employee:Entity):void
		{
			CharUtils.setDirection(this.shellApi.player, true);

			var dialog:Dialog = employee.get(Dialog);
			dialog.sayById("band");
			dialog.complete.addOnce(handleBandDialog);
		}
		
		private function handleBandDialog(dialog:DialogData):void
		{
			this.band.get(Timeline).gotoAndStop("removed");
			
			SceneUtil.lockInput(this, false);
			
			CharUtils.stopFollowEntity(this.getEntityById("employee"));
			
			//Is this needed if it's already in the dialog.xml?
			this.shellApi.getItem(_events.RESISTANCE_BAND);
		}
	}
}