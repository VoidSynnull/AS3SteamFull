package com.poptropica
{
	import org.osflash.signals.Signal;

	public class Assert
	{
		public static function assert(expression:Boolean, message:String, trackingChoice:String = null):void
		{
			if(!expression)
			{
				error(message, trackingChoice);
			}
		}
		
		public static function error(message:String, trackingChoice:String = null):void
		{
			errorThrown.dispatch(message, trackingChoice);
			
			throw(new Error(message));
		}
		
		public static var errorThrown:Signal = new Signal(String, String);
	}
}