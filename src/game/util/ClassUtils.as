package game.util
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	public class ClassUtils
	{
		/**
		 * @see flash.utils.#getDefinitionByName()
		 */
		public static function getClassByName(value:String):Class
		{
			if (value) {
				try
				{
					return getDefinitionByName(value) as Class;
				} 
				catch(error:Error) 
				{
					trace("ERROR: ClassUtils::getClassByName() could not get a class for", value);
					trace(error.getStackTrace());
				}
			}
			return null;
		}
		
		/**
		 * @see flash.utils.#getQualifiedClassName()
		 */
		public static function getNameByObject(value:*):String
		{
			if (value) {
				try
				{
					return getQualifiedClassName(value);
				} 
				catch(error:Error) 
				{
					trace("ERROR: ClassUtils::getNameByObject() could not get a name for", value);
					trace(error.getStackTrace());
				}
			}
			return null;
		}
		
		/**
		 * @see flash.utils.#getDefinitionByName()
		 * @see flash.utils.#getQualifiedClassName()
		 */
		public static function getClassByObject(value:*):Class
		{
			if (value) {
				try
				{
					return getDefinitionByName(getQualifiedClassName(value)) as Class;
				} 
				catch(error:Error) 
				{
					trace("ERROR: ClassUtils::getClassByObject() could not get a class for", value);
					trace(error.getStackTrace());
				}
			}
			return null;
		}
	}
}