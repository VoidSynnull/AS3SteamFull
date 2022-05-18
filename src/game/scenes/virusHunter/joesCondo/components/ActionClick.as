package game.scenes.virusHunter.joesCondo.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.group.Group;
	
	import game.systems.actionChain.ActionCommand;
	import game.scenes.virusHunter.joesCondo.systems.ActionClickSystem;

	// This class simply pairs an entity/SceneInteraction with the Action to execute,
	// to reduce a lot of obnoxious callback/setup code.
	public class ActionClick extends Component {

		public var action:ActionCommand;
		public var interactor:Entity;

		// callback after the action is completed.
		public var callback:Function;

		// If true, action will trigger only once. To use the object again, you will have to call clickObject.enable()
		public var triggerOnce:Boolean = false;

		/**
		 * action -
		 * 		- ActionCommand to execute when the click entity is reached.
		 * 
		 * interactor -
		 * 		the entity which can interact with the clickable object. usually this will be the player,
		 * 		but if you set interactor to null, any entity can trigger the action. (npcs for example)
		 *
		 * finalCabllack -
		 * 		Callback function after the action has completed executing.
		 * 	
		 */
		public function ActionClick( group:Group, action:ActionCommand, interactor:Entity=null, finalCallback:Function=null ) {

			if ( group.getSystem( ActionClickSystem ) == null ) {
				group.addSystem( new ActionClickSystem() )
			} //

			this.interactor = interactor;
			this.action = action;
			this.callback = finalCallback;

		} //

		/*// I don't think this ever gets called. interacted should be our entity.
		private function onTrigger( interacted:Entity ):void {
			trace( "SCENE INTERACTION TRIGGERED" );
		} //*/

	} // End ClickObject
	
} // End package