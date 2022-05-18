package game.scenes.virusHunter.joesCondo.creators {

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.SceneObjectMotion;
	import game.scenes.virusHunter.joesCondo.components.RollingObject;
	
	// Create some basic clip types that frequently appear in scenes.
	public class RollingObjectCreator {

		public var sceneContainer:DisplayObjectContainer;			// Most likely this is hitContainer.

		// We can't get a handle on the engine directly, so add entities to this.
		private var group:Group;

		public function RollingObjectCreator( container:DisplayObjectContainer, engineAdder:Group ) {

			sceneContainer = container;

			this.group = engineAdder;

		} //

		// Create a rolling, possibly interactive clip.
		public function createRoller( clip:DisplayObjectContainer ):Entity {

			var display:Display = new Display( clip );
			var motion:Motion = new Motion();
			motion.rotationVelocity = motion.rotationAcceleration = 0;
			
			var player:Entity = group.getEntityById( "player" );
			var zone:Zone = new Zone();

			var mb:MotionBounds = player.get( MotionBounds );
			var bounds:MotionBounds = new MotionBounds( mb.box );
			bounds.reposition = true;

			var radius:Number = clip.width/2;

			var e:Entity = new Entity()
				.add( display )
				.add( new Spatial( clip.x, clip.y ) )
				.add( motion )
				.add( new Id( clip.name ) )
				.add( zone )
				.add( new BitmapCollider() )
				.add( new CurrentHit() )
				.add( bounds )
				.add( new Edge( radius, radius, radius, radius ) )
				.add( new PlatformCollider() )
				.add( new SceneCollider() )
				.add(new SceneObjectMotion());

			var roller:RollingObject = new RollingObject( e );

			group.addEntity( e );

			// The order here is important. adding entity to group adds it to the zone system, which overwrites
			// the old zone signals.
			zone.inside.add( roller.onHit );

			e.add( roller );

			return e;

		} //

	} // End RollingObjectCreator
	
} // End package