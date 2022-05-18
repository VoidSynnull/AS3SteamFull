package game.data.photos {
	
	/**
	 * PhotoData encapsulates the values necessary
	 * to describe the conditions which will trigger a photo.
	 * @author Mike H./Rich Martin
	 * 
	 */
	public class PhotoData
	{
		import flash.utils.Dictionary;

		public static const TRIGGER_EVENT:String	= "event";
		public static const TRIGGER_ITEM:String		= "item";
		public static const TRIGGER_LOCATION:String	= "location";

		public var id:String;						// The CMS value defines the photo's id
		public var trigger:String					// "event" "item" or "location"
		public var params:Dictionary;

		/**
		 * Creates a <code>PhotoData</code> instance,
		 * optionally configuring it with a given <code>xml</code> document.
		 * @param xml	An optional xml document whose <code>DOCTYPE</code> is <code>photos</code>
		 */		
		public function PhotoData( xml:XML )
		{
			params = new Dictionary();
			if (xml)
			{
				parse(xml);
			}
		}

		/**
		 * Populates instance variables from values
		 * found in the given xml.
		 * @param xml	An xml document whose <code>DOCTYPE</code> is <code>photos</code>
		 */		
		public function parse( xml:XML ):void
		{
			if (xml.attribute('id')) {
				id = xml.@id;
			}
			if (xml.attribute('trigger')) {
				trigger = xml.@trigger;
			}
			
			for each (var param:XML in xml.param) {
				var key:String = param.@id;
				params[key] = param.toString();
			}
		}

		/**
		 * Provides an overview of an instance's properties, useful for debugging.
		 */		
		public function toString():String {
			return '[PhotoData id:' + id + ' trigger:' + trigger + ' params:' + params + ']';
		}
		
	}
	
}