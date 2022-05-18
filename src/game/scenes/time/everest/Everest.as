package game.scenes.time.everest{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.group.TransportGroup;
	
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.scenes.time.TimeEvents;
	import game.particles.emitter.Snow;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	
	import org.flintparticles.common.counters.Random;
	
	public class Everest extends PlatformerGameScene
	{
		public function Everest()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/everest/";
			
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
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH)
				createSnowEmitter();
			
			configureSnowFall();
			placeTimeDeviceButton();
			_events = TimeEvents(events);
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function createSnowEmitter():void
		{			
			var snow:Snow = new Snow();
			snow.init(new Random(20, 25), new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight));
			EmitterCreator.createSceneWide(this, snow);
		}
		
		private function configureSnowFall():void
		{
			var snowEntity:Entity = super.getEntityById("zone1");
			Display(snowEntity.get(Display)).visible = true;
			var zone:Zone = snowEntity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(snowHit);
		}
		
		private function snowHit(zoneId:String, characterId:String):void
		{
			var zone1:MovieClip = this._hitContainer["zone1"];
			for(var i:int = 1; i <= 8; i++)
			{
				var movieClip:MovieClip = this._hitContainer["zone1"]["s" + i];
				var entity:Entity = EntityUtils.createMovingEntity(this, movieClip, zone1);
				var motion:Motion = entity.get(Motion);
				
				motion.velocity.y = Math.random() * 400 + 600;
			}
			shellApi.triggerEvent("snow_crumble");
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
		private var timeButton:Entity;
		private var _events:TimeEvents;
	}
}