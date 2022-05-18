package game.scenes.prison.messHall.foodFight
{	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.data.display.SharedBitmapData;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Hazard;
	import game.components.hit.ValidHit;
	import game.data.TimedEvent;
	import game.managers.EntityPool;
	import game.systems.SystemPriorities;
	import game.systems.hit.HazardHitSystem;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class FoodFightGroup extends Group
	{
		public static const GROUP_ID:String = "foodFightGroup";
		
		private var _container:DisplayObjectContainer;
		
		public var foodReady:Signal;
		
		private var foodPool:EntityPool;
		private const poolsize:int = 10;
		
		private var spawmDelay:Number = 0.3;
		private var shotTimer:TimedEvent;
		
		private var spawnX:Number = 2400;
		private var spawnYMin:Number = 512;
		private var spawnYMax:Number = 1050;
		
		private var startedFoodFight:Boolean = false;
		private var hazardsEnabled:Boolean = true;
		private var foodAsset:MovieClip;
		
		private var ignoredHits:Array;
		
		public function foodFightRunning():Boolean
		{
			return startedFoodFight;
		}
		
		public function FoodFightGroup(container:DisplayObjectContainer, spawnX:Number = 2400, spawnYMin:Number = 512, spawnYMax:Number = 1050, ingoredHits:Array = null)
		{
			_container = container;
			this.id = GROUP_ID;
			foodReady = new Signal();
			this.ignoredHits = ingoredHits;
		}
		
		override public function added():void
		{
			shellApi = parent.shellApi;
			
			super.addSystem(new HazardHitSystem(),SystemPriorities.update);
			
			shellApi.loadFile(shellApi.assetPrefix+"scenes/prison/messHall/potato.swf",setupPotatos);
			
			foodReady.dispatch();
			super.added();
		}
		
		private function setupPotatos(asset:MovieClip):void
		{
			foodPool = new EntityPool();
			foodPool.setSize("food",poolsize);
			foodAsset = asset["flyingPotato"];
			var bitData:SharedBitmapData;
			bitData = BitmapUtils.createBitmapData(foodAsset, 1);
			for (var i:int = 0; i < poolsize; i++) 
			{
				var bitmapedAsset:Sprite = BitmapUtils.createBitmapSprite(foodAsset, 1, null, true, 0, bitData);
				var food:Entity = EntityUtils.createMovingEntity(this,bitmapedAsset, _container);
				food.add(new Id("food"+i));
				food.add(new WallCollider());
				food.add(new BitmapCollider());
				food.add(new CurrentHit());
				EntityUtils.position(food, 240 + i*14, 1200);
				//add sys components for hazard and flying tater
				makeHazard(food);
				var comp:FlyingFood = new FlyingFood();
				food.add(comp);
				food.add(new Sleep(false,true));
				Display(food.get(Display)).visible = false;
				var validHits:ValidHit = new ValidHit();
				for (var j:int = 0; j < ignoredHits.length; j++) 
				{
					validHits.setHitValidState(ignoredHits[j], true);
					validHits.inverse = true;
				}
				food.add(validHits);
				// put to pool
				foodPool.release(food,"food");
			}
		}
		
		public function startFoodFight(hazardsEnabled:Boolean = true):void
		{
			// begin firing food blobs from right side
			this.hazardsEnabled = hazardsEnabled;
			
			if(!startedFoodFight){
				startedFoodFight = true;
				shotTimer = SceneUtil.addTimedEvent(this, new TimedEvent(spawmDelay,1,firePotato),"food_timer");
			}
			else{
				// update active food fight
				//firePotato();
			}		
		}
		
		public function stopFight(...p):void
		{
			if(shotTimer){
				shotTimer.stop();
			}
			var pool:Vector.<Entity> = foodPool.getPool("food"); 
			for (var i:int = 0; i < pool.length; i++) 
			{
				pool[i].get(FlyingFood).flying = false;
				killPotato(pool[i]);
			}
			
			startedFoodFight = false;
		}
		
		private function firePotato(...p):void
		{
			// fire tater from pool at random offscreen location
			if(startedFoodFight){
				var tater:Entity = foodPool.request("food");
				if(tater){
					trace("tater requested::Recieved: " + tater.get(Id).id)
					var target:Point = new Point();
					var velocity:Point = new Point();
					var comp:FlyingFood = tater.get(FlyingFood);
					var motion:Motion = tater.get(Motion);
					if(hazardsEnabled){
						makeHazard(tater);
					}
					comp.flying = true;
					Display(tater.get(Display)).visible = true;
					target.x = spawnX;
					target.y = GeomUtils.randomInRange(spawnYMin,spawnYMax);
					EntityUtils.position(tater,target.x,target.y);
					motion.velocity.x = comp.flySpeed;
					motion.acceleration.y = comp.gravity;
					motion.rotationVelocity = GeomUtils.randomInRange(-60,60);
					if(comp.killTimer){
						comp.killTimer.stop();
					}
					comp.killTimer = SceneUtil.addTimedEvent(this, new TimedEvent(comp.lifetime,1,Command.create(killPotato,tater)),"kill");
				}else{
					trace("tater requested::Recieved: FAIL")
				}
				if(shotTimer){
					shotTimer.stop();
				}
				shotTimer = SceneUtil.addTimedEvent(this, new TimedEvent(spawmDelay,1,firePotato),"food_timer");
			}
		}
		
		private function killPotato(tater:Entity, hitTarget:Entity = null):void
		{
			foodPool.release(tater,"food");
			tater.get(FlyingFood).flying = false;
			Display(tater.get(Display)).visible = false;
			Motion(tater.get(Motion)).zeroMotion();
			Motion(tater.get(Motion)).zeroAcceleration();
			tater.remove(Hazard);
			EntityUtils.position(tater, -200, -200);
		}
		
		public function throwSingleFood(thrower:Entity, targetent:Entity, faceRight:Boolean = true):void
		{
			// throw single food chuck from target character
			var tater:Entity = foodPool.request("food");
			if(tater){
				var start:Point = EntityUtils.getPosition(thrower);
				var target:Point = EntityUtils.getPosition(targetent);
				var comp:FlyingFood = tater.get(FlyingFood);
				
				EntityUtils.position(tater,start.x,start.y);
				Display(tater.get(Display)).visible = true;
				
				TweenUtils.entityTo(tater, Spatial, 0.3,{x:target.x, y:target.y, onComplete:Command.create(killPotato,tater,targetent)});
				
				if(comp.killTimer){
					comp.killTimer.stop();
				}
			}
		}
		
		private function makeHazard(entity:Entity):void
		{			
			var hit:Hazard = new Hazard();
			
			hit.velocity = new Point(600,-200);
			hit.coolDown = 0.5;
			hit.interval = 0.1;
			hit.velocityByHitAngle = true;
			hit.slipThrough = false;
			
			// bounding box overlap test is more efficient for projectiles.
			hit.boundingBoxOverlapHitTest = true;
			
			entity.add(hit);
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}