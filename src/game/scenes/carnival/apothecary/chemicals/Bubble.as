package game.scenes.carnival.apothecary.chemicals
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import game.scenes.carnival.apothecary.components.Molecules;
	
	import nape.callbacks.CbType;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Shape;
	import nape.space.Space;
	
	public class Bubble
	{
		public function Bubble($graphicDisplay:DisplayObject, $molecules:Molecules, $createPoint:Point = null, $rogue:Boolean = false)
		{
			display = $graphicDisplay;	
			container = $molecules.display;
			space = $molecules.space;
			
			if(!$rogue){
				_cbType = $molecules.bubbleCollisionType;
			} else {
				_cbType = $molecules.rBubbleCollisionType;
			}
			
			createGraphic(); // create graphic for nape physics
			if(!$rogue){
				createBody(); // create Nape physics body
			} else {
				createBody($createPoint, 1000);
			}
		}
		
		private function createGraphic():void{
			bmd = new BitmapData(display.width, display.height, true, 0x000000);
			bmd.draw(display);
			
			var bitmap:Bitmap = new Bitmap(bmd, "auto", true);
			
			bitmap.x = -(bitmap.width/2);
			bitmap.y = -(bitmap.height/2);
			
			// size the bitmap
			
			
			graphicSprite = new Sprite();
			graphicSprite.addChild(bitmap);
			
			graphicSprite.mouseChildren = false;
			graphicSprite.mouseEnabled = false;
			
			container["chemHolder"].addChild(graphicSprite);
		}
		
		private function createBody($point:Point = null, $burstVelocity:Number = 100):void{
			if($point == null){
				_body = new Body(BodyType.DYNAMIC, new Vec2(100+Math.random()*600, 100+Math.random()*400));
			} else {
				_body = new Body(BodyType.DYNAMIC, new Vec2($point.x, $point.y));
			}
			var material:Material = new Material(1.5, 1, 0, 1);
			var shape:Shape = new Circle(graphicSprite.width / 2, null, material);
			//shape.filter.collisionGroup = 2;
			shape.filter.fluidGroup = 2;
			_body.shapes.add(shape);
			_body.userData.graphic = graphicSprite;
			_body.velocity = new Vec2((Math.random()*$burstVelocity)-($burstVelocity/2),(Math.random()*$burstVelocity)-($burstVelocity/2));
			
			_body.cbTypes.add(_cbType);
			
			_body.mass = 1;

			space.bodies.add(_body);
		}
		
		// ------- getters and setters --------
		
		public function get body():Body{
			return _body;
		}
		
		public function get bodyDisplay():DisplayObject{
			return display;
		}
		
		public function destroy($bubbles:Vector.<Bubble>):void{
			// remove display from display list
			container["chemHolder"].removeChild(graphicSprite);
			
			// remove body from space
			space.bodies.remove(_body);
			
			// remove this from bubbles vector
			for(var c:int = 0; c < $bubbles.length; c++){
				if($bubbles[c] == this){
					$bubbles.splice(c,1);
				}
			}
		}
		
		protected var display:DisplayObject;
		protected var bmd:BitmapData;
		public var graphicSprite:Sprite
		protected var container:DisplayObjectContainer
		protected var space:Space;
		
		private var _body:Body;
		
		private var _cbType:CbType;
		
		
	}
}