package org.flintparticles.common.displayObjects
{
	import flash.display.BlendMode;
	import flash.display.Shape;
	
	/**
	 * Author: Drew Martin
	 */
	public class PolyStar extends Shape
	{
		private var _outerRadius:Number;
		private var _innerRadius:Number;
		private var _numPoints:int;
		private var _color:uint;
		
		/**
		 * The PolyStar is a many-sided star shape.
		 * 
		 * @param OuterRadius: The outer radius for the tip of the star points.
		 * @param InnerRadius: The inner radius for the base of the star points.
		 * @param NumPoints: How many points the star should have.
		 * @param Color: An optional color for the star. Defaults to white.
		 */
		public function PolyStar(outerRadius:Number, innerRadius:Number, numPoints:int, color:uint = 0xFFFFFF)
		{
			this._outerRadius 	= outerRadius;
			this._innerRadius 	= innerRadius;
			this._numPoints 	= numPoints;
			this._color 		= color;
			this.blendMode 		= BlendMode.NORMAL;
			
			this.draw();
		}
		
		private function draw():void
		{
			//Usually both are multiplied by 2 to simulate a full 360 degrees, but this works too!
			const offset:Number = Math.PI / this._numPoints;
			
			var radians:Number = 0;
			var x:Number;
			var y:Number;
			
			graphics.beginFill(this._color);
			graphics.moveTo(0, this._outerRadius);
			
			for(var i:int = 0; i < this._numPoints; i++)
			{
				radians += offset;
				x = this._innerRadius * Math.sin(radians);
				y = this._innerRadius * Math.cos(radians);
				graphics.lineTo(x, y);
				
				radians += offset;
				x = this._outerRadius * Math.sin(radians);
				y = this._outerRadius * Math.cos(radians);
				graphics.lineTo(x, y);
			}
			
			graphics.endFill();
		}
		
		public function get outerRadius():Number { return this._outerRadius; }
		public function set outerRadius(outerRadius:Number):void
		{
			if(this._outerRadius == outerRadius) return;
			
			this._outerRadius = outerRadius;
			this.draw();
		}
		
		public function get innerRadius():Number { return this._innerRadius; }
		public function set innerRadius(innerRadius:Number):void
		{
			if(this._innerRadius == innerRadius) return;
			
			this._innerRadius = innerRadius;
			this.draw();
		}
		
		public function get numPoints():int { return this._numPoints; }
		public function set numPoints(numPoints:int):void
		{
			if(this._numPoints == numPoints) return;
			
			this._numPoints = numPoints;
			this.draw();
		}
		
		public function get color():uint { return this._color; }
		public function set color(color:uint):void
		{
			if(this._color == color) return;
			
			this._color = color;
			this.draw();
		}
	}
}