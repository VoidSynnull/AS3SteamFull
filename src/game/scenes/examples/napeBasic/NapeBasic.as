package game.scenes.examples.napeBasic
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.input.Input;
	import game.components.motion.nape.NapePivotJoint;
	import game.components.motion.nape.NapeSpace;
	import game.creators.motion.nape.NapeCreator;
	import game.scene.template.GameScene;
	import game.scene.template.NapeGroup;
	import game.util.EntityUtils;
	
	import nape.constraint.PivotJoint;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.space.Space;
	
	public class NapeBasic extends GameScene
	{
		public function NapeBasic()
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
			var inputEntity:Entity = shellApi.inputEntity;
			var input:Input = inputEntity.get(Input) as Input;						
			var spaceEntity:Entity = _napeGroup.getEntityById(NapeCreator.SPACE_ENTITY);
			var napeSpace:NapeSpace = spaceEntity.get(NapeSpace);
			var boxSize:int = 80;
			
			input.inputDown.add(handleDown);
			input.inputUp.add(handleUp);
			
			// this will create a joint to 'pick up' objects
			addInputConstraint(napeSpace.space);
			
			// adds some platforms to collide with
			addPlatforms(napeSpace.space);

			for (var i:int = 0; i < 5; i++) 
			{	
				var x:int = areaWidth / 2;
				var y:int = areaHeight - boxSize * i;
				// boxes have centered reg. points (both in Nape and in the art), so need to be positioned half of their size up.
				addBox(x, y - boxSize * .5, boxSize, napeSpace.space);
			}
			
			var ballSize:Number = 20;
			addBall(areaWidth * .5, 100, ballSize, napeSpace.space);
		}
				
		private function addPlatforms(space:Space):void
		{
			var platform1:Body = new Body(BodyType.STATIC);
			var ramp:Polygon = new Polygon(Polygon.regular(50, 150, 3));
			ramp.material = Material.rubber();  // materials can be applied to both static and dynamic bodies.
			platform1.shapes.add(ramp);
			platform1.position.x = 200;
			platform1.position.y = 540 - 25;
			platform1.rotation = -Math.PI/2;
			platform1.space = space;
		}
		
		private function addInputConstraint(space:Space):void
		{
			var entity:Entity = _napeGroup.creator.createNapeInputPivotJoint(space, true);
			_napeGroup.addEntity(entity);
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
		
		private function handleDown(input:Input):void 
		{	
			var targetX:Number = super.shellApi.globalToScene(input.target.x, "x");
			var targetY:Number = super.shellApi.globalToScene(input.target.y, "y");
			// request a vec2 from the object pool for temporary use.
			var mousePoint:Vec2 = Vec2.get(targetX, targetY);
			// gather all the objects underneath the input
			var bodies:BodyList = _napeGroup.getEntityById(NapeCreator.SPACE_ENTITY).get(NapeSpace).space.bodiesUnderPoint(mousePoint);
			// get the pivot joint we'll be attaching to.
			var pivot:PivotJoint = NapePivotJoint(_napeGroup.getEntityById(NapeCreator.INPUT_ENTITY).get(NapePivotJoint)).pivotJoint;
			// find the first 'dynamic' body and attach it to the pivot so it will move with the pivot joint (which follows input.)
			for (var i:int = 0; i < bodies.length; i++) 
			{
				var body:Body = bodies.at(i);

				if (!body.isDynamic()) 
				{
					continue;
				}
				
				// A pivot joint can have two anchor points to allow free rotation as it is moved.  
				//   Set the first anchor point to the place in the scene where we clicked
				pivot.anchor1.setxy(targetX, targetY);
				// ...and set the second pivot anchor based on the point touched on the body.
				pivot.anchor2.set(body.worldPointToLocal(mousePoint, true));
				// map the pivot body to the body we clicked.
				pivot.body2 = body; 
				// Enable hand joint.
				pivot.active = true;
				break;
			}
			
			// Release Vec2 back to object pool.
			mousePoint.dispose();
		}
		
		private function handleUp(input:Input):void 
		{
			var pivot:PivotJoint = NapePivotJoint(_napeGroup.getEntityById(NapeCreator.INPUT_ENTITY).get(NapePivotJoint)).pivotJoint;
			
			if(pivot.active)
			{
				var body:Body = pivot.body2;
				
				// release the body from the constraint
				pivot.active = false;
				pivot.body2 = null;
				
				// apply an impulse based on the distance between the input and the current body position
				//   to allow the body to be 'thrown' in the direction of input movement.
				//   This would work better in a system that tracks the body's previous and current position, but
				//   gets the job done to demo the application of an inpulse.
				var dx:Number = input.target.x - body.position.x;
				var dy:Number = input.target.y - body.position.y;
				// Another way to request an object from the pool is to use 'weak' instead of 'get'.  This will
				//   allow the object to be released back to the pool automatically rather than requiring an
				//   explicit call to object.dispose().
				var impulse:Vec2 = Vec2.weak(dx, dy);
				// only apply an impulse if we're moving the input fast enough.
				if(impulse.length > 20)
				{
					// use a multiplier to increase the effect of the impulse, but cap it at a max value.
					impulse.length *= 30;
					
					if(impulse.length > 5000)
					{
						impulse.length = 5000;
					}
					
					body.applyImpulse(impulse);
				}
			}
		}
				
		private var _napeGroup:NapeGroup;
		private var _debug:Boolean = false;
	}
}