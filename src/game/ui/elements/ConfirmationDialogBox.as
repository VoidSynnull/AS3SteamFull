
package game.ui.elements
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.ui.popup.Popup;
	import game.util.DataUtils;
	import game.util.DisplayPositionUtils;
	import game.util.ScreenEffects;
	import game.util.TextUtils;
	
	import org.flintparticles.common.displayObjects.Rect;
	import org.osflash.signals.Signal;
	
	/**
	 * A standard dialog popup, with options for "OK" and "Cancel" buttons.
	 * @author umckiba
	 * 
	 */
	public class ConfirmationDialogBox extends Popup {

		/**
		 * Create a standard dialog box with confirmation buttons.
		 * Additional handlers can be passed that will be called when the confirmation or cancel/close buttons are pressed.
		 * @param numBtns - Number of buttons created, max is 2 "OK" &amp; "Cancel".  If only 1 button is specified only an "OK" button is created.
		 * @param dialogText - Text that will be displayed in the popup.
		 * @param confirmHandler - additional handler called when "OK" button is clicked.
		 * @param cancelHandler - additional handler called when "Cancel" is clicked, or when popup is closed if there only one button
		 * @param createClose - flag determining if an close button will be created for popup, if so, it is loaded and placed in top-left corner of popup.
		 * @param modal
		 */
		public static const GROUP_ID:String = "ConfirmationPopup";
		public function ConfirmationDialogBox( numBtns:uint = 2, dialogText:String = "", confirmHandler:Function = null, cancelHandler:Function = null, createClose:Boolean = false, modal:Boolean = false ) 
		{
			super();
			super.id = GROUP_ID;
			
			this.dialogText = dialogText;
			_confirmHandler = confirmHandler;
			_cancelHandler = cancelHandler;
			_createCloseButton = createClose;
			
			_numVisibleBtns = numBtns;
			if( _numVisibleBtns > 0 )
			{
				confirmClicked = new Signal();
			}
			if ( _numVisibleBtns > 1 )
			{
				cancelClicked = new Signal();
			}

			this.modal = modal;
			
			configData("dialogBox.swf","ui/elements/");// default
		}
		
		override public function destroy():void
		{
			// remove all references to this screen's signals
			if (confirmClicked) confirmClicked.removeAll();
			if (cancelClicked) cancelClicked.removeAll();
			
			super.destroy();
		}	
		
		public function configData(asset:String = null, prefix:String = null, confirmText:String = null, cancelText:String = null):void
		{
			// set the prefix for the assets path.
			if(prefix != null)
				super.groupPrefix = prefix;
			if(asset != null)
				super.screenAsset = asset;
			if(confirmText != null)
				this.confirmText = confirmText;
			if(cancelText != null)
				this.cancelText = cancelText;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{	
			if( !this._isRemoved )	// NOTE :: make sure popup hasn't been removed before loaded has been called
			{
				if(this.modal)
				{
					var screenUtils:ScreenEffects = new ScreenEffects();
					var blocker:DisplayObject = super.groupContainer.addChild(screenUtils.createBox(super.shellApi.viewportWidth, super.shellApi.viewportHeight, 0x000000));
					blocker.alpha = .4;
				}
				
				super.preparePopup();
				
				if( _createCloseButton )
				{
					super.loadCloseButton( "", 10, 10, false );    
				}
	
				var tf:TextField = TextUtils.refreshText(super.screen["tf"],"CreativeBlock BB");
				if(DataUtils.validString(dialogText))
					tf.htmlText = dialogText;
				
				var rect:Rectangle = tf.getBounds(tf.parent);
				
				tf.y = rect.top + (rect.height - tf.textHeight)/2; 
							
				DisplayPositionUtils.centerWithinScreen(super.screen, super.shellApi);
					
				// to do: build the buttons from the data
				var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
				
				var confirmBtn:Entity
				if ( _numVisibleBtns == 0 ) 
				{
					if(MovieClip(super.screen).hasOwnProperty("cancelButton"))
					{
						super.screen.cancelButton.visible = false;
					}
					if(MovieClip(super.screen).hasOwnProperty("okButton"))
					{
						super.screen.okButton.visible = false;
					}
				}
				else if ( _numVisibleBtns == 1 ) 
				{
					// hide cancel button
					if(MovieClip(super.screen).hasOwnProperty("cancelButton"))
					{
						super.screen.cancelButton.visible = false;
					}
					super.screen.okButton.x = (super.screen.width - super.screen.okButton.width) / 2;
					
					// create OK button
					confirmBtn = ButtonCreator.createButtonEntity(super.screen.okButton, this, this.onConfirmClick );
					ButtonCreator.addLabel(super.screen.okButton, confirmText, labelFormat);
				}
				else if ( _numVisibleBtns == 2 ) 
				{
					// create OK button
					confirmBtn = ButtonCreator.createButtonEntity(super.screen.okButton, this, this.onConfirmClick );
					ButtonCreator.addLabel(super.screen.okButton, confirmText, labelFormat);
					
					// create Cancel button
					var cancelmBtn:Entity = ButtonCreator.createButtonEntity(super.screen.cancelButton, this, this.onCancelClick );
					ButtonCreator.addLabel(super.screen.cancelButton, cancelText, labelFormat);
				}
				
				// dispatch is ready.
				this.groupReady();
			}
		}
		
		private function onConfirmClick( btnEntity:Entity = null ):void
		{
			super.playClick();
			
			if( _confirmHandler != null )
			{
				_confirmHandler();
			}
			confirmClicked.dispatch();
			super.close();
		}
		
		private function onCancelClick( btnEntity:Entity = null ):void
		{
			super.playCancel();
			
			if( _cancelHandler != null )
			{
				_cancelHandler();
			}
			cancelClicked.dispatch();
			super.close();
		}
		
		/**
		 * Signal dispatched when "OK" button is selected. 
		 */
		public var confirmClicked:Signal;
		/**
		 * Signal dispatched when "Cancel" button is selected. 
		 */
		public var cancelClicked:Signal;
		/**
		 * Text that will be displayed withing popup. 
		 */
		public var dialogText:String;
		
		public var confirmText:String = "OK";
		public var cancelText:String = "Cancel";
		
		private var _numVisibleBtns:uint;
		private var _createCloseButton:Boolean
		
		private var _confirmHandler:Function;
		/**
		 * Optional Function called when "OK" button is selected. 
		 */
		public function set confirmHandler( func:Function ):void	{ _confirmHandler = func; }
		private var _cancelHandler:Function;
		/**
		 * Optional Function called when "Cancel" button is selected, of when close is clicked if there is no cancel button 
		 */
		public function set cancelHandler( func:Function ):void		{ _cancelHandler = func; }
		public var modal:Boolean = false;

	}
}
