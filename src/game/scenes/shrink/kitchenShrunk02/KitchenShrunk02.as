package game.scenes.shrink.kitchenShrunk02
{
	import com.greensock.easing.Quad;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.ValidHit;
	import game.components.hit.Wall;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.Threshold;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.shrink.kitchenShrunk01.Particles.Fog;
	import game.scenes.shrink.kitchenShrunk02.catFoodSystem.CatFood;
	import game.scenes.shrink.kitchenShrunk02.catFoodSystem.CatFoodSystem;
	import game.scenes.shrink.kitchenShrunk02.particles.Kibbles;
	import game.scenes.shrink.shared.Systems.TipSystem.Tip;
	import game.scenes.shrink.shared.Systems.TipSystem.TipSystem;
	import game.scenes.shrink.shared.groups.GrapeGroup;
	import game.scenes.shrink.shared.groups.ShrinkScene;
	import game.scenes.survival1.cave.particles.CaveDrip;
	import game.scenes.survival1.cave.particles.CaveSplash;
	import game.scenes.virusHunter.joesCondo.creators.RollingObjectCreator;
	import game.scenes.virusHunter.joesCondo.systems.RollingObjectSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class KitchenShrunk02 extends ShrinkScene
	{
		public function KitchenShrunk02()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/kitchenShrunk02/";
			
			super.init(container);
		}
		
		override public function destroy():void
		{
			var oilDrips:Entity = getEntityById( "oilDrips" );
			if( oilDrips )
			{
				CaveDrip( oilDrips.get( Emitter ).emitter ).destroy();
			}
			for(var i:int = 0; i < catFoodData.length; i++)
			{
				catFoodData[i].dispose();
			}
			catFoodData = null;
			catFoodAssets = null;
			rollerCreator = null;
			_sceneObjectCreator = null;
			super.destroy();
		}
		
		private const ROLLED_PIN_POS:Point = new Point(425, 1150);
		private const MOVED_KETTLE_POS:Number = 845;
		
		private const KIBBLE_SPAWN_POINT:Point = new Point(1900,1190);
		
		private const MAX_KIBBLES:int = 10;
		private var kibs:uint;
		
		
		private var steamMover:Mover;
		
		private var catFoodAssets:Array = 
			[
				"o_kibble.swf", 
				"x_kibble.swf", 
				"tri_kibble.swf"
			];
		
		private var catFoodData:Array;
		
		private var catFood:Entity;
		
		private var rollerCreator:RollingObjectCreator;
		private var _sceneObjectCreator:SceneObjectCreator;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_sceneObjectCreator = new SceneObjectCreator();
			addSystem(new SceneObjectHitRectSystem());
			addSystem(new SceneObjectMotionSystem(), SystemPriorities.moveComplete);
			addSystem(new ThresholdSystem());
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			setUpRollingPin();
			setUpKettle();
			setUpCatDish();
			setUpOil();
			setUpKitchenTable();
			setUpRollingKibbles();
		}
		
		override public function setUpGrape():void
		{
			grapeGroup = addChildGroup(new GrapeGroup(_hitContainer, this, new Point(2935, 1240))) as GrapeGroup;
		}
		
		private function setUpRollingKibbles():void
		{
			addSystem( new RollingObjectSystem());
			addSystem( new ZoneHitSystem());
			addSystem( new RollingObjectSystem());
			var clip:MovieClip;
			rollerCreator = new RollingObjectCreator(_hitContainer, this);
			for(var i:int = 1; i <= 4; i++)
			{
				clip = _hitContainer["kib"+i];
				createRollingKibble(clip);
			}
		}
		
		private function createRollingKibble(disp:DisplayObjectContainer):Entity
		{
			var entity:Entity = rollerCreator.createRoller(disp);
			Edge(entity.get(Edge)).unscaled.bottom *= .5;
			return entity;
		}
		
		private var oilMotion:Motion;
		
		private function setUpCatDish():void
		{
			var clip:MovieClip = _hitContainer["catDish"];
			BitmapUtils.convertContainer(clip);
			var foodContainer:MovieClip = clip["foodClip"];
			
			oilMotion = new Motion();
			oilMotion.maxVelocity 	= new Point(1000, 1000);
			oilMotion.minVelocity 	= new Point(0, 0);
			oilMotion.restVelocity = 100;
			oilMotion.friction = new Point(100, 0);
			var catDish:Entity = _sceneObjectCreator.createBox(clip, 0, _hitContainer, NaN, NaN, oilMotion, null, sceneData.bounds, this, null, null, 500, false);
			catDish.add(new Platform()).add(new Id(clip.name));
			Platform(catDish.get(Platform)).top = true;
			MotionUtils.zeroMotion(catDish);
			
			SceneObjectHit(catDish.get(SceneObjectHit)).anchored = !shellApi.checkEvent(shrink.TIPPED_OIL);
			
			catFoodData = [];
			
			for(var i:int = 0; i < catFoodAssets.length; i++)
			{
				var asset:MovieClip = super.getAsset(catFoodAssets[i]);
				catFoodData.push(BitmapUtils.createBitmapData(asset));
			}
			
			catFood = EntityUtils.createSpatialEntity(this, foodContainer, clip).add(new CatFood(catFoodData));
			
			addSystem(new CatFoodSystem());
			
			setUpCatFood();
		}
		
		private function setUpCatFood():void
		{
			var collider:Entity = getEntityById("catFood");
			collider.add(new HitTest(spillKibbles))
			
			addSystem(new HitTestSystem());
			
			var kibbles:Kibbles = new Kibbles();
			kibbles.init(catFoodData);
			
			var kibbleEmitter:Entity = EmitterCreator.create(this, _hitContainer, kibbles,0, 0, null,"kibbles",null,false);
			var kibblePosition:Spatial = kibbleEmitter.get(Spatial);
			kibblePosition.x = KIBBLE_SPAWN_POINT.x;
			kibblePosition.y = KIBBLE_SPAWN_POINT.y;
			
			kibs = 0;
		}
		
		private function spillKibbles(bag:Entity, hitId:String):void
		{
			var kibbles:Emitter = getEntityById("kibbles").get(Emitter);
			kibbles.start = true;
			kibbles.emitter.counter.resume();
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1,stopOverFlow));
			SceneUtil.setCameraPoint(this, KIBBLE_SPAWN_POINT.x, KIBBLE_SPAWN_POINT.y);
			SceneUtil.lockInput(this);
			
			var stagePos:Point = DisplayUtils.localToLocal(_hitContainer, _hitContainer.stage);
			
			var dish:Entity = getEntityById("catDish");
			var spatial:Spatial = dish.get(Spatial);
			
			if(spatial.x < 2000 && spatial.x > 1800)
				CatFood(catFood.get(CatFood)).filling = true;
			else
			{
				var spawnZone:RectangleZone = new RectangleZone(1850, 1650, 1950, 1700);
				var point:Point;
				var data:BitmapData;
				var bounds:Rectangle;
				var entity:Entity;
				var sprite:Sprite;
				for(var i:int = 0; i < MAX_KIBBLES / 2; i ++)
				{
					point = spawnZone.getLocation();
					data = catFoodData[int(Math.random() * catFoodData.length)];
					bounds = data.rect;
					bounds.x -= bounds.width / 2;
					bounds.y -= bounds.height / 2;
					sprite = BitmapUtils.createBitmapSprite(new MovieClip(), 1, bounds, true, 0, data);
					sprite.x = point.x;
					sprite.y = point.y;
					_hitContainer.addChild(sprite);
					if(kibs < MAX_KIBBLES)
					{
						trace(kibs);
						entity = createRollingKibble(sprite);
						entity.add(new Id("spill_kib"+kibs));
					}
					else
						poolKibbles(sprite);
					kibs++;
				}
			}
		}
		
		private function poolKibbles(sprite:Sprite):void
		{
			//kibs%MAX_KIBBLES cycles through all the kibbles from oldest to newest
			var kibble:Entity = getEntityById("spill_kib"+kibs%MAX_KIBBLES);
			Display(kibble.get(Display)).swapDisplayObject(sprite);
			var spatial:Spatial = kibble.get(Spatial);
			spatial.x = sprite.x;
			spatial.y = sprite.y;
		}
		
		private function stopOverFlow():void
		{
			var kibbles:Emitter = getEntityById("kibbles").get(Emitter);
			kibbles.emitter.counter.stop();
			SceneUtil.lockInput(this,false);
			SceneUtil.setCameraTarget(this, player);
		}
		
		private function setUpKitchenTable():void
		{
			var paper:Entity = getEntityById("blank_paper");
			if(paper != null)
			{
				Interaction(paper.get(Interaction)).click.add(commentOnPaper);
			}
			
			if(!shellApi.checkEvent(shrink.GRAPE_DROPPED))
			{
				var table:Entity = getEntityById("table");
				table.add(new HitTest(dropGrape, true));
				addSystem(new HitTestSystem());
			}
		}
		
		private function commentOnPaper(...args):void
		{
			var spatial:Spatial = player.get(Spatial);
			CharUtils.moveToTarget(player, spatial.x, spatial.y);
			if(spatial.y > 1300)
				Dialog(player.get(Dialog)).sayById("clues");
		}
		
		private function dropGrape(table:Entity, hitId:String):void
		{
			SceneUtil.lockInput(this);
			HitTest(table.get(HitTest)).onEnter.add(grapeDropped);
			var grape:Entity =  getEntityById("grape");
			Motion(grape.get(Motion)).acceleration.y = MotionUtils.GRAVITY;
			SceneUtil.setCameraTarget(this, grape);
		}
		
		private function grapeDropped(table:Entity, hitId:String):void
		{
			if(hitId == "grape")
			{
				table.remove(HitTest);
				shellApi.completeEvent(shrink.GRAPE_DROPPED);
				SceneUtil.lockInput(this, false);
				SceneUtil.setCameraTarget(this, player);
			}
		}
		
		private function setUpOil():void
		{
			var clip:MovieClip = _hitContainer["oilBottle"];
			var oil:Entity = EntityUtils.createMovingEntity(this,clip,_hitContainer);
			
			clip = _hitContainer["oilSpill"];
			var spill:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			spill.add(new Id("oilSpill"));
			
			clip = _hitContainer["oilHit"];
			
			if(shellApi.checkEvent(shrink.TIPPED_OIL))
			{
				_hitContainer.removeChild(clip);
				Spatial(oil.get(Spatial)).rotation = 90;
				tippedOil(oil);
			}
			else
			{
				var hit:Entity = _sceneObjectCreator.createBox(clip, 0, _hitContainer, NaN,NaN,null, null,sceneData.bounds, this, null, null, 200, false);
				var follow:FollowTarget = new FollowTarget(oil.get(Spatial), 1, false, true);
				follow.offset = new Point(-clip.width / 2, - clip.height / 2);
				hit.add(follow).add(new HitTest()).add(new EntityIdList()).add(new Id(clip.name));
				
				var tip:Tip = new Tip(hit.get(HitTest), this, 30);
				tip.tipped.add(tippedOil);
				
				oil.add(tip)
				
				addSystem(new TipSystem(),SystemPriorities.moveComplete);
				
				Display(spill.get(Display)).visible = false;
			}
		}
		
		private function tippedOil(oil:Entity):void
		{
			var spill:Entity = getEntityById("oilSpill");
			EntityUtils.visible(spill);
			TweenUtils.entityTo(spill, Spatial, 60, {scaleX:10});
			removeEntity(getEntityById("oilHit"));
			oil.remove(Tip);
			shellApi.completeEvent(shrink.TIPPED_OIL);
			var dish:Entity = getEntityById("catDish");
			SceneObjectHit(dish.get(SceneObjectHit)).anchored = false;
			
			var range:AudioRange = new AudioRange(1000, 0, 1, Quad.easeIn);
			var clip:MovieClip = _hitContainer["oilDrips"];
			var zone:Rectangle = clip.getBounds(_hitContainer);
			var rate:Number = .25;
			var particle:CaveDrip = new CaveDrip(zone, rate, 1, 0xC8C764, 0xB1B05C);
			particle.deadParticle.add(playDripAudio);
			var entity:Entity = EmitterCreator.create(this, _hitContainer, particle,0, 0, null, "oilDrips");
			entity.remove(Sleep);
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = zone.x;
			spatial.y = zone.y;
			
			var splash:CaveSplash = new CaveSplash( new Point(zone.x, zone.bottom), 0xC8C764, 0xB1B05C );
			entity = EmitterCreator.create(this, this._hitContainer, splash,0,0, null, "splash", null, false);
			entity.add(new Audio()).add(range).remove(Sleep);
			spatial = entity.get(Spatial);
			spatial.x = zone.x;
			spatial.y = zone.bottom;
			_hitContainer.removeChild(clip);
		}
		
		private function playDripAudio(caveDrip:CaveDrip):void
		{
			var entity:Entity = this.getEntityById("splash");
			
			var emitter:Emitter = entity.get(Emitter);
			emitter.start = true;
			emitter.emitter.start();
			
			Audio(entity.get(Audio)).play(SoundManager.EFFECTS_PATH + "drip_0" + Utils.randInRange(1, 3) + ".mp3", false,SoundModifier.POSITION);
		}
		
		private function setUpKettle():void
		{
			var clip:MovieClip = _hitContainer["teapot"];
			var kettle:Entity = EntityUtils.createSpatialEntity(this, clip,_hitContainer);
			kettle.add(new Id("kettle"));
			var kettleSpatial:Spatial = kettle.get(Spatial);
			
			clip = _hitContainer["kettlePlatform"];
			var kettlePlatform:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			var follow:FollowTarget = new FollowTarget(kettleSpatial);
			follow.offset = new Point(0,-110);
			kettlePlatform.add(follow).add(new Platform());
			Display(kettlePlatform.get(Display)).alpha = 0;
			
			clip = _hitContainer["kettleWall"];
			var kettleWall:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			follow = new FollowTarget(kettleSpatial);
			follow.offset = new Point(0,-50);
			kettleWall.add(follow).add(new Wall());
			Display(kettleWall.get(Display)).alpha = 0;
			
			var steam:Fog = new Fog();
			steam.init(32, 16, 4, 1, -Math.PI / 4, Math.PI / 4 , 200, 0);
			var emitter:Entity = EmitterCreator.create(this, _hitContainer, steam, kettleSpatial.width / 2 + 10, - kettleSpatial.height / 2 + 10, null, "steam", kettleSpatial, shellApi.checkEvent(shrink.ROLLED_PIN));
			
			var steamHit:Entity = getEntityById("steamHit");
			
			steamMover = steamHit.get(Mover);
			
			if(shellApi.checkEvent(shrink.ROLLED_PIN))
				kettleSpatial.x = MOVED_KETTLE_POS;
			else
				steamHit.remove(Mover);
		}
		
		private function setUpRollingPin():void
		{
			var validHits:ValidHit = new ValidHit("dough");
			validHits.inverse = true;
			player.add(validHits);
			
			var clip:MovieClip = _hitContainer["rollingPin"];
			var pin:Entity;
			
			if(!shellApi.checkEvent(shrink.ROLLED_PIN))
			{
				var threshold:Threshold = new Threshold("x", ">");
				threshold.threshold = 175;
				threshold.entered.addOnce(pinRollDownHill);
				pin  = _sceneObjectCreator.createCircle(clip, 0, _hitContainer, NaN, NaN, null, null,new Rectangle(35, 1080, 1200, 140), this, null, null, 2000,true); 
				pin.add(threshold);
				SceneObjectMotion(pin.get(SceneObjectMotion)).platformFriction = 100;
				Motion(pin.get(Motion)).restVelocity = 0;
			}
			else
				pin = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			pin.add(new Id(clip.name));
			var pinSpatial:Spatial = pin.get(Spatial);
			
			var pinPlatform:Entity = getEntityById("pinPlatform");
			Display(pinPlatform.get(Display)).isStatic = false;
			
			var follow:FollowTarget = new FollowTarget(pinSpatial);
			follow.offset = new Point(0,-47.5);
			pinPlatform.add(follow);
			
			var pinWall:Entity = getEntityById("pinWall");
			pinWall.get(Display).isStatic = false;
			
			follow = new FollowTarget(pinSpatial);
			follow.offset = new Point(0,7.5);
			pinWall.add(follow);
			
			if(shellApi.checkEvent(shrink.ROLLED_PIN))
			{
				pinSpatial.x = ROLLED_PIN_POS.x;
				pinSpatial.y = ROLLED_PIN_POS.y;
			}
			else
				pinWall.remove(Wall);
		}
		
		private function pinRollDownHill():void
		{
			var pin:Entity = getEntityById("rollingPin");
			var threshold:Threshold = pin.get(Threshold);
			threshold.threshold = ROLLED_PIN_POS.x;
			threshold.entered.addOnce(hitKettle);
			MotionUtils.zeroMotion(player);
			SceneUtil.lockInput(this);
		}
		
		private function hitKettle():void
		{
			getEntityById("pinWall").add(new Wall());
			var pin:Entity = getEntityById("rollingPin");
			MotionUtils.zeroMotion(pin);
			pin.remove(Motion);
			var kettle:Entity = getEntityById("kettle");
			SceneUtil.setCameraTarget(this, kettle);
			TweenUtils.entityTo(kettle,Spatial,1,{x:MOVED_KETTLE_POS,onComplete:kettleMoved});
		}
		
		private function kettleMoved():void
		{
			var emitter:Emitter = getEntityById("steam").get(Emitter);
			emitter.start = true;
			emitter.emitter.counter.resume();
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,rolledPin));
		}
		
		private function rolledPin():void
		{
			shellApi.completeEvent(shrink.ROLLED_PIN);
			getEntityById("steamHit").add(steamMover);
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this,player);
		}
	}
}