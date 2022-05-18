package game.systems.actionChain {

	import ash.core.Engine;
	import ash.core.Entity;
	
	import game.systems.GameSystem;
	import game.components.actionChain.ActionExecutor;
	import game.nodes.actionChain.ActionExecutionNode;

	public class ActionExecutionSystem extends GameSystem {

		// holds the defaultExecutor Component.
		private var _execEntity:Entity;
		private var _executor:ActionExecutor;

		public function ActionExecutionSystem() {

			super( ActionExecutionNode, updateNode, null, null );

		} //

		// Note: might want to store different executors for each group. Not sure how the individual actions
		// will access them though.
		override public function addToEngine( e:Engine ):void {

			if ( this._executor == null ) {

				this._executor = new ActionExecutor( this.group );

				if ( ActionCommand.DefaultExecutor == null ) {
					ActionCommand.DefaultExecutor = this._executor;
				}
				if ( this._execEntity == null ) {
					this._execEntity = new Entity();
				}

				this._execEntity.add( this._executor );
				this.group.addEntity( this._execEntity );

			} //

			super.addToEngine( e );

		} //

		public function getDefaultExecutor():ActionExecutor {

			return this._executor;

		} //

		// The problem here is if multiple groups write on top of each other's executors, there MIGHT be a potential conflict
		// when the sole reference to the executor gets erased.
		override public function removeFromEngine( e:Engine ):void {

			e.removeEntity( this._execEntity );
			this._execEntity = null;
			this._executor = null;

			super.removeFromEngine( e );

		} //

		private function updateNode( node:ActionExecutionNode, time:Number ):void {

			node.executionList.update( time );

		} // updateNode()

		private function nodeAdded( node:ActionExecutionNode ):void {
		} //

		private function nodeRemoved( node:ActionExecutionNode ):void {
		} //

	} // End class

} // End package