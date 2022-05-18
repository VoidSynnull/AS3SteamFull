package game.scenes.virusHunter.condoInterior.popups {

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.scenes.virusHunter.condoInterior.classes.PopupDragItem;
	import game.systems.SystemPriorities;
	import game.components.actionChain.ActionExecutor;
	import game.systems.actionChain.ActionExecutionSystem;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.util.DisplayPositionUtils;
	
	public class CondoMailPopup extends SearchPopup {

		private var payStub:PopupDragItem;
		private var travelMail:PopupDragItem;

		private var sawPayStub:Boolean = false;
		private var sawTravelMail:Boolean = false;

		private var executorEntity:Entity;

		public var canFindLetters:Boolean = false;

		/**
		 * After touchedItems == 0, need to disable the close button, because the ending animation sequence could be playing.
		 */
		public var touchedItems:int = 0;

		public function CondoMailPopup(fileName:String, groupPrefix:String, container:DisplayObjectContainer=null, canFindLetters:Boolean=false ) {

			super( fileName, groupPrefix, container, false );

			this.canFindLetters = canFindLetters;

			this.useCloseButton = true;

		} //

		/*override public function destroy():void {
	
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
			
		} //*/

		/*// initiate asset load of scene specific assets.
		override public function load():void {
			
			super.load();
			
		} //*/

		// all assets ready
		override public function loaded():void {

			super.loaded();

			// enables actions.
			this.addSystem( new ActionExecutionSystem(), SystemPriorities.update );
			
			DisplayPositionUtils.centerWithinDimensions(this.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 960, 640);
			
			this.centerWithinDimensions(this.screen.background);
			this.screen.background.x = this.screen.background.y = 0;
			this.screen.background.width 	= this.shellApi.viewportWidth;
			this.screen.background.height 	= this.shellApi.viewportHeight;
			//DisplayPositionUtils.
			
			executorEntity = new Entity();
			var executor:ActionExecutor = new ActionExecutor( this );
			executorEntity.add( executor, ActionExecutor );
			this.addEntity( executorEntity );

			payStub = this.getDraggableByName( "payStubMail" );
			travelMail = this.getDraggableByName( "travelMail" );

			if ( canFindLetters ) {

				payStub.makePrize();
				payStub.onFound = this.markFound;
				payStub.onTouched = this.markTouched;


				travelMail.makePrize();
				travelMail.onFound = this.markFound;
				travelMail.onTouched = this.markTouched;

			} //

		} //

		/**
		 * Need this because once the two 'prizes'
		 */
		private function markTouched( dragItem:PopupDragItem ):void {

			dragItem.onTouched = null;

			if ( ++this.touchedItems >= 2 ) {

				super.disableCloseButton();

			} //

		} //

		private function markFound( dragItem:PopupDragItem ):void {

			dragItem.isPrize = false;
			dragItem.onFound = null;

			if ( dragItem == payStub ) {

				sawPayStub = true;

			} else {

				sawTravelMail = true;

			} // end-if.

			var a:CallFunctionAction;

			if ( sawPayStub && sawTravelMail ) {

				// popup is done.
				this.disableDrags();
				a = new CallFunctionAction( Command.create(this.onSearchComplete, this) );
				a.startDelay = 2;
				a.execute( null, executorEntity.get(ActionExecutor) );

			} else {

				// put the object back after a short wait.
				a = new CallFunctionAction( dragItem.unzoomItem );
				a.startDelay = 2;
				a.execute( null, executorEntity.get(ActionExecutor) );

			} //

		} // end markFound()

	} // End CondoMailPopup
	
} // End package