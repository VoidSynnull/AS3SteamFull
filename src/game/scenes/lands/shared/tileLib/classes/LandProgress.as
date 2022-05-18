package game.scenes.lands.shared.tileLib.classes {

	import flash.utils.Dictionary;
	
	import engine.util.Command;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.ObjectIconPair;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	
	import org.osflash.signals.Signal;

	/**
	 * 
	 * Manages requirements for using the different tile types.
	 * 
	 */

	public class LandProgress {

		/**
		 * how much poptanium per level to collect after you've reached the end of the progression array.
		 */
		private const endProgress:int = 1500;

		// progression[ curLevel ] is the amount needed to get to the NEXT level from the current level.
		//private var progression:Array = [ 0, 50, 100, 200, 300, 450, 600, 800, 1000, 1250, 1500, 1800, 2200, 2700, 3300 ];
		private var progression:Array = [ 0, 50, 150, 300, 500, 800, 1200, 1700, 2300, 3000, 3800, 4700, 5700, 6800, 8000 ];

		/**
		 * need a list of the biome icons associated with the biome levels so they can be displayed
		 * when the level for a given biome is reached. there is no easy way around this fact.
		 * once biomes are defined in xml, this will be done through parsing and loading biome icon files.
		 **/
		private var biomeIcons:Array;

		private var _curLevel:int = 1;

		/**
		 * onLevelUp( newLevel:int, unlockedObjects:Vector.<ObjectIconPair> )
		 * The objects in the ObjectIconPair are tileTypes combined with IBitmapDrawables
		 * 
		 * Although it would seem to make sense to just include a list of TileTypes unlocked on level-up,
		 * we used to have biomes that were unlocked at different levels as well, and in the future the user
		 * might also unlock special powers that will have their own icons.
		 */
		public var onLevelUp:Signal;

		/**
		 * onLevelChanged( newLevel:int )
		 * called when a level jumps to a new value - either from loading data from the server,
		 * being set from game world xml, or by special cheats.
		 */
		public var onLevelChanged:Signal;

		private var tileSets:Dictionary;

		private var landGroup:LandGroup;

		public function LandProgress( group:LandGroup ) {

			this.onLevelUp = new Signal( int, Vector.<ObjectIconPair> );
			this.onLevelChanged = new Signal( int );

			this.landGroup = group;
			this.tileSets = group.gameData.tileSets;

		} //

		/**
		 * annoying thing to get the biome icons so they can be displayed in the level up pane.
		 */
		public function setBiomeIcons( icons:Array ):void {

			this.biomeIcons = icons;

		} //

		/**
		 * set the level for the amount of experience the user currently has.
		 */
		public function recalculateLevel( levelPoints:int ):void {

			var oldLevel:int = this._curLevel;
			this._curLevel = this.getLevelByAmount( levelPoints );

			if ( oldLevel != this._curLevel ) {

				// CATCH UP with any missed items.
				if ( this._curLevel >= 5 ) {

					this.landGroup.shellApi.getItem( "pound", null, true );

					if ( this._curLevel >= 10 ) {

						this.landGroup.shellApi.getItem( "hammerang", null, true );
	
						if ( this._curLevel >= 15 ) {
							this.landGroup.shellApi.getItem( "creator", null, true );
						}

					} // level 10

				} // level 5

				this.onLevelChanged.dispatch( this._curLevel );

			} //

		} //

		/**
		 * annoying patch for now to reset to current level when testers get poptanium with cheats
		 * -- but also displays the most current level up screen.
		 */
		public function recalculateAndLevelUp( levelPoints:int ):void {

			var oldLevel:int = this._curLevel;

			// makes sure to get any items the player needs.
			this.recalculateLevel( levelPoints );

			if ( oldLevel != this._curLevel ) {

				this.triggerLevelUp();

			} //

		} // recalculateAndLevelUp()

		/**
		 * checks if the player has enough points to level up. If so, they level up.
		 */
		public function tryLevelUp( levelPoints:int ):void {

			var required:int = this.getRequiredForLevel( this._curLevel + 1 );

			if ( levelPoints < required ) {
				return;
			}

			this._curLevel++;
			this.triggerLevelUp();

			//level up awards
			if ( this._curLevel == 5 ) {
				this.landGroup.shellApi.getItem( "pound", null, true );
			} else if ( this._curLevel == 10 ) {
				this.landGroup.shellApi.getItem( "hammerang", null, true );
			} else if ( this._curLevel == 15 ) {
				this.landGroup.shellApi.getItem( "creator", null, true );
			}

		} //

		private function triggerLevelUp():void {

			/**
			 * array of unlocked tile types.
			 */
			var unlocked:Vector.<ObjectIconPair> = new Vector.<ObjectIconPair>();
			var tileType:TileType;
			
			var loadList:Dictionary;
			var loadCount:int = 0;
			
			var type:TileType;
			var typeList:Vector.<TileType>;
			// create a list of all unlocked tiles.
			for each ( var tset:TileSet in this.tileSets ) {
				
				typeList = tset.tileTypes;
				
				for( var i:int = typeList.length-1; i >= 0; i-- ) {
					
					if ( typeList[i].level == this._curLevel ) {
						
						tileType = typeList[i];
						if ( !tileType.allowEdit ) {
							continue;
						}
						
						if ( tileType.image == null && tileType is ClipTileType ) {
							
							if ( !loadList ) { loadList = new Dictionary(); }
							// tileType must preload before it can be displayed.
							loadList[ tileType ] = tileType;
							loadCount++;
							
						}
						unlocked.push( new ObjectIconPair( tileType, tileType.image, tset.setType == "natural" ) );
						
					} //
					
				} // end tiletype-loop.
				
			} // end tile-set-loop
			
			if ( loadCount > 0 ) {
				// wait for icons to load before dispatching the level up event.
				this.landGroup.assetLoader.loadDecalTypes( loadList, Command.create( this.levelUpIconsLoaded, unlocked ) );
			} else {
				this.onLevelUp.dispatch( this._curLevel, unlocked );
			}

		} //

		/**
		 * gets the percent of the way to the next level.
		 */
		public function getProgressPercent( levelPoints:int ):Number {

			var lastAmount:int = this.getRequiredForLevel( this._curLevel );

			var percent:Number = (  (levelPoints - lastAmount) / ( this.getRequiredForLevel(this._curLevel+1) - lastAmount ) );
			if ( percent > 1 ) {
				percent = 0;			// currently only used because cheating allows overkill and doesn't set the level right.
			}

			return percent;

		} //

		/**
		 * called when the icons needed to display a level up pane have been loaded.
		 */
		private function levelUpIconsLoaded( unlocked:Vector.<ObjectIconPair> ):void {

			var clipType:ClipTileType;
			var pair:ObjectIconPair;

			// search for any decal icons that don't have their bitmap icon set yet.
			for( var i:int = unlocked.length-1; i >= 0; i-- ) {

				pair = unlocked[i];
				if ( pair.icon == null ) {

					clipType = pair.object as ClipTileType;
					if ( clipType ) {
						pair.icon = clipType.image;
					} //

				} //

			} // end for-loop.

			/**
			 * dispatch the level up event now.
			 */
			this.onLevelUp.dispatch( this._curLevel, unlocked );

		} //

		/**
		 * takes an amount of points and returns the level the player would be at for that amount.
		 */
		public function getLevelByAmount( levelPoints:int ):int {
			
			// see if the points are more or less than needed for the very highest level.
			var i:int = this.progression.length-1;
			var max:int = this.progression[ i ];
			if ( levelPoints >= max ) {
				
				// just math. you get 1 level above i because you reached the requirement for going beyond
				// the i-th level. then you have one additional level for every unit of 'end progress' above the max.
				return Math.floor( ( levelPoints - max ) /  this.endProgress ) + i + 1;
				
			} else {
				
				// could do binary search here.
				for( i = i - 1; i > 0; i-- ) {
					
					// progression[i] is the amount needed to get to level i+1
					if ( levelPoints >= this.progression[ i ] ) {
						return ( i + 1 );
					} //
					
				} //
				
				return 1;
				
			} //
			
		} //
		
		public function getRequiredForLevel( level:int ):int {
			
			if ( level > this.progression.length ) {
				
				// required is amount needed for the previous level, plus 'endProgress' for every level over.
				return this.progression[ this.progression.length-1 ] + endProgress*( level - this.progression.length );
				
			} else {
				
				return this.progression[ level-1 ];
				
			}
			
		} //

		public function hasSuperJump():Boolean {
			return this._curLevel >= 15;
		}

		public function hasHammerang():Boolean {
			return this._curLevel >= 10;
		}

		public function hasHammerPound():Boolean {
			return this._curLevel >= 5;
		}

		public function destroy():void {

			this.onLevelUp.removeAll();
			this.tileSets = null;

		} //

		public function get curLevel():int {
			return this._curLevel;
		}

		public function get nextLevel():int {
			return this._curLevel+1;
		}

	} // class

} // package