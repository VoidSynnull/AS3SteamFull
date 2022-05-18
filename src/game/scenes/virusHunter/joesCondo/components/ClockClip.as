package game.scenes.virusHunter.joesCondo.components {

	import flash.display.DisplayObject;
	
	import ash.core.Component;

	public class ClockClip extends Component {

		public var minuteHand:DisplayObject;
		public var hourHand:DisplayObject;

		// Not really necessary to track these separately but simpler.
		public var seconds:Number;
		public var minutes:Number;
		public var hours:Number;

		public function ClockClip( useCurrentTime:Boolean=true ) {

			if ( useCurrentTime ) {

				var d:Date = new Date();

				seconds = d.seconds;
				minutes = d.minutes;
				hours = d.hours;

			} else {

				seconds = 0;
				minutes = 0;
				hours = 0;

			} //

		} //

		public function setTime( hour:int, minute:int ):void {

			hours = hour % 24;
			minutes = minute % 60;

			minuteHand.rotation = -90 + (minutes/60)*360;
			hourHand.rotation = -90 + (hours/12)*360;

		} //

	} // End ClockClip
	
} // End package