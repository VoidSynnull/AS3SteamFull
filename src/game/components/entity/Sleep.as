
package game.components.entity
{	
	import flash.geom.Rectangle;
	
	import ash.core.Component;

	/**
	 * Sleep is checked in most systems to determine if an entity's components should be included in the update loop. If an entity moves offscreen 'sleeping'
	 * will be set to 'true'.
	 * The offscreen sleep can be manually controlled if 'ignore' is set to true. 
	 */
	public class Sleep extends Component
	{
		public function Sleep( isSleeping:Boolean = false, ignoreOffscreenSleep:Boolean = false )
		{
			this.sleeping = isSleeping;
			this.ignoreOffscreenSleep = ignoreOffscreenSleep;
		}

		/**
		 * When true, the owning <code>Entity</code> will not be updated by systems
		 */		
		public var sleeping:Boolean;

		/**
		 * When true, <code>sleeping</code> will not be updated by <code>SleepSystem</code>, which normally updates <code>sleeping</code> based on position
		 */		
		public var ignoreOffscreenSleep:Boolean;

		/**
		 * A bounding rectangle outside of which the owning <code>Entity</code> will go to sleep.
		 */		
		public var zone:Rectangle;
		
		/**
		 * When true, an entity's edge will be used instead of it's display object for testing overlap with the viewport.
		 */	
		public var useEdgeForBounds:Boolean;
	}
}