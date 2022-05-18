package game.scenes.lands.shared.monsters.components {

	import ash.core.Component;

	public class Spider extends Component {

		public var reachedTarget:Boolean = false;
		public var moving:Boolean = false;

		public var targetX:Number;
		public var targetY:Number;

		public var falling:int = 0;

		public function Spider() {

			super();

		} //

		public function setDest( nx:Number, ny:Number ):void {

			this.targetX = nx;
			this.targetY = ny;

			this.moving = true;

		} //

	} // class
	
} // package