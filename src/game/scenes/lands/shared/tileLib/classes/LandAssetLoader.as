package game.scenes.lands.shared.tileLib.classes {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.util.Command;
	
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.TileTypeSpecial;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TerrainTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	import game.scenes.lands.shared.util.LandUtils;

	/**
	 *
	 * handles loading and preloading of Land Assets.
	 *
	 */

	public class LandAssetLoader {

		private var shellApi:ShellApi;

		private var gameData:LandGameData;

		private var baseAssetURL:String;

		public function get materialsURL():String		{ return this.baseAssetURL + "materials/"; }
		public function get propsURL():String			{ return this.baseAssetURL + "props/"; }
		public function get detailsURL():String			{ return this.baseAssetURL + "details/"; }

		/**
		 * assetURL is a base asset folder.
		 * 
		 * individual tile assets are located at:
		 * 	assetURL/materials/, assetURL/props/ and assetURL/details/
		 */
		public function LandAssetLoader( shell:ShellApi, assetURL:String, gameData:LandGameData ) {

			this.baseAssetURL = assetURL;
			this.shellApi = shell;
			this.gameData = gameData;

		} //

		/**
		 * loads the resoures for a single terrain type. does not check for special tiles.
		 */
		public function loadSingleTerrain( tileType:TerrainTileType, callback:Function ):void {

			var loadArray:Array = new Array();

			this.pushDetailFiles( tileType as TerrainTileType, loadArray );

			// main bitmap file:
			if ( tileType.viewSourceFile != null && tileType.viewSourceFile != "" ) {

				var fileName:String = this.materialsURL + tileType.viewSourceFile;

				if (loadArray.indexOf( fileName ) == -1 ) {
					loadArray.push( fileName );
				}

			} //

			this.shellApi.loadFiles( loadArray, Command.create( this.singleTerrainLoaded, tileType, callback ) );

		} //

		private function singleTerrainLoaded( tileType:TerrainTileType, callback:Function ):void {

			this.initTerrainFiles( tileType );

			// files common to all:
			if ( tileType.viewSourceFile != null ) {

				var image:DisplayObjectContainer = this.shellApi.getFile( this.materialsURL + tileType.viewSourceFile, false );
				tileType.viewBitmapFill = LandUtils.prepareBitmap( image, image.width, image.height );

				tileType.viewSourceFile = null;

			} //

			if ( callback ) {
				callback();
			}

		} //

		/**
		 * load the information for a single tile type. a batch-load of tile types is more efficient
		 * but for tile buttons we want the tiles to show up the instant they become available
		 * instead of all tiles appearing at once.
		 * 
		 * callback returns with no params. maybe it should return with the loaded type? wouldn't that be something...
		 */
		public function loadSingleDecal( clipType:ClipTileType, callback:Function ):void {

			if ( clipType.viewSourceFile == null || clipType.viewSourceFile == "" ) {
				return;
			}

			clipType.loading = true;

			var spec:TileTypeSpecial = this.gameData.tileSpecials[ clipType ];
			if ( spec && spec.swapTile != 0 ) {

				var swapType:ClipTileType = ( this.gameData.tileSets[ "decal" ] as TileSet ).getTypeByCode( spec.swapTile ) as ClipTileType;
				if ( swapType != null &&  swapType.viewSourceFile != null && swapType.loading == false ) {
					this.loadSingleDecal( swapType, null );
				}

			}

			this.shellApi.loadFile( this.propsURL + clipType.viewSourceFile, this.singleDecalLoaded, clipType, callback );

		} //

		/**
		 * NOTE: the single-clipType file load and initialization duplicates code from the mass-load functions.
		 * it would be best to rewrite this so they use the same mechanic.
		 */
		private function singleDecalLoaded( file:MovieClip, clipType:ClipTileType, callback:Function ):void {

			clipType.clip = file;
			clipType.loading = false;
			clipType.clip.gotoAndStop( 1 );
			clipType.viewSourceFile = null;

			if ( callback ) {
				callback();
			}

		} //

		/**
		 * loads any decals being used inside decal tileMaps from the given mapDictionary.
		 * 
		 * - the tileMaps param is a dictionary of tileMaps, either from the main gameData, or from a loaded template.
		 * 
		 * - callback is only called if decals need to be loaded. otherwise no callback is made.
		 * 
		 * - returns true if decals are loading, false otherwise.
		 * 
		 */
		public function loadMapDecals( tileMaps:Dictionary, callback:Function=null ):Boolean {

			var tileSet:TileSet = this.gameData.tileSets[ "decal" ];
			if ( tileSet.loaded ) {
				return false;
			}

			var loads:Dictionary = new Dictionary();
			var mustLoad:Boolean = false;

			// check if any decals are being used in the current scene that haven't been loaded yet.
			// if so, load them and come back later.
			var tileMap:TileMap = tileMaps[ "decal" ];
			if ( tileMap ) {
				mustLoad = tileMap.findUnloadedTiles( loads, tileSet );
			}

			tileMap = tileMaps[ "bgdecal" ];
			if ( tileMap ) {
				// mustLoad MUST come second here or the operation gets short circuited. amazing.
				mustLoad = tileMap.findUnloadedTiles( loads, tileSet ) || mustLoad;
			}

			if ( mustLoad ) {
				this.loadDecalTypes( loads, callback );
				return true;
			}

			return false;

		} //

		/**
		 * late-load a dictionary of decal tile types.
		 * 
		 * note: if a decal has a special swap tile action that swaps to a second decal,
		 * that second decal must also be preloaded, because if the user interacts with it,
		 * the second decal must already be ready to swap.
		 */
		public function loadDecalTypes( decalTypes:Dictionary, callback:Function=null ):void {

			var specials:Dictionary = this.gameData.tileSpecials;
			var spec:TileTypeSpecial;
			var decalSet:TileSet = this.gameData.tileSets["decal"];

			var loadArray:Array = new Array();			// array for all the loads.
			var baseURL:String = this.propsURL;

			var fileName:String;

			// tile types swappable with the current decal types.
			var swapTypes:Vector.<ClipTileType> = new Vector.<ClipTileType>();

			for( var clipType:ClipTileType in decalTypes ) {

				if ( clipType.viewSourceFile == null || clipType.loading ) {
					continue;
				}

				clipType.loading = true;
				spec = specials[ clipType ];
				if ( spec && spec.swapTile != 0 ) {

					var swapType:ClipTileType = decalSet.getTypeByCode( spec.swapTile ) as ClipTileType;
					if ( swapType != null && swapType.loading == false ) {
						// --> you can't add to a dictionary in the middle of a loop
						swapTypes.push( swapType );
					} //

				} //

				fileName = baseURL + clipType.viewSourceFile;
				// prevent FileManager crash from duplicate load urls.
				if ( loadArray.indexOf( fileName ) == -1 ) {
					loadArray.push( fileName );
				}

			} // for-loop.

			if ( loadArray.length > 0 ) {

				this.shellApi.loadFiles( loadArray, Command.create( this.decalFilesLoaded, decalTypes, callback ) );

			} else if ( callback ) {
				callback();
			} //

			if ( swapTypes.length > 0 ) {
				// now load any tile swaps.
				this.loadDecalVector( swapTypes, false );
			} //

		} //

		/**
		 * later can replace this with a binary search / sorted array.
		 */
		/*private function addIfUnique( array:Array, url:String ):void {

			for( var i:int = array.length-1; i >= 0; i-- ) {

				if ( array[i] == url ) {
					return;
				}

			} //

			array.push( url );

		} //*/

		/**
		 * identical to load decal types but uses a vector of tiles to load instead.
		 * this has the advantage of not needing to call 'loadSingleDecal'
		 * eventually i might just stick to one of these functions, though both are more convenient
		 * in different circumstances.
		 *
		 * if ( loadSwaps == true ) then tiles swappable with these tile types will also be loaded.
		 */
		public function loadDecalVector( decalTypes:Vector.<ClipTileType>, loadSwaps:Boolean=true, callback:Function=null ):void {
			
			var specials:Dictionary = this.gameData.tileSpecials;
			var spec:TileTypeSpecial;
			var decalSet:TileSet = this.gameData.tileSets["decal"];
			
			var loadArray:Array = new Array();			// array for all the loads.
			var baseURL:String = this.propsURL;

			/**
			 * swap tiles must be loaded on a separate list or the original list will be unintentionally altered.
			 */
			var swapList:Vector.<ClipTileType>;
			if ( loadSwaps ) {
				swapList = new Vector.<ClipTileType>();
			}

			var fileName:String;

			var len:int = decalTypes.length;
			var clipType:ClipTileType;
			for( var i:int = 0; i < len; i++ ) {

				clipType = decalTypes[i];
				if ( clipType.viewSourceFile == null ) {
					continue;
				}
				clipType.loading = true;

				if ( loadSwaps ) {

					spec = specials[ clipType ];
					if ( spec && spec.swapTile != 0 ) {
						
						var swapType:ClipTileType = decalSet.getTypeByCode( spec.swapTile ) as ClipTileType;
						if ( swapType != null && swapType.loading == false ) {
	
							swapType.loading = true;			// this needs to be set now to prevent duplicates.
							swapList.push( swapType );
	
						} //
	
					} //

				} //

				fileName = baseURL + clipType.viewSourceFile;
				// prevent FileManager crash from duplicate load urls.
				if ( loadArray.indexOf( fileName ) == -1 ) {
					loadArray.push( fileName );
				}

			} // for-loop.

			if ( loadArray.length > 0 ) {

				this.shellApi.loadFiles( loadArray, Command.create( this.vectorDecalsLoaded, decalTypes, callback ) );

			} else if ( callback ) {
				callback();	
			} //

			if ( swapList && swapList.length > 0 ) {
				// now load any tile swaps.
				this.loadDecalVector( swapList, false );
			} //
			
		} //

		/**
		 * !!!UPDATE: decal tiles are no longer preloaded by default.
		 * 
		 * complicated function to get all the tile files that need loading.
		 * 
		 * eventually tileSets might supply their own file lists by asking their tileTypes what files
		 * they need.
		 */
		public function loadTileFiles( onTilesLoaded:Function=null ):void {

			var loadArray:Array = new Array();			// array for all the loads.
			var tileTypes:Vector.<TileType>;
			var tileType:TileType;

			var baseURL:String = this.materialsURL;		// base url for Materials  - not for props.
			var fileName:String;

			var tileSets:Dictionary = this.gameData.tileSets;

			// loop through each tile set, picking up whatever files it needs.
			for each ( var tileSet:TileSet in tileSets ) {

				tileTypes = tileSet.tileTypes;
				// loop through tile types and find whatever load stuff they need.
				for( var i:int = tileTypes.length-1; i >= 0; i-- ) {

					tileType = tileTypes[i];
					if ( tileType is TerrainTileType ) {
						this.pushDetailFiles( tileType as TerrainTileType, loadArray );
					} else if ( tileType is ClipTileType ) {

						//this.loadClipTileFiles( tileType as ClipTileType, loadArray );
						// need to short circuit the duplicate viewSourceFile load.
						continue;

					} //

					// files common to all:
					if ( tileType.viewSourceFile != null && tileType.viewSourceFile != "" ) {
						fileName = baseURL + tileType.viewSourceFile;
						if (loadArray.indexOf( fileName ) == -1 ) {
							loadArray.push( fileName );
						}
					}

				} //

			} // end for-loop.

			if ( loadArray.length > 0 ) {
				this.shellApi.loadFiles( loadArray, this.tileFilesLoaded, onTilesLoaded );
			} else {

				// this will never happen.
				if ( onTilesLoaded ) {
					onTilesLoaded();
				}

			} //

		} //

		protected function pushDecalFiles( data:ClipTileType, loadArray:Array ):void {

			if ( data.viewSourceFile == null || data.viewSourceFile == "" ) {
				return;
			}

			var fileName:String = this.propsURL + data.viewSourceFile;
			if ( loadArray.indexOf( fileName ) == -1 ) {
				loadArray.push( fileName );
			}

		} // loadClipTileFiles()
		
		public function pushDetailFiles( data:TerrainTileType, loadArray:Array ):void {

			var baseURL:String = this.detailsURL;
			var fileName:String;

			if ( data.details != null ) {

				for each ( var detail:DetailType in data.details ) {

					if ( detail.clip != null ) {
						continue;
					}

					fileName = baseURL + detail.url;
					if ( loadArray.indexOf( fileName ) == -1 ) {
						loadArray.push( fileName );
					}

				} //

			} // end-details.

		} // loadTerrainFiles()

		/**
		 * decal tile files that were loaded on-demand.
		 */
		protected function decalFilesLoaded( decalTypes:Dictionary, callback:Function ):void {

			for each ( var clipType:ClipTileType in decalTypes ) {

				if ( clipType.loading ) {
					this.initClipTile( clipType );
				}

			} // end for-loop.

			if ( callback ) {
				callback();
			}

			this.shellApi.fileManager.clearCache();

		} //

		protected function vectorDecalsLoaded( decalTypes:Vector.<ClipTileType>, callback:Function ):void {

			var clipType:ClipTileType;

			for ( var i:int = decalTypes.length-1; i >= 0; i-- ) {

				clipType = decalTypes[i];

				if ( clipType.loading ) {
					this.initClipTile( clipType );
				}

			} // end for-loop.
			
			if ( callback ) {
				callback();
			}
			this.shellApi.fileManager.clearCache();

		} //

		/**
		 * This stuff might be relegated to tileSet functions that have their tileTypes
		 * get their own files. but whatever.
		 **/
		protected function tileFilesLoaded( onAssetsLoaded:Function ):void {
			
			var tileTypes:Vector.<TileType>;
			var tileType:TileType;
			
			var baseURL:String = this.materialsURL;
			var fileName:String;
			var image:DisplayObjectContainer;
			
			// loop through each tile set, picking up whatever files it needs.
			for each ( var tileSet:TileSet in this.gameData.tileSets ) {

				tileTypes = tileSet.tileTypes;
				// loop through tile types and find whatever load stuff they need.
				for( var i:int = tileTypes.length-1; i >= 0; i-- ) {
					
					tileType = tileTypes[i];
					
					if ( tileType is TerrainTileType ) {
						this.initTerrainFiles( tileType as TerrainTileType );
					} else if ( tileType is ClipTileType ) {
						
						//this.initClipTile( tileType as ClipTileType );
						// circumvent bitmap preparation.
						continue;

					} //

					// files common to all:
					if ( tileType.viewSourceFile != null ) {
						image = this.shellApi.getFile( baseURL + tileType.viewSourceFile, false );
						tileType.viewBitmapFill = LandUtils.prepareBitmap( image, image.width, image.height );
						// memory; all alone in the moonlight.
						tileType.viewSourceFile = null;
					} //

				} // another for-loop.

			} // end for-loop.

			if ( onAssetsLoaded ) {
				onAssetsLoaded();
			}

			this.shellApi.fileManager.clearCache();

		} // tileFilesLoaded()

		private function initClipTile( data:ClipTileType ):void {

			data.loading = false;
			if ( data.viewSourceFile ) {

				data.clip = this.shellApi.getFile( this.propsURL + data.viewSourceFile, false );
				data.clip.gotoAndStop( 1 );
				// let the memory, live again.
				data.viewSourceFile = null;
				
			} //
			
		} //
		
		private function initTerrainFiles( data:TerrainTileType ):void {

			/**
			 * Need to save detailer swfs.
			 */
			if ( data.details ) {
				
				for each ( var detail:DetailType in data.details ) {
					
					// the same detail clip can be stored for multiple sides, in which case
					// it might already have its clip assigned.
					if ( detail.clip == null ) {
						detail.setClip( this.shellApi.getFile( this.detailsURL + detail.url, false ) );
					}
					
				} //
				
			} // end-details.
			
		} // initTerrainFiles()

	} // class
	
} // package