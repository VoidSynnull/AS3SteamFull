package game.data.specialAbility.character.objects
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.util.Utils;

	
	
	public class Lightning extends MovieClip
	{
		private var mOffset:Object;
		private var mClips:Array;
		
		private var LINE_THICKNESS:Number = 7;
		private var LINE_ALPHA:Number = 100;
		private var TOTAL_GENERATIONS:Number = 10;
		private var DEGRADE_RATE:Number = .75;
		
		private var SIZE_FACTOR:Number = 250;
		private var X_OFFSET_MIN:Number = -.3 * SIZE_FACTOR;
		private var X_OFFSET_MAX:Number = .3 * SIZE_FACTOR;
		private var Y_OFFSET_MIN:Number = .3 * SIZE_FACTOR;
		private var Y_OFFSET_MAX:Number = SIZE_FACTOR;
		
		private var MIN_CHILDREN:Number = 2;
		private var MAX_CHILDREN:Number = 4;
		
		private var FILTER_QUALITY:Number = 1;
		private var GLOW_OFFSET:Number = 17;
		private var GLOW_STRENGTH:Number = 7;
		private var theDisplay:Display;
		
		
		public function init():void
		{	
			makeBolt(0, 0, 1);
		}
		
		private function makeBolt(x:Number, y:Number, generation:Number):void
		{
			var newBolt:Shape = new Shape();
			this.addChild(newBolt);
			
			var prevDegrade:Number = (TOTAL_GENERATIONS - generation - 1) / TOTAL_GENERATIONS;
			var degrade:Number = (TOTAL_GENERATIONS - generation) / TOTAL_GENERATIONS;
			
			var stepDegrade:Number = (prevDegrade + degrade) * .5;
			
			var targetX:Number = x + Utils.randInRange(X_OFFSET_MIN * degrade, X_OFFSET_MAX * degrade);
			var targetY:Number = y + Utils.randInRange(Y_OFFSET_MIN * degrade, Y_OFFSET_MAX * degrade);
			
			var initPoint:Point = new Point(x, y);
			var targetPoint:Point = new Point(targetX, targetY);
			
			var midPoint:Point = Point.interpolate(initPoint, targetPoint, .5);
			
			newBolt.graphics.lineStyle(LINE_THICKNESS * degrade, 0xFFFFFF, LINE_ALPHA * degrade);
			newBolt.graphics.moveTo(x, y);
			newBolt.graphics.lineTo(midPoint.x, midPoint.y);
			newBolt.graphics.lineStyle(LINE_THICKNESS * stepDegrade, 0xFFFFFF, LINE_ALPHA * stepDegrade);
			newBolt.graphics.moveTo(midPoint.x, midPoint.y);
			newBolt.graphics.lineTo(targetX, targetY);
			
			if (generation < TOTAL_GENERATIONS)
			{				
				// chance for no children increases as generations increase
				var total:Number = Math.floor(Utils.randInRange(MIN_CHILDREN * degrade, MAX_CHILDREN * degrade));
				
				for (var n:Number = 0; n < total; n++)
				{
					makeBolt(targetX, targetY, generation + 1);
				}
			}
		}
	}
}