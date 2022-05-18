package game.scenes.lands.shared.classes {

	/**
	 * Handles saving and loading of LOCAL files - files on the user's computer.
	 *
	 * this is just the first version - doesn't allow for multiple save/load jobs at the same time
	 * or cancelling a save/load.
	 */

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;

	public class SaveAndLoadFile {

		/**
		 * Internally used file operation constants.
		 */
		private const OPERATION_LOAD:int = 1;
		private const OPERATION_SAVE:int = 2;
		private const OPERATION_BROWSE:int = 3;

		/**
		 * when a file fails, nothing is returned. eventually might supply an error code.
		 */
		//public var onFileFail:Function;

		/**
		 * callback when a save/load operation is complete or has an error.
		 * attempting multiple simultaneous file operations is not currently supported.
		 * 
		 * loads: opCallback( loadedFileData:*, error:String )
		 * saves: opCallback( savedFileName:String, error:String )
		 * 
		 * error in callbacks are null if no error.
		 */
		public var opCallback:Function;

		private var fileRef:FileReference;
		private var data:ByteArray;

		/**
		 * since there is no save/load batching yet, this gives the current operation type.
		 * this is used to clean up the correct events afterwards.
		 */
		private var curOperation:int;

		private var busy:Boolean;

		public function SaveAndLoadFile() {
		} //

		public function browseAndLoad( onComplete:Function ):void {
			
			//var filters:FileFilter = new FileFilter( "Poptropica Land", "*.pop" );
			var success:Boolean;
			
			this.opCallback = onComplete;

			this.fileRef = new FileReference();

			this.addBrowseEvents( this.fileRef );

			try {
				
				// TRYING TO BROWSE.
				//success = fileRef.browse( [filters] );
				success = fileRef.browse();

			} catch( e:Error ) {

				// bad exception error.
				success = false;

			} // end-if.

			if ( !success ) {
				
				fileRef.removeEventListener( Event.SELECT, this.fileLoadSelected );
				fileRef.removeEventListener( Event.CANCEL, this.fileLoadSelected );
				fileRef.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, this.securityError );

				// file dialog did not even open.
				this.dispatchError( "unknown" );

			} // end-if.
			
		} // end function browseAndLoad()

		/**
		 * User selected a file to load.
		 */
		private function fileLoadSelected( e:Event ):void {
			
			var file:FileReference = e.target as FileReference;
			
			file.removeEventListener( Event.SELECT, this.fileLoadSelected );
			file.removeEventListener( Event.CANCEL, this.fileLoadSelected );
			
			if ( e.type == Event.SELECT ) {
				
				this.addLoadEvents( file );

				file.load();

			} else {

				// load file cancelled. the event type should give some indication why.
				this.dispatchError( e.type );

			} // end-if.
			
		} //

		private function fileLoaded( e:Event ):void {
			
			var file:FileReference = e.target as FileReference;
			this.removeLoadEvents( file );
			
			if ( e.type == Event.COMPLETE ) {

				if ( file.data ) {

					if ( this.opCallback ) {
						this.opCallback( file.data, "" );
					}

				} else {

					this.dispatchError( e.type );

				} //

			} else {
				
				// SOME KIND OF FILE LOAD ERROR
				this.dispatchError( e.type );
				
			} //
			
		} //

		/**
		 * Does not currently allow user to browse location of file. This is a problem.
		 * 
		 * callback: onSave( fileName:String, error:String )
		 * - if there was an error saving, fileName is null.
		 * - if no error saving, error is null.
		 */
		public function save( data:*, defaultFileName:String, callback:Function=null ):void {

			var file:FileReference = new FileReference();
			this.addSaveEvents( file );

			if ( callback ) {
				this.opCallback = callback;
			}

			file.save( data, defaultFileName );

		} //

		private function saveComplete( e:Event ):void {

			var file:FileReference = e.target as FileReference;

			this.removeSaveEvents( file );

			if ( e.type == Event.COMPLETE ) {

				if ( this.opCallback ) {
					this.opCallback( file.name, "" );
				}

			} else {

				// unknown error.
				this.dispatchError( e.type );

			} // end-if.

		} //

		private function ioError( e:Event ):void {

			if ( this.curOperation == this.OPERATION_LOAD ) {
				this.removeLoadEvents( e.target as FileReference );
			} else if ( this.curOperation == this.OPERATION_SAVE ) {
				this.removeSaveEvents( e.target as FileReference );
			} else {
				this.removeBrowseEvents( e.target as FileReference );
			} //

			this.dispatchError( e.type );

		} //

		
		private function securityError( e:Event ):void {

			if ( this.curOperation == this.OPERATION_LOAD ) {
				this.removeLoadEvents( e.target as FileReference );
			} else if ( this.curOperation == this.OPERATION_SAVE ) {
				this.removeSaveEvents( e.target as FileReference );
			} else {
				this.removeBrowseEvents( e.target as FileReference );
			} //

			this.dispatchError( e.type );

		} //

		
		private function dispatchError( type:String ):void {
			
			if ( this.opCallback ) {
				this.opCallback( null, type );
			}
			
		} //

		private function addSaveEvents( file:FileReference ):void {

			file.addEventListener( Event.COMPLETE, this.saveComplete );
			file.addEventListener( IOErrorEvent.IO_ERROR, this.saveComplete );
			//file.addEventListener( Event.CANCEL, this.saveComplete );
			file.addEventListener( SecurityErrorEvent.SECURITY_ERROR, this.securityError );

		} //

		private function removeSaveEvents( file:FileReference ):void {
			
			file.removeEventListener( Event.COMPLETE, this.saveComplete );
			file.removeEventListener( IOErrorEvent.IO_ERROR, this.saveComplete );
			file.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, this.securityError );

		} // end function removeSaveEvents()*/

		private function addLoadEvents( file:FileReference ):void {

			file.addEventListener( Event.COMPLETE, this.fileLoaded );
			file.addEventListener( IOErrorEvent.IO_ERROR, this.fileLoaded );
			// already set from browse events.
		//	file.addEventListener( SecurityErrorEvent.SECURITY_ERROR, this.securityError );

		} //

		private function removeLoadEvents( file:FileReference ):void {

			file.removeEventListener( Event.COMPLETE, this.fileLoaded );
			file.removeEventListener( IOErrorEvent.IO_ERROR, this.fileLoaded );
			file.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, this.securityError );

		} //

		private function addBrowseEvents( file:FileReference ):void {

			file.addEventListener( Event.SELECT, this.fileLoadSelected );
			file.addEventListener( Event.CANCEL, this.fileLoadSelected );
			file.addEventListener( SecurityErrorEvent.SECURITY_ERROR, this.securityError );

		} //

		private function removeBrowseEvents( file:FileReference ):void {

			file.removeEventListener( Event.SELECT, this.fileLoadSelected );
			file.removeEventListener( Event.CANCEL, this.fileLoadSelected );
			file.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, this.securityError );

		} //

		/*private function saveCancelled( e:Event ):void {
		
		removeSaveEvents( e.target as FileReference );
		
		} //
		
		private function saveError( e:IOErrorEvent ):void {
		
		removeSaveEvents( e.target as FileReference );
		
		} //*/

	} // class

} // package