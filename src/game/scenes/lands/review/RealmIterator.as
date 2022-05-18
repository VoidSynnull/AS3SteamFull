package game.scenes.lands.review {

	import game.scenes.lands.shared.world.LandGalaxy;
	import game.scenes.lands.shared.world.LandRealmData;

	/**
	 * steps through the realms of a galaxy, so they can be viewed one at a time.
	 * new realms being loaded from the server should get added to the end of the galaxy's
	 * realm list, so they curRealmIndex stays valid when new realms are added.
	 * 
	 * Other mechanisms will be needed for removing excess realms.
	 * 
	 */

	public class RealmIterator {

		private var curRealmIndex:int;

		private var galaxy:LandGalaxy;
		public function getRealmCount():int { return this.galaxy.getRealmCount(); }

		public function get currentRealm():LandRealmData {
			return this.galaxy.curRealm;
		}

		public function RealmIterator( galaxy:LandGalaxy ) {

			this.curRealmIndex = 0;
			this.galaxy = galaxy;

		}

		/**
		 * call when a galaxy has changed its realms - maybe all realms have been reloaded
		 * from a new source, or existing realms have been removed.
		 * 
		 * newGalaxy may optionally be specified to replace the current galaxy object.
		 * otherwise the previous galaxy will still be used.
		 */
		public function reset( newGalaxy:LandGalaxy=null ):void {

			this.curRealmIndex = 0;
			this.galaxy.setRealmByIndex( this.curRealmIndex );

			if ( newGalaxy != null ) {
				this.galaxy = newGalaxy;
			} //
			//galaxy.setRealmByIndex( this.curRealmIndex );

		} //

		/**
		 * advance to the next realm.
		 * returns false if the realms loop.
		 */
		public function advanceRealm():Boolean {

			this.curRealmIndex++;
			if ( this.curRealmIndex >= this.galaxy.getRealmCount() ) {

				this.curRealmIndex = 0;
				if ( this.galaxy.getRealmCount() != 0 ) {
					galaxy.setRealmByIndex( this.curRealmIndex );
				}

				return false;
			}
			
			galaxy.setRealmByIndex( this.curRealmIndex );

			return true;

		} //

		/**
		 * return to previous realm.
		 */
		public function previousRealm():void {

			this.curRealmIndex--;
			if ( this.curRealmIndex < 0 ) {
				this.curRealmIndex = this.galaxy.getRealms().length-1;
			}
			galaxy.setRealmByIndex( this.curRealmIndex );

		} //

	} // class
	
} // package