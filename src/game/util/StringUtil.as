package game.util 
{

	/**
	 * Utilities for string manipulation 
	 */
    public class StringUtil
    {
		public static const NEW_LINE:String = "\n";
		
        public function StringUtil()
        {
        }
				
		/**
		 * Removes and returns the last character ina string
		 * @param	string
		 * @return
		 */
		public static function removeLast( string:String ):String
		{
			return string.substring(0, string.length - 1);
		}
		
		/**
		 * Removes and returns the first character in a string
		 * @param	string
		 * @return
		 */
		public static function removeFirst( string:String ):String
		{
			return  string.substring(1, string.length);
		}
		
		/**
		 * Removes whitespace from string
		 * @param	string
		 * @return
		 */
		public static function removeWhiteSpace( string:String ):String
		{
			var rex:RegExp = /[\s\r\n]*/gim;			
			return  string.replace(rex,'');
		}

		public static function UCFirst(s:String):String
		{
			return s ? s.charAt(0).toUpperCase() + s.substr(1) : '';
		}
		
		/**
		 * Converts a String to camel-case with the first letter lower-cased.
		 * @param String A String to lower camel-case.
		 * @return A String in the format of <code>camelCase</code>.
		 */
		public static function toLowerCamelCase(string:String):String
		{
			return string.substr(0, 1).toLowerCase() + string.substr(1);
		}
		
		/**
		 * Converts a String to camel-case with the first letter upper-cased.
		 * @param String A String to upper camel-case.
		 * @return A String in the format of <code>CamelCase</code>.
		 */
		public static function toUpperCamelCase(string:String):String
		{
			return string.substr(0, 1).toUpperCase() + string.substr(1);
		}
	}
}
