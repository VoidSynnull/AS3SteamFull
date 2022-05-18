package game.scenes.mocktropica.cheeseInterior.systems {

	import ash.core.Engine;
	
	import game.scenes.mocktropica.cheeseInterior.components.CheeseMachine;
	import game.scenes.mocktropica.cheeseInterior.nodes.CheeseMachineNode;
	import game.systems.GameSystem;

	/**
	 * Because the exact time displayed isn't very important, not bothering to work
	 * through the date object. 
	 */
	public class CheeseMachineSystem extends GameSystem {

		public function CheeseMachineSystem() {

			super( CheeseMachineNode, this.updateNode, this.nodeAdded, this.nodeRemoved );

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );

		} //

		private function updateNode( node:CheeseMachineNode, time:Number ):void {

			var machine:CheeseMachine = node.machine;

			if ( machine.targetSpeed != machine.machineSpeed ) {

				machine.machineSpeed += ( machine.targetSpeed - machine.machineSpeed )*0.75*time;
				if ( Math.abs( machine.targetSpeed - machine.machineSpeed ) < 0.05 ) {

					machine.machineSpeed = machine.targetSpeed;

				} //

			} //

			if ( machine._breakMachine == true ) {

				machine.breakTimer -= time;
				if ( machine.breakTimer <= 0 ) {
					this.breakMachine( node );
				} //

			} //

		} //

		private function breakMachine( node:CheeseMachineNode ):void {

			node.machine._breakMachine = false;
			node.machine.onMachineBroken.dispatch( node.entity, node.machine );

		} //

		/**
		 * Machine breaking in progress.
		 */
		private function doBreakProgress( node:CheeseMachineNode, time:Number ):void {
		} //

		private function nodeAdded( node:CheeseMachineNode ):void {
		} //

		private function nodeRemoved( node:CheeseMachineNode ):void {

			node.machine._indicator = null;
			node.machine._wheel = null;

		} //

		/*override public function removeFromEngine( engine:Engine ):void {

			super.removeFromEngine( engine );

		} //*/

	} // End class

} // End package