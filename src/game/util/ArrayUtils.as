package game.util
{
	import flash.geom.Point;

	public class ArrayUtils
	{
		/**
		 * Returns a random element within the array. 
		 * @param elements
		 * @return 
		 * 
		 */
		public static function getRandomElement(elements:Array):*
		{
			return(elements[Math.floor(Math.random() * elements.length)]);
		}
		
		
		/**
		 * Return a random element within the Vector.  Must pass a Vector and cast returned Object;\.
		 * @param elements
		 * @return 
		 * 
		 */
		public static function getRandomElementVector(elements:*):*
		{
			return(elements[Math.floor(Math.random() * elements.length)]);
		}

		public static function addPrefix(elements:Array, prefix:String):void
		{
			for(var n:uint = 0; n < elements.length; n++)
			{
				elements[n] = prefix + elements[n];
			}
		}
		
		public static function merge( array1:Array, array2:Array ):Array
		{
			var i:int = 0;
			for ( i; i < array2.length; i++ )
			{
				array1.push( array2[i] );
			}
			return array1;
		}

		/**
		* Count how many array items are not empty.
		* An item is considered empty if it has a <code>false</code> value.
		*	@param a	The array to search.
		*	@return		The sum of populated array items.
		*/
		public static function arrayPopulation(a:Array):uint {
			var i:uint, num:uint=0;
			for (i=0; i<a.length; i++) {
				if (a[i]) ++num;
			}
			return num;
		}

		/**
		* Search an array for an empty item.
		* An item is considered empty if it has a <code>false</code> value.
		*	@param a	The array to search.
		*	@return		the index of the first empty element found, or -1 if all are full.
		*/
		public static function firstEmptyIndex(a:Array):int {
			var i:int;
			for (i=0; i<a.length; i++) {
				if (!a[i]) return i;
			}
			return -1;
		}

		/**
		 * Count how many times an <code>Object</code> appears in a list.
		 * @param needle	The object to find
		 * @param haystack	The array in which to look
		 * @return The number of occurences of &lt;needle&gt; in &lt;haystack&gt;
		 * 
		 */		
		public static function numOccurences(needle:Object, haystack:Array):uint {
			var count:uint=0;
			for (var i:int=0; i<haystack.length; i++) {
				i = haystack.indexOf(needle, i);
				if (-1 == i) {
					break;
				} else {
					++count;
				}
			}
			return count;
		}
		
		public static function convertAssociativeArrayToURLEncoding(sourceArray:Object, targetArrayName:String, targetObject:Object):void
		{		
			for (var prop:String in sourceArray) 
			{
				targetObject[targetArrayName + "[" + prop + "]"] = sourceArray[prop];
			}
		}
		
		/**
		 * Get an element from an array that matches the pattern.
		 */	
		public static function getMatchingElement(pattern:String, elements:Array):String
		{
			for(var n:int = 0; n < elements.length; n++)
			{
				if(String(elements[n]).indexOf(pattern) > -1)
				{
					return(elements[n]);
				}
			}
			
			return(null);
		}
		
		public static function getMatchingElements(pattern:String, elements:Array):Array
		{
			var matchingElements:Array = new Array();
			for(var n:int = 0; n < elements.length; n++)
			{
				if(String(elements[n]).indexOf(pattern) > -1)
				{
					matchingElements.push(elements[n]);
				}
			}
			
			if( matchingElements.length > 0 )
			{
				return matchingElements;
			}
			else
			{
				return(null);
			}
		}
		
		
		///**
		// copy2DArray( sourceArray )
		// Function to duplicate a 2d array.  Returns the duplicate.
		// sourceArray = any 2d array
		///**
		public static function copy2DArray(sourceArray:Array):Array
		{    
			var destinationArray:Array = [];
			
			for (var i:int = 0; i < sourceArray.length; i++) 
			{ 
				destinationArray[i] = sourceArray[i].slice(); 
			}    
			
			return destinationArray;
		}
		
		/**
		// shuffleArray( array )
		// Function to mix array contents.  Modifies the passed in array, and ensures
		//   the first element doesn't match the last element of the original.
		// array = any array
		*/
		public static function shuffleArray( targetArray:Array ):void
		{	
			var lastSeen:* = targetArray[targetArray.length-1];
			
			for ( var c:int = 0; c < targetArray.length; c++ )
			{
				var temp:* = targetArray[c];
				var randompos:int = Math.floor( Math.random() * targetArray.length ); 
				targetArray[c] = targetArray[ randompos ];
				targetArray[ randompos ] = temp;
			}
			
			// If the first element of the new order is the same as the last
			// element of the old order, swap the first to a new random spot
			if (targetArray[0] == lastSeen) 
			{
				var firstElem:* = targetArray[0];
				var swapSpot:int = Math.ceil(Math.random() * (targetArray.length-1)); // Anywhere but 0
				targetArray[0] = targetArray[swapSpot];
				targetArray[swapSpot] = firstElem;
			}
		}
		
		/**
		// removeElement( element, targetArray )
		// Function to remove an element from an array.  Modifies the passed in array by removing the element.
		// element = an element inside the array you want to remove.  If not found, the array is unchanged.
		// element = any array element
		// targetArray = any array
		*/
		public static function removeElement(element, targetArray:Array):void
		{
			var counter:int = 0; // where are we in targetArray.
			
			while (counter < targetArray.length) 
			{
				if (targetArray[counter] == element) 
				{
					targetArray.splice(counter, 1);
				} 
				else 
				{
					counter++;  // only increment if we're not changing the length
				}
			}
		}
		
		/**
		// removePoint( point, targetArray )
		// Function to remove a point from an array.  Modifies the passed in array by removing the point.
		// point = a point inside the array you want to remove.  If not found, the array is unchanged.
		// targetArray = any array
		*/
		public static function removePoint(point:flash.geom.Point, targetArray:Array):void
		{
			var counter:int = 0; // where are we in targetArray.
			
			while (counter < targetArray.length) 
			{
				if (targetArray[counter].x == point.x && targetArray[counter].y == point.y) 
				{
					targetArray.splice(counter, 1);
				} 
				else 
				{
					counter++;  // only increment if we're not changing the length
				}
			}
		}
		
		/**
		// removeElements( elements, targetArray )
		// Function to remove elements from an array.  Modifies the passed in arry.
		// element = an array of elements to remove.  If none are found, the array is unchanged.
		// targetArray = any array
		*/
		public static function removeElements(elements:Array, targetArray:Array):void
		{
			for (var n:int = 0; n < elements.length; n++) 
			{
				for (var m:Number = 0; m < targetArray.length; m++) 
				{
					if (targetArray[m] == elements[n]) 
					{ 
						targetArray.splice(m, 1); 
						m--; 
					}  // if targetArray size changes, take a step back so we don't miss duplicates.
				}
			}
		}
		
		/**
		// searchArray( element, targetArray )
		// Function to find an element in an array.  Returns true if found, else false.
		// element = an element inside the array you want to find.
		// targetArray = any array
		*/
		public static function searchArray(element, targetArray:Array):Boolean
		{
			var counter:Number = 0; // where are we in targetArray.
			
			while (counter < targetArray.length) 
			{
				if (targetArray[counter] == element) 
				{
					return(true);
				} 
				else 
				{
					counter++;  // only increment if we're not changing the length
				}
			}
			
			return(false);
		}
		
		
		/**
		// findElements(elements, targetArray, dupes)
		// Function to find multiple elements in an array.  Returns any matching elements found, an empty array if none found.
		//   If element if found multiple times, the array returned will contain multiple copies of element if 'dupes'
		//   is set to true, otherwise it will only return an array with one copy of each element it found.
		// elements = an array of elements inside the array you want to find.
		// targetArray = any array
		// dupes = true or false.  Do we want multiple copies of found elements in returned array?
		*/
		public static function findElements(elements:Array, targetArray:Array, dupes:Boolean):Array
		{
			var foundElements:Array = new Array();  // storage for found elements.
			
			for (var n:Number = 0; n < elements.length; n++) 
			{
				for (var m:Number = 0; m < targetArray.length; m++) 
				{
					if (targetArray[m] == elements[n]) 
					{
						if (dupes) 
						{ 
							foundElements.push(targetArray[m]); 
						}
						else 
						{ 
							if (!searchArray(targetArray[m], foundElements)) 
							{ 
								foundElements.push(targetArray[m]); 
							}
						}
					}
				}
			}
			
			return(foundElements); 
		}
		
		/**
		// removeDupes(targetArray)
		// Function to remove all duplicate entries in the array.  Requires the 'searchArray' function defined above.
		// targetArray = any array
		*/
		public static function removeDupes(targetArray:Array):Array 
		{
			var noDupes:Array = new Array();
			var n:int = 0;
			
			targetArray = targetArray.sort();
			
			while (targetArray.length > n) 
			{	
				if (!searchArray(targetArray[n], targetArray.slice(n + 1))) 
				{
					noDupes.push(targetArray[n]);
				}
				
				n++;
			}
			
			return(noDupes);
		}
		
		public static function getIndex(element, targetArray:Array):Number
		{
			var counter:int = 0; // where are we in targetArray.
			
			while (counter < targetArray.length) 
			{
				if (targetArray[counter] == element) 
				{
					return(counter);
				} 
				else 
				{
					counter++;
				}
			}
			
			return(-1);
		}
		
		// rotate a non-jagged 2d array 90 degrees.  Leaves passed in array intact, returns rotated version.
		public static function rotate2DArray(array:Array):Array 
		{
			var arrayHeight:int = array.length;
			var arrayWidth:int = array[0].length;
			var temp:Array = new Array(arrayWidth);
			
			for (var i:Number = 0; i < arrayWidth; i++)
			{
				var t:Array = new Array(arrayHeight);
				
				for (var j:Number = 0; j < arrayHeight; j++)
				{
					t[j] = array[arrayHeight - 1 - j][i];
				}
				
				temp[i] = t;
			}
			
			return(temp);
		}
		
		public static function trace2DArray(array:Array):void 
		{
			var r:String = '[';
			for (var i:Number = 0; i < array.length; i++)
			{
				if (i != 0)
				{
					r += ' ';
				}
				
				r += '[' + array[i].join(',') + ']';
				
				if (i != array.length - 1)
				{
					r += ',\n';
				}
			}
			trace(r + ']');
		}
		
		public static function convertArrayToURLEncoding(sourceArray:Array, targetArrayName:String, targetObject:Object):void
		{		
			for (var i:Number = 0; i < sourceArray.length; i++) 
			{
				targetObject[targetArrayName + "[" + i + "]"] = sourceArray[i];
			}
		}
				
		public static function fillArray(sourceArray:Array, fillElement, total:Number = NaN):void
		{
			if (isNaN(total))
			{
				total = sourceArray.length;
			}
			else
			{
				sourceArray = new Array(total);
			}
			
			for (var n:Number = 0; n < total; n++)
			{
				sourceArray[n] = fillElement;
			}
		}
		
		public static function reverse(sourceArray:Array):void
		{		
			var temp:Array;
			
			for (var i:Number = 0; i < Math.floor(sourceArray.length * .5); i++) 
			{
				temp = sourceArray[i];
				sourceArray[i] = sourceArray[sourceArray.length - i - 1];
				sourceArray[sourceArray.length - i - 1] = temp;
			}
		}
		
		public static function traceObject(obj:Object, prefix:String = ""):void
		{
			for(var n:String in obj)
			{
				if(typeof(obj[n]) == "object")
				{
					trace(prefix + " : " + n + " contains : ");
					traceObject(obj[n], prefix);
					trace(prefix + " : " + n + " end");
				}
				else
				{
					trace(prefix + " : " + n + " : " + obj[n]);
				}
			}
		}
	}
}