package game.scenes.lands.shared.components {
	
	import ash.core.Component;

	import org.osflash.signals.Signal;


	public class LandMeteor extends Component {

		public var onRemoved:Signal;

		/**
		 * temporary fix. meteors spawn poptanium on explode, cannon balls don't.
		 * maybe this should be a completely different component.
		 */
		public var spawnPoptanium:Boolean;

		public function LandMeteor( spawnPoptanium:Boolean=false ) {

			super();

			this.onRemoved = new Signal();
			
			this.spawnPoptanium = spawnPoptanium;

		} //
		
	} // class
	
} // package