package game.util
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import org.as3commons.collections.utils.ArrayUtils;
	
	/*****************************************************
	 * Utils for parsing xml.
	 * <p>Plus validation utilities.</p>
	 * <p>Plus some handy data-wrangling utilities.</p>
	 * 
	 * <p>Date : 5/2/09</p>
	 * 
	 * @author	Billy Belfield, Bard McKinley, Rich Martin
	 * ***************************************************/
	public class DataUtils
	{				 						
		/**
		 * Convert Strings to Boolean
		 * @param	value	Any string, or null
		 * @return	true if <code>value</code> equals <code>String('true')</code>, false otherwise
		 */
		public static function getBoolean(value:String):Boolean
		{
			if(value == "true")
			{
				return(true);
			}
			else
			{
				return(false);
			}
		}
		
		/**
		 * Convert Strings to Numbers
		 * @param value	Any string, or null
		 * @return NaN if <code>value</code> can't be cast to <code>Number</code>, otherwise the cast.
		 */		
		public static function getNumber(value:String):Number		
		{
			if(isNull(value))
			{
				return(NaN);
			}
			else
			{
				return(Number(value));
			}
		}
		
		// Convert xml to Point
		public static function getPoint(xml:*):Point		
		{
			if(xml is XMLList)
			{
				xml = xml[0];
			}
			
			var newPoint:Point = new Point(0, 0);
			
			if(xml != null)
			{
				if(!isNull(xml.x))
				{
					newPoint.x = xml.x;
				}
				
				if(!isNull(xml.y))
				{
					newPoint.y = xml.y;
				}
			}
			
			return(newPoint);
		}
		
		// Convert Strings to Arrays
		public static function getArray(value:String):Array		
		{
			if(isNull(value))
			{
				return([]);
			}
			else
			{
				value = removeWhiteSpace(value);
				return(value.split(","));
			}
		}

		public static function getUint(value:String):uint
		{
			if(isNull(value))
			{
				return(0);
			}
			else
			{
				return(uint(value));
			}	
		}
		
		public static function getString(value:String):String
		{
			if(isNull(value))
			{
				return(null);
			}
			else
			{
				return(value);
			}	
		}

		public static function getNonNullString(value:String):String
		{
			if(isNull(value))
			{
				return("");
			}
			else
			{
				return(value);
			}	
		}
		
		/**
		 * Inspects an <code>Object</code> for a named property and return its value.
		 * @param o	The <code>Object</code> to be searched
		 * @param p	The name of the property to be searched for
		 * @return The value of property <code>p</code>, or <code>null</code> if <code>o</code> does not contain property <code>p</code>
		 * 
		 */		
		public static function getProp(o:Object, p:String):* {
			var theProperty:* = null;
			if (o.hasOwnProperty(p)) {
				theProperty = o[p];
			}
			return theProperty;
		}

		/**
		 * Evaluates a given <code>Object</code> in an effort to dedide whether it is useless.
		 * Here, useless means really <code>null</code>, just plain empty or void-y. 
		 * @param element	The <code>Object</code> to be evaluated
		 * @return <code>true</code> if <code>element</code> is <code>null</code>,
		 * has zero length, or is the empty string,
		 * or a string-ified voidoid.
		 * Otherwise, a <code>true</code> result suggests that <code>element</code>
		 * is presumable non-empty and potentially useful.
		 */		
		public static function isNull(element:*):Boolean
		{
			if (element == null)
			{
				return(true);
			}
			
			if(element.hasOwnProperty("length"))
			{
				if(element.length == 0)
				{
					return(true);
				}
			}
			
			if(typeof(element) is String)
			{
				if (removeWhiteSpace(element) == "" || element == "undefined" || element == "NaN")
				{
					return(true);
				}
			}

			return(false);
		}
		
		/**
		 * Converts a <code>String</code> value to a <code>Number</code> if possible,
		 * otherwise returns the given default value.
		 * @param value	The <code>String</code> to be converted
		 * @param defaultValue	The <code>Number</code> to be used in case conversion is unsuccessful
		 * @return <code>value</code> cast as <code>Number</code>,
		 * or <code>defaultValue</code> if the cast can't be made
		 */		
		public static function useNumber(value:String, defaultValue:Number):Number
		{
			var returnValue:Number = getNumber(value);
			
			if (isNaN(returnValue))
			{
				returnValue = defaultValue;
			}
			
			return(returnValue);
		}
		
		/**
		 * Examines <code>value</code> for useful <code>String</code> data. Otherwise,
		 * returns the given default <code>String</code>.
		 * <p>Null or empty strings are not considered useful, nor are
		 * strings containing only whitespace, nor are <code>String("undefined")</code>
		 * and <code>String("NaN")</code></p>
		 * 
		 * @param value	The string to be inspected
		 * @param defaultValue	The <code>String</code> to be used in case if <code>value</code> is not useful
		 * @return <code>value</code>, if it is a useful <code>String</code>, <code>defaultValue</code> if not
		 * 
		 */		
		public static function useString(value:String, defaultValue:String):String
		{
			var returnValue:String = getString(value);
			
			if (isNull(returnValue))
			{
				returnValue = defaultValue;
			}
			
			return(returnValue);
		}
	
		public static function useArray(value:String, defaultValue:Array):Array
		{
			var returnValue:Array = getArray(value);
			
			if (isNull(returnValue))
			{
				returnValue = defaultValue;
			}
			
			return(returnValue);
		}
		
		public static function useBoolean(value:String, defaultValue:Boolean):Boolean
		{
			if(isNull(value))
			{
				return(defaultValue);
			}
			else
			{
				return(getBoolean(value));
			}
		}
		
		public static function isValidStringOrNumber( value:* ):Boolean
		{
			if ( DataUtils.validString( value ) )
			{
				return true
			}
			else if ( value is Number )
			{
				if( isNaN( value ) )
				{
					return false;
				}
				return true;
			}
			return false;
		}
		
		public static function validString( value:* ):Boolean
		{
			if ( value is String )
			{
				if ( value == null )
				{
					return false;
				}
				else if ( value == "null" )
				{
					return false;
				}
				else if ( value == "undefined" )
				{
					return false;
				}
				else if ( value == "" )
				{
					return false;
				}
				else if(String(value).length <= 0){
					return false;
				}
				return true;
			}
			return false;
		}
		
		public static function fixXMLNewLines(str:String):String
		{
			var new_str:String = str.split("\\n").join("\n");
			return(new_str);
		}
		
		public static function removeWhiteSpace(str:String):String
		{
			if(str != null)
			{
				var rex:RegExp = /[\s\r\n]*/gim;

				return(str.replace(rex,""));
			}
			else
			{
				return("");
			}
		}
		
		/**
		 * Converts a string to a boolean or a number if it matches the requirements for that type.  Otherwise it leaves the argument as a string.
		 */
		public static function castToType(value:String):*
		{
			if(value == "true")
			{
				return(true);
			}
			else if(value == "false")
			{
				return(false);
			}
			else if(!isNaN(Number(value)))
			{
				return(Number(value));
			}
			else
			{
				return(value);
			}
		}

		/**
		 * Merges two xml files modifying the original.  Has support for handling matching attributes.
		 * @param xml1 : 'source' xml file.  Will be altered as a result of calling this method to contain children of xml2.
		 * @param xml2 : An xml file which will have its children appended to xml1.  Will not be altered.
		 * @param [attribute] : An optional parameter as an attribute to look for in both xml files.  If it is found in both the child node will be appended based on the operation chosen.
		 * @param [operationForMatchingAttributes] : Required if above param is used.  Determines what happens when matching attributes are found in xml1 and xml2.
		 * <listing version="3.0">
 * valid operations:
 *       "ignore" : this will cause the node in xml2 to NOT be appended to xml1.
 *       "combine" : this will cause the subnodes with the node with the matching attribute to be added to the matching node in xml1.
 *    
 * example:
 * 
var x1:XML =
&lt;sounds&gt;
	&lt;sound type="effect"&gt;
		&lt;asset&gt;"four"&lt;/asset&gt;
		&lt;asset&gt;"five"&lt;/asset&gt;
		&lt;asset&gt;"six"&lt;/asset&gt;
	&lt;/sound&gt;
&lt;/sounds&gt;;

var x2:XML =
&lt;sounds&gt;
	&lt;sound type="effect"&gt;
		&lt;asset&gt;"one"&lt;/asset&gt;
		&lt;asset&gt;"two"&lt;/asset&gt;
		&lt;asset&gt;"three"&lt;/asset&gt;
	&lt;/sound&gt;
&lt;/sounds&gt;;

result of 'trace(mergeXML(x1, x2, "type", "ignore"));' :

&lt;sounds&gt;
	&lt;sound type="effect"&gt;
		&lt;asset&gt;"four"&lt;/asset&gt;
		&lt;asset&gt;"five"&lt;/asset&gt;
		&lt;asset&gt;"six"&lt;/asset&gt;
	&lt;/sound&gt;
&lt;/sounds&gt; 

result of 'trace(mergeXML(x1, x2, "type", "combine"));' : 

&lt;sounds&gt;
	&lt;sound type="effect"&gt;
		&lt;asset&gt;"four"&lt;/asset&gt;
		&lt;asset&gt;"five"&lt;/asset&gt;
		&lt;asset&gt;"six"&lt;/asset&gt;
		&lt;asset&gt;"one"&lt;/asset&gt;
		&lt;asset&gt;"two"&lt;/asset&gt;
		&lt;asset&gt;"three"&lt;/asset&gt;
	&lt;/sound&gt;
&lt;/sounds&gt;

 * </listing>
		 */
		public static function mergeXMLAttributes(xml1:XML, xml2:XML, attribute:* = null, operationForMatchingAttributes:String = null):XML
		{
			if(xml1 == null) { return(xml2); }
			if(xml2 == null) { return(xml1); }
			
			var childList:XMLList = xml2.children();
			var childNode:XML;
			var sourceChildList:XMLList = xml1.children();
			var sourceChildNode:XML;
			var append:Boolean = true;
			var subNode:XML;
			var subNodeList:XMLList;
			var sourceChildAttributes:Array;
			
			for each(childNode in childList)
			{
				if(attribute != null && operationForMatchingAttributes != null)
				{
					for each(sourceChildNode in sourceChildList)
					{
						//matchAttribute = false;
						
						if(childNode.attribute(attribute) || typeof(attribute) == "object")
						{
							if(typeof(attribute) == "object")
							{
								for each (var att:XML in sourceChildNode.@*)
								{
									sourceChildAttributes.push(att.name());
								}
							}
							
							if((typeof(attribute) == "string" && childNode.attribute(attribute) == sourceChildNode.attribute(attribute)) ||
							   (typeof(attribute) == "object" && org.as3commons.collections.utils.ArrayUtils.arraysMatch(sourceChildAttributes, attribute)))
							{
								if(operationForMatchingAttributes == "ignore")
								{
									append = false;
									break;
								}
								else if(operationForMatchingAttributes == "combine")
								{
									append = false;
									
									subNodeList = childNode.children();
									
									for each(subNode in subNodeList)
									{
										sourceChildNode.appendChild(subNode);
									}
									
									break;
								}
							}
						}
					}
				}
				
				if(append) { xml1.appendChild(childNode); }
			}
			
			return(xml1);
		}
		
		/**
		 * Merges xml together
		 * @param xml1
		 * @param xml2
		 * @param operationForMatchingAttributes - optional param to specify method merge, valid values are "ignore" & "merge"
		 * @return 
		 */
		public static function mergeXML(xml1:XML, xml2:XML, operationForMatchingAttributes:String = null):XML
		{
			if(xml1 == null) { return(xml2); }
			if(xml2 == null) { return(xml1); }
			
			var childList:XMLList = xml2.children();
			var childNode:XML;
			var sourceChildList:XMLList = xml1.children();
			var sourceChildNode:XML;
			var append:Boolean = true;
			var subNode:XML;
			var subNodeList:XMLList;
			var sourceChildAttributes:Array;
			var childAttributes:Array;
			var matchAttribute:Boolean = false;
			var currentAttribute:XML;
			
			for each(childNode in childList)
			{
				childAttributes = new Array();
				
				// create a list of the childNode attributes to compare against the sourceChildNodes. 
				for each (currentAttribute in childNode.@*)
				{
					childAttributes.push(currentAttribute.valueOf().toString());
				}
				
				for each(sourceChildNode in sourceChildList)
				{
					matchAttribute = false;
					append = true;
					
					sourceChildAttributes = new Array();
					
					for each (currentAttribute in sourceChildNode.@*)
					{
						sourceChildAttributes.push(currentAttribute.valueOf().toString());
					}
					
					// If the values of the attributes all match, append the childNode.
					if(org.as3commons.collections.utils.ArrayUtils.arraysMatch(sourceChildAttributes, childAttributes))
					{
						matchAttribute = true;
					}
					
					//trace("comparing arrays : \n" + sourceChildAttributes + "\n" + childAttributes + "\n match : "+ matchAttribute);

					if(matchAttribute)
					{
						// if you have two chunks of data that are the same will ignored added data and proceed
						if(operationForMatchingAttributes == "ignore")
						{
							append = false;
							break;
						}
						// if you have two chunks of data that are the same will combine them together
						else if(operationForMatchingAttributes == "combine")
						{
							append = false;
							
							subNodeList = childNode.children();
							
							for each(subNode in subNodeList)
							{
								sourceChildNode.appendChild(subNode);
							}
							break;
						}
					}
				}
				
				if(append) { xml1.appendChild(childNode); }
			}
			
			return(xml1);
		}

		// this method is now deprecated. Use JSON.stringify() instead for simplicity and efficiency _RAM
		public static function toJSONString(o:Object):String {
			return JSON.stringify(o);
		}

		public static function toPrunedJSONString(o:Object):String {
			function pruneNulls(key:*, value:*):* {
				if (null == value) {
					return undefined;
				}
				if ((value is Number) && (isNaN(value))) {
					return undefined;
				}
				return value;
			}
			return JSON.stringify(o, pruneNulls);
		}

		public static function anyOfTheseArgsIsANumber(...args):Boolean {
			var satisfied:Boolean = false;
			while (args.length) {
				var theValue:Number = args.shift();
				satisfied = !isNaN(theValue);
				if (satisfied) {
					return satisfied;
				}
			}
			return satisfied;
		}
		
		public static function allOfTheseArgsAreNumbers(...args):Boolean 
		{
			while (args.length) 
			{
				if(isNaN(args.shift())) { return false; }
			}
			return true;
		}

		public static function arrayFromObject(o:Object):Array {
			var theArray:Array = [];
			for (var prop:String in o) {
				theArray[prop] = o[prop];
			}
			return theArray;
		}
		
		public static function getDictionaryLength(dictionary:Dictionary):int
		{
			var count:int = 0;
			
			for (var key:Object in dictionary)
			{
				count++;
			}
			
			return(count);
		}
		
		/**
		 *  Returns <code>true</code> if the object reference specified
		 *  is a simple data type. The simple data types include the following:
		 *  <ul>
		 *    <li><code>String</code></li>
		 *    <li><code>Number</code></li>
		 *    <li><code>uint</code></li>
		 *    <li><code>int</code></li>
		 *    <li><code>Boolean</code></li>
		 *    <li><code>Date</code></li>
		 *    <li><code>Array</code></li>
		 *  </ul>
		 *
		 *  @param value Object inspected.
		 *
		 *  @return <code>true</code> if the object specified
		 *  is one of the types above; <code>false</code> otherwise.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		public static function isSimple(value:Object):Boolean
		{
			var type:String = typeof(value);
			switch (type)
			{
				case "number":
				case "string":
				case "boolean":
				{
					return true;
				}
					
				case "object":
				{
					return (value is Date) || (value is Array);
				}
			}
			
			return false;
		}

	}
}
