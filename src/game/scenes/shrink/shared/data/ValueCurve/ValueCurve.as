package game.scenes.shrink.shared.data.ValueCurve
{
	import flash.geom.Point;
	
	public class ValueCurve
	{
		private var _curve:Function;
		private var _range:Point;
		private var _difference:Number;
		
		public function ValueCurve(curve:Function = null, range:Point = null)
		{
			_curve = curve;
			if(range == null)
				range = new Point(0,1);
			this.range = range;
		}
		
		public function get curve():Function{return _curve;}
		
		public function set curve(valueCurve:Function):void{_curve = valueCurve;}
		
		public function set range(minMax:Point):void
		{
			_range = minMax;
			_difference = minMax.y - minMax.x;
		}
		
		public function get range():Point{return _range;}
		
		public function get scale():Number{return _difference;}
		
		public function getValue(x:Number):Number
		{
			//x *= scale;
			
			if(curve != null)
				x = curve(x);
			var value:Number = x * scale;
			//trace("examples of how curves could effect " + x + ": acos: " +  Math.acos(x) * scale + " asin: " +  Math.asin(x) * scale + " sqrt: " +  Math.sqrt(x) * scale + " pow: " +  Math.pow(x, 2) * scale);
			return range.x + value;
		}
	}
}