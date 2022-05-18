package game.scenes.virusHunter.joesCondo.classes {

	import flash.display.MovieClip;

	import game.util.TimelineUtils;
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.timeline.Timeline;

	public class AnimatedDoor {

		private var doorEntity:Entity;
		private var timeline:Timeline;

		public function AnimatedDoor( mc:MovieClip, group:Group ) {

			doorEntity = TimelineUtils.convertClip( mc, group );

			timeline = doorEntity.get( Timeline );

		} //

	} // End AnimatedDoor
	
} // End package