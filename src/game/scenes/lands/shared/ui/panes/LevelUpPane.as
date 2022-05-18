package game.scenes.lands.shared.ui.panes {

	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import engine.components.Audio;
	
	import game.scenes.lands.shared.classes.ObjectIconPair;
	import game.scenes.lands.shared.groups.LandUIGroup;


	public class LevelUpPane extends LandPane {

		/**
		 * size of the displayed unlocked tiles.
		 */
		private var iconSize:int = 64;

		private var iconPane:MovieClip;

		private var icons:Vector.<Shape>;

		/**
		 * just use this to reset landInventoryView when the pane is closed.
		 * eventually could make this work more dynamically.. but onLevelUp
		 * doesnt work for that because the poptanium resets too fast...you want to see
		 * it get to the end of the bar and then go back to 0.
		 */
		//public var onClosed:Function;

		public function LevelUpPane( clip:MovieClip, group:LandUIGroup ) {

			super( clip, group );

			this.iconPane = clip.iconPane;
			this.icons = new Vector.<Shape>();

			this.makeButton( this.clipPane.btnClose, this.onCloseClick, 2 );

			//moved to LandUIGroup
			//var hint:MovieClip = this.clipPane.helpfulHint;
			//hint.gotoAndStop( 1 );

		} //

		/**
		 * probably never happen but need to do this to remove icons
		 * just in case.
		 */
		override public function hide():void {

			super.hide();
			this.removeIcons();

		} //

		private function onCloseClick( e:MouseEvent ):void {

			super.hide();

			for( var i:int = this.icons.length-1; i >= 0; i-- ) {
				this.iconPane.removeChild( this.icons[i] );
			}

			this.icons.length = 0;

			/*if ( this.onClosed ) {
				this.onClosed();
			}*/

			// remove all unlocked tile icons.
			// can't use - this removes the drawing frame from the swf too, even though its not even an object.
			/*if ( this.iconPane.numChildren > 0 ) {
				this.iconPane.removeChildren( 0, this.iconPane.numChildren-1 );
			}*/
			
			//hide helpful hint too
			this.myGroup.hideHelpfulHint();

		} //

		private function removeIcons():void {

			for( var i:int = this.icons.length-1; i >= 0; i-- ) {
				this.iconPane.removeChild( this.icons[i] );
			}
			
			this.icons.length = 0;

		} //

		public function showLevelUp( newLevel:int, unlocked:Vector.<ObjectIconPair> ):void {

			( this.myGroup.landGroup.gameEntity.get( Audio ) as Audio ).playCurrentAction( "level_up" );
			var fld:TextField = this.clipPane.fldLevel;
			fld.text = newLevel.toString();

			var len:Number = unlocked.length;

			// nothing unlocked this level.
			if ( len <= 0 ) {
				return;
			}

			if ( this.icons.length > 0 ) {
				// only happens by cheating now, but a good check anyway.
				this.removeIcons();
			} //

			// +4 is padding. the equation can be found by 'math'.
			var rowIcons:int = Math.floor( ( this.iconPane.width + 4 ) / ( this.iconSize + 4) );

			var x:Number = 0;
			var y:Number = 0;

			var shape:Shape;
			var pair:ObjectIconPair;

			// fill the icon pane with the unlocked tile types.
			for( var i:int = len-1; i >= 0; i-- ) {

				shape = new Shape();
				shape.x = x;
				shape.y = y;

				x += this.iconSize + 4;		// iconSize + padding.
				if ( x >= this.iconPane.width ) {
					x = 0;
					y += ( this.iconSize + 4 );
				}

				pair = unlocked[i];
				pair.draw( shape, this.iconSize );

				this.iconPane.addChild( shape );
				this.icons.push( shape );

			} //

			//var hint:MovieClip = this.clipPane.helpfulHint;
			//hint.gotoAndStop( newLevel );
			this.myGroup.showHelpfulHint( newLevel );

			this.show();

		} // displayLevelUp()

		/**
		 * draw one of the unlocked tile types.
		 */
		/*private function drawTileType( s:Shape, tileType:TileType, circleIcon:Boolean=false ):void {

			var g:Graphics = s.graphics;

			if ( tileType.image != null ) {

				// If tileType.image is NOT a bitmap then this function here is inefficient
				// since we create a new bitmap every time - fix this.
				var b:BitmapData = LandUtils.prepareBitmap( tileType.image, this.unlockSize, this.unlockSize );
				
				// draw an outline.
				g.lineStyle( 2, 0, 0.5 );
				g.beginBitmapFill( b );
				
			} else {
				
				g.lineStyle( 2, 0, 0.5 );
				g.beginFill( tileType.color );
				
			} //
			
			// need to be careful on the range coordinates here because the lineStyle extends the draw past the bitmap boundaries.
			if ( circleIcon ) {
				g.drawCircle( this.unlockSize/2, this.unlockSize/2, this.unlockSize/2-2 );
			} else {
				g.drawRect( 1, 1, this.unlockSize-2, this.unlockSize-2 );
			} //

			// draw the background onto the clip bitmap.
			g.endFill();
			
		} //*/

	} // class

} // package