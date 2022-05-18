package game.scenes.virusHunter.joesCondo.components {
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;

	public class RollingObject extends Component {

		public var myEntity:Entity;

		// to allow multiple pushers, would require a group for doing an id search or a full rolling system.
		public var pusher:Entity;

		// how much velocity to take from pusher on impact.
		public var pushRate:Number = 0.05;

		public var motion:Motion;

		public var friction:Number = 0.9;

		public var radius:Number = 10;

		public function RollingObject( owner:Entity, pusher:Entity=null ) {

			super();

			myEntity = owner;
			this.pusher = pusher;

			motion = owner.get( Motion ) as Motion;
			if ( motion == null ) {
				// It might be good to just define a motion here, but things could get tricky if the entity tries
				// to add one afterwards. For now I won't bother with it.
			} //
			motion.friction = new Point( 0, 0 );
			motion.acceleration = new Point( 0, 100 );

			var clip:MovieClip = owner.get( Display ).displayObject as MovieClip;
			if ( clip != null ) {
				radius = clip.width/2;
			}

		} //

		// Assuming a rolling object handles its own zone hits, objectId should be the id
		// of this -> myEntity.
		// hitterId is the id of the entity that went into the object's zone.
		public function onHit( objectId:String, hitterId:String ):void {

			// check that we have the correct pusher.
			/*if ( ( pusher.get( Id ) as Id ).id != hitterId ) {
				return;
			}*/

			var charMotion:Motion = pusher.get( Motion ) as Motion;

			if ( motion == null || charMotion == null ) {
				return;
			}

			motion.velocity.x += pushRate * charMotion.velocity.x;

			//motion.friction.x = Math.abs(motion.velocity.x)*friction;
			//var clip:MovieClip = (( myEntity.get( Display ) as Display ).displayObject ) as MovieClip;
			//motion.rotationVelocity = (180/Math.PI)*motion.velocity.x / (clip.width/2);

		} //

	} // End RollingObject
	
} // End package