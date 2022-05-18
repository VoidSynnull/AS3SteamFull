package game.scenes.lands.shared.ui.panes {

	/**
	 * TO DO: turn this into a LandPane subclass for eventual better integration with blah blah blah.
 	*/

	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;
	
	import engine.util.Command;
	
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.SaveAndLoadFile;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.systems.TemplateSystem;
	import game.scenes.lands.shared.tileLib.classes.LandEncoder;
	import game.scenes.lands.shared.tileLib.templates.TileTemplate;
	import game.systems.SystemPriorities;

	public class TemplatePane extends LandPane {

		private var templateSystem:TemplateSystem;

		private var saveY:int;

		/**
		 * used to store/set last save name for when save dialog is called.
		 */
		private var lastSaveFile:String = "landTemplate.xml";

		public function TemplatePane( clip:MovieClip, group:LandUIGroup ) {

			super( clip, group );

			this.initButtons();

		} // TemplatePane

		/**
		 * Note that save/load operations can't be done within the regular poptropica system.
		 * The save/load dialog must trigger as the direct result of a mouse click, and the
		 * poptropica input system waits a frame and triggers during onEnterFrame()
		 */
		private function initButtons():void {
			
			// SAVE BUTTON
			super.makeButton( this.clipPane.btnSave, this.onSaveClick, "Save Template" );

			// LOAD BUTTON
			
			super.makeButton( this.clipPane.btnLoad, this.onLoadClick, "Load Template" );

			//** TEMPLATE CLOSE BUTTON.
			super.makeButton( this.clipPane.btnClose, this.doClose, "Close", 2 );

		} //

		private function doClose( e:MouseEvent ):void {

			/**
			 * this will effectively close the pane.
			 */
			this.myGroup.getEditContext().curEditMode = LandEditMode.PLAY;

			this.hide();

		} //

		/**
		 * according to how jordan wants things now, this will store whatever selection
		 * is currently hilited through the TemplateSystem. Needs a save popup dialog.
		 */
		private function onSaveClick( e:MouseEvent ):void {

			/**
			 * try to get the tile template for the currently selected region.
			 */
			var template:TileTemplate = this.templateSystem.tryCreateTemplate();

			if ( template == null ) {
				trace( "template too small or something." );
				return;
			} //

			var encoder:LandEncoder = new LandEncoder();
			encoder.encodeTemplate( template );

			var save:SaveAndLoadFile = new SaveAndLoadFile();
			save.save( encoder.encodeTemplate( template ), this.lastSaveFile, this.templateSaved );


		} //

		private function templateSaved( fileName:String, error:String ):void {

			if ( fileName != null ) {
				this.lastSaveFile = fileName;
			}

		} //

		private function templateSaveFailed():void {

			this.myGroup.showDialog( "Could not save template. You have no manner of luck at all." );

		} //

		private function onLoadClick( e:MouseEvent ):void {

			var load:SaveAndLoadFile = new SaveAndLoadFile();
			load.browseAndLoad( this.templateDataLoaded );

		} //

		private function templateDataLoaded( bytes:ByteArray, error:String ):void {

			if ( error || bytes == null ) {
				this.loadTemplateFailed( error );
				return;
			}

			var template:TileTemplate = new TileTemplate();
			var encoder:LandEncoder = new LandEncoder();

			if ( encoder.decodeTemplate( template,  new XML( bytes.readUTFBytes(bytes.length) ) ) ) {

				// Really messy check to make sure the decals used in the template have their images loaded.
				if ( this.myGroup.assetLoader.loadMapDecals( template.getGrids(),
					Command.create( this.mapDecalsLoaded, template ) ) == true ) {
					// decal data is preloading.
					return;
				}

				// template was successfully decoded. now allow the user to place it on the map.
				// also actually need to draw it to a bitmap, etc. eventually.
				this.templateSystem.beginTemplateDrop( template );

			} else {

				this.myGroup.showDialog( "Could not load template. Maybe Binary Bard stole it?" );

			} // end-if.

		} //

		private function mapDecalsLoaded( template:TileTemplate ):void {

			//trace( "LOADED DECALS" );
			this.templateSystem.beginTemplateDrop( template );

		} //

		private function loadTemplateFailed( eventType:String ):void {

			trace( "TemplatePane: Could not load template" );

		} //

		public function isVisible():Boolean {
			return this.myPane.visible;
		}

		override public function show():void {

			if ( this.templateSystem == null ) {
				this.templateSystem = new TemplateSystem( this.myGroup.curScene, this.myGroup.landGroup.gameData );
			} //

			this.myGroup.addSystem( this.templateSystem, SystemPriorities.update );
			this.templateSystem.beginTemplateCreate();

			super.show();

		} //
		
		override public function hide():void {

			super.hide();

			this.myGroup.removeSystem( this.templateSystem, false );

		} //

	} // class
	
} // package