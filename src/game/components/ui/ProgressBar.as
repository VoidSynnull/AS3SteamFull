package game.components.ui
{
	import ash.core.Component;
	
	public class ProgressBar extends Component
	{
		public function ProgressBar()
		{
			
		}
		
		/**
		 * Percent value.
		 * Assumes a decimal percentage, range 0 to 1.
		 */
		public var percent:Number = 0;
		/**
		 * Increment at which the bar will update its display.
		 */
		public var scaleRate:Number = .01;
		/**
		 * Instance name of the asset used as the progrress dispaly.
		 * Display's x scale will be tied to percent value.
		 */
		public var barAsset:String = "bar";
		/**
		 * The initial x scale of the bar asset, prior to any adjustments by system.
		 * This will be the maximum x scale the asset can reach.
		 */
		public var barMaxScaleX:Number;
		/**
		 * Defines maximum percentage value.
		 * Generally 1 should be used. 
		 */
		public var range:Number = 1;
		
		public var hideWhenInactive:Boolean = true;
		public var hideWait:Number = 2;
		public var hideWaitTime:Number = 0;
		
		/**
		 * Tells the system to set the bar to 0
		 */
		public var reset : Boolean = false;
		
		/**
		 * Component used to retrieve a percentage value from. 
		 */
		public var sourceComponent:*;
		/**
		 * Property of sourceComponent to be used as percentage value.
		 */
		public var sourceProperty:String;
	}
}
