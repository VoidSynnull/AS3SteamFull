package game.ui.elements
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.group.DisplayGroup;
	
	import game.components.ui.ProgressBar;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ProgressBarCreator;
	import game.util.DisplayPositionUtils;
	import game.util.ScreenEffects;
	
	public class ProgressDialogBox extends DisplayGroup
	{
		public function ProgressDialogBox(container:DisplayObjectContainer=null)
		{
			super(container);
		}
			
		override public function destroy():void
		{
			_screen = null;
			_cancelButton = null;
			_buttonLabelFormat = null;
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "ui/elements/";
			super.init(container);
		}
		
		public function setup(cancelHandler:Function, titleText:String, statusText:String, buttonText:String):void
		{
			_titleText = titleText;
			_statusText = statusText;
			_buttonText = buttonText;
			super.loadFile("progressDialogBox.swf", boxLoaded, cancelHandler);
			
			//_textFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
			_buttonLabelFormat = new TextFormat("CreativeBlock BB", 18, 0xFFFFFF);
		}
		
	    private function boxLoaded(clip:DisplayObjectContainer, cancelHandler:Function):void
		{
			if(this.modal)
			{
				var screenUtils:ScreenEffects = new ScreenEffects();
				var blocker:DisplayObject = super.groupContainer.addChild(screenUtils.createBox(super.shellApi.viewportWidth, super.shellApi.viewportHeight, 0x000000));
				blocker.alpha = .4;
			}
			
			_screen = clip as MovieClip;
			super.groupContainer.addChild(_screen);
			
			DisplayPositionUtils.centerWithinScreen(_screen, super.shellApi);
			
			_screen.title.htmlText = _titleText;
			_screen.status.htmlText = _statusText;
			
			_cancelButton = ButtonCreator.createButtonEntity(_screen.cancelButton, this, cancelHandler);
			ButtonCreator.addLabel(_screen.cancelButton, _buttonText, _buttonLabelFormat, ButtonCreator.ORIENT_CENTERED);
			
			if(_disableCancel)
			{
				disableCancel(true);
			}
			
			var progressBarCreator:ProgressBarCreator = new ProgressBarCreator();
			var bar:Entity = progressBarCreator.createFromDisplay(_screen, this);
			ProgressBar(bar.get(ProgressBar)).scaleRate = 1;
			bar.add(new Id("progressBarBig"));
		}
		
		public function disableCancel(disable:Boolean = true):void
		{
			_disableCancel = disable;
			
			if(_cancelButton != null)
			{
				//super.removeEntity(_cancelButton);
				//_cancelButton = null;
				var interaction:Interaction = _cancelButton.get(Interaction);
				interaction.lock = disable;
				
				var display:Display = _cancelButton.get(Display);
				
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
		
		public function set progress(progress:Number):void
		{
			var bar:Entity = super.getEntityById("progressBarBig");
			
			if(bar != null)
			{
				var progressBar:ProgressBar = bar.get(ProgressBar);
				progressBar.percent = progress;
			}
		}
		
		public function get statusText():String { return(_statusText); }
		
		public function set statusText(text:String):void 
		{ 
			_statusText = text;
			
			if(_screen != null)
			{
				_screen.status.htmlText = _statusText;
			}
		}
		
		public function set titleText(text:String):void 
		{ 
			_titleText = text;
			
			if(_screen != null)
			{
				_screen.title.htmlText = _titleText;
			}
		}
		
		public function set buttonText(text:String):void { _buttonText = text; }
		
		/*
		public function addButton(label:String, handler:Function):void
		{
			super.loadFile("blueRectBtn.swf", setupButton, label, handler);
		}
		
		private function setupButton(display:DisplayObjectContainer, label:String, handler:Function):void
		{
			_screen.addChild(display);
			ButtonCreator.createButtonEntity(display, this, handler);
			ButtonCreator.addLabel(display,label, _buttonLabelFormat, ButtonCreator.ORIENT_CENTERED);
		}
		*/
		private var _screen:MovieClip;
		private var _titleText:String;
		private var _statusText:String;
		private var _buttonText:String;
		private var _cancelButton:Entity;
		//private var _textFormat:TextFormat;
		private var _buttonLabelFormat:TextFormat;
		public var modal:Boolean = true;
		private var _disableCancel:Boolean = false;
	}
}