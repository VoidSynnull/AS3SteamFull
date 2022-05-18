package game.systems.animation 
{
	import ash.core.Node;
	
	/**
	 * ...
	 * @author Bard McKinley
	 */
	public class FSMState 
	{
		public var type:String;
		protected var updateStage:Function;
		protected var _node:Node;
		public function setNode( node:Node ):void { _node = node; }

		
		public function FSMState() {}

		/**
		 * Start the state
		 */
		public function start():void {}

		/**
		 * Manage the state
		 */
		public function update( time:Number ):void {}
		
		/**
		 * Check for state
		 */
		public function check():Boolean { return false; }
		
		/**
		 * Called before exiting the state
		 */
		public function exit():void {}
		
		/**
		 * Called when removing a state from an FSMControl
		 */
		public function destroy():void 
		{
			_node = null;
		}
		
		
	}

}