package game.scenes.time.renaissance {
	
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.TransportGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.motion.MotionTarget;
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.time.TimeEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.renaissance.components.HitPulley;
	import game.scenes.time.renaissance.systems.HitPulleySystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.WaterFall;
	import game.scenes.time.shared.emitters.WaterSteam;
	import game.systems.SystemPriorities;
	import game.systems.motion.MotionTargetSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Renaissance extends PlatformerGameScene
	{
		private var timeEvents:TimeEvents;
		
		private static var PULLEY_SPEED:Number = 100;
		private static var LIFT_MAX_VELOCITY:Number = 200;
		
		private var _transportGroup:TransportGroup;
		
		public function Renaissance()
		{
			super();
		}
		
		override public function destroy():void
		{
			timeButton = null;
			_particleTimedEvent.stop();
			_particleTimedEvent = null;
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/renaissance/";
			//super.showHits  = true;
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
			timeEvents = super.events as TimeEvents;
			addSystem(new HitPulleySystem(), SystemPriorities.move);
			addSystem(new MotionTargetSystem());
			
			placeTimeDeviceButton();
			setupPulleys();			
			setupWaterFall();
			setupWaterfallZone();
			
			if( this.shellApi.checkEvent( timeEvents.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
	
		// Only play the waterfall emitters when we are near it
		private function setupWaterfallZone():void
		{
			var hit:Entity = this.getEntityById("zone1");
			var zone:Zone = hit.get(Zone);
			zone.pointHit = true;
			zone.entered.addOnce(Command.create(waterfallZoneHit, true, zone));
		}
		
		private function waterfallZoneHit(zoneId:String, characterId:String, entered:Boolean, zone:Zone):void
		{
			if(_particleTimedEvent != null)
			{
				if(_particleTimedEvent.running)
				{
					_particleTimedEvent.stop();
					_particleTimedEvent = null;
				}
			}
			
			var waterFallEntity:Entity = super.getEntityById("fallsbubbles");
			var waterFallEmitter:Emitter = waterFallEntity.get(Emitter);
			var steamEntity:Entity = super.getEntityById("fallssteam");
			var steamEmitter:Emitter = steamEntity.get(Emitter);
			
			if(entered)
			{
				waterFallEmitter.emitter.resume();
				steamEmitter.emitter.resume();
				zone.exitted.addOnce(Command.create(waterfallZoneHit, false, zone));
			}
			else
			{
				waterFallEmitter.emitter.pause();
				steamEmitter.emitter.pause();
				zone.entered.addOnce(Command.create(waterfallZoneHit, true, zone));
			}
		}
		
		private function setupWaterFall():void
		{	
			var clip:MovieClip = this._hitContainer[ "Falls" ];
			var frontclips:Sprite = super.convertToBitmapSprite(this._hitContainer[ "fallsBlockers" ]).sprite;
			
			var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
			var display:Display = entity.get( Display );
			
			// falling drops
			var waterFall:WaterFall = new WaterFall();	
			waterFall.init( new RectangleZone( clip.x, clip.y, clip.x + clip.width, clip.y + clip.height ));
			EmitterCreator.create( this, display.container, waterFall, 0, 0, entity, "fallsbubbles");
			
			// steam
			var steam:WaterSteam = new WaterSteam();
			steam.init( new RectangleZone( clip.x, clip.y, clip.x + clip.width, clip.y + clip.height ), 10, 14 );
			EmitterCreator.create( this, display.container, steam, 0, 10, entity, "fallssteam");
			
			// Create timer to wait until waterfall is ready to be paused
			_particleTimedEvent = new TimedEvent(60, 1, emitterWaitDone);
			_particleTimedEvent.countByUpdate = true;
			SceneUtil.addTimedEvent(this, _particleTimedEvent);
		
			// put stuff in front of waterfall			
			DisplayUtils.moveToTop( frontclips );
			DisplayUtils.moveToTop( EntityUtils.getDisplayObject( player ));			
			// sounds
			var audio:Audio = new Audio();			
			var soundEnt:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "fallsSound" ]);
			soundEnt.add( audio );
			soundEnt.add( new AudioRange( 2000, 0, 1.2, Sine.easeIn ));
			audio.play( SoundManager.EFFECTS_PATH + "waterfall.mp3", true, [ SoundModifier.POSITION, SoundModifier.FADE ]);
		}
		
		private function emitterWaitDone():void
		{
			var waterFallEntity:Entity = super.getEntityById("fallsbubbles");
			var waterFallEmitter:Emitter = waterFallEntity.get(Emitter);
			var steamEntity:Entity = super.getEntityById("fallssteam");
			var steamEmitter:Emitter = steamEntity.get(Emitter);
			
			waterFallEmitter.emitter.pause();
			steamEmitter.emitter.pause();
		}
		
		private function setupPulleys():void
		{
			var hitPulley:HitPulley;
			var entity:Entity;
			var target:MotionTarget;
			var id:Id;
			var number:int;
			
			for( number = 1; number < 4; number ++)
			{
				entity = super.getEntityById( "pulleyHit" + number );
				hitPulley = new HitPulley();
				hitPulley.acceleration = PULLEY_SPEED;
				
				switch( number )
				{
					case 1:
						// moves based on node state
						id = new Id( "flat" );
						entity.name = "flat";
						hitPulley.pointOne = new Point(2050, 1923);
						hitPulley.pointTwo = new Point(1690, 1923);
						break;
					case 2:
						// right side, moves left
						id = new Id( "left" );
						entity.name = "left";
						hitPulley.pointOne = new Point(2295.75, 1230.60);
						hitPulley.pointTwo = new Point(2396, 1624);
						break;
					case 3:
						// left side, moves right
						id = new Id( "right" );
						entity.name = "right";
						hitPulley.pointOne = new Point(1976, 1502);
						hitPulley.pointTwo = new Point(2226, 1218);
						break;
				}
				
				target = new MotionTarget();
				target.useSpatial = false;
				
				entity.add( hitPulley ).add( id ).add(target);
			}	
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(timeEvents.TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		
		private var timeButton:Entity;
		private var _particleTimedEvent:TimedEvent;
	}
}





















