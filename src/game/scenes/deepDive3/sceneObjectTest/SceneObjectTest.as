package game.scenes.deepDive3.sceneObjectTest
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.CircularCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ButtonCreator;
	import game.scenes.deepDive1.shared.SubScene;
	import game.systems.hit.SceneObjectHitCircleSystem;
	import game.util.TimelineUtils;
	
	public class SceneObjectTest extends SubScene
	{
		public function SceneObjectTest()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive3/sceneObjectTest/";
			super.initialScale = .75;
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
			
			setupButtons();
			
			_sceneObjectCreator = new SceneObjectCreator();
			
			super.addSystem(new SceneObjectHitCircleSystem());
			
			var sceneObjectCollider:SceneObjectCollider = new SceneObjectCollider();
			
			super.shellApi.player.add(sceneObjectCollider);
			super.shellApi.player.add(new CircularCollider());
			super.shellApi.player.add(new Mass(100));
			super.shellApi.player.add(new ValidHit("cave", "shipBlocker"));
			
			TimelineUtils.convertClip(super.hitContainer["target"], this);
			
			configureZones();
		}
		
		private function createBall(targetX:Number, targetY:Number):void
		{
			var motion:Motion;
			var sceneObjectMotion:SceneObjectMotion;
			var entity:Entity = super.getEntityById("ball");
			
			if(entity != null)
			{
				motion = entity.get(Motion);
				motion.zeroMotion();
				motion.x = targetX;
				motion.y = targetY;
			}
			else
			{
				sceneObjectMotion = new SceneObjectMotion();
				sceneObjectMotion.rotateByPlatform = false;
				sceneObjectMotion.rotateByVelocity = true;
				sceneObjectMotion.platformFriction = 0;
				sceneObjectMotion.applyGravity = false;
				
				motion = new Motion();
				motion.friction 	= new Point(200, 200);
				motion.maxVelocity 	= new Point(500, 500);
				motion.minVelocity 	= new Point(0, 0);
				motion.acceleration = new Point(0, 0);
				motion.restVelocity = 100;
				
				entity = _sceneObjectCreator.create("scenes/examples/standaloneMotion/ball3.swf",
					.9,
					super.hitContainer,
					targetX, targetY,
					motion,
					sceneObjectMotion,
					super.sceneData.bounds,
					this,
					objectLoaded,
					[RadialCollider]);
				
				var radialCollider:RadialCollider = entity.get(RadialCollider);
				radialCollider.rebound = .5;  // add additional rebound
				
				var bitmapCollider:BitmapCollider = entity.get(BitmapCollider);
				bitmapCollider.useEdge = true;
				
				entity.add(new SceneObjectHit());
				entity.add(new Id("ball"));
				entity.add(new ZoneCollider());
				entity.add(new Mass(50));
				entity.add(new SceneCollider());  // for hits with air vent if needed.
			}
			
			entity.add(new ValidHit("cave", "ballBlocker", "airUp", "airRight", "airDown"));
		}
				
		// additional setup can occur after asset is loaded if needed.
		private function objectLoaded(entity:Entity):void
		{
			trace("object loaded!");
		}
		
		private function setupButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 12, 0xD5E1FF);
			
			ButtonCreator.createButtonEntity( MovieClip(super.hitContainer).ballButton, this, buttonClicked );
			ButtonCreator.addLabel( MovieClip(super.hitContainer).ballButton, "Create Ball", labelFormat, ButtonCreator.ORIENT_CENTERED);
		}
		
		private function buttonClicked(button:Entity):void
		{
			createBall(450, 1840);
			var entity:Entity = super.getEntityById("ball");
			var motion:Motion = entity.get(Motion);
			motion.velocity.y = -400;
		}
		
		private function configureZones():void
		{
			super._hitContainer["light1"].gotoAndStop("off");
			
			var entity:Entity = super.getEntityById("zone1");
			var zone:Zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(handleZoneEntered);
			zone.exitted.add(handleZoneExitted);
			zone.inside.add(handleZoneInside);
		}
		
		private function handleZoneEntered(zoneId:String, entityId:String):void
		{			
			if(entityId == "ball")
			{
				super._hitContainer["light1"].gotoAndStop("on");
			}	
		}
		
		private function handleZoneExitted(zoneId:String, entityId:String):void
		{
			if(entityId == "ball")
			{
				super._hitContainer["light1"].gotoAndStop("off");
			}	
		}
		
		private function handleZoneInside(zoneId:String, entityId:String):void
		{
			if(entityId == "ball")
			{
				super._hitContainer["light1"].label.text = Number(super._hitContainer["light1"].label.text) + 1;
			}
		}
		
		private var _sceneObjectCreator:SceneObjectCreator;
	}
}