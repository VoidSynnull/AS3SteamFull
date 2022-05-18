package game.data.structs {

	public class TopologyLink {

		/**
		 * cost to take this link.
		 */
		public var cost:Number;

		/**
		 * Location after taking this link.
		 */
		public var loc:TopologyState;

		public function TopologyLink( loc:TopologyState=null, cost:Number=1 ) {

			this.loc = loc;
			this.cost = cost;

		} //

	} // End Link

} // End package