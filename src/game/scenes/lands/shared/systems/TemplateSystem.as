package game.scenes.lands.shared.systems {

	/**
	 * controls the display and placement of templates.
	 * 
	 * this includes several things:
	 * - dragging over the land to create a new template.
	 * - displaying template outlines under the mouse before they're placed in the map.
	 * - placing a selected template on the map under the current mouse location.
	 */
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.input.Input;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.components.LandEditContext;
	import game.scenes.lands.shared.nodes.LandEditNode;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.templates.TileTemplate;

	public class TemplateSystem extends System {

		/**
		 * template system modes.
		 */
		public const MODE_CREATE_TEMPLATE:int = 1;
		public const MODE_DROP_TEMPLATE:int = 2;

		/**
		 * currently only save data in increments of 64.
		 */
		public var TILE_CHUNK_SIZE:int = 64;
		public var biggestMap:TileMap;

		private var curMode:int = this.MODE_CREATE_TEMPLATE;

		/**
		 * Display used for getting the location of mouse clicks.
		 */
		private var clickDisplay:DisplayObject;

		private var editContext:LandEditContext;

		/**
		 * temp. need to move this to some entity or something.
		 */
		private var mapOffsetX:int;

		private var masterNode:LandEditNode;

		/**
		 * true if holding down and dragging while in create mode.
		 */
		private var dragging:Boolean;

		/**
		 * used because the shellApi sometimes gives a mouseUp without a corresponding mouseDown.
		 * this forces the system to wait for a mouseDown after a template has been loaded
		 * before dropping it in screen.
		 */
		private var dropping:Boolean;

		/**
		 * starting point of a drag.
		 */
		private var dragStart:Point;
		private var dragEnd:Point;

		private var gameData:LandGameData;

		/**
		 * current template being dropped.
		 */
		private var curTemplate:TileTemplate;

		/**
		 * need the editNode to control the tile hilite.
		 */
		private var editNodes:NodeList;

		public function TemplateSystem( curScene:PlatformerGameScene, gameData:LandGameData ) {

			super();

			this.gameData = gameData;

			this.mapOffsetX = gameData.mapOffsetX;

			this.dragStart = new Point();
			this.dragEnd = new Point();

		} //

		private function onMouseDown( input:Input ):void {

			if ( this.curMode == this.MODE_CREATE_TEMPLATE ) {

				this.dragStart.x = this.TILE_CHUNK_SIZE * Math.floor( this.clickDisplay.mouseX / this.TILE_CHUNK_SIZE );
				this.dragStart.y = this.TILE_CHUNK_SIZE * Math.floor( this.clickDisplay.mouseY / this.TILE_CHUNK_SIZE );

				this.dragging = true;

				this.masterNode.hilite.hiliteRect.setTo( this.dragStart.x, this.dragStart.y, this.TILE_CHUNK_SIZE, this.TILE_CHUNK_SIZE );
				this.masterNode.hilite.redrawHilite();
				this.masterNode.hilite.hiliteBox.visible = true;
				this.masterNode.hilite.hiliteBox.x = this.dragStart.x + this.mapOffsetX;
				this.masterNode.hilite.hiliteBox.y = this.dragStart.y;

			} else if ( this.curMode == this.MODE_DROP_TEMPLATE ) {

				this.dropping = true;

			} //

		} //

		private function onMouseUp( input:Input ):void {

			if ( this.dropping && this.curMode == this.MODE_DROP_TEMPLATE ) {

				this.dropping = false;

				/**
				 * must align the placement to the largest chunk size, or separate tile maps will align to different grid sizes.
				 */
				var xmouse:Number = this.TILE_CHUNK_SIZE*Math.floor( this.clickDisplay.mouseX / this.TILE_CHUNK_SIZE );
				var ymouse:Number = this.TILE_CHUNK_SIZE*Math.floor( this.clickDisplay.mouseY / this.TILE_CHUNK_SIZE );

				// user just dropped a template somewhere.
				// try to place it and then... close the pane? or something?
				this.curTemplate.pasteTemplate( this.gameData.tileMaps, xmouse, ymouse );

				// reset mode.. for now.
				this.curMode = this.MODE_CREATE_TEMPLATE;

				var rect:Rectangle =
					new Rectangle( xmouse, ymouse, this.curTemplate.width, this.curTemplate.height );

				this.gameData.fgLayer.renderArea( rect );
				this.gameData.bgLayer.renderArea( rect );

				this.editContext.curEditMode = LandEditMode.PLAY;
				this.masterNode.hilite.hiliteBox.visible = false;

			} else if ( this.curMode == this.MODE_CREATE_TEMPLATE && this.dragging ) {

				this.dragging = false;
				this.dragEnd.x = this.TILE_CHUNK_SIZE * Math.ceil( this.clickDisplay.mouseX / this.TILE_CHUNK_SIZE );
				this.dragEnd.y = this.TILE_CHUNK_SIZE * Math.ceil( this.clickDisplay.mouseY / this.TILE_CHUNK_SIZE );

			} // end-if.

		} //

		override public function update( time:Number ):void {

			var mousex:int;
			var mousey:int;

			if ( this.curMode == this.MODE_DROP_TEMPLATE ) {

				mousex = this.TILE_CHUNK_SIZE*Math.floor( this.clickDisplay.mouseX/this.TILE_CHUNK_SIZE );
				mousey = this.TILE_CHUNK_SIZE*Math.floor( this.clickDisplay.mouseY/this.TILE_CHUNK_SIZE );
				
				this.masterNode.hilite.hiliteRect.setTo( mousex, mousey,
					this.TILE_CHUNK_SIZE*Math.ceil( this.curTemplate.width/this.TILE_CHUNK_SIZE),
					this.TILE_CHUNK_SIZE*Math.ceil( this.curTemplate.height/this.TILE_CHUNK_SIZE) );

				this.masterNode.hilite.hiliteBox.x = mousex + this.mapOffsetX;
				this.masterNode.hilite.hiliteBox.y = mousey;

			} else if ( this.dragging ) {

				//this.clickDisplay.mouseX, this.clickDisplay.mouseY
				mousex = this.clickDisplay.mouseX;
				if (mousex < this.dragStart.x ) {
					mousex = this.TILE_CHUNK_SIZE*Math.floor( this.clickDisplay.mouseX/this.TILE_CHUNK_SIZE );
				} else {
					mousex = this.TILE_CHUNK_SIZE*Math.ceil( this.clickDisplay.mouseX/this.TILE_CHUNK_SIZE );
				} //
				mousey = this.clickDisplay.mouseY;
				if ( mousey < this.dragStart.y ) {
					mousey = this.TILE_CHUNK_SIZE*Math.floor( this.clickDisplay.mouseY/this.TILE_CHUNK_SIZE );
				} else {
					mousey = this.TILE_CHUNK_SIZE*Math.ceil( this.clickDisplay.mouseY/this.TILE_CHUNK_SIZE );
				} //

				this.masterNode.hilite.hiliteRect.setTo( this.dragStart.x, this.dragStart.y,
					this.TILE_CHUNK_SIZE*Math.ceil( (mousex - this.dragStart.x) / this.TILE_CHUNK_SIZE),
					this.TILE_CHUNK_SIZE*Math.ceil( (mousey - this.dragStart.y) / this.TILE_CHUNK_SIZE) );

				this.masterNode.hilite.redrawHilite();

			} //

		} // update()

		public function beginTemplateCreate():void {

			this.curMode = this.MODE_CREATE_TEMPLATE;

			this.masterNode.hilite.hiliteBox.visible = false;

			this.masterNode.hilite.redrawGrid( this.biggestMap.tileSize, this.biggestMap.rows, this.biggestMap.cols );


		} //

		public function beginTemplateDrop( template:TileTemplate ):void {

			// wait for the next mousedown/mouseup
			this.dropping = false;

			this.curTemplate = template;
			this.curMode = this.MODE_DROP_TEMPLATE;

			var xstart:int = this.TILE_CHUNK_SIZE*Math.floor( this.clickDisplay.mouseX/this.TILE_CHUNK_SIZE );
			var ystart:int = this.TILE_CHUNK_SIZE*Math.floor( this.clickDisplay.mouseY/this.TILE_CHUNK_SIZE );
			
			this.masterNode.hilite.hiliteRect.setTo( xstart, ystart,
				this.TILE_CHUNK_SIZE*Math.ceil(template.width/this.TILE_CHUNK_SIZE),
				this.TILE_CHUNK_SIZE*Math.ceil(template.height/this.TILE_CHUNK_SIZE) );
			
			this.masterNode.hilite.hiliteBox.x = xstart + this.mapOffsetX;
			this.masterNode.hilite.hiliteBox.y = ystart;

			this.masterNode.hilite.hiliteBox.visible = true;
			this.masterNode.hilite.redrawHilite();
			
		} //

		public function tryCreateTemplate():TileTemplate {
			
			var minX:Number;
			var minY:Number;
			var width:Number;
			var height:Number;
			
			if ( this.dragEnd.x <= this.dragStart.x ) {
				minX = this.dragEnd.x;
				width = this.dragStart.x - minX;
			} else {
				minX = this.dragStart.x;
				width = this.dragEnd.x - minX;
			}
			
			if ( this.dragEnd.y <= this.dragStart.y ) {

				minY = this.dragEnd.y;
				height = this.dragStart.y - minY;

			} else {

				minY = this.dragStart.y;
				height = this.dragEnd.y - minY;

			} //

			if ( width < 64 || height < 64 ) {
				return null;
			}

			var template:TileTemplate = new TileTemplate();
			template.createTemplate( this.gameData.tileMaps, minX, minY, width, height, this.gameData.tileSpecials );

			return template;

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
				this.clickDisplay = node.hilite.tileGrid;

				this.biggestMap = this.gameData.getFGLayer().findBiggestTiles();
				this.TILE_CHUNK_SIZE = this.biggestMap.tileSize;

			} //

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.editNodes = systemManager.getNodeList( LandEditNode );
			this.editNodes.nodeAdded.add( this.editNodeAdded );
			this.editNodes.nodeRemoved.add( this.editNodeRemoved );

			this.setMasterNode( this.editNodes.head );

			var input:Input = ( super.group.shellApi.inputEntity.get( Input ) as Input );
			input.inputDown.add( this.onMouseDown );
			input.inputUp.add( this.onMouseUp );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			var input:Input = ( super.group.shellApi.inputEntity.get( Input ) as Input );
			input.inputDown.remove( this.onMouseDown );
			input.inputUp.remove( this.onMouseUp );

			this.editNodes.nodeAdded.remove( this.editNodeAdded );
			this.editNodes.nodeRemoved.remove( this.editNodeRemoved );

			this.editNodes = null;

		} //

	} // class

} // package