package game.scenes.carnival.apothecary.chemicals
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import game.scenes.carnival.apothecary.components.Molecules;
	import game.util.ClassUtils;
	
	import nape.callbacks.CbType;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Shape;
	import nape.space.Space;
	
	public class Chemical
	{
		public function Chemical($graphicDisplay:DisplayObject, $molecules:Molecules, $allowedReactions:int = 1)
		{
			display = $graphicDisplay;	
			container = $molecules.display;
			space = $molecules.space;
			
			_allowedReactions = $allowedReactions;
			
			_cbType = $molecules.ballCollisionType;
			
			createGraphic(); // create graphic for nape physics
			createBody(); // create Nape physics body
		}
		
		private function createGraphic():void{
			bmd = new BitmapData(display.width+2, display.height+2, true, 0x000000); // added 2 to prevent culling
			bmd.draw(display);
			
			bitmap = new Bitmap(bmd, "auto", true);
			
			bitmap.scaleX = 0.7;
			bitmap.scaleY = 0.7;
			
			bitmap.x = -(bitmap.width/2) + graphicOffsetX;
			bitmap.y = -(bitmap.height/2) + graphicOffsetY;
			
			// size the bitmap
			
			
			graphicSprite = new Sprite();
			graphicSprite.addChild(bitmap);
			
			graphicSprite.mouseChildren = false;
			graphicSprite.mouseEnabled = false;
			
			container["chemHolder"].addChild(graphicSprite);
		}
		
		private function createBody():void{
			_body = new Body(BodyType.DYNAMIC, new Vec2(100+Math.random()*600, 200+Math.random()*300));
			var material:Material = new Material(1.5, 1, 0, 1);
			var shape:Shape = new Circle(graphicSprite.width / 2, null, material);
			//shape.filter.collisionGroup = 2;
			//shape.filter.fluidGroup = 2;
			_body.shapes.add(shape);
			_body.userData.graphic = graphicSprite;
			_body.velocity = new Vec2((Math.random()*100)-50,(Math.random()*100)-50);
			
			_body.mass = 10;
			
			bondPoint = new Point(graphicSprite.width / 2, graphicSprite.width / 2);
			
			space.bodies.add(_body);
		}
		
		public function checkForCollisions():void{
			_body.cbTypes.add(_cbType);
		}
		
		public function removeCollisions():void{
			_body.cbTypes.remove(_cbType);
		}
		
		public function changeCBType($cbType:CbType):void{
			_body.cbTypes.remove(_cbType);
			_body.cbTypes.add($cbType);
		}
		
		// ------- getters and setters --------
		
		public function get body():Body{
			return _body;
		}
		
		public function set bondPoint($point:Point):void{
			_bondPoint = $point;
			_bondPoint.offset(-2,-2); // to account for preventing culling of the bitmap draw
		}
		
		public function get bondPoint():Point{
			return _bondPoint;
		}
		
		public function set compound($compound:Compound):void{
			_compound = $compound;
		}
		
		public function get compound():Compound{
			return _compound;
		}
		
		public function get bodyDisplay():DisplayObject{
			return display;
		}
		
		public function set reactsWith($class:Class):void{
			_reactsWith = $class;
		}
		
		public function get reactsWith():Class{
			return _reactsWith;
		}
		
		public function get allowedReactions():int{
			return _allowedReactions;
		}
		
		public function get reactions():Vector.<Object>{
			return _reactions;
		}
		
		public function set reactive($boolean:Boolean):void{
			_reactive = $boolean;
		}
		
		public function get reactive():Boolean{
			return _reactive;
		}
		
		public function set position($string:String):void{
			_position = $string;
		}
		
		public function get position():String{
			return _position;
		}
		
		public function get thisClass():Class{
			return ClassUtils.getClassByObject(this);
		}
		
		public function bondOffset($point:Point):void{
			// offsetGraphic
			bitmap.x += $point.x;
			bitmap.y += $point.y;
			_bondOffset = $point;
		}
		
		public function bondRotation($rotation:Number):void{
			// normalize position (as it rotates on its upper left position
			var mH:Number = 2*((bitmap.height / 2)*Math.sin($rotation / 2));
			
			_rotateOffsetX = (mH*bitmap.scaleY)*Math.cos($rotation / 2);
			_rotateOffsetY = (mH*bitmap.scaleY)*Math.sin($rotation / 2);

			bitmap.x += _rotateOffsetX;
			bitmap.y += _rotateOffsetY;
			
			bitmap.rotation += $rotation;
			_bondRotation = $rotation;
		}
		
		public function resetBondOffset():void{
			// return graphic to original point
			if(_bondOffset != null){
				bitmap.x -= _bondOffset.x;
				bitmap.y -= _bondOffset.y;
				_bondOffset = null;
			}
		}
		
		public function resetBondRotation():void{
			if(_bondRotation != 0){
				bitmap.rotation -= _bondRotation;
				_bondRotation = 0;
				
				bitmap.x -= _rotateOffsetX;
				bitmap.y -= _rotateOffsetY;
				
			}
		}
		
		public function set leftBondOffset($point:Point):void{
			_leftBondOffset = $point;
		}
		
		public function get leftBondOffset():Point{
			return _leftBondOffset;
		}
		
		public function set rightBondOffset($point:Point):void{
			_rightBondOffset = $point;
		}
		
		public function get rightBondOffset():Point{
			return _rightBondOffset;
		}
		
		public function set leftBondRotation($rotation:Number):void{
			_leftBondRotation = $rotation;
		}
		
		public function get leftBondRotation():Number{
			return _leftBondRotation;
		}
		
		public function set rightBondRotation($rotation:Number):void{
			_rightBondRotation = $rotation;
		}
		
		public function get rightBondRotation():Number{
			return _rightBondRotation;
		}
		
		protected var display:DisplayObject;
		protected var bmd:BitmapData;
		public var graphicSprite:Sprite
		protected var container:DisplayObjectContainer
		protected var space:Space;
		
		protected var bitmap:Bitmap;
		
		private var _bondPoint:Point = new Point();
		private var _body:Body;
		private var _compound:Compound // what compound this chem is in, if any
		
		private var _cbType:CbType;
		
		private var _reactsWith:Class;
		
		private var _position:String;
		private var _reactions:Vector.<Object> = new Vector.<Object>;
		private var _reactive:Boolean = false;
		
		private var _allowedReactions:Number = 1;
		
		protected var graphicOffsetY:Number = 0;
		protected var graphicOffsetX:Number = 0;
		
		private var _leftBondOffset:Point;
		private var _leftBondRotation:Number = 0;
		private var _rightBondOffset:Point;
		private var _rightBondRotation:Number = 0;
		
		private var _bondOffset:Point;
		private var _bondRotation:Number = 0;
		
		private var _rotateOffsetX:Number;
		private var _rotateOffsetY:Number;
	}
}