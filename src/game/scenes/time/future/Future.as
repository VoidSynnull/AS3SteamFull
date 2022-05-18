package game.scenes.time.future
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.TransportGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Threshold;
	import game.components.hit.Mover;
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.time.TimeEvents;
	import game.data.scene.hit.MovingHitData;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.future.components.HitElevator;
	import game.scenes.time.future.systems.HitElevatorSystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Wind;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class Future extends PlatformerGameScene
	{
		public function Future()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/future/";
			//super.showHits = true;
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
			_events = TimeEvents(events);
			placeTimeDeviceButton();
			this.addSystem(new ThresholdSystem(), SystemPriorities.update);
			this.addSystem(new HitElevatorSystem(), SystemPriorities.move);
			
			var char1Dialog:Dialog = this.getEntityById("char1").get(Dialog);
			char1Dialog.current.dialog = String(char1Dialog.current.dialog).replace("[PlayerName]", this.shellApi.profileManager.active.avatarName.toString());
			
			setupTrains();
			setupFans();
			setupElevator();
			setupTubeZone();
			
			shellApi.eventTriggered.add(handleEventTriggered);

			if(shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = this.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.LIFT_MOVING && lastEvent != event)
			{
				liftAudio.play(SoundManager.EFFECTS_PATH + "hover_lift_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
			}
			
			if(event == _events.LIFT_STOPPED && lastEvent != event)
			{
				liftAudio.stopAll(SoundType.EFFECTS);
			}
			lastEvent = event;
		}
		
		// Setting up the base motion for the two trains
		// The top train doesn't stop when it turns around so we set the waitTime to 0.
		private function setupTrains():void
		{
			var numTrains:int = 2
				
			for(var i:int = 1; i <= numTrains; i++)
			{
				var trainDisplay:Entity = this.getEntityById("train" + i);
				var display:MovieClip = EntityUtils.getDisplayObject(trainDisplay) as MovieClip;
				this._hitContainer.setChildIndex(display, this._hitContainer.numChildren - 1);
				
				var trainAir:MovieClip = this._hitContainer["airShute" + i];
				var trainAirShute:Entity = EntityUtils.createSpatialEntity(this, trainAir);
				var mover:Mover = new Mover();
				mover.acceleration = new Point(0, -1300);
				mover.friction = new Point(400, 0);
				mover.stickToPlatforms = false;
				trainAirShute.add(mover);
				
				var follow:FollowTarget = new FollowTarget(trainDisplay.get(Spatial));
				follow.offset = new Point(0, -50);
				trainAirShute.add(follow);
				
				Display(trainDisplay.get(Display)).displayObject = DisplayUtils.convertToBitmapSprite(display).sprite;
				
				if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH)
					windParticle(new Rectangle(-trainAir.width/2, 0, trainAir.width, trainAir.height), trainAirShute);				
				
				// engine turbine sound
				var engineAudio:Audio = new Audio();				
				var engineEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["trainAirAudioHolder" + i]);
				engineEntity.add(engineAudio);
				engineEntity.add(new AudioRange(1400, 0, 1, Sine.easeIn));
				engineAudio.play(SoundManager.EFFECTS_PATH + "turbine_engine_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
				engineEntity.add(new FollowTarget(trainDisplay.get(Spatial), 1));
				
				if(i == 1)
				{
					var bottom:Entity = super.getEntityById("train1BottomPlatform");
					var top:Entity = super.getEntityById("train1TopPlatform");
					bottom.remove(MovingHitData);
					top.remove(MovingHitData);
					
					train1Audio = new Audio();
					engineEntity.add(train1Audio);
					train1Audio.play(SoundManager.EFFECTS_PATH + "mono_rail_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
					
					trainMove(bottom, top, 2, 0, false);
				}
				else
				{
					var train2Audio:Audio = new Audio();
					engineEntity.add(train2Audio);
					train2Audio.play(SoundManager.EFFECTS_PATH + "mono_rail_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
				}
			}
		}
		
		/**
		 * Stops and pauses the train when it reaches its end points 
		 */
		private function trainMove(bottom:Entity, top:Entity, waitTime:Number, state:uint = 0, wait:Boolean = false):void
		{
			var bottomMotion:Motion = bottom.get(Motion);
			var topMotion:Motion = top.get(Motion);
			var threshold:Threshold = new Threshold("x");
			
			if(wait)
			{
				bottomMotion.velocity = new Point(0, 0);
				topMotion.velocity = new Point(0, 0);
				SceneUtil.addTimedEvent(this, new TimedEvent(waitTime, 1, Command.create(trainMove, bottom, top, waitTime, state, false)));
				train1Audio.stop(SoundManager.EFFECTS_PATH + "mono_rail_01_L.mp3");
				train1Audio.play(SoundManager.EFFECTS_PATH + "mono_rail_stop_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
			}
			else
			{
				// Go Right
				if(state == 0)
				{
					bottomMotion.velocity.x = 150;
					topMotion.velocity.x = 150;
					threshold.operator = ">";
					threshold.threshold = 3184;
					threshold.entered.addOnce(Command.create(trainMove, bottom, top, waitTime, 1, true));
					train1Audio.play(SoundManager.EFFECTS_PATH + "mono_rail_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
				}
				else if(state == 1)
				{
					// Go Left
					bottomMotion.velocity.x = -150;
					topMotion.velocity.x = -150;
					threshold.operator = "<"
					threshold.threshold = 1967;
					threshold.entered.addOnce(Command.create(trainMove, bottom, top, waitTime, 0, true));
					train1Audio.play(SoundManager.EFFECTS_PATH + "mono_rail_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
				}
				bottom.add(threshold);
			}
		}
		
		private function windParticle(ventBounds:Rectangle, vent:Entity):void
		{
			var wind:Wind = new Wind();
			wind.init(18, ventBounds);
			
			var group:Group = OwningGroup(vent.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(vent.get(Display)).displayObject;
			var emitterEntity:Entity = EmitterCreator.create(group, container, wind);
		}
		
		private function setupFans():void
		{
			var numFans:Number = 2;
			
			for(var i:int = 1; i <= numFans; i++)
			{
				var fan:Sprite = DisplayUtils.convertToBitmapSprite(this._hitContainer["fan" + i]).sprite;
				var fanEntity:Entity = EntityUtils.createMovingEntity(this, fan);
				fanEntity.add(new Sleep(true));
				var fanMotion:Motion = fanEntity.get(Motion);
				
				fanMotion.rotationVelocity = 300;
				
				// Add audio to each fan
				var fanAudio:Audio = new Audio();
				var fanSoundEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["fanAudioHolder" + i]);
				fanSoundEntity.add(fanAudio);
				fanSoundEntity.add(new AudioRange(1200, 0, 1, Sine.easeIn));
				fanAudio.play(SoundManager.EFFECTS_PATH + "spinning_fans_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
			}
		}
		
		private function setupElevator():void
		{
			var lift:Entity = super.getEntityById("lift");
			var liftDisplay:MovieClip = EntityUtils.getDisplayObject(lift) as MovieClip;
			this._hitContainer.setChildIndex(liftDisplay, this._hitContainer.numChildren - 1);
			Display(lift.get(Display)).displayObject = DisplayUtils.convertToBitmapSprite(liftDisplay).sprite;
				
			// can't add sleep because then the elevator won't go back to its base position
			var elevator:Entity = super.getEntityById("elevator");			
			var hitElevator:HitElevator = new HitElevator();
			hitElevator.endPoints = new Point(460, 1935);
			hitElevator.velocity = LIFT_VELOCITY;
			elevator.add(hitElevator);
			
			// add sound
			liftAudio = new Audio();
			var soundEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["elevatorAudioHolder"]);
			soundEntity.add(liftAudio);
			soundEntity.add(new AudioRange(1200, 0, 1, Sine.easeIn));
			soundEntity.add(new FollowTarget(elevator.get(Spatial), 1));
		}
		
		// Have a zone setup to trigger the tube sound and it plays when
		private function setupTubeZone():void
		{
			var hit:Entity = super.getEntityById("zone1");
			var zone:Zone = hit.get(Zone);
			zone.pointHit = true;
			zone.entered.add(tubeTriggered);
		}
		
		private function tubeTriggered(zoneId:String, characterId:String):void
		{
			super.shellApi.triggerEvent("entered_tube");
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
		
		private var train1Audio:Audio;
		private var liftAudio:Audio;
		private var timeButton:Entity;
		public var _events:TimeEvents;
		private var lastEvent:String = "null";
		private static var LIFT_VELOCITY:Number = 300;
	}
}