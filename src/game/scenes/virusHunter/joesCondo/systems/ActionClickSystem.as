package game.scenes.virusHunter.joesCondo.systems {

	import ash.core.Engine;
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.scene.SceneInteraction;
	import game.scenes.virusHunter.joesCondo.components.ActionClick;
	import game.scenes.virusHunter.joesCondo.nodes.ActionClickNode;
	import game.systems.actionChain.ActionExecutionSystem;
	import game.systems.actionChain.ActionCommand;
	import game.systems.SystemPriorities;

	/**
	 * ActionClicks link SceneInteractions with Actions to execute.
	 * 
	 * No point in manking this a deeper system, since it doesn't even use the update function.
	 */
	public class ActionClickSystem extends ListIteratingSystem {

		public function ActionClickSystem() {

			super( ActionClickNode, nodeUpdate, nodeAdded, nodeRemoved );

		} //

		/**
		 * There's nothing to do, so override the update so it doesn't try to do anything.
		 */
		override public function update( time:Number ):void {
		} //

		public function nodeUpdate( node:ActionClickNode, time:Number ):void {
		} //

		public function nodeAdded( node:ActionClickNode ):void {

			// The interaction has to be added to the entity BEFORE the scene interaction, or the scene interaction
			// won't see the interaction signals.
			InteractionCreator.addToEntity( node.entity, [ InteractionCreator.CLICK ] );
			
			var sceneInteraction:SceneInteraction = node.entity.get( SceneInteraction );
			if ( !sceneInteraction ) {
				sceneInteraction = new SceneInteraction();
				node.entity.add( sceneInteraction, SceneInteraction );
			}

			sceneInteraction.reached.add( onEntityReached );

		} //

		public function nodeRemoved( node:ActionClickNode ):void {
		} //

		/**
		 * Interacted is the ActionClick object.
		 */
		private function onEntityReached( curInteractor:Entity, interacted:Entity ):void {

			var click:ActionClick = interacted.get( ActionClick );
			if ( click == null ) {
				return;
			}

			// Wrong interactor.
			if ( click.interactor != null && click.interactor != curInteractor ) {
				return;
			}

			/**
			 * Appends clickAction's entity to the action callback ( which is just the action itself )
			 * Need to fix this up, but whatever.
			 */
			click.action.run( this.group, Command.create( actionDone, interacted ) );

		} //

		private function onEntityClicked( curInteractor:Entity, interacted:Entity ):void {
		} //

		private function actionDone( action:ActionCommand, entity:Entity ):void {

			var click:ActionClick = entity.get( ActionClick ) as ActionClick;

			if ( click.callback != null ) {
				click.callback( entity );
			}

		} //

		override public function addToEngine( e:Engine ):void {

			if ( this.group.getSystem( ActionExecutionSystem ) == null ) {
				this.group.addSystem( new ActionExecutionSystem(), SystemPriorities.update );
			}

			super.addToEngine( e );

		} //

		override public function removeFromEngine( engine:Engine ):void {
		} //

	} // End ActionClickSystem

} // End package