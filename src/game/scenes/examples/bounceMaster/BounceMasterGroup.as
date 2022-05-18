package game.scenes.examples.bounceMaster
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.hit.ProximityHit;
	import game.components.motion.Edge;
	import game.scene.template.ads.BotBreakerGame;
	import game.scenes.examples.bounceMaster.components.BounceMasterGameState;
	import game.scenes.examples.bounceMaster.components.Bouncer;
	import game.scenes.examples.bounceMaster.systems.BounceMasterGameSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.ProximityHitSystem;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	public class BounceMasterGroup extends Group
	{
		public function BounceMasterGroup()
		{
			super();
		}
		
		public function setupGroup(game:BotBreakerGame, container:DisplayObjectContainer, hud:DisplayObjectContainer, width:Number, height:Number,bouncerClip:MovieClip,player:Entity,playerClip:MovieClip):void
		{
			_creator = new BounceMasterCreator();
			
			super.addSystem(new ProximityHitSystem(), SystemPriorities.checkCollisions);
			super.addSystem(new BounceMasterGameSystem(game,this, container, _creator, width, height,bouncerClip,player,playerClip), SystemPriorities.resolveCollisions);
			
			var gameStateEntity:Entity = _creator.createGameState(hud, STATE_ID);
			this.gameOver = BounceMasterGameState(gameStateEntity.get(BounceMasterGameState)).gameOver;
			
			super.addEntity(gameStateEntity);
		}
		
		public function createCatcher(clip:MovieClip, followSpatial:Spatial):void
		{
			super.addEntity(_creator.createCatcher(clip, followSpatial));
		}

		public function createBrick(clip:MovieClip):Entity
		{
			var entity:Entity = new Entity();
			
			entity.add(new Display(clip));
			entity.add(new Spatial(clip.x,clip.y));
			entity.add(new ProximityHit(clip.width*.5, clip.height));
			entity.add(new Id(clip.name));
			trace("createBrick: " + clip.name);
			return entity;
			
		}
		public function createMultiBallPowerUp(clip:MovieClip, spatial:Spatial):void
		{
			var entity:Entity = new Entity();
			
			entity.add(new Display(clip));
			entity.add(new Spatial(spatial.x,spatial.y));
			entity.add(new ProximityHit(clip.width*.5, clip.height));
			entity.add(new Id("multiball"));
			var motion:Motion = new Motion();
			
			motion.velocity.x = 0;
			motion.velocity.y = 300;
			//motion.acceleration.y = 800;
			entity.add(motion);
			trace("create multiball");
			super.addEntity(entity);
			
		}
		public function createPointsPowerUp(clip:MovieClip, spatial:Spatial):void
		{
			var entity:Entity = new Entity();
			
			entity.add(new Display(clip));
			entity.add(new Spatial(spatial.x,spatial.y));
			entity.add(new ProximityHit(clip.width*.5, clip.height));
			entity.add(new Id("multiplierpower"));
			var motion:Motion = new Motion();
			
			motion.velocity.x = 0;
			motion.velocity.y = 300;
			//motion.acceleration.y = 800;
			entity.add(motion);
			trace("create pointspower");
			super.addEntity(entity);
			
		}
		public function createMultiBouncer(container:DisplayObjectContainer, x:Number, y:Number, velX:Number, velY:Number,
										   boundsWidth:Number, boundsHeight:Number):void
		{
			for(var i:Number=1;i<2;i++)
			{
				var clip:MovieClip = container["ball" + i.toString()];
				var entity:Entity = new Entity();
				var side:Number = clip.width * .5;
				
				var motion:Motion = new Motion();
				
				motion.velocity.x = Utils.randInRange(velX/1.4,velX);
				motion.velocity.y = Utils.randInRange(velY/1.4,velY);
				if(Utils.randInRange(0,1) == 1)
					motion.velocity.x *= -1;
				//motion.acceleration.y = 800;
				motion.maxVelocity = new Point(800, 800);
				entity.add(motion);
				
				var edge:Edge = new Edge();
				edge.unscaled.setTo(-side, -side, side * 2, side * 2);
				entity.add(edge);
				
				entity.add(new Bouncer());
				entity.add(new Spatial(x, y));
				entity.add(new Display(clip));
				entity.add(new ProximityHit(side, side));
				entity.add(new Id("multibouncer" + i.toString()));
				entity.add(new MotionBounds(new Rectangle(0, 0, boundsWidth, boundsHeight)));
				super.addEntity(entity);
			}
		}
		public function setupStage(container:DisplayObjectContainer, stageClipName:String, callback:Function=null):void
		{
			//bricks = new Array();
			var stageClip:MovieClip = container[stageClipName];
			stageClip.x = stageClip.y = 0;
			
			for (var i:int = stageClip.numChildren - 1; i != -1; i--)
			{
				// if movie clip
				if (stageClip.getChildAt(i) is MovieClip)
				{
					var clip:MovieClip = MovieClip(stageClip.getChildAt(i));
					if(clip.name.indexOf("brick") >-1)
					{
						//brick clip found, make brick ent
						var brick:Entity = createBrick(clip);
						//bricks.push(clip);
						super.addEntity(brick);
						numBricks++;
					}
				}
			}
			if(callback != null)
				callback();
		}
		public function makeCatcher(entity:Entity, hitWidth:Number, hitHeight:Number):void
		{
			_creator.makeCatcher(entity, hitWidth, hitHeight);
		}
		
		public function startGame():void
		{
			var gameStateEntity:Entity = super.getEntityById(STATE_ID);
			BounceMasterGameState(gameStateEntity.get(BounceMasterGameState)).gameActive = true;
		}
		private var _creator:BounceMasterCreator;
		private const STATE_ID:String = "bounceMasterGameState";
		public var gameOver:Signal;
		public var numBricks:Number = 0;
	}
}