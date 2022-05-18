package game.scenes.lands.shared.components {

	/**
	 * Component to enable interactive tiles in tileMaps.
	 *
	 * Having a new entity with its own interactions and sceneInteractions and rollovers for every interactible
	 * tile in Lands would probably be a very bad idea. Instead the LandInteractionSystem makes a single
	 * rollover clip and a single landTarget clip, and these are moved based on what land tile the user's
	 * mouse is rolled over, and what tile the player is headed for.
	 */

	import ash.core.Component;
		
	public class LandInteraction extends Component {

		//public var targeting:Boolean;

		public function LandInteraction() {

			super();

		}

	} // class

} // package