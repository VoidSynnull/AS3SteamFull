package game.scenes.lands.shared.classes {

	import flash.display.DisplayObjectContainer;

	public class SharedTipTarget {

		public var tipType:String;
		public var tipText:String;

		public var clip:DisplayObjectContainer;

		/**
		 * optional clip roll over frame on roll over.
		 */
		public var rollOverFrame:int = 0;

		/**
		 * tooltip offset from registration point.
		 */
		public var offsetX:int = 0;
		public var offsetY:int = 0;

		public function SharedTipTarget( clip:DisplayObjectContainer=null, type:String=null, text:String=null ) {

			this.clip = clip;
			this.tipType = type;
			this.tipText = text;

		} //

	} // class
	
} // package