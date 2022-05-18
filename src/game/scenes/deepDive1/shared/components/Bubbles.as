package game.scenes.deepDive1.shared.components
{
	import flash.display.Sprite;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import nape.callbacks.CbEvent;
	import nape.callbacks.CbType;
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionListener;
	import nape.callbacks.InteractionType;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.shape.Shape;
	import nape.space.Space;
	import nape.util.ShapeDebug;
	
	public class Bubbles extends Component
	{
		public function Bubbles($amount:int, $container:Sprite, $width:Number, $height:Number, $player:Entity, $debug:Boolean = false, $offsetX:Number = 0, $offsetY:Number = 0)
		{
			super();
			
			width = $width;
			height = $height;
			
			container = $container;
			player = $player;
			debug = $debug;
			
			player.group.shellApi
			
			// init physics
			initNape($width,$height,$offsetX,$offsetY);
			
			// create bubbles
			for(var c:int = 0; c < Math.floor($amount/3); c++){
				_bubbles.push(new Bubble(this, player.group));
				_bubbles.push(new Bubble(this, player.group));
				_bubbles.push(new Bubble(this, player.group));
			}
		}
		
		private function initNape($width:Number, $height:Number, $offsetX, $offsetY):void
		{
			
			bubbleCollisionType = new CbType();
			teleporterType = new CbType();
			
			space = new Space(new Vec2(0, 100));
			
			space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, bubbleCollisionType, teleporterType, handleTeleport));
			
			if (debug) {
				shapeDebug = new ShapeDebug($width, $height);
				shapeDebug.drawConstraints = true;
				container.addChild(shapeDebug.display);
			}

			// create fluid body for scene
			var fluidBody:Body = new Body(BodyType.STATIC);
			var fluidShape:Shape = new Polygon(Polygon.rect(0+$offsetX,-100+$offsetY,$width,$height+200));
			
			fluidShape.filter.collisionMask = 0;
			fluidShape.fluidEnabled = true;
			fluidShape.filter.fluidMask = 2;
			
			fluidShape.fluidProperties.density = 8;
			fluidShape.fluidProperties.viscosity = 3;
			
			fluidShape.body = fluidBody;
			fluidBody.space = space;
			
			subBody = new Body(BodyType.KINEMATIC);
			var c:Circle = new Circle(74, new Vec2($offsetX,$offsetY));
			subBody.shapes.add(c);
			
			space.bodies.add(subBody);
			
			// add teleporter border (to transport bubbles back down to the bottom of the tank)
			
			var border:Body = new Body(BodyType.STATIC);
			border.shapes.add(new Polygon(Polygon.rect(0+$offsetX, -50+$offsetY, width, 10)));
			border.cbTypes.add(teleporterType);
			border.space = space;
			
		}
		
		private function handleTeleport($collision:InteractionCallback):void
		{
			var object:Body = $collision.int1.castBody;
			
			// return to bottom
			object.position = new Vec2(Math.random()*width, height + 50);
		}
		
		public var teleporterType:CbType;
		public var bubbleCollisionType:CbType;
		
		public var width:int;
		public var height:int;
		
		public var debug:Boolean;
		public var shapeDebug:ShapeDebug;
		public var space:Space;
		
		public var container:Sprite;
		
		public var subBody:Body; // circular body that follows the sub and pushes bubbles out of the way as it travels through
		
		public var player:Entity;
		private var _bubbles:Vector.<Bubble> = new Vector.<Bubble>;
		
	}
}