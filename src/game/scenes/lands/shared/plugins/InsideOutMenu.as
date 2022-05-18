package game.scenes.lands.shared.plugins {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.systems.LandEditSystem;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	import game.scenes.lands.shared.ui.panes.LandPane;
	import game.util.ColorUtil;
	
	
	public class InsideOutMenu extends LandPane {

		private const blueType:uint = 1;
		private const greenType:uint = 2;
		private const redType:uint = 4;
		private const yellowType:uint = 8;
		private const purpleType:uint = 16;

		private const blueColor:int = 0xFFFFF;
		private const redColor:int = 0xEF3B24;
		private const greenColor:int = 0xB3D335;
		private const yellowColor:int = 0xF2EA23;
		private const purpleColor:int = 0x994F9F;

		/**
		 * last button selected. the selected button is made large and moved
		 * into the center position
		 * from the fla, the yellow button starts selected.
		 */
		private var selectedBtn:MovieClip;

		/**
		 * tile set to use for the drawing.
		 */
		private var tileSet:TileSet;

		private var plugin:InsideOutPlugin;

		public function InsideOutMenu( pane:DisplayObjectContainer, group:LandUIGroup, parentPlugin:InsideOutPlugin ) {

			super( pane, group );

			this.plugin = parentPlugin;
			this.tileSet = group.landGroup.gameData.tileSets["trees"];

		}

		public function init():void {

			var btn:MovieClip = this.clipPane.btnBlue;
			// !! sizeclip is a subclip with the 'large' size icon on frame 2.
			btn.sizeClip.gotoAndStop( 1 );

			this.makeButton( btn, this.onClickMode, 2, "Blue" );

			btn = this.clipPane.btnRed;
			btn.sizeClip.gotoAndStop( 1 );
			this.makeButton( btn, this.onClickMode, 2, "Red" );

			btn = this.clipPane.btnYellow;
			btn.sizeClip.gotoAndStop( 1 );
			this.makeButton( this.clipPane.btnYellow, this.onClickMode, 2, "Yellow" );

			btn = this.clipPane.btnGreen;
			btn.sizeClip.gotoAndStop( 1 );
			this.makeButton( this.clipPane.btnGreen, this.onClickMode, 2, "Green" );

			btn = this.clipPane.btnPurple;
			btn.sizeClip.gotoAndStop( 1 );
			this.makeButton( this.clipPane.btnPurple, this.onClickMode, 2, "Purple" );

			this.selectedBtn = this.clipPane.btnYellow;

		} //

		override public function show():void {

			super.show();

			this.selectColorBtn( this.selectedBtn );

		} //

		public function selectColorBtn( btn:MovieClip ):void {

			if ( !this.selectBtnTile( btn ) ) {
				// if a tile type isnt associated with the button, don't select it.
				return;
			}

			if ( this.selectedBtn != null ) {
				
				var saveX:Number = btn.x;
				var saveY:Number = btn.y;
				
				btn.x = this.selectedBtn.x;
				btn.y = this.selectedBtn.y;
				
				// shrink selected button back down and swap places with new selected button.
				this.selectedBtn.sizeClip.gotoAndStop( 1 );
				this.selectedBtn.x = saveX;
				this.selectedBtn.y = saveY;
				
			} //
			btn.sizeClip.gotoAndStop( 2 );

			this.selectedBtn = btn;
			

		} //

		/**
		 * select the tile type associated with a particular button.
		 */
		private function selectBtnTile( target:MovieClip ):Boolean {

			var typeId:uint;
			var color:int;

			if ( target == this.clipPane.btnBlue ) {
				
				typeId = blueType;
				color = blueColor;
				
			} else if ( target == this.clipPane.btnRed ) {
				
				typeId = redType;
				color = redColor;
				
			} else if ( target == this.clipPane.btnYellow ) {
				
				typeId = yellowType;
				color = yellowColor;

			} else if ( target == this.clipPane.btnGreen ) {
				
				typeId = greenType;
				color = greenColor;
				
			} else if ( target == this.clipPane.btnPurple ) {
				
				typeId = purpleType;
				color = purpleColor;
				
			} else {
				return false;
			}
			
			var selectedType:TileType = this.tileSet.getTypeByCode( typeId );
			if ( selectedType == null ) {
				return false;
			}

			this.myGroup.selectTileType( new TypeSelector( selectedType, this.tileSet ) );

			this.plugin.SetCurrentColor( color );

			return true;

		} //

		private function onClickMode( e:MouseEvent ):void {

			this.selectColorBtn( e.target as MovieClip );

		} //

	} // class
	
} // package