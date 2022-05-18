package game.scenes.lands.shared.plugins {

	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.groups.LandUIGroup;

	/**
	 *
	 * subclass this class in order to create Ad-plugins that can alter the functionality of Realms
	 * for a single ad-campaign.
	 *
	 */

	public class RealmsAdPlugin {

		/**
		 * subclasses override this with the campaign name.
		 */
		protected var _campaignName:String;
		public function get campaignName():String {
			return this._campaignName;
		}

		/**
		 * set to override the name of the swf file that is loaded for the ui.
		 */
		protected var _uiFileName:String;
		public function get uiFileName():String {
			return this._uiFileName;
		}

		/**
		 * set to override the realms popup (world selection menu ) swf that gets loaded.
		 */
		protected var _realmsPopupFileName:String;
		public function get realmsPopupFileName():String {
			return this._realmsPopupFileName;
		}

		protected var landGroup:LandGroup;
		protected var uiGroup:LandUIGroup;

		public function RealmsAdPlugin() {
		} //

		/**
		 * init() gets called after the uiGroup has been created, but before it's been loaded.
		 */
		public function init( group:LandGroup ):void {

			this.landGroup = group;
			this.uiGroup = this.landGroup.getUIGroup();

		} //

		public function destroy():void {
		} //

	} // class
	
} // package