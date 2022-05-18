package game.util
{	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * Contains a grab-bag of useful functions for 
	 * math, randomization plus a whole lot more.
	 * Definitely worth a look-see.
	 */	
	public class Utils
	{		
		public static const baseTime:Number = 1 / 60;
		
		/**
		 * Traces out an object, including any nested objects.
		 * <p>An example of an object with nested objects.
		 * <li>Dictionary</li>
		 * <ul><li>Array</li></ul>
		 * <ul><ul><li>String</li></ul></ul>
		 * <ul><ul><li>Number</li></ul></ul>
		 * <ul><ul><li>Boolean</li></ul></ul>
		 * <ul><li>Dictionary</li></ul>
		 * <ul><ul><li>String</li></ul></ul>
		 * <ul><ul><li>Number</li></ul></ul>
		 * <ul><ul><li>Boolean</li></ul></ul>
		 * <ul><li>String</li></ul>
		 * <ul><li>Number</li></ul>
		 * <ul><li>Boolean</li></ul>
		 */
		private static function traceObject(object:*, prefix:String = "", indent:String = ""):void
		{
			trace(indent + prefix, object);
			if(typeof(object) == "object")
			{
				for(var key:* in object)
				{
					traceObject(object[key], key, indent + "  ");
				}
			}
		}
		
		public static function toFixed(number:Number, decimals:int = 2):Number
		{
			return Number(number.toFixed(decimals));
		}
		
		public static function toDecimal(number:Number, min:Number, max:Number):Number
		{
			return (number - min) / (max - min);
		}
		
		public static function fromDecimal(decimal:Number, min:Number, max:Number):Number
		{
			return decimal * (max - min) + min;
		}
		
		public static function toPercent(number:Number, min:Number, max:Number):Number
		{
			return (number - min) / (max - min) * 100;
		}
		
		public static function fromPercent(percent:Number, min:Number, max:Number):Number
		{
			return (percent / 100) * (max - min) + min;
		}
		
		public static function convertRatio(number:Number, min1:Number, max1:Number, min2:Number, max2:Number):Number
		{
			return Utils.fromDecimal(Utils.toDecimal(number, min1, max1), min2, max2);
		}
		
		public static function distance(x1:Number, y1:Number, x2:Number, y2:Number):Number
		{
			return(Math.sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1))));
		}
		
		public static function convertToMegabyte(value:Number):String
		{
			return(Number( value / 1024 / 1024 ).toFixed( 2 ) + "Mb");
		}
		
		public static const POSITIVE_CHARGE:int	= 1;
		public static const NEGATIVE_CHARGE:int	= -1;
		/**
		 * Coerces a Number's value to &#177;1.
		 * 
		 * @param num The <code>Number</code> to be evaluated.
		 * @return Either a value of <code>Utils.POSITIVE_CHARGE</code> or <code>Utils.NEGATIVE_CHARGE</code>. 
		 * If the value is not negative, the Number is considered to have a <code>POSITIVE_CHARGE</code>, or
		 * <code>+1</code>. Negative values are considered to have a <code>NEGATIVE_CHARGE</code>, or <code>-1</code>.
		 * 
		 */		
		public static function getCharge( num:Number ):int
		{
			if ( num >= 0 )
			{
				return POSITIVE_CHARGE;
			}
			return NEGATIVE_CHARGE;
		}
		
		public static function getDictLength( dict:Dictionary ):int 
		{
			var n:int = 0;
			for (var key:* in dict) {
				n++;
			}
			return n;
		}
		
		public static function convertVectorToArray(vector:*):Array
		{
			var result:Array = new Array();
			
			if( vector != null )
			{
				var total:Number = vector.length;
				for(var n:uint = 0; n < total; n++)
				{
					result[n] = vector[n];
				}
			}
			
			return(result);
		}

		/**
		 * Copies property values from one object to another. Only properties which are shared between objects are modified.
		 * @param	src	An object holding the new property values.
		 * @param	dest	An object to be modified.
		 * @return	The destination object, whether modified or not.
		 */
		public static function overlayObjectProperties(src:Object, dest:Object):Object {
			for (var propName:String in src) {
				if (dest.hasOwnProperty(propName)) {
					dest[propName] = src[propName];
				}
			}
			return dest;
		}

		public static function ensureObjectProperty(o:Object, propertyName:String, defaultValue:*=null):* {
			var propertyFound:Boolean = o.hasOwnProperty(propertyName);
			if (!propertyFound) {
				o[propertyName] = defaultValue;
			}
			return o[propertyName];
		}

		/**
		* Rounds a number to the nearest multiple of <code>unitSize</code>.
		*	@param curVal	The Number to adjust.
		*	@param unitSize	The size of a grid unit.
		*	@return	The multiple of <code>unitSize</code> closest to <code>curVal</code>.
		*/
		public static function nearestMultiple(number:Number, step:Number):Number
		{
			return step * Math.round(number / step);
		}

		/**
		* Generates a random integer with upper and lower bounds. 
		* @param min	The lowest allowable value.
		* @param max	The highest allowable value.
		* @return		A random integer between <code>min</code> and <code>max</code>, inclusive.
		*/
		public static function randInRange(min:Number, max:Number):int
		{
			return Math.floor(min) + Math.floor(Math.random() * (max + 1 - min));
		}
		
		/**
		 * Clamps <code>number</code> to the nearest step between the range of <code>min</code> and
		 * <code>max</code> with a given number of <code>steps</code> between them.
		 * 
		 * <p>For a range between 0 - 100 units and 5 steps, each step would be 20 units. The steps would
		 * be 0, 20, 40, 60, 80, 100. If <code>number</code> was 31 it would be rounded up to 40.</p>
		 */
		public static function clampToStep(number:Number, min:Number, max:Number, steps:uint):Number
		{
			if(number < min) 		return min;
			else if(number > max) 	return max;
			const step:Number = (max - min) / steps;
			return nearestMultiple(number - min, step) + min;
		}
		
		/**
		 * Generates a random Number within the given <code>min</code> and <code>max</code>. 
		 * @param min	The lowest allowable value.
		 * @param max	The highest allowable value.
		 * @return		A random Number between <code>min</code> and <code>max</code>.
		 * @see			Utils.randInRange()
		 */
		public static function randNumInRange(min:Number, max:Number):Number
		{
			return min + (Math.random() * (max - min));
		}

		/**
		* Choose a random Point within a Rectangle.
		*	@param r The bounding Rectangle
		*	@return A Point somewhere within <code>r</code>.
		*/
		public static function randPtInRect(r:Rectangle):Point {
			return new Point(randInRange(r.left, r.right), randInRange(r.top, r.bottom));
		}

		/**
		* Randomly select <code>howMany</code> items from <code>anArray</code>.
		* @param anArray	The source array of items
		* @param howMany	The number of items to return
		* @return			An array containing the selected items
		*/
		public static function randomSubset(anArray:Array, howMany:int):Array {
			var results:Array = [];
			for (var i:int=0; i<howMany; i++) {
				var anIndex:Number = randInRange(0, anArray.length-1);
				results.push(anArray.splice(anIndex, 1)[0]);
			}
			return results;
		}

		/**
		 * Randomly select one of the <code>anArray's</code> indices.
		 * @param	anArray
		 * @return	random int from 0 to <code>anArray.length - 1</code>
		 */
		public static function anyIndex(anArray:Array):int {
			return randInRange(0, anArray.length-1);
		}

		/**
		* Randomize the order of items in <code>anArray</code>
		* @param anArray	The array to shuffle
		* @return			A shuffled copy of the original array
		*/
		public static function shuffleArray(anArray:Array):Array {
			return randomSubset(anArray.concat(), anArray.length);
		}
		
		public static function getVariableTimeEase(ease:Number, time:Number, theBaseTime:Number = Utils.baseTime, max:Number = 1):Number
		{
			ease *= (time / theBaseTime);
			return(Math.min(max, ease));
		}

	}
}