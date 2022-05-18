package game.scenes.examples.napeCharacter
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.motion.nape.NapeSpace;
	import game.creators.motion.nape.NapeCreator;
	import game.scene.template.NapeGroup;
	import game.scene.template.PlatformerGameScene;
	import game.util.EntityUtils;
	
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.space.Space;
	
	public class NapeCharacter extends PlatformerGameScene
	{
		public function NapeCharacter()
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
			var spaceEntity:Entity = _napeGroup.getEntityById(NapeCreator.SPACE_ENTITY);
			var napeSpace:NapeSpace = spaceEntity.get(NapeSpace);
			var boxSize:int = 78;  // make bodies slightly smaller than box art to allow some overlap

			for (var i:int = 0; i < 5; i++) 
			{	
				var x:int = 1400;
				var y:int = areaHeight - boxSize * i;
				// boxes have centered reg. points (both in Nape and in the art), so need to be positioned half of their size up.
				addBox(x, y - boxSize * .5, boxSize, napeSpace.space);
			}
			
			var ballSize:Number = 20;
			addBall(areaWidth * .5, 100, ballSize, napeSpace.space);
			
			addColliderToPlayer();
		}
		
		private function addColliderToPlayer():void
		{
			// create a nape body to map to the player.
			var playerBody:Body = new Body(BodyType.DYNAMIC);
			playerBody.shapes.add(new Polygon(Polygon.box(40, 80)));
			// mass in nape is determined by size by default.  For a box of this size it would be about 10.  
			//  We override this here to allow the player to push boxes without passing through them.
			//  Depending on the scenario this may have to be adjusted up or down.
			playerBody.mass = 100;
			
			_napeGroup.makeNapeCollider(super.player, playerBody);
		}
		
		private function addBox(x:int, y:int, size, space:Space):void
		{
			var box:Body = new Body(BodyType.DYNAMIC);
			box.shapes.add(new Polygon(Polygon.box(size, size)));
			
			var entity:Entity = _napeGroup.creator.createNapeObject(x, y, space, box);
			
			EntityUtils.loadAndSetToDisplay(super.hitContainer, "scenes/examples/scenePhysics/box.swf", entity, this, setupNapeObject);
		}
		
		private function addBall(x:int, y:int, size:Number, space:Space):void
		{
			var ballShape:Circle = new Circle(size);
			ballShape.material = Material.rubber();      // apply a material preset to make the ball bouncy.
			
			var ball:Body = new Body(BodyType.DYNAMIC);
			ball.shapes.add(ballShape);
			ball.angularVel = 1;
			
			var entity:Entity = _napeGroup.creator.createNapeObject(x, y, space, ball, "ball");
			
			EntityUtils.loadAndSetToDisplay(super.hitContainer, "scenes/examples/standaloneMotion/ball2.swf", entity, this, setupNapeObject);
		}
		
		private function setupNapeObject(display:MovieClip, entity:Entity):void
		{
			if(_debug)
			{
				Display(entity.get(Display)).visible = false;
			}
			
			// move width/height setting here too
			_napeGroup.addEntity(entity);
		}
		
		private var _napeGroup:NapeGroup;
		private var _debug:Boolean = false;
	}
}