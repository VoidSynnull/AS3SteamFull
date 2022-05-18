package game.scenes.deepDive1.shared.components
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import engine.group.Group;
	import engine.util.Command;
	
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Shape;
	import nape.space.Space;

	public class Bubble
	{
		
		public function Bubble($bubbles:Bubbles, $group:Group, $createPoint:Point = null)
		{
			//display = $graphicDisplay;	
			container = $bubbles.container;
			space = $bubbles.space;
			bubbles = $bubbles;
			
			_createPoint = $createPoint;
			
			// random size
			_randScale = 0.7 + (Math.random() * 30)/100;
			
			// load bubble .swf
			$group.shellApi.loadFile($group.shellApi.assetPrefix + "scenes/deepDive1/shared/bubble.swf", onLoaded);
		}
		
		private function onLoaded(clip:MovieClip):void{
			display = clip;
			
			createGraphic();
			createBody(_createPoint);
		}
		
		private function createGraphic():void{
			bmd = new BitmapData(display.width+2, display.height+2, true, 0x000000);
			bmd.draw(display);
			
			var bitmap:Bitmap = new Bitmap(bmd, "auto", true);
			
			bitmap.x = -(bitmap.width/2);
			bitmap.y = -(bitmap.height/2);
			
			// size the bitmap
			bitmap.scaleX = _randScale;
			bitmap.scaleY = _randScale;
			
			graphicSprite = new Sprite();
			graphicSprite.addChild(bitmap);
			
			graphicSprite.mouseChildren = false;
			graphicSprite.mouseEnabled = false;
			
			container.addChild(graphicSprite);
		}
		
		private function createBody($point:Point = null):void{
			_body = new Body(BodyType.DYNAMIC, new Vec2(Math.random()*bubbles.width, 100+Math.random()*bubbles.height));
			
			var material:Material = new Material(1.5, 1, 0, 1);
			var shape:Shape = new Circle((graphicSprite.width*_randScale) / 2, null, material);
			//shape.filter.collisionGroup = 2;
			shape.filter.fluidGroup = 2;
			_body.shapes.add(shape);
			_body.userData.graphic = graphicSprite;
			
			_body.cbTypes.add(bubbles.bubbleCollisionType);
			
			_body.mass = 0.2;
			
			space.bodies.add(_body);
		}
		
		public var graphicSprite:Sprite
		
		protected var display:DisplayObject;
		protected var container:Sprite;
		protected var space:Space;
		
		protected var bmd:BitmapData;
		
		private var _body:Body;
		private var bubbles:Bubbles;
		private var _createPoint:Point;
		private var _randScale:Number;
	}
}