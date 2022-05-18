package game.scenes.time.everest3{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.scenes.time.TimeEvents;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.particles.emitter.Snow;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.everest3.components.FallingIcicle;
	import game.scenes.time.everest3.systems.FallingIcicleSystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	
	import org.flintparticles.common.counters.Random;
	
	public class Everest3 extends PlatformerGameScene
	{
		public function Everest3()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/everest3/";
			
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
			
			super.addSystem(new FallingIcicleSystem(), SystemPriorities.move);
			
			setupFallingIcicle();
			
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_HIGH)
				createSnowEmitter();
			
			
			placeTimeDeviceButton();
			
			var fallDoor:Entity = super.getEntityById("fallDoor");
			Sleep(fallDoor.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(fallDoor.get(Sleep)).sleeping = false;
		}
		
		private function createSnowEmitter():void
		{			
			var snow:Snow = new Snow();
			snow.init(new Random(20, 25), new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight));
			EmitterCreator.createSceneWide(this, snow);
		}
		
		private function setupFallingIcicle():void
		{
			var totalSnowBalls:int = 5;
			var icicleDisplay:MovieClip = this._hitContainer["fallingIcicle"];
			this._hitContainer.setChildIndex(icicleDisplay, this._hitContainer.numChildren - 1);

			var snowballArray:Array = new Array();
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = .75;
			hazardHitData.knockBackVelocity = new Point(1500, 400);
			hazardHitData.velocityByHitAngle = false;
			var hitCreator:HitCreator = new HitCreator();
			var icicle:Entity = hitCreator.createHit(icicleDisplay, HitType.HAZARD, hazardHitData, this, false);
			var motion:Motion = new Motion();
			icicle.add(motion);
			icicle.remove(Sleep);
			
			hitCreator.addAudioToHit(icicle, "icicle_fall_hit_01.mp3");
			
			for(var i:int = 1; i <= totalSnowBalls; i++)
			{
				var snowball:MovieClip = this._hitContainer["fallingIcicle"]["icicleSnow" + i];
				var snowballEntity:Entity = EntityUtils.createSpatialEntity(this, snowball, icicleDisplay);
				snowballArray.push(snowballEntity);
			}			
			
			var fallingIcicle:FallingIcicle = new FallingIcicle();
			//fallingIcicle.hit = hit;
			fallingIcicle.state = "stopped";
			fallingIcicle.velocity = 650;
			fallingIcicle.range = new Point(1180, 2200);
			fallingIcicle.waitTime = 1.2;
			fallingIcicle.snowballs = snowballArray;
			icicle.add(fallingIcicle);
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
	}
}