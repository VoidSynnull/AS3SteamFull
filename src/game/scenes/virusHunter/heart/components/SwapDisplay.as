package game.scenes.virusHunter.heart.components {

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	import engine.components.Spatial;

	public class SwapDisplay extends Component {

		public var mainDisplay:Display;
		public var mainSpatial:Spatial;

		/**
		 * The display object to swap out.
		 */
		public var saveClip:DisplayObjectContainer;

		/**
		 * if true, position and scaling are saved/restored when clips are swapped.
		 */
		public var savePosition:Boolean = false;

		public function SwapDisplay( e:Entity, secondClip:DisplayObjectContainer ) {

			super();

			this.mainDisplay = e.get( Display );
			this.mainSpatial = e.get( Spatial );

			this.saveClip = secondClip;

		} //

		public function swap():void {

			var tmp:DisplayObjectContainer = mainDisplay.displayObject;

			var ind:int = tmp.parent.getChildIndex( tmp );
			tmp.parent.addChildAt( saveClip, ind );

			mainDisplay.displayObject = saveClip;
			if ( savePosition ) {

				mainSpatial.x = saveClip.x;
				mainSpatial.y = saveClip.y;
				mainSpatial.rotation = saveClip.rotation;

			} //

			tmp.parent.removeChild( tmp );
			saveClip = tmp;

		} // swap()

	} // End SwapDisplay

} // End package