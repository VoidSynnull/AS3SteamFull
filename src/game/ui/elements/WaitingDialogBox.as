package game.ui.elements
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ButtonSpec;
	import game.ui.popup.Popup;
	import game.util.DisplayPositionUtils;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;

	/**
	 * Dialog box for displaying loading progress.
	 * Loading progress is displayed via loading bar.
	 * @author Bard Mckinley
	 */
	public class WaitingDialogBox  extends Popup 
	{
		public function WaitingDialogBox( container:DisplayObjectContainer = null, isWaiting:Boolean = true, titleText:String = "", statusText:String = "",  darkenBackground:Boolean = true, createClose:Boolean = false, createComplete:Boolean = true, confirmHandler:Function = null, buttonText:String = "Complete" )
		{
			super(container);

			_isWaiting = isWaiting;
			_titleText = titleText;
			_statusText = statusText;
			_buttonText = buttonText;
			super.darkenBackground = darkenBackground;
			this.createComplete = createComplete;
			this.createClose = createClose;
			
			if( confirmHandler != null )
			{
				super.popupRemoved.add( confirmHandler ); 
			}
		}
		
		override public function destroy():void
		{
			_progressEntity = null;
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "ui/elements/";
			super.screenAsset = this.ASSET;
			super.init(container);
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.preparePopup();
			
			_progressEntity = EntityUtils.createDisplayEntity( this, super.screen.progress );
			var clip:MovieClip = super.screen.progress;
			TimelineUtils.convertClip( clip, this, _progressEntity, null, _isWaiting, 8 );
			
			_statusTF = TextUtils.convertText( super.screen.status, _statusFormat, _statusText );
			super.screen.title = TextUtils.refreshText( super.screen.title, "CreativeBlock BB" );
			this.titleText = _titleText;
			
			if( this.createClose )
			{
				loadCloseButton( DisplayPositions.TOP_RIGHT, 10, 10, false, super.screen, onButtonLoaded );
			}
			
			if( this.createComplete )
			{
				loadCompleteButton();
			}
			
			DisplayPositionUtils.centerWithinScreen(super.screen, super.shellApi);
			
			this.groupReady();
		}

		public function hideDarkenBG( hide:Boolean = true ):void
		{	
			if( _darkBG )
			{
				_darkBG.visible = !hide;
			}
		}
		
		private function loadCompleteButton( displayPosition:String = "", xOffset:int = 50, yOffset:int = 50, viewportRelative:Boolean = true, btnContainer:DisplayObjectContainer = null ): void 
		{
			var btnSpec:ButtonSpec = new ButtonSpec();
			btnSpec.position = new Point( DisplayObject(super.screen).width * .5, DisplayObject(super.screen.progress).y);
			btnSpec.container = super.screen;
			btnSpec.clickHandler = super.handleCloseClicked;
			btnSpec.isStatic = false;
			_completeButton = ButtonCreator.loadButtonEntityFromSpec( BUTTON_ASSET, this, btnSpec, onButtonLoaded );
		}
		
		private function onButtonLoaded( ...args ):void
		{
			this.closeButtonText = _buttonText;
			this.isWaiting = _isWaiting;
		}
		
		public function get isWaiting():Boolean	{ return _isWaiting; }
		public function set isWaiting( value:Boolean ):void
		{
			_isWaiting = value;
			
			if( _completeButton )
			{
				EntityUtils.visible( _completeButton, !_isWaiting, true );
			}
			
			if( super.closeButton )
			{
				EntityUtils.visible( super.closeButton, !_isWaiting, true );
			}
			
			if( _progressEntity )
			{
				Timeline(_progressEntity.get(Timeline)).reset( _isWaiting );
				EntityUtils.visible( _progressEntity, _isWaiting, true );
			}
		}
		
		public function set closeButtonText(text:String):void 
		{ 
			_buttonText = text;
			if(_completeButton)
			{
				var clip:MovieClip = EntityUtils.getDisplayObject(_completeButton) as MovieClip;
				if( clip )
				{
					TextField(clip.base.tf).text = _buttonText;
				}
			}
		}
		
		private var _statusText:String;
		public function get statusText():String { return(_statusText); }
		public function set statusText(text:String):void 
		{ 
			_statusText = text;
			if( _statusTF )
			{
				_statusTF.text = _statusText;
			}
		}
		
		private var _titleText:String;
		public function set titleText(text:String):void 
		{ 
			_titleText = text;
			if(super.screen != null)
			{
				super.screen.title.htmlText = _titleText;
			}
		}

		private const ASSET:String = "waiting_dialog_box.swf";
		private const BUTTON_ASSET:String = "ui/general/rectGlossBtn.swf";

		
		private var _completeButton:Entity;
		private var _isWaiting:Boolean;
		private var _buttonText:String;
		private var _statusTF:TextField;
		private var _progressEntity:Entity;
		private const _buttonLabelFormat:TextFormat = new TextFormat("CreativeBlock BB", 18, 0xFFFFFF);
		private const _statusFormat:TextFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
		public var createClose:Boolean = false;
		public var createComplete:Boolean = false;
	}
}


