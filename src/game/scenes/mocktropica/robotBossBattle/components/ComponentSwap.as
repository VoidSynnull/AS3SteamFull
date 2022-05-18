package game.scenes.mocktropica.robotBossBattle.components {
	
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.scenes.mocktropica.robotBossBattle.classes.ComponentSet;

	/**
	 * simplified version of the EntityStateMachine that comes with ash.
	 * It swaps out lists of components from an entity based on an id,
	 * which can be the name of an associated entity state.
	 * 
	 */
	public class ComponentSwap extends Component {

		/**
		 * The component sets associated with each id string.
		 */
		private var sets:Dictionary;
		private var currentSet:ComponentSet;

		public function ComponentSwap() {

			super();

			this.sets = new Dictionary();

		} //

		/**
		 * id: id of component set to use
		 * entity: entity to use the component set
		 * removePrev: if true, the current component set is removed from the entity before the new component set is added.
		 */
		public function useComponentSet( id:String, e:Entity=null, removePrev:Boolean=false ):void {

			var s:ComponentSet = this.sets[ id ];
			if ( s == null ) {
				return;
			}

			if ( e != null ) {

				if ( removePrev ) {
					this.currentSet.removeFromEntity( e );
				}
				s.addToEntity( e );

			} //

			this.currentSet = s;

		} //

		public function getCurrentSet():ComponentSet {

			return this.currentSet;

		} //

		public function addComponentSet( id:String, s:ComponentSet ):void {

			this.sets[ id ] = s;

		} //

		public function removeComponentSet( id:String ):void {

			this.sets[id] = null;

		} //

		public function getComponentSet( id:String ):ComponentSet {

			return this.sets[ id ];

		} //

	} // End ComponentSwitch

} // End package