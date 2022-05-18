package game.ui.elements
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	
	import game.components.timeline.Timeline;
	import game.components.ui.ProgressBar;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ProgressBarCreator;
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
	public class ProgressBox extends Popup 
	{
		public function ProgressBox( container:DisplayObjectContainer = null )
		{
			super(container);
			super.id = GROUP_ID;
		}
		
		/**
		 * Setup initial state of ProgressBox, these settings will be applied on loaded.
		 * @param initialState - the initial state, defaults to STATE_NONE
		 * @param titleText - title of dialog box
		 * @param statusText - status message of dialog box
		 * @param darkenBackground - whether a darkened background will be created behind popup
		 * @param createCloseBtn - whether a close button should be created, if not true prior to loading a close button will not be available
		 * @param buttonText - text within of button
		 */
		public function setup( initialState:String = STATE_NONE, titleText:String = "", statusText:String = "", darkenBackground:Boolean = true, createCloseBtn:Boolean = false, buttonText:String = "Complete" ):void
		{
			_state = initialState;
			_title = titleText;
			_message = statusText;
			_buttonText = buttonText;
			this.createClose = createCloseBtn;
			super.darkenBackground = darkenBackground;
		}
		
		override public function destroy():void
		{
			_waitTickerEntity = null;
			_progressBarEntity = null;
			_completeButton = null;
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
			if( !this._isRemoved )	// NOTE :: make sure popup hasn't been removed before loaded has been called
			{
				super.preparePopup();
				DisplayObject(super.screen).visible = false;
				
				// setup text
				_messageTF = TextUtils.convertText( super.screen.status, _statusFormat, _message );
				super.screen.title = TextUtils.refreshText( super.screen.title, "CreativeBlock BB" );
				this.title = _title;
				
				// setup waiting ticker
				var clip:MovieClip = super.screen.waiting_ticker;
				clip.visible = false;
				_waitTickerEntity = EntityUtils.createSpatialEntity( this, clip );
				TimelineUtils.convertClip( clip, this, _waitTickerEntity, null, false, 8 );
				
				// setup complete (usage can vary, could be used for cancel for example)
				clip = super.screen.complete_btn;
				clip.visible = false;
				_buttonTF = TextUtils.convertText( clip.base.tf, _buttonLabelFormat, _buttonText );
				_completeButton = ButtonCreator.createButtonEntity( clip, this, super.handleCloseClicked);
				
				//setup loader
				clip = super.screen.load_bar;
				clip.visible = false;
				var progressBarCreator:ProgressBarCreator = new ProgressBarCreator();
				_progressBarEntity = progressBarCreator.createFromDisplay( clip, this);
				//ProgressBar(_progressBarEntity.get(ProgressBar)).scaleRate = 1;
				_progressBarEntity.add(new Id("progressBarBig"));
	
				// center popup
				DisplayPositionUtils.centerWithinScreen(super.screen, super.shellApi);
				
				// setup close button (if specified)
				if( this.createClose )
				{
					loadCloseButton( DisplayPositions.TOP_RIGHT, 10, 10, false, super.screen, completeSetup);
				}
				else
				{
					completeSetup();
				}
			}
		}
		
		private function completeSetup( ...args ):void
		{
			setState( _state );
			DisplayObject(super.screen).visible = true;
			this.groupReady();
		}
		
		public function hideDarkenBG( hide:Boolean = true ):void
		{	
			if( _darkBG )
			{
				_darkBG.visible = !hide;
			}
		}
		
		/**
		 * Set the state of the ProgressBox, essentially hides and reveals appropriate elements.
		 * ProgressBox can be setup manually as well, with setState meant to cover general usage. 
		 * @param state - String determining how progess bar displays, refer to ProgressBar.STATE_ for accepted constants
		 * @param makePermanent - flag determining if the given state should be made the permanent state
		 */
		public function setState( state:String, makePermanent:Boolean = false ): void 
		{
			if( makePermanent ) { _state = state; } 

			switch(state)
			{
				case STATE_NONE:
					//hide all, except text & close
					showCloseButton( true );
					showProgressBar( false );
					showCompleteButton( false );
					showWaitTicker(false);
					break;
				
				case STATE_WAITING:
					showCloseButton( false );
					showProgressBar( false );
					showCompleteButton( false );
					showWaitTicker(true);
					break;
				
				case STATE_LOADING:
					showCloseButton( false );
					showWaitTicker(false);
					showProgressBar( true );
					//_buttonTF.text = "CANCEL";
					this.buttonText = "CANCEL";
					showCompleteButton( true );
					break;
				
				case STATE_COMPLETE:
					showProgressBar( false );
					showWaitTicker(false);
					showCloseButton( true );
					this.buttonText = _buttonText;
					showCompleteButton( true );					
					break;
				
				default:
					break;
				
			}
		}
		
		public function showCloseButton( show:Boolean = true):void
		{
			if( this.closeButton )
			{ 
				EntityUtils.visible( super.closeButton, show, true );
			}	
		}
		
		//////////////////////////////// COMPLETE BUTTON ////////////////////////////////
		
		public function showCompleteButton( show:Boolean = true):void
		{
			if( _completeButton )
			{
				EntityUtils.visible(_completeButton, show, true );
			}
		}
		
		public function disableButton(disable:Boolean = true):void
		{
			_disableButton = disable;
			
			if( _completeButton )
			{
				var interaction:Interaction = _completeButton.get(Interaction);
				interaction.lock = disable;
				
				var display:Display = _completeButton.get(Display);
				
				if(disable)
				{
					display.alpha = .4;
				}
				else
				{
					display.alpha = 1;
				}
			}
		}
		
		public function set buttonText(text:String):void 
		{ 
			_buttonText = text;
			if(_completeButton)
			{
				_buttonTF.text = _buttonText;
			}
		}
		
		//////////////////////////////// WAITING TICKER ////////////////////////////////
		
		public function showWaitTicker( show:Boolean = true):void
		{
			if( _waitTickerEntity )
			{
				EntityUtils.visible(_waitTickerEntity, show, true );
				Timeline(_waitTickerEntity.get(Timeline)).reset( show );
			}
		}
		
		//////////////////////////////// LOADING BAR ////////////////////////////////
		
		public function showProgressBar( show:Boolean = true):void
		{
			if( _progressBarEntity )
			{
				EntityUtils.visible(_progressBarEntity, show, true );
				DisplayObject(super.screen.load_bar_overlay).visible = show;
			}else{
				trace("ProgressBox :: showProgressBar : no _progressBarEntity");
			}
			
		}
		
		public function resetProgressBar() : void
		{
			if( _progressBarEntity )
			{
				var progressBar:ProgressBar = _progressBarEntity.get(ProgressBar);
				progressBar.reset = true;
				
			}
		}
		
		/**
		 * Update the progress bar. 
		 * @param percent - a percentage in decimal form, 0 to 1
		 */
		public function set progressPercent(percent:Number):void
		{
			if( _progressBarEntity )
			{
				var progressBar:ProgressBar = _progressBarEntity.get(ProgressBar);
				progressBar.percent = percent;
			}
		}

		public function get progressPercent():Number
		{
			if( _progressBarEntity )
			{
				var progressBar:ProgressBar = _progressBarEntity.get(ProgressBar);
				return progressBar.percent;
			}
			return NaN
		}
		
		//////////////////////////////// TEXT DISPLAY ////////////////////////////////
		
		private var _message:String;
		public function get message():String { return(_message); }
		/**
		 * Status message, dispalyed below title.
		 * @param text
		 */
		public function set message(text:String):void 
		{ 
			_message = text;
			if( _messageTF )
			{
				_messageTF.text = _message;
			}
		}
		
		private var _title:String = "";
		/**
		 * Title/Header text display at top of box.
		 * @param text
		 */
		public function set title(text:String):void 
		{ 
			_title = text;
			if(super.screen != null)
			{
				super.screen.title.htmlText = _title;
			}
		}
		
		public static const GROUP_ID:String = "progressPopup";
		
		private const ASSET:String = "progress_dialog_box.swf";
		
		public static const STATE_NONE:String = "none";
		public static const STATE_WAITING:String = "waiting";
		public static const STATE_COMPLETE:String = "complete";
		public static const STATE_LOADING:String = "loading";
		
		public var createClose:Boolean = false;
		
		private var _state:String = STATE_NONE
		private var _completeButton:Entity;
		private var _buttonText:String = "Complete";
		private var _messageTF:TextField;
		private var _buttonTF:TextField;
		private var _waitTickerEntity:Entity;
		private var _progressBarEntity:Entity;
		private var _disableButton:Boolean = false;
		
		private const _buttonLabelFormat:TextFormat = new TextFormat("CreativeBlock BB", 26, 0xFFFFFF);
		private const _statusFormat:TextFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
		
	}
}


