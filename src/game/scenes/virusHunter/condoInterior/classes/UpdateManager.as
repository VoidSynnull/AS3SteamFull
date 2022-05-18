package game.scenes.virusHunter.condoInterior.classes {

	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.scenes.virusHunter.condoInterior.components.SimpleUpdater;
	import game.scenes.virusHunter.condoInterior.systems.SimpleUpdateSystem;
	import game.systems.SystemPriorities;

	// Handles the addition and removal of SimpleUpdate components, so
	// classes don't have to track the addition/removal of the component
	// to entities + the groups they are attached to.

	// For example - for a control class to directly use a simple update,
	// it would need an entity, an update component, and the group the
	// entity gets added to. Now it only needs a reference to an update manager.
	public class UpdateManager {

		private var group:Group;

		private var entities:Dictionary;		// update function -> entity
		private var updates:Dictionary;			// update function -> SimpleUpdate component

		public function UpdateManager( group:Group ) {

			this.group = group;

			if ( group.getSystem( SimpleUpdateSystem ) == null ) {
				group.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );
			} //

			updates = new Dictionary();
			entities = new Dictionary();

		} // UpdateManager()

		public function addUpdate( func:Function ):void {

			var e:Entity = entities[func];
			var updater:SimpleUpdater;

			if ( e != null ) {

				// entity already exists for this function.
				updater = e.get( SimpleUpdater );
				if ( updater != null ) {

					updater.update = func;

				} else {

					// Has entity but no update component. Find update component or create a new one.
					updater = updates[func];
					if ( updater != null ) {
						updater.update = func;
					} else {
						updater = new SimpleUpdater( func );
					}
					e.add( updater );

				} //

			} else {

				e = new Entity();
				updater = new SimpleUpdater( func );
				e.add( updater );

				group.addEntity( e );

				entities[func] = e;

			} // End-if.

		} //

		public function removeUpdate( func:Function, removeEntity:Boolean=false ):void {

			var e:Entity = entities[func];
			if ( e == null ) {
				// technically we still might be holding on to the update component,
				// though this should never happen.
				return;

			} //

			var updater:SimpleUpdater = e.get( SimpleUpdater );

			if ( updater != null ) {

				e.remove( SimpleUpdater );
				if ( !removeEntity ) {
					updates[func] = updater;			// save for later.
				} //

			} //

			if ( removeEntity ) {

				delete entities[func];
				delete updates[func];
				this.group.removeEntity( e );

			} //
				
		} //

		public function getUpdater( func:Function ):SimpleUpdater {

			var e:Entity = updates[func];
			if ( e == null ) {
				return null;
			}

			return e.get( SimpleUpdater );

		} //

		public function destroy():void {

			// empty all entities.
			for each( var e:Entity in entities ) {

				this.group.removeEntity( e );
				e.remove( SimpleUpdater );

			} //

			entities = null;
			updates = null;

		} //

	} // End UpdateManager
	
} // End package