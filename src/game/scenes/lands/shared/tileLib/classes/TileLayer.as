package game.scenes.lands.shared.tileLib.classes {

	import flash.geom.Rectangle;
	
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	//import game.scenes.lands.shared.tileLib.renderers.LightRenderer;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;

	public class TileLayer {

		public var name:String;

		/**
		 * lowest draw order first.
		 */
		protected var tileMaps:Vector.<TileMap>;

		/**
		 * area being erased during a layer redraw, in tile coordinate space.
		 */
		protected var tileEraseRect:Rectangle;

		/**
		 * contains basic draw shapes and matrices that are reused for every renderer.
		 */
		private var renderContext:RenderContext;

		/**
		 * layer offset for randoms in this layer. used to give different layers
		 * different land features - otherwise things like trees match up 
		 * almost exactly.
		 */
		public var randOffset:int = 0;

		/**
		 * sort of complicated. the different tile types can define different visual properties based on what layer
		 * they're in. For example: a 'wood wall' tile type can define a thicker outline stroke when its in the foreground
		 * than when its in the background.
		 * 
		 * This would be tedious to store in the tiles themselves, so instead it's stored in the
		 * layers. Before rendering, these properties are set by the layer. Need to think of a better (but efficient)
		 * way to do this.
		 * 
		 */
		public var layerProps:Vector.<TileLayerProp>;

		/**
		 * temporary place to shove the light renderer, if any.
		 */
		//public var lights:LightRenderer;

		public function TileLayer( layerName:String, rc:RenderContext ) {

			this.name = layerName;

			this.layerProps = new Vector.<TileLayerProp>();

			this.tileEraseRect = new Rectangle();

			this.renderContext = rc;

		} // TileLayer()

		public function render():void {

			this.resetLayerProps();

			// clear everything.
			this.renderContext.clearContext();

			var len:int = this.tileMaps.length;
			var tmap:TileMap;
			var renders:int;

			//var t1:Number = getTimer();

			for( var i:int = 0; i < len; i++ ) {

				tmap = this.tileMaps[i];

				renders = tmap.renderers.length;
				for( var j:int = 0; j < renders; j++ ) {
					tmap.renderers[j].render();
				} //

			} // for-loop.

			/*if ( this.lights ) {
				this.lights.render();
			}*/

			//var t2:Number = getTimer();
			//trace( this.name + " LAYER RENDER TIME: " + (t2-t1) );

		} //

		/**
		 * render function just for reviewing a realm.
		 * no erase rect is set and layer props are ignored.
		 * erasing isnt done because the bitmap is reused.
		 */
		public function renderReview():void {

			var len:int = this.tileMaps.length;
			var tmap:TileMap;
			var renders:int;
			
			for( var i:int = 0; i < len; i++ ) {

				tmap = this.tileMaps[i];

				renders = tmap.renderers.length;
				for( var j:int = 0; j < renders; j++ ) {
					tmap.renderers[j].render();
				} //

			} // for-loop.

		} //

		/**
		 * Re-render a given region of the screen.
		 * 
		 * the updateRect is in tileMap coordinates, so its origin is offscreen. (at mapOffsetX)
		 * 
		 * The rendered area is actually slightly larger than the size indicated, because local changes
		 * can change the appearance of nearby tiles and some tiles are larger than their bounding rects.
		 */
		public function renderArea( updateRect:Rectangle ):void {

			this.resetLayerProps();
			this.setEraseRect( updateRect );

			var len:int = this.tileMaps.length;
			var renders:int;

			var tmap:TileMap;
			for( var i:int = 0; i < len; i++ ) {

				tmap = this.tileMaps[i];

				renders = tmap.renderers.length;
				for( var j:int = 0; j < renders; j++ ) {
					tmap.renderers[j].renderArea( this.tileEraseRect );
				} //

			} // for-loop.

			/*if ( this.lights ) {
				this.lights.renderArea( this.tileEraseRect );
			}*/

		} //

		/**
		 * set the eraseRect becased on the given updateRect - a region that was updated on screen.
		 */
		protected function setEraseRect( updateRect:Rectangle ):void {

			// updateRect extensions are 256,256 because its being extended by 128 in each direction.
			this.tileEraseRect.setTo( updateRect.x - 128, updateRect.y - 128, updateRect.width + 256, updateRect.height + 256 );

			// keep the rect in the bounds of the screen, though it probably doesn't really matter.
			if ( this.tileEraseRect.x < 0 ) {
				this.tileEraseRect.width += this.tileEraseRect.x;
				this.tileEraseRect.x = 0;
			}
			if ( this.tileEraseRect.y < 0 ) {
				this.tileEraseRect.height += this.tileEraseRect.y;
				this.tileEraseRect.y = 0;
			}

			this.renderContext.clearMapRect( this.tileEraseRect );

		} //

		/**
		 * maps should be pre-sorted in order by map.drawOrder (lowest first).
		 */
		public function setTileMaps( maps:Vector.<TileMap> ):void {
	
			this.tileMaps = maps;

			/*this.tileSets = new Vector.<TileSet>( this.tileMaps.length, true );
			for( var i:int = this.tileMaps.length-1; i >= 0; i-- ) {
				this.tileSets[i] = maps[i].tileSet;
			} //*/

		} //

		/**
		 * returns the tile map which uses the given tileset, or null if none found.
		 */
		public function getMapWithSet( tileSet:TileSet ):TileMap {

			for( var i:int = this.tileMaps.length-1; i >= 0; i-- ) {

				if ( this.tileMaps[i].tileSet == tileSet ) {
					return this.tileMaps[i];
				}

			} //

			return null;

		} //

		public function addLayerProp( obj:*, propName:String, value:*):void {

			this.layerProps.push( new TileLayerProp( obj, propName, value ) );

		} //

		/**
		 * call this function when the rendering layer changes.
		 */
		public function resetLayerProps():void {
			
			var prop:TileLayerProp;
			
			for( var i:int = this.layerProps.length-1; i >= 0; i-- ) {
				
				prop = this.layerProps[i];
				prop.obj[ prop.prop ] = prop.value;
				
			} //
			
		} //

		/**
		 * returns true if there is any filled tile at the row,col
		 * location on this tile layer, assuming a tile size of 32.
		 */
		public function isEmpty( r:int, c:int ):Boolean {

			var tmap:TileMap;

			for( var i:int = this.tileMaps.length-1; i >= 0; i-- ) {

				tmap = this.tileMaps[i];
				if ( tmap.tileSize == 32 ) {

					if ( this.tileMaps[i].getTileType( r, c ) != 0 ) {
						return false;
					}

				} else {

					if ( this.tileMaps[i].getTileType( r/2, c/2 ) != 0 ) {
						return false;
					}

				} //

			} //

			return true;

		} //

		/**
		 * several operations need to know the largest tileSize in a layer
		 * and which map has the largest tile size.
		 * 
		 * things like random-variable maps, scene scrolling, and template creation need to align themselves
		 * to the largest tileSize, since tileMaps can only place on whole tiles.
		 * 
		 * for example: if a tileMap has a tileSize of 64, it can't fit into a 32-tileSize template of total width 96
		 */
		public function findBiggestTiles():TileMap {
			
			var biggest:TileMap;
			var tileSize:int = 0;

			for ( var i:int = this.tileMaps.length-1; i >= 0; i-- ) {
				
				if ( this.tileMaps[i].tileSize > tileSize ) {
					biggest = this.tileMaps[i];
					tileSize = biggest.tileSize;
				} //

			} //

			return biggest;

		} //

		public function getMapByName( name:String ):TileMap {
			
			for( var i:int = 0; i < this.tileMaps.length; i++ ) {
				
				if ( this.tileMaps[i].name == name ) {
					return this.tileMaps[i];
				}
				
			} //
			
			return null;
			
		} //

		public function getRenderContext():RenderContext {
			return this.renderContext;
		}

		public function getMaps():Vector.<TileMap> {
			return this.tileMaps;
		}

		public function reset():void {

			for( var i:int = this.tileMaps.length-1; i >= 0; i-- ) {
				this.tileMaps[i].destroy();
			} //
			this.tileMaps = null;

			this.layerProps.length = 0;

		} //

		/**
		 * add a light renderer for this layer - typically foreground only.
		 */
		/*public function addLightRenderer( gameData:LandGameData ):void {

			if ( this.lights == null ) {
				this.lights = new LightRenderer( this, gameData.tileHits );
				this.lights.setRenderContext( this.renderContext );
			} else {
				this.lights.refreshMaps();
			}

		} //*/
		
		public function destroy():void {
			
			this.renderContext.viewBitmap.dispose();
	
			if ( this.tileMaps != null ) {
				for( var i:int = this.tileMaps.length-1; i >= 0; i-- ) {
					this.tileMaps[i].destroy();
				} //
			}
			this.tileMaps = null;
			
			this.layerProps.length = 0;
			this.layerProps = null;
			
		} //

		/**
		 * tricky thing. need to use the renderers for this layer to render its parts of the tileTemplate.
		 */
		/*		public function renderTemplate( template:TileTemplate, viewBitmap:BitmapData ):void {
		
		var len:int = this.tileMaps.length;
		var tmap:TileMap;
		var renders:int;
		
		// dictionary of template templateGrid grids.
		// each grid is template data corresponding to one of the layer's tile maps (or empty)
		var grids:Dictionary;
		var curGrid:TemplateGrid;
		
		for( var i:int = 0; i < len; i++ ) {
		
		tmap = this.tileMaps[i];
		
		curGrid = grids[ tmap.name ];
		if ( curGrid == null ) {
		// no template data corresponding to this tilemap.
		continue;
		} //
		
		// each renderer needs to be prepared to render the grid data instead of the tileMap data.
		// it also needs a new bitmap assigned so it doesnt draw into the layer bitmap.
		renders = tmap.renderers.length;
		for( var j:int = 0; j < renders; j++ ) {
		
		
		tmap.renderers[j].render();
		
		
		} //
		
		} // for-loop.
		
		} */

	} // class

} // package