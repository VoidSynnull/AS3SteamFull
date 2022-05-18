package game.scene.template
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.PlatformReboundCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.Wall;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.Proximity;
	import game.components.motion.SceneObjectMotion;
	import game.components.render.PlatformDepthCollider;
	import game.components.timeline.Timeline;
	import game.creators.motion.SceneObjectCreator;
	import game.scenes.cavern1.shared.components.Breakable;
	import game.scenes.cavern1.shared.components.Magnetic;
	import game.scenes.cavern1.shared.components.MagneticData;
	import game.scenes.cavern1.shared.systems.BreakableSystem;
	import game.scenes.cavern1.shared.systems.MagnetSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.ProximitySystem;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;
	
	public class CavernScene extends PlatformerGameScene
	{
		public function CavernScene()
		{
			super();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			this.setupMagnetics();
		}
		
		private function setupMagnetics():void
		{
			this.addSystem(new MagnetSystem());
			this.addSystem(new FollowTargetSystem());
			this.addSystem(new MotionTargetSystem());
			this.addSystem(new DestinationSystem());
			this.addSystem(new ProximitySystem());
			this.addSystem(new BreakableSystem());
			addSystem(new SceneObjectHitRectSystem());
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			var entity:Entity;
			var sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
			
			for(var index:int = _hitContainer.numChildren - 1; index > -1; --index)
			{
				var child:DisplayObject = _hitContainer.getChildAt(index);
				
				if(child.name.indexOf("magnetic") > -1)
				{
					var isMovable:Boolean = false;
					
					if(child.name.indexOf("box") > -1)
					{
						isMovable = true;
						entity = sceneObjectCreator.createBox(child, 0, null, child.x, child.y, null, null, null, this, null, null, NaN, isMovable);
						entity.add(new SceneObjectCollider());
						entity.add(new RectangularCollider());
						entity.add(new PlatformCollider());
						entity.add(new PlatformReboundCollider());
						entity.add(new WallCollider());
						entity.add(new SceneCollider());
						entity.add(new BitmapCollider());
						entity.add(new PlatformDepthCollider());
						entity.add(new CurrentHit());
					}
					else if(child.name.indexOf("rock") > -1)
					{
						isMovable = false;
						entity = sceneObjectCreator.create(child, 0, null, child.x, child.y, null, null, null, this, null, null, null, isMovable);
					}
					else continue;
					
					entity.add(new Id(child.name));
					entity.add(new Sleep());
					
					if(isMovable)
					{
						var hit:SceneObjectHit = new SceneObjectHit(true, false);
						hit.anchored = true;
						//entity.add(hit);//adds wall for player, but may want to disable or figure out how to prevent it from pushing player when being magnetized
					}
					entity.add(new MagneticData(1, child.width / 2));
					entity.add(new Magnetic(isMovable));
					if(!isMovable)
					{
						var motion:Motion = entity.get(Motion);
						motion.maxVelocity.setTo(0, 0);
					}
					else
					{
						var sceneObjectMotion:SceneObjectMotion = entity.get(SceneObjectMotion);
						sceneObjectMotion.rotateByPlatform = true;
						sceneObjectMotion.rotateByVelocity = false;
					}
				}
				else if(child.name.indexOf("glowWorm") > -1)
				{
					if(PlatformUtils.isMobileOS)
						convertContainer(child as DisplayObjectContainer);
					entity = EntityUtils.createSpatialEntity(this, child);
					TimelineUtils.convertAllClips(child as MovieClip, entity, this);
					var prox:Proximity = new Proximity(400, player.get(Spatial));
					prox.entered.add(Command.create(setWormState,"close"));
					prox.exited.add(Command.create(setWormState, "idle"));
					entity.add(prox);
				}
				else if(child.name.indexOf("breakable") > -1)
				{
					if(PlatformUtils.isMobileOS)
						convertContainer(child as DisplayObjectContainer);
					entity = sceneObjectCreator.create(child, 0, null, child.x, child.y,null,null, null, this);
					var edge:Edge = entity.get(Edge);
					Motion(entity.get(Motion)).parentMotionFactor = .5;// just so there is a little bit of difference for when they drop on one another
					
					var sprite:Sprite = new Sprite();
					sprite.graphics.beginFill(0,0);
					sprite.graphics.drawRect(edge.rectangle.left, -25, edge.rectangle.width, 50);
					sprite.x = child.x;
					sprite.y = child.y + edge.rectangle.top;
					sprite.mouseChildren = sprite.mouseEnabled = false;
					
					var plat:Entity = EntityUtils.createSpatialEntity(this, sprite, _hitContainer);
					var follow:FollowTarget = new FollowTarget(entity.get(Spatial));
					follow.offset = new Point(0, edge.rectangle.top);
					plat.add(follow).add(new Platform());
					
					entity.add(new PlatformCollider()).add(new Wall()).add(new Breakable(plat,.25, 100)).add(new Id(child.name));
					var piece:Entity;
					for(var childIndex:int = MovieClip(child).numChildren - 1; childIndex > -1; --childIndex)
					{
						var nested:DisplayObject = MovieClip(child).getChildAt(childIndex);
						piece = EntityUtils.createSpatialEntity(this, nested as DisplayObjectContainer);
						motion = new Motion();
						motion.rotationFriction = 360;
						motion.friction = new Point(1000,1000);
						piece.add(motion);
						piece.add(new MotionBounds(nested.getBounds(nested)));
						EntityUtils.addParentChild(piece, entity);
					}
				}
			}
		}
		
		private function setWormState(entity:Entity, state:String):void
		{
			var children:Children = entity.get(Children);
			var timeline:Timeline;
			var endLabel:String = state == "close"?"endIdle":"endClose";
			for each(var worm:Entity in children.children)
			{
				timeline = worm.get(Timeline);
				timeline.handleLabel(endLabel, Command.create(timeline.gotoAndPlay, state));
				//Timeline(worm.get(Timeline)).gotoAndPlay(state);
			}
		}
	}
}