package game.scenes.lands.shared.components {

	import flash.display.DisplayObject;
	
	import ash.core.Component;

	public class BarComponent extends Component {

		/**
		 * don't want to bother with Display/Spatial components for just a life bar.
		 */
		public var barClip:DisplayObject;

		/**
		 * scale rate per tick, don't need timer.
		 * Maximum change in scale percent per tick. This is the decimal percent change, so a '1' indicates
		 * that the bar can always update to the current value instantly ( 100% scale change )
		 */
		public var scaleRate:Number = 1;

		public var dataObj:*;
		public var curProp:String;
		public var maxProp:String;

		public var maxValue:Number;

		public function BarComponent( bar_clip:DisplayObject, obj:*, curValueProp:String, maxValue:Number ) {

			this.barClip = bar_clip;

			this.dataObj = obj;
			this.curProp = curValueProp;

			this.maxValue = maxValue;

		} //

	} // class

} // package