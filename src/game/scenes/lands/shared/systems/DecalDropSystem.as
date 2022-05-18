package game.scenes.lands.shared.systems {

	/**
	 * controls dropping decals into the land scene.
	 * 
	 * this includes:
	 * - displaying a selected decal under the mouse location before it's placed.
	 * - placing the decal in the correct tile map location when the mouse is released.
	 * 
	 * Update: need some extra code to make props cost money and give experience. this is sadly ad-hoc
	 * since the code is duplicated in the LandEditSystem. We could have a system soley dedicated to
	 * tracking poptanium usage, although it would be a bit wasteful currently.
	 */

	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.input.Input;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.LandInventory;
	import game.scenes.lands.shared.classes.ResourceType;
	import game.scenes.lands.shared.components.LandEditContext;
	import game.scenes.lands.shared.nodes.LandEditNode;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;

	public class DecalDropSystem extends System {

		private var editContext:LandEditContext;

		private var masterNode:LandEditNode;

		/**
		 * used because the shellApi sometimes gives a mouseUp without a corresponding mouseDown.
		 * this forces the system to wait for a mouseDown after a decal has been selected
		 * before dropping it in screen.
		 */
		private var mouseIsDown:Boolean;

		/**
		 * deleteMode occurs whenever you roll over a decal of the same type as the one being placed.
		 * decals can then be 'paint-deleted' like regular tiles.
		 */
		private var deleteMode:Boolean;

		/**
		 * current decal being dropped.
		 */
		private var curDecalType:ClipTileType;

		/**
		 * need the editNode to control the tile hilite.
		 */
		private var editNodes:NodeList;

		private var active:Boolean;

		/**
		 * used to take away poptanium spent on props, and award experience for prop placement.
		 */
		private var inventory:LandInventory;

		private var expResource:ResourceType;
		private var popResource:ResourceType;

		/**
		 * the cost in poptanium of placing the current decal.
		 */
		private var curDecalCost:int;

		/**
		 * experience granted for placing the decal: current rows*cols
		 */
		//private var curDecalExp:int;

		public function DecalDropSystem() {

			super();

			this.active = false;

		} //

		private function onEditModeChanged( newMode:int ):void {

			if ( newMode == LandEditMode.DECAL ) {

				if ( !this.active ) {
					this.activate();
				}

			} else {

				if ( this.active ) {
					this.deactivate();
				}

			} //

		} //

		public function deactivate():void {

			this.active = false;
			this.mouseIsDown = false;
			var input:Input = ( super.group.shellApi.inputEntity.get( Input ) as Input );
			input.inputDown.remove( this.onMouseDown );
			input.inputUp.remove( this.onMouseUp );

			this.curDecalType = null;

		} //

		public function activate():void {
			
			this.masterNode.hilite.tileGrid.visible = this.masterNode.hilite.hiliteBox.visible = true;
			//this.masterNode.focus.enabled = false;

			// don't duplicate the add-listeners.
			var input:Input = ( super.group.shellApi.inputEntity.get( Input ) as Input );
			input.inputDown.add( this.onMouseDown );
			input.inputUp.add( this.onMouseUp );

			this.active = true;
			this.deleteMode = false;
			this.mouseIsDown = false;		// might get the mouseUp from something before decal mode began.
			
		} //

		override public function update( time:Number ):void {
			
			if ( !this.active || this.editContext.curTileType == null ) {
				return;
			}
			
			if ( this.curDecalType != this.editContext.curTileType ) {
				this.setActiveDecal( this.editContext.curTileType as ClipTileType );
			}

			var focus:LandTile = this.masterNode.focus.tile;
			if ( !focus ) {
				return;
			}

			// if the mouse is UP, check if you're hovering over a prop to delete.
			// if you have a prop selected and you click on the same type of prop in the scene, it will attempt to delete it.
			// However, delete mode doesn't toggle while the mouse is being held down - if you start placing props and hold-drag the mouse, they keep placing.
			if ( !this.mouseIsDown ) {

				// focus tile has same type. enter delete mode.
				if ( focus.type == this.curDecalType.type ) {

					if ( !this.deleteMode ) {
						this.doDeleteMode();
					}
					
				} else {

					if ( this.deleteMode ) {
						this.deleteMode = false;
						this.setDropHilite();
					} //
					
				} //

			} else {

				// mouse is DOWN - check for deleting current tile.
				if ( this.deleteMode && focus.type == this.curDecalType.type ) {
					this.deleteCurTile();
				}

			} //
			
		} // update()

		private function setActiveDecal( decalType:ClipTileType ):void {
			
			// get the current edit-tile type - the type selected by the user for placing on map.
			// this should be the current decal being placed. if not, return.
			this.curDecalType = decalType;

			// this is probably necessary since input can give mouseDown events for unrelated buttons.
			// need to switch the listener to something more rational.
			this.mouseIsDown = false;

			if ( !this.deleteMode ) {
				this.setDropHilite();
			}

		} //

		/**
		 * set the hilite colors and sizes for drop mode.
		 */
		private function setDropHilite():void {

			var decalClip:MovieClip = this.curDecalType.clip;
			var decalTileSize:int = this.editContext.curTileSize;

			// TO-DO: set something in the hilite component that changes all this automatically.
			var hiliteRect:Rectangle = this.masterNode.hilite.hiliteRect;

			// using loaderInfo.width/height to get the stage size of the loaded swf.
			// this is because the swfs might be centered within the loaded swf and have white-space on either side.
			var cols:int = Math.ceil( (decalClip.loaderInfo.width) / decalTileSize );
			var rows:int = Math.ceil( decalClip.loaderInfo.height / decalTileSize );

			this.curDecalCost = rows*cols;

			hiliteRect.width = decalTileSize*cols;
			hiliteRect.height = decalTileSize*rows;

			this.masterNode.hilite.setHiliteColor( this.masterNode.hilite.WHITE_HILITE );

			// wait for the next mousedown/mouseup to place the decal.

		} //

		private function doDeleteMode():void {

			// TO-DO: set something in the hilite component that changes all this automatically.
			var hiliteRect:Rectangle = this.masterNode.hilite.hiliteRect;
			
			// using loaderInfo.width/height to get the stage size of the loaded swf.
			hiliteRect.width = hiliteRect.height = this.editContext.curTileSize;
			this.masterNode.hilite.setHiliteColor( this.masterNode.hilite.RED_HILITE );

			this.deleteMode = true;
			
		} //

		private function onMouseDown( input:Input ):void {

			if ( this.active && this.curDecalType != null ) {

				this.mouseIsDown = true;

			} //

		} //

		private function deleteCurTile():void {

			this.masterNode.audio.playCurrentAction( "erase" );
			this.masterNode.focus.tile.type = 0;

			this.editContext.curLayer.renderArea( this.masterNode.hilite.hiliteRect );

		} //

		private function onMouseUp( input:Input ):void {

			if ( !this.mouseIsDown || !this.active || this.curDecalType == null ) {
				return;
			}
			this.mouseIsDown = false;
			if ( this.deleteMode ) {
				return;
			}

			// this had better be a decal tile map...
			var tileMap:TileMap = this.editContext.curTileMap;
			if ( tileMap.tileSet.setType != "decal" ) {
				// better not happen...
				return;
			}

			var popCost:int = this.curDecalCost;
			if ( this.curDecalType.cost != 0 && this.editContext.curLayer.name == "foreground" ) {
				popCost = this.curDecalType.cost;
			} //

			if ( this.popResource.count < popCost ) {
				( this.group as LandGroup ).getUIGroup().showPoptaniumWarning();
				return;
			}

			this.masterNode.game.gameData.sceneMustSave = true;

			var rect:Rectangle = this.masterNode.hilite.hiliteRect;

			if ( this.editContext.flipped ) {
				this.curDecalType.dropFlippedDecal( tileMap, rect );
			} else {
				this.curDecalType.dropDecal( tileMap, rect );
			}

			this.editContext.curLayer.renderArea( rect );
			this.masterNode.audio.playCurrentAction( "build" );

			//this.inventory.useResource( this.popResource, this.curDecalCost );
			( this.group as LandGroup ).losePoptanium( rect.x + rect.width/2 - 40, rect.y, popCost );
			this.inventory.collectResource( this.expResource, this.curDecalCost );

			( this.group as LandGroup ).gameData.progress.tryLevelUp( this.expResource.count );

		} //

		/**
		 * There should only ever be ONE node added.
		 */
		private function editNodeAdded( node:LandEditNode ):void {

			this.setMasterNode( node );

		} //

		private function editNodeRemoved( node:LandEditNode ):void {

			if ( this.masterNode == node ) {

				this.setMasterNode( this.editNodes.head );

			} //

		} //

		private function setMasterNode( node:LandEditNode ):void {

			this.masterNode = node;
			if ( node ) {

				this.editContext = node.editContext;
				//this.editContext.onTileTypeChanged.add( this.onTileTypeChanged );
				this.editContext.onEditModeChanged.add( this.onEditModeChanged );

			} else if ( this.active ) {
				// no master node, deactivate system.
				this.deactivate();
			}

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.editNodes = systemManager.getNodeList( LandEditNode );
			this.editNodes.nodeAdded.add( this.editNodeAdded );
			this.editNodes.nodeRemoved.add( this.editNodeRemoved );

			this.setMasterNode( this.editNodes.head );

			if ( !ClipTileType.TestBitmap ) {
				ClipTileType.TestBitmap = new BitmapData( 16, 16, true );
			}

			this.inventory = ( this.group as LandGroup ).gameData.inventory;
			this.popResource = inventory.getResource( "poptanium" );
			this.expResource = inventory.getResource( "experience" );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			if ( this.active ) {
				this.deactivate();
			}

			if ( ClipTileType.TestBitmap ) {
				ClipTileType.TestBitmap.dispose();
				ClipTileType.TestBitmap = null;			// this has to be done for leaving/returning to ad scenes.
			}

			this.editNodes.nodeAdded.remove( this.editNodeAdded );
			this.editNodes.nodeRemoved.remove( this.editNodeRemoved );

			this.inventory = null;
			this.popResource = this.expResource = null;

			this.editNodes = null;

		} //

	} // class

} // package