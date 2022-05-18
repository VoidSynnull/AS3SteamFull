package game.scenes.mocktropica.cheeseInterior.data {

	public class VariableRange {

		public var object:Object;
		public var variable:String;

		public var minValue:Number;
		public var maxValue:Number;

		public function VariableRange( obj:Object, varName:String, minValue:Number=0, maxValue:Number=1.0 ) {

			this.object = obj;
			this.variable = varName;

			this.minValue = minValue;
			this.maxValue = maxValue;

		} //

	} // End VariableRange

} // End package