package game.scenes.lands.shared.systems {

	/**
	 * 
	 * tracks which tile and tile type are currently in focus under the mouse.
	 * 
	 * it also redraws the hilite box, the hilite grid, and sets the refresh rect
	 * for redrawing portions of the tile layers.
	 */

	import flash.display.Shape;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.components.FocusTileComponent;
	import game.scenes.lands.shared.components.LandEditContext;
	import game.scenes.lands.shared.components.LandHiliteComponent;
	import game.scenes.lands.shared.nodes.LandEditNode;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;

	public class FocusTileSystem extends System {

		/**
		 * currently there can only ever be a single edit node. I'm not quite sure how multiple edit nodes
		 * would even work.
		 */
		private var focusNodes:NodeList;

		/**
		 * cached components of the master node.
		 */
		private var editContext:LandEditContext;
		private var hilite:LandHiliteComponent;
		private var focus:FocusTileComponent;

		/**
		 * tile hilite box.
		 */
		private var hiliteBox:Shape;

		/**
		 * Grid to show while editing.
		 */
		protected var tileGrid:Shape;

		/**
		 * temp. need to move this to some entity or something.
		 */
		private var mapOffsetX:int;

		private var masterNode:LandEditNode;

		/**
		 * used to store a new focus before the old one is changed.
		 * this is because the newFocus might have something preventing it from becoming current.
		 */
		private var newFocus:TileSelector;

		public function FocusTileSystem( mapOffsetX:int ) {

			super();

			this.mapOffsetX = mapOffsetX;

			this.newFocus = new TileSelector();

		} //

		override public function update( time:Number ):void {

			/**
			 * there should only be ONE land edit node. anything else is just wrong wrong wrong.
			 * note the stupid template pause fix - this needs to go.
			 */
			if ( this.masterNode == null || this.masterNode.entity.sleeping || this.focus.enabled == false ) {
				return;
			}
			var x:Number = this.tileGrid.mouseX;
			var y:Number = this.tileGrid.mouseY;

			var r:int;
			var c:int;

			var tile:LandTile;

			if ( this.editContext.curEditMode == LandEditMode.PLAY ) {

				tile = this.focus.tile = this.findTopMinable( x, y, this.newFocus );

				/**
				 * in destroy mode, hilight any tile from the same layer.
				 */
				if ( tile == null ) {

					this.focus.tile = null;
					this.focus.type = null;
					this.focus.tileMap = null;

				} else {

					this.focus.type = this.newFocus.tileType;
					this.focus.tileMap = this.newFocus.tileMap;

				} // end-if.

				return;

			} else if ( this.editContext.curEditMode & LandEditMode.MINING ) {

			 	tile = this.findTopMinable( x, y, this.newFocus );

				/**
				 * in destroy mode, hilight any tile from the same layer.
				 */
				if ( tile == null ) {

					// no destroyable tile at this location.
					this.hiliteBox.visible = false;
					this.focus.tile = null;
					this.focus.type = null;

				} else {

					r = tile.row;
					c = tile.col;

					if ( this.newFocus.tileMap != this.editContext.curTileMap ) {

						this.editContext.setCurTileMap( this.newFocus.tileMap );
						this.hilite.setBrushSize( this.editContext.curTileSize );

					} //

					this.focus.tileMap = this.newFocus.tileMap;
					this.focus.type = this.newFocus.tileType;
					this.hiliteBox.visible = true;

				} // end-if.
				
			} else if ( this.editContext.curEditMode == LandEditMode.EDIT ) {

				r = Math.floor( y / this.editContext.curTileSize );
				c = Math.floor( x / this.editContext.curTileSize );
				tile = this.focus.tile = this.editContext.curTileMap.getTile( r, c );

				if ( !this.editContext.isPainting ) {

					// only update hilite color when NOT painting.
					if ( tile == null || tile.type == 0 || !this.editContext.curTileMap.hasType( tile, this.editContext.curTileType.type ) ) {
	
						// Land Edit Mode create option. Turn the hilite white UNLESS currently painting.
						if ( this.hilite.hiliteColor != this.hilite.WHITE_HILITE ) {
							this.hilite.setHiliteColor( this.hilite.WHITE_HILITE );
						}
	
					} else {

						// Land Edit Mode delete option. Turn the hilite red.
						if ( this.hilite.hiliteColor != this.hilite.RED_HILITE ) {
							this.hilite.setHiliteColor( this.hilite.RED_HILITE );
						} //

					} //

				} // ( !painting )
				
			} else {

				r = Math.floor( y / this.editContext.curTileSize );
				c = Math.floor( x / this.editContext.curTileSize );
				tile = this.focus.tile = this.editContext.curTileMap.getTile( r, c );

			} // end-if.

			/**
			 * These coordinates are set last because the tileSet may have changed by looking for non-empty tile types.
			 */
			if ( this.hilite.autoUpdate ) {

				this.hiliteBox.y = this.hilite.hiliteRect.y = this.editContext.curTileSize*r;

				this.hilite.hiliteRect.x = this.editContext.curTileSize*c;
				this.hiliteBox.x = this.hilite.hiliteRect.x + this.mapOffsetX;

				this.focus.tile = tile;

			} //

		} // update()

		/**
		 * finds the highest non-empty tile in a layer that can be mined, or null if none found.
		 */
		private function findTopMinable( x:Number, y:Number, highTile:TileSelector ):LandTile {
			
			var tmaps:Vector.<TileMap> = this.editContext.curLayer.getMaps();
			var tmap:TileMap;
			var tile:LandTile;

			for( var i:int = tmaps.length-1; i >= 0; i-- ) {

				tmap = tmaps[i];
				tile = tmap.getTileAt( x, y );

				if ( tile != null && tile.type != 0 ) {

					highTile.tileType = tmap.getType( tile );
					if ( !highTile.tileType.allowMining ) {
						continue;
					}
					highTile.tileMap = tmap;
					highTile.tile = tile;

					return tile;

				} // end-if.

			} // end for-loop.

			return null;

		} //

		/**
		 * There should only ever be ONE edit node.
		 */
		private function editNodeAdded( node:LandEditNode ):void {

			this.setMasterNode( node );

		} //

		private function editNodeRemoved( node:LandEditNode ):void {

			if ( this.masterNode == node ) {
				this.setMasterNode( this.focusNodes.head );
			} //

		} //

		private function setMasterNode( node:LandEditNode ):void {

			this.masterNode = node;
			if ( node ) {

				this.editContext = node.editContext;
				this.hilite = node.hilite;

				this.tileGrid = node.hilite.tileGrid;
				this.hiliteBox = node.hilite.hiliteBox;
				this.focus = node.focus;

			} //

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.focusNodes = systemManager.getNodeList( LandEditNode );
			this.focusNodes.nodeAdded.add( this.editNodeAdded );
			this.focusNodes.nodeRemoved.add( this.editNodeRemoved );

			this.setMasterNode( this.focusNodes.head );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			if ( this.tileGrid.parent ) {
				this.tileGrid.parent.removeChild( this.tileGrid );
			}
			if ( this.hiliteBox.parent ) {
				this.hiliteBox.parent.removeChild( this.hiliteBox );
			}

			this.focusNodes.nodeAdded.remove( this.editNodeAdded );
			this.focusNodes.nodeRemoved.remove( this.editNodeRemoved );

			this.focusNodes = null;

		} //

	} // class

} // package