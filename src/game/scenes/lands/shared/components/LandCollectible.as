package game.scenes.lands.shared.components {

	import ash.core.Component;
	
	import game.scenes.lands.shared.classes.CollectibleResource;
	import game.scenes.lands.shared.classes.ResourceType;

	public class LandCollectible extends Component {

		//static public var POPTANIUM:String = "poptanium";

		/**
		 * the type of collectible. going to start with 'poptanium'
		 */
		public var type:CollectibleResource;

		public var amount:int;

		public function LandCollectible( type:CollectibleResource, amt:int ) {

			super();

			this.type = type;
			this.amount = amt;

		} // TileCollectible.

	} // class

} // package