package com.poptropica.platformSpecific
{
	import com.poptropica.interfaces.IPlatform;
	
	import flash.utils.Dictionary;
	
	import org.assetloader.core.ILoader;
	import org.assetloader.loaders.SWFLoader;
	
	public class Platform implements IPlatform
	{
		public function Platform()
		{
			_classes = new Dictionary();
			_classes[ILoader] = SWFLoader;
		}
		
		/**
		 * Creates an instance of the Class that implements passed Class. 
		 * @param _class - generaly an Interface Class, used as the key to retrieve the Class that instantiates it. 
		 * @param paramObject - Object storing parameters used to instantiate class
		 * @return 
		 */
		public function getInstance( keyClass:Class, paramObject:Object = null) : Object
		{
			if(_classes[keyClass])
			{	
				//if params, params.
				if(paramObject)
				{
					/**
					 * Ulitmate ugly down below
					 * I wrote this to account for classes that need more than 1 parameter passed to the constructor
					 * If you need more than 4, just use a Value Object.
					 */
					_propsArray = paramObject as Array;	// TODO :: Seems like this could just be in function scope, or paramObject used directly
					
					switch(_propsArray.length){
						case 1 :
							return new _classes[keyClass](_propsArray[0]);
							break;
						case 2 :
							return new _classes[keyClass](_propsArray[0], _propsArray[1]);
							break;
						case 3 :
							return new _classes[keyClass](_propsArray[0], _propsArray[1],_propsArray[2]);
							break;
						case 4 :
							return new _classes[keyClass](_propsArray[0], _propsArray[1],_propsArray[2],_propsArray[3]);
							break;
					}
					
				}
				return new _classes[keyClass]();
			}
			else
			{
				trace( "WARNING :: Platform :: getInstance : No class found for:" + keyClass);
				return null;
			}
		}
		
		public function checkClass( keyClass : Class) : Boolean
		{
			if(_classes[keyClass]){
				return true;
			}
			return false;
		}
		
		/** Dictionary of Classes, using the Interface Class the stored Class implements as the key */
		protected var _classes:Dictionary;
		/** Used to store Class paramters, is overridden on getInstance call*/
		protected var _propsArray:Array;
	}
}