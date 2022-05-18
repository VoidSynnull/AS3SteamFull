package game.scenes.lands.shared.classes {

	import flash.utils.Dictionary;
	
	import org.osflash.signals.Signal;

	/**
	 * inventory of all the stuff from the lands things.
	 */
	public class LandInventory {

		/**
		 * type string -> CollectibleType object.
		 */
		private var resources:Dictionary;

		/**
		 * onUpdate( ResourceType )
		 */
		public var onUpdate:Signal;

		public function LandInventory( resourceTypes:Dictionary=null ) {

			if ( resourceTypes != null ) {

				this.resources = resourceTypes;

			} else {

				this.resources = new Dictionary();

				var poptanium:CollectibleResource = new CollectibleResource();
				poptanium.name = "Poptanium";
				poptanium.type = "poptanium";
				poptanium.swf = poptanium.type + ".swf";

				this.resources[ poptanium.type ] = poptanium;

				var type:ResourceType = new ResourceType();
				type.name = "Experience";
				type.type = "experience";
				this.resources[ type.type ] = type;

			} //

			this.onUpdate = new Signal( ResourceType );

		} //

		public function getResourceCount( resource:String ):int {

			return ( this.resources[ resource ] as ResourceType ).count;

		} //

		/**
		 * standard resource collect.
		 * returns the new resource amount for convenience.
		 * triggers onUpdate() signal.
		 */
		public function collectResource( type:ResourceType, amt:int ):int {

			type.count += amt;
			this.onUpdate.dispatch( type );

			return type.count;

		} //

		/**
		 * spends a resource without checking if you have enough of it.
		 * count may go below zero.
		 */
		public function useResource( type:ResourceType, amt:int ):void {

			type.count -= amt;
			this.onUpdate.dispatch( type );

		} //

		/**
		 * this was added for the +resource cheat but can be used to add a resource amount to any named resource.
		 */
		public function addResource( resource:String, amount:int ):void {

			var type:ResourceType = ( this.resources[ resource ] as ResourceType );
			type.count += amount;

			this.onUpdate.dispatch( type );

		} //

		/**
		 * attempts to consume a given amount of the given resource type.
		 * if not enough is available, no resource is consumed and false is returned.
 		 */
		/*public function tryUseResource( type:String, count:int ):Boolean {

			var typeObj:ResourceType = this.resources[ type ];
			if ( typeObj == null ) {
				return false;
			}

			if ( typeObj.count < count ) {
				return false;
			}

			typeObj.count -= count;

			this.onUpdate.dispatch( typeObj );

			return true;

		} //*/

		/**
		 * forces an update signal for the given resourceType.
		 */
		/*public function forceUpdate( resourceType:ResourceType ):void {

			this.onUpdate.dispatch( resourceType );

		} //*/

		/**
		 * subtracts an amount from the given resource. if the resource count
		 * becomes negative, it is set to 0. no other checks are made.
		 */
		/*public function subtractResource( type:String, count:int ):void {

			var typeObj:ResourceType = this.resources[ type ];

			typeObj.count -= count;
			if ( typeObj.count < 0 ) {
				typeObj.count = 0;
			}

			this.onUpdate.dispatch( typeObj );

		} //*/

		public function getResource( typeString:String ):ResourceType {
			return this.resources[ typeString ];
		}

		public function getResources():Dictionary {
			return this.resources;
		}

	} // class

} // package