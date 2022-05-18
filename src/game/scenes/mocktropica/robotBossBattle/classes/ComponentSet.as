package game.scenes.mocktropica.robotBossBattle.classes {

	import ash.core.Entity;
	import ash.core.Component;

	public class ComponentSet {

		/**
		 * For now, use a vector. Later can change to a linked list implementation.
		 */
		private var components:Vector.<Component>;

		public function ComponentSet() {

			this.components = new Vector.<Component>();

		} //

		public function add( component:Component ):void {

			this.components.push( component );

		} //

		public function remove( component:Component ):void {

			var ind:int = this.components.indexOf( component );
			if ( ind >= 0 ) {

				this.components[ind] = this.components[ this.components.length-1 ];
				this.components.pop();

			} //

			return;

		} //

		/**
		 * If we store the class, this will be more efficient.
		 * 
		 */
		public function removeFromEntity( e:Entity ):void {

			for( var i:int = this.components.length-1; i >= 0; i-- ) {

				e.remove( Class(this.components[i].constructor) );

			} //

		} //

		public function addToEntity( e:Entity ):void {

			for( var i:int = components.length-1; i >= 0; i-- ) {

				e.add( this.components[i] );

			} //

		} //

	} // End ComponentSet

} // End package