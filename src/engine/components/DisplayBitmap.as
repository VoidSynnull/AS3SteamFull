package engine.components
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import ash.core.Component;
	
	public class DisplayBitmap extends Component
	{
		/**
		 * The <code>Bitmap</code> which is the
		 * visual representation of the owning <code>Entity</code>.
		 * 
		 * @default	null
		 */		
		public var displayObject:Bitmap;

		/**
		 * The <code>DisplayObjectContainer</code>
		 * which is the <code>parent</code> property of this component's
		 * <code>displayObject</code>.
		 * 
		 * @default	null
		 */		
		public var container:DisplayObjectContainer;

		/**
		 * The <code>BitmapData</code> which encapsulates the pixels of
		 * the raster image. 
		 * 
		 * @default	null
		 */		
		//public var data:BitmapData;
		
		/**
		 * A flag indicating that the basic positional properties (<code>x</code>, <code>y</code> and <code>rotation</code>)
		 * of this component's <code>displayObject</code> have been updated by
		 * a paired <code>Spatial</code> component.
		 * 
		 * @default	false
		 */		
		public var syncedWithSpatial:Boolean = false;
		
		/**
		 * When set, this flag indicates that the <code>displayObject</code>
		 * should not be modified by a paired <code>Spatial</code> component.
		 * It functions as a "Do Not Disturb" sign.
		 * <p>Clearing the flag allows
		 * the <code>displayObject's</code> basic positional properties to
		 * be overwritten by a paired <code>Spatial</code> component.</p>
		 * 
		 * @default	false
		 */		
		public var isStatic:Boolean = false;
		
		/**
		 * When set, this flag indicates that the <code>displayObject's</code>
		 * <code>visible</code> should be overwritten. This overwriting takes place
		 * regardless of the setting of <code>isStatic</code> unless the owning
		 * <code>Entity</code> is sleeping and not paused.
		 * 
		 * @default	true
		 */		
		public var visible:Boolean = true;
		
		/**
		 * When set, this flag indicates that the <code>displayObject's</code>
		 * <code>alpha</code> should be overwritten. This overwriting takes place
		 * regardless of the setting of <code>isStatic</code>.
		 * 
		 * @default	1.0
		 */		
		public var alpha:Number = 1;
		//public var smoothPosition:Boolean = false;

		public function DisplayBitmap() {}

	}
}
