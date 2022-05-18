package game.scenes.lands.shared.classes {

	/**
	 * A collectible resource is a Land ResourceType that has an associated swf or bitmap
	 * that can be displayed or show up in Lands. Currently this is only "poptanium"
	 */
	import flash.display.BitmapData;

	public class CollectibleResource extends ResourceType {

		/**
		 * swf file name for the collectible on screen.
		 */
		public var swf:String;
		
		public var bitmap:BitmapData;
		
		/**
		 * if true, the resource type should be bitmapped so it doesn't
		 * have to be reloaded every time it's needed. this means you
		 * can't currently have it animated though. Maybe later use the
		 * bitmap animations but that's a pain as well.
		 */
		public var useBitmap:Boolean = false;

		public function CollectibleResource() {

			super();

		} //

	} // class
	
} // package