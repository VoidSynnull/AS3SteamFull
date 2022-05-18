package game.scenes.mocktropica.cheeseInterior.components {

	import ash.core.Component;
	
	import game.scenes.mocktropica.cheeseInterior.data.VariableRange;

	/**
	 * When a process is changing a source variable ( such as position )
	 * this component will match corresponding values in the watch objects ( for example, indicators on a display. )
	 */
	public class ValueMatch extends Component {

		public var sourceVar:VariableRange;
		public var matchVars:Vector.<VariableRange>;

		/**
		 * If pause=true, values will stop matching until unpaused.
		 */
		public var pause:Boolean = false;

		public function ValueMatch( sourceObject:Object, varName:String, minValue:Number=0, maxValue:Number=1 ) {

			this.sourceVar = new VariableRange( sourceObject, varName, minValue, maxValue );

			this.matchVars = new Vector.<VariableRange>();

		} //

		public function addMatchVariable( matchObject:Object, varName:String, minValue:Number=0, maxValue:Number=1 ):void {

			this.matchVars.push( new VariableRange( matchObject, varName, minValue, maxValue ) );

		} //

	} // End ValueMatch

} // End package