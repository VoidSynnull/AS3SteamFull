package game.scenes.mocktropica.robotBossBattle.components {

	import ash.core.Component;

	public class CoinShot3D extends Component {

		public var timer:Number;
		public var falling:Boolean = false;

		public function CoinShot3D() {

			super();

			this.timer = 100*Math.random();

		} //
		
	} // End CoinShot3D
	
} // End package