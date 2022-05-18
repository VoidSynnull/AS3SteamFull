package game.scenes.mocktropica.cheeseInterior.systems {

	import ash.core.Engine;
	
	import game.scenes.mocktropica.cheeseInterior.components.ValueMatch;
	import game.scenes.mocktropica.cheeseInterior.data.VariableRange;
	import game.scenes.mocktropica.cheeseInterior.nodes.ValueMatchNode;
	import game.systems.GameSystem;

	/**
	 * Because the exact time displayed isn't very important, not bothering to work
	 * through the date object. 
	 */
	public class ValueMatchSystem extends GameSystem {

		public function ValueMatchSystem() {

			super( ValueMatchNode, this.updateNode, null, null );

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );

		} //

		private function updateNode( node:ValueMatchNode, time:Number ):void {

			var valueMatch:ValueMatch = node.valueMatch;
			if ( valueMatch.pause == true ) {
				return;
			}

			var matchVars:Vector.<VariableRange> = valueMatch.matchVars;

			var srcVar:VariableRange = valueMatch.sourceVar;
			var destVar:VariableRange;

			var t:Number = ( srcVar.object[ srcVar.variable ] - srcVar.minValue ) / ( srcVar.maxValue - srcVar.minValue );

			for( var i:int = matchVars.length-1; i >= 0; i-- ) {

				destVar = matchVars[ i ];
				destVar.object[ destVar.variable ] = destVar.minValue + t*( destVar.maxValue - destVar.minValue );

			} //

		} //

		/*private function nodeAdded( node:ValueMatchNode ):void {
		} //

		private function nodeRemoved( node:ValueMatchNode ):void {
		} //*/

		/*override public function removeFromEngine( engine:Engine ):void {

			super.removeFromEngine( engine );

		} //*/

	} // End class

} // End package