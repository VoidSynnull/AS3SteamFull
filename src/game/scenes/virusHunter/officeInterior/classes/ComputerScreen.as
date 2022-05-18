package game.scenes.virusHunter.officeInterior.classes {

	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;

	// Mainly need this to properly track the timeline signals for the computer screen movieclips.
	public class ComputerScreen {

		// in theory, we could just store the timeline, but i suppose the entity could disappear.
		public var entity:Entity;

		public function ComputerScreen( e:Entity ) {

			entity = e;
			var t:Timeline = entity.get( Timeline ) as Timeline;

			t.labelReached.add( this.labelReached );
			t.playing = true;
		} //

		public function labelReached( label:String ):void {

			var t:Timeline = entity.get( Timeline ) as Timeline;
			t.looped = true;

			if ( label == "off" ) {
				t.playing = true;
			} else if ( label == "on" ) {
				t.playing = true;
			} //

		} //

	} // End ComputerScreen

} // End package