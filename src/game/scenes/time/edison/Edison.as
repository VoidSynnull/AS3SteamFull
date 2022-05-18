package game.scenes.time.edison{	
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.TransportGroup;
	import engine.managers.SoundManager;
	
	import game.components.motion.FollowTarget;
	import game.components.scene.SceneInteraction;
	import game.components.ui.ToolTip;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.time.TimeEvents;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.edison.components.MovingCar;
	import game.scenes.time.edison.systems.MovingCarSystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Smoke;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class Edison extends PlatformerGameScene
	{
		public function Edison()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/edison/";
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
			
			movingCarSystem = new MovingCarSystem();
			movingCarSystem._reachedEnd.addOnce(handleStopCar);
			
			super.addSystem(movingCarSystem, SystemPriorities.update);
			
			placeTimeDeviceButton();
			
			setupMovingCar();
			_events = TimeEvents(events);
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function setupMovingCar():void
		{
			motor = this._hitContainer["benz"]["carBench"]["motor"];
			motor.gotoAndStop(1);
			
			var motorBtn:MovieClip = this._hitContainer["motorBtn"];
			var motorBtnEntity:Entity = ButtonCreator.createButtonEntity(motorBtn, this, moveCar, null, null, ToolTipType.CLICK, true, true);
			ToolTipCreator.addToEntity(motorBtnEntity);
			
			var benz:MovieClip = this._hitContainer["benz"];
			car = EntityUtils.createMovingEntity(this, benz);
			var carMotion:Motion = new Motion();
			carMotion.minVelocity = new Point(0, 0);
			carMotion.maxVelocity = MAX_VELOCITY;
			car.add(carMotion);
			
			var wheel1:MovieClip = this._hitContainer["benz"]["bigWheel"];
			var bigWheel:Entity = EntityUtils.createMovingEntity(this, wheel1);
			bigWheel.add(new Motion());
			
			var wheel2:MovieClip = this._hitContainer["benz"]["smallWheel"];
			var smallWheel:Entity = EntityUtils.createMovingEntity(this, wheel2);
			smallWheel.add(new Motion());
			
			var seat:Entity = super.getEntityById("carSeat");
			var follow:FollowTarget = new FollowTarget();
			follow.target = car.get(Spatial);
			follow.offset = new Point(seat.get(Spatial).x - car.get(Spatial).x, seat.get(Spatial).y - car.get(Spatial).y);
			seat.add(follow);
			
			var top:Entity = super.getEntityById("carTop");
			var target:FollowTarget = new FollowTarget();
			target.target = car.get(Spatial);
			target.offset = new Point(top.get(Spatial).x - car.get(Spatial).x, top.get(Spatial).y - car.get(Spatial).y);
			top.add(target);
			
			movingCar = new MovingCar();
			movingCar.bigWheel = bigWheel;
			movingCar.smallWheel = smallWheel;
			movingCar.seatPlatform = seat;
			movingCar.topPlatform = top;
			movingCar.stopX = STOP_X;
			movingCar.accel = ACCEL;
			movingCar.state = "stopped";
			car.add(movingCar);
		}
		
		private function handleStopCar():void
		{
			// clean up the car
			movingAudio.stopAll(SoundType.EFFECTS);
			movingAudio.play(SoundManager.EFFECTS_PATH + "tractor_stop_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
			motor.gotoAndStop(1);
			emitter.counter.stop();
		}
		
		private function moveCar(entity:Entity):void
		{
			ToolTipCreator.removeFromEntity(entity);
			super.removeEntity(entity);
			motor.play();
			
			movingCar.state = "moving";
			var motorEntity:Entity = EntityUtils.createSpatialEntity(this, motor);
			var followTarget:Spatial = motorEntity.get(Spatial);
			
			// Create positional audio for the car
			movingAudio = new Audio();
			var soundEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["audioHolder"]);
			soundEntity.add(movingAudio);
			soundEntity.add(new AudioRange(1500, 0, 1, Sine.easeIn));
			movingAudio.play(SoundManager.EFFECTS_PATH + "tractor_start_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
			movingAudio.play(SoundManager.EFFECTS_PATH + "tractor_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
			soundEntity.add(new FollowTarget(car.get(Spatial), 1));
			
			emitter = new Smoke();
			emitter.init(followTarget);
			var group:Group = OwningGroup(motorEntity.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(motorEntity.get(Display)).container;
			var emitterEntity:Entity = EmitterCreator.create(group, container, emitter, -45, 15, motorEntity, "smoke", followTarget);
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
		
		private var car:Entity;
		private var movingAudio:Audio;	
		private var timeButton:Entity;
		private var _events:TimeEvents;
		private var movingCar:MovingCar;
		private var motor:MovieClip;
		private var emitter:Smoke;
		private var movingCarSystem:MovingCarSystem;
		private static var MAX_VELOCITY:Point = new Point(200, 0);
		private static var STOP_X:Number = 1900;
		private static var ACCEL:Number = 100;
		
	}
}