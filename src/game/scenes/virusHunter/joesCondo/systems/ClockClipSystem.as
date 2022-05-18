package game.scenes.virusHunter.joesCondo.systems {

	import ash.core.Engine;
	
	import game.scenes.virusHunter.joesCondo.components.ClockClip;
	import game.scenes.virusHunter.joesCondo.nodes.ClockClipNode;
	import game.systems.GameSystem;

	/**
	 * Because the exact time displayed isn't very important, not bothering to work
	 * through the date object. 
	 */
	public class ClockClipSystem extends GameSystem {

		public function ClockClipSystem() {

			super( ClockClipNode, updateNode, nodeAdded, null );

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );

		} //

		private function updateNode( node:ClockClipNode, time:Number ):void {

			var clock:ClockClip = node.clockClip;

			clock.seconds += time;
			if ( clock.seconds >= 60 ) {

				clock.minutes += Math.floor( clock.seconds/60 );
				clock.seconds = clock.seconds % 60;

				if ( clock.minutes >= 60 ) {

					clock.hours += Math.floor( clock.minutes/60 );
					clock.minutes = clock.minutes % 60;

					if ( clock.hours >= 24 ) {
						clock.hours = clock.hours % 24;
					}

				} //

			} //

			clock.minuteHand.rotation = -90 + (clock.minutes/60)*360;
			clock.hourHand.rotation = -90 + (clock.hours/12)*360;

		} //
		
		private function nodeAdded( node:ClockClipNode ):void {

			var clock:ClockClip = node.clockClip;

			clock.minuteHand = node.display.displayObject[ "minuteHand" ];
			clock.hourHand = node.display.displayObject[ "hourHand" ];

		} //

		/*override public function removeFromEngine( engine:Engine ):void {

			super.removeFromEngine( engine );

		} //*/

	} // End class

} // End package