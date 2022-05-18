package game.scenes.time.graff{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.group.TransportGroup;
	
	import game.components.motion.Threshold;
	import game.data.WaveMotionData;
	import game.scenes.time.TimeEvents;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.graff.components.MovingHazard;
	import game.scenes.time.graff.systems.MovingHazardSystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.MotionUtils;
	
	public class Graff extends PlatformerGameScene
	{
		public function Graff()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/graff/";
			
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
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			super.addSystem( new WaveMotionSystem() );
			
			_events = super.events as TimeEvents;
						
			if(super.shellApi.checkItemUsedUp(_events.DECLARATION))
			{
				hideNpc();
			}
			setupPorcupines();
			placeTimeDeviceButton();
			
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function hideNpc():void
		{
			var char:Entity = super.getEntityById("char1");
			removeEntity(char);
		}
		
		private function setupPorcupines():void
		{
			MovingHazardSystem(addSystem(new MovingHazardSystem(),SystemPriorities.update));			
			porcupineHit = super.getEntityById( "porcupineHit1" );	
			var movingHaz:MovingHazard = new MovingHazard();
			movingHaz.visible = super.getEntityById( "porc1" );
			//movingHaz.motion = new Motion();
			//movingHaz.motion.velocity = new Point( 110, 0 );
			//movingHaz.threshHold = new Threshold( "x", ">" );			
			movingHaz.leftThreshHold = 1700;
			movingHaz.rightThreshHold = 2400;
			porcupineHit.add(new Motion());
			porcupineHit.get(Motion).velocity = new Point( 110, 0 );
			porcupineHit.add(new Threshold( "x", ">" ));
			porcupineHit.add(movingHaz);
			MotionUtils.addWaveMotion(porcupineHit,new WaveMotionData( "y", 1.5, 50 ),this);
			//////
			porcupineHit2 = super.getEntityById( "porcupineHit2" );	
			var movingHaz2:MovingHazard = new MovingHazard();
			movingHaz2.visible = super.getEntityById( "porc2" );			
			movingHaz2.leftThreshHold = 2900;
			movingHaz2.rightThreshHold = 3600;
			porcupineHit2.add(new Motion());
			porcupineHit2.get(Motion).velocity = new Point( 110, 0 );
			porcupineHit2.add(new Threshold( "x", ">" ));
			porcupineHit2.add(movingHaz2);
			MotionUtils.addWaveMotion(porcupineHit2,new WaveMotionData( "y", 1.5, 50 ),this);
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(_events).TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		
		private var timeButton:Entity;
		private var porcupineHit:Entity;
		private var porcupineHit2:Entity;
		private var _events:TimeEvents;
	}
}