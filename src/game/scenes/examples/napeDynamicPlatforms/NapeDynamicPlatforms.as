package game.scenes.examples.napeDynamicPlatforms
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	
	import game.components.hit.Platform;
	import game.components.motion.Edge;
	import game.components.motion.nape.NapeMotion;
	import game.components.motion.nape.NapeSpace;
	import game.creators.motion.nape.NapeCreator;
	import game.data.TimedEvent;
	import game.scene.template.NapeGroup;
	import game.scene.template.PlatformerGameScene;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.space.Space;
	
	public class NapeDynamicPlatforms extends PlatformerGameScene
	{
		public function NapeDynamicPlatforms()
		{
			super();
		}
		
		
		// all assets ready
		override public function loaded():void
		{
			setup();
			
			super.loaded();
		}
		
		// all assets ready
		private function setup():void
		{				
			// The NapeGroup adds the nape motion systems, creator and the main nape space entity.
			_napeGroup = new NapeGroup();
			_napeGroup.setupGameScene(this, _debug);
			
			var areaWidth:int = super.sceneData.bounds.width;
			var areaHeight:int = super.sceneData.bounds.height;
								
			for (var i:int = 0; i < 10; i++) 
			{	
				addRandomBox();
			}

			addColliderToPlayer();
			
			addWaterBody();
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 0, addRandomBox));
		}
		
		private function addRandomBox():void
		{
			var x:int = Utils.randNumInRange(1100, 1300);
			var y:int = Utils.randNumInRange(40, 140);
			
			if(_totalBoxes < MAX_BOXES)
			{
				var spaceEntity:Entity = _napeGroup.getEntityById(NapeCreator.SPACE_ENTITY);
				var napeSpace:NapeSpace = spaceEntity.get(NapeSpace);
				var boxSize:int = 76;  // make bodies slightly smaller than box art to allow some overlap
				// boxes have centered reg. points (both in Nape and in the art), so need to be positioned half of their size up.
				addBox(x, y - boxSize * .5, boxSize, napeSpace.space, "box_" + _totalBoxes);
				_totalBoxes++;
			}
			else
			{
				var randomId:int = Utils.randInRange(0, MAX_BOXES - 1);
				var randomBox:Entity = _napeGroup.getEntityById("box_" + randomId);
				var body:Body = NapeMotion(randomBox.get(NapeMotion)).body;
				
				if(body.velocity.length < 10)
				{
					var motion:Motion = randomBox.get(Motion);
					
					motion.x = body.position.x = x;
					motion.y = body.position.y = y;
				}
			}
		}
		
		private function addColliderToPlayer():void
		{
			// create a nape body to map to the player.
			var playerBody:Body = new Body(BodyType.DYNAMIC);
			playerBody.shapes.add(new Polygon(Polygon.box(40, 80)));
			// mass in nape is determined by size by default.  For a box of this size it would be about 10.  
			//  We override this here to allow the player to push boxes without passing through them.
			//  Depending on the scenario this may have to be adjusted up or down.
			playerBody.mass = 10;
			
			_napeGroup.makeNapeCollider(super.player, playerBody);
		}
		
		private function addWaterBody():void
		{
			var x:Number = 1300;
			var y:Number = 700;
			var width:Number = 600;
			var height:Number = 250;
			var shape:Polygon = new Polygon(Polygon.box(width, height));
			var body:Body = new Body(BodyType.STATIC);
			
			shape.fluidEnabled = true;
			shape.fluidProperties.density = 3;
			shape.fluidProperties.viscosity = 6;
			
			body.shapes.add(shape);
			body.position.x = x + width * .5;
			body.position.y = y + height * .5;
			
			var spaceEntity:Entity = _napeGroup.getEntityById(NapeCreator.SPACE_ENTITY);
			var napeSpace:NapeSpace = spaceEntity.get(NapeSpace);
			body.space = napeSpace.space;
			
			var entity:Entity = new Entity();
			entity.add(new NapeMotion(body));
		}
		
		private function addBox(x:int, y:int, size, space:Space, id:String):void
		{
			var heavy:Boolean = Math.random() > .5;
			var asset:String = "scenes/examples/scenePhysics/box.swf";
			var box:Body = new Body(BodyType.DYNAMIC);
						
			box.shapes.add(new Polygon(Polygon.box(size, size)));
			
			if(heavy)
			{
				asset = "scenes/examples/scenePhysics/box_heavy.swf";
				box.mass *= 10;
			}
			
			var entity:Entity = _napeGroup.creator.createNapeObject(x, y, space, box, id);
			
			EntityUtils.loadAndSetToDisplay(super.hitContainer, asset, entity, this, setupNapeObject);
		}
				
		private function setupNapeObject(display:MovieClip, entity:Entity):void
		{
			var displayObject:DisplayObjectContainer = Display(entity.get(Display)).displayObject;
			
			if(_debug)
			{
				displayObject.visible = false;
			}
			
			//var hitCreator:HitCreator = new HitCreator();
			//hitCreator.createHit(displayObject, HitType.PLATFORM_TOP, null, this);
			addEdge(displayObject, entity);
			addPlatform(entity);
			
			// move width/height setting here too
			_napeGroup.addEntity(entity);
		}
		
		private function addPlatform(entity:Entity, edge:Edge = null):void
		{
			if( edge == null )	{ edge = entity.get(Edge); }
			
			var platformHit:Platform = new Platform();
			platformHit.top = true;
			platformHit.limitHitRectAngle = true;   // don't let this tilt past 45 degrees.
			platformHit.hitRect = new Rectangle(edge.unscaled.left, edge.unscaled.top, edge.unscaled.width, edge.unscaled.height);
			entity.add( platformHit );
		}
		
		private function addEdge(clip:DisplayObject, entity:Entity):Edge
		{
			// this component defines an edge from the registration point of this entity.  This prevents the ball from going all the way to its center point when hitting bounds.
			var bounds:Rectangle = clip.getBounds(clip);
			var edge:Edge = new Edge();
			edge.unscaled.top = -bounds.height * .5;
			edge.unscaled.bottom = bounds.height * .5;
			edge.unscaled.left = -bounds.width * .5;
			edge.unscaled.right = bounds.width * .5;
			entity.add(edge);
			return edge;
		}
		
		private var _napeGroup:NapeGroup;
		private var _debug:Boolean = false;
		private var _totalBoxes:int = 0;
		private var MAX_BOXES:int = 30;
	}
}