package game.scenes.mocktropica.cheeseInterior.components {

	import ash.core.Component;

	public class Interpolation extends Component {

		public static const LINEAR:int = 1;
		public static const QUADRIC:int = 2;
		public static const CUBIC:int = 3;

		public var type:int;

		/**
		 * Counts from 0 to 1 to interpolate the values.
		 */
		public var _timer:Number;


		public function Interpolation( type:int=LINEAR ) {

		} //

	} // End Interpolation

} // End package