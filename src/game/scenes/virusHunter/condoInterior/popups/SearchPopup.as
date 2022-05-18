package game.scenes.virusHunter.condoInterior.popups {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import game.data.ui.TransitionData;
	import game.scenes.virusHunter.condoInterior.classes.PopupDragItem;
	import game.scenes.virusHunter.condoInterior.systems.DraggableSystem;
	import game.scenes.virusHunter.condoInterior.systems.ScaleBounceSystem;
	import game.systems.SystemPriorities;
	import game.ui.elements.StandardButton;
	import game.ui.popup.Popup;

	public class SearchPopup extends Popup {

		public var popupFileName:String;

		public var useCloseButton:Boolean = true;

		// NOTE ON DRAG CLIP INTIIALIZATION:  draggable clips should be in a popup subclip called: dragClipsContainer
		// If useSpecificDrags = false (default) then all movieclips within the dragClips clip will be converted into draggable clips.
		// If useSpecificDrags = true, then clips with the indicated dragClipPrefix will be converted (piece0, piece1, etc) followed
		// by any clips listed in the draggableNames vector (for instance "letterClip", "secretKey", "pieceOfPopcorn" )
		public var useSpecificDrags:Boolean;

		// Movieclips on the popup with this prefix, followed by an ordered number -> 0,1,2,... will be turned into draggable clips.
		public var dragClipPrefix:String = "piece";
		// names of clips that should be initialized to draggable clips.
		public var draggableNames:Vector.<String>;

		private var dragsByName:Dictionary;							// draggable objects by name.

		protected var btnClose:StandardButton;

		// Boundary applied to all draggable items.
		// If your search popup includes a "bounds" movieclip, the outline of that movieclip will be used to set the _dragBounds.
		// The coordinate system of that clip should have (0,0) at the (left,top) of the clip.
		private var _dragBounds:Rectangle;
		private var boundsRect:Rectangle;

		// Container that holds all the draggable clips.
		public var dragClipsContainer:MovieClip;

		// This function will not currently trigger automatically, because each popup might have different conditions
		// for completing a search. Might set some basic defaults later - i.e. after finding a certain number of 'prizes'
		public var onSearchComplete:Function;

		public function SearchPopup( fileName:String, groupPrefix:String, container:DisplayObjectContainer=null,
			useSpecificDrags:Boolean=false, dragNames:Vector.<String>=null ) {

			super( container );

			this.popupFileName = fileName;
			super.groupPrefix = groupPrefix;

			this.useSpecificDrags = useSpecificDrags;

			if ( dragNames == null ) {
				draggableNames = new Vector.<String>();
			} else {
				draggableNames = dragNames;
			}

		} //

		// pre load setup
		// prefix is URL prefix.
		override public function init( container:DisplayObjectContainer=null ):void {

			// setup the signal that a parent group (the scene) will use to receive messages from this popup.

			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = 0.3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();

			super.darkenBackground = true;

			super.init( container );

			load();

		} //

		// initiate asset load of scene specific assets.
		override public function load():void {

			super.shellApi.fileLoadComplete.addOnce( loaded );
			super.loadFiles( new Array( popupFileName ) );

		} //

		// all assets ready
		override public function loaded():void {

			this.addSystem( new DraggableSystem(), SystemPriorities.update );
			this.addSystem( new ScaleBounceSystem(), SystemPriorities.update );

			super.screen = ( super.getAsset( this.popupFileName, true ) ) as MovieClip;

			initBackground();

			// center the boundsRects in the viewPort.
			screen.x = -boundsRect.x + 0.5*( this.shellApi.viewportWidth - boundsRect.width );
			screen.y = -boundsRect.y + 0.5*( this.shellApi.viewportHeight - boundsRect.height );

			if ( this.useCloseButton ) {
				this.loadCloseButton();
			}

			dragClipsContainer = screen.content["dragClipsContainer"];

			// Attempt to set drag boundary. dragClipsContainer must be defined for this, to get the bounds offset.
			var dragBounds:MovieClip = screen.content["dragBounds"];
			if ( dragBounds ) {
				setDragBounds( dragBounds );
			}

			// any entities or systems created within this group will automatically be removed on close.
			dragsByName = new Dictionary();

			if ( useSpecificDrags ) {

				initSpecificClips();

			} else {

				initAllClips();

			} // End-if.

			super.loaded();

		} //

		public function disableCloseButton():void
		{
			if(btnClose)
			{
				btnClose.displayObject.mouseEnabled = false;
				btnClose.click.removeAll();
				btnClose.up.removeAll();
			}
		} //

		protected function disableDrags():void {

			for each ( var dragItem:PopupDragItem in dragsByName ) {

				dragItem.disable();

			} //

		} //

		protected function enableDrags():void {

			for each ( var dragItem:PopupDragItem in dragsByName ) {

				dragItem.enable();

			} //

		} //

		override public function destroy():void {
			
			// do any cleanup required in this Group before calling the super classes destroy method

			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
			
		} //

		// bitmap the background.
		protected function initBackground():void {

			var bg:MovieClip = screen["background"];

			if ( bg == null ) {
				return;
			}

			var bounds:MovieClip = screen.content["popupBounds"];
			if ( bounds == null ) {
				boundsRect = new Rectangle( 0, 0, bg.width, bg.height );
			} else {
				super.screen.content.removeChild( bounds );
				boundsRect = new Rectangle( bounds.x, bounds.y, bounds.width, bounds.height );
			} //

			var bm:BitmapData = new BitmapData( boundsRect.width, boundsRect.height, false, 0 );
			bm.draw( bg/*, new Matrix( 1, 0, 0, 1, -boundsRect.x, -boundsRect.y )*/ );

			var bitmap:Bitmap = new Bitmap( bm );
			bitmap.x = boundsRect.x;
			bitmap.y = boundsRect.y;
			bitmap.name = bg.name;

			screen.addChildAt( bitmap, 0 );

			// get rid of the background.
			screen.removeChild( bg );
			
			screen[bg.name] = bitmap;

		} //

		protected function initAllClips():void {

			var clip:DisplayObjectContainer;
			var dragItem:PopupDragItem;

			for( var s:String in dragClipsContainer ) {

				clip = dragClipsContainer[s];
				if ( !(clip is DisplayObjectContainer) ) {
					continue;
				} //

				dragItem = new PopupDragItem( this, clip );
				dragItem.draggable.bounds = _dragBounds;

				dragsByName[ clip.name ] = dragItem;

			} // end for-loop.

		} //

		/*public function getDraggableByIndex( i:int ):PopupDragItem {
			return draggables[i];
		} //*/
		
		public function getDraggableByName( name:String ):PopupDragItem {
			
			return dragsByName[ name ];
			
		} //

		protected function initSpecificClips():void {

			var i:int = 0;
			var clip:MovieClip = dragClipsContainer[ "piece"+i ];

			var dragItem:PopupDragItem;

			while ( clip != null ) {

				dragItem = new PopupDragItem( this, clip );
				dragItem.draggable.bounds = _dragBounds;

				dragsByName[ clip.name ] = dragItem;

				i++;
				clip = dragClipsContainer[ dragClipPrefix+i ];

			} //

			for( i = draggableNames.length-1; i >= 0; i-- ) {

				clip = dragClipsContainer[ draggableNames[i] ];

				dragItem = new PopupDragItem( this, clip );
				dragItem.draggable.bounds = _dragBounds;

				dragsByName[ clip.name ] = dragItem;

			} //

		} // initSpecificClips()

		// Sets the drag boundary to match the given movieclip. At the moment, this function does not retroactively apply
		// to drag items which were already created.
		public function setDragBounds( clip:MovieClip ):void {

			clip.parent.removeChild( clip );

			dragBounds = new Rectangle( clip.x - dragClipsContainer.x, clip.y - dragClipsContainer.y, clip.width, clip.height );

		} //

		public function get dragBounds():Rectangle {
			return _dragBounds;
		}

		public function set dragBounds( r:Rectangle ):void {
			_dragBounds = r;
		} //

		/*private function createDragEntity( clip:MovieClip ):void {

			var e:Entity = new Entity();
				e.add( new Display( clip ) )
				e.add( new Spatial( clip.x, clip.y ) )
				e.add( new Interaction() );

			this.addEntity( e );			// need to do this first to get the interaction signals.

			var draggable:Draggable = new Draggable();
			e.add( draggable );

		} //*/

	} // class

} // package