package game.util
{
	/**
	 * Author: Drew Martin
	 * 
	 * <p>Utility for aligning Objects. Normally, alignments are used for (x, y) positioning, but these functions allow for
	 * any property that an Object has. This is useful for aligning and offsetting alphas, rotations, and any other values.
	 * 
	 * <p>For functions that require an <code>index</code>, it should be noted that indices are zero-based.
	 */
	public final class Alignment
	{
		public static const LEFT:int 	= 1;
		public static const CENTER:int 	= 2;
		public static const RIGHT:int 	= 4;
		public static const JUSTIFY:int = 8;
		
		public static function align(objects:Array, property:String, alignment:int, value1:Number, value2:Number):void
		{
			var numObjects:uint = objects.length;
			var index:uint 		= 0;
			
			switch(alignment)
			{
				case Alignment.LEFT:
					for(; index < numObjects; ++index)
					{
						Alignment.leftAtIndex(objects[index], property, value1, value2, index);
					}
					break;
				
				case Alignment.CENTER:
					for(; index < numObjects; ++index)
					{
						Alignment.centerAtIndex(objects[index], property, value1, value2, index, numObjects);
					}
					break;
				
				case Alignment.RIGHT:
					for(; index < numObjects; ++index)
					{
						Alignment.rightAtIndex(objects[index], property, value1, value2, index, numObjects);
					}
					break;
				
				case Alignment.JUSTIFY:
					for(; index < numObjects; ++index)
					{
						Alignment.justifyAtIndex(objects[index], property, value1, value2, index, numObjects);
					}
					break;
			}
		}
		
		public static function alignAtIndex(object:Object, property:String, alignment:int, value1:Number, value2:Number, index:int, numObjects:uint):void
		{
			switch(alignment)
			{
				case Alignment.LEFT:
					Alignment.leftAtIndex(object, property, value1, value2, index);
					break;
				
				case Alignment.CENTER:
					Alignment.centerAtIndex(object, property, value1, value2, index, numObjects);
					break;
				
				case Alignment.RIGHT:
					Alignment.rightAtIndex(object, property, value1, value2, index, numObjects);
					break;
				
				case Alignment.JUSTIFY:
					Alignment.justifyAtIndex(object, property, value1, value2, index, numObjects);
					break;
			}
		}
		
		/**
		 * Takes an Array of Objects and - starting at the <code>left</code> value - left-aligns and evenly spaces each
		 * Object's <code>property</code> to a value based on that Object's index multiplied by <code>offset</code>.
		 */
		public static function left(objects:Array, property:String, left:Number, offset:Number):void
		{
			var numObjects:uint = objects.length;
			for(var index:uint = 0; index < numObjects; ++index)
			{
				Alignment.leftAtIndex(objects[index], property, left, offset, index);
			}
		}
		
		/**
		 * Takes an Object and - starting at the <code>left</code> value - left-aligns its <code>property</code> to a value
		 * determined by its <code>index</code> multiplied by <code>offset</code>.
		 */
		public static function leftAtIndex(object:Object, property:String, left:Number, offset:Number, index:int):void
		{
			object[property] = left + index * offset;
		}
		
		/**
		 * Takes an Array of Objects and - starting at the <code>center</code> value - center-aligns and evenly spaces each
		 * Object's <code>property</code> to a value based on that Object's index multiplied by <code>offset</code>.
		 */
		public static function center(objects:Array, property:String, center:Number, offset:Number):void
		{
			var numObjects:uint = objects.length;
			for(var index:uint = 0; index < numObjects; ++index)
			{
				Alignment.centerAtIndex(objects[index], property, center, offset, index, numObjects);
			}
		}
		
		/**
		 * Takes an Object and - starting at the <code>center</code> value - center-aligns its <code>property</code> to a value
		 * determined by its <code>index</code> multiplied by <code>offset</code>.
		 */
		public static function centerAtIndex(object:Object, property:String, center:Number, offset:Number, index:int, numObjects:uint):void
		{
			object[property] = center - ((numObjects - 1) / 2) * offset + index * offset;
		}
		
		/**
		 * Takes an Array of Objects and - starting at the <code>right</code> value - right-aligns and evenly spaces each
		 * Object's <code>property</code> to a value based on that Object's index multiplied by <code>offset</code>.
		 */
		public static function right(objects:Array, property:String, right:Number, offset:Number):void
		{
			var numObjects:uint = objects.length;
			for(var index:uint = 0; index < numObjects; ++index)
			{
				Alignment.rightAtIndex(objects[index], property, right, offset, index, numObjects);
			}
		}
		
		/**
		 * Takes an Object and - starting at the <code>right</code> value - right-aligns its <code>property</code> to a value
		 * determined by its <code>index</code> multiplied by <code>offset</code>.
		 */
		public static function rightAtIndex(object:Object, property:String, right:Number, offset:Number, index:int, numObjects:uint):void
		{
			object[property] = right - (numObjects - 1) * offset + index * offset;
		}
		
		/**
		 * Takes an Array of Objects and - using <code>min</code> and <code>max</code> values - justify-aligns and evenly
		 * spaces each Object's <code>property</code> to a value based on that Object's index multiplied by a calculated offset.
		 */
		public static function justify(objects:Array, property:String, min:Number, max:Number):void
		{
			var numObjects:uint = objects.length;
			for(var index:uint = 0; index < numObjects; ++index)
			{
				Alignment.justifyAtIndex(objects[index], property, min, max, index, numObjects);
			}
		}
		
		/**
		 * Takes an Object and - using <code>min</code> and <code>max</code> values - justify-aligns its <code>property</code> to a value
		 * determined by its <code>index</code> multiplied by a calculated offset.
		 */
		public static function justifyAtIndex(object:Object, property:String, min:Number, max:Number, index:int, numObjects:uint):void
		{
			object[property] = min + index * ((max - min) / (numObjects - 1));
		}
	}
}