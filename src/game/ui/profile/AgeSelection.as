package game.ui.profile
{
	import engine.creators.InteractionCreator;
	import engine.group.UIView;
	import game.creators.ui.ButtonCreator;
	import game.ui.elements.BasicButton;
	
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	import game.ui.elements.Dial;
	import game.ui.elements.DialEntry;
	
	import org.osflash.signals.natives.NativeSignal;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * ...
	 * @author gabriel
	 * 
	 * UI for selecting your age
	 */

	public class AgeSelection extends UIView
	{
		
		public function AgeSelection()
		{
			super();
		}
		
		
		override public function destroy():void
		{
			super.destroy();
		}		
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "ui/profile/";
			super.init(container);
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("ageSelection.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			// get the screen movieclip from the loaded assets.
			super.screen = super.getAsset("ageSelection.swf", true) as MovieClip;
			super.groupContainer.addChild(super.screen);
			// reposition for device
			super.layout.fitUI(super.screen);
				
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
			var nextButton:BasicButton = ButtonCreator.createBasicButton(super.screen.content.nextButton, [InteractionCreator.CLICK], this);
			nextClicked = nextButton.click;
			ButtonCreator.addLabel(super.screen.content.nextButton, "NEXT>", labelFormat);
			
			var backButton:BasicButton = ButtonCreator.createBasicButton(super.screen.content.backButton, [InteractionCreator.CLICK], this);
			backClicked = backButton.click;
			ButtonCreator.addLabel(super.screen.content.backButton, "<BACK", labelFormat);
			
			super.screen.content.tfTitle.text = "How Old Are You?"
				
			initAgeDial();
			super.loaded()
		}
		
		
		private function initAgeDial(): void 
		{
			var format:TextFormat = new TextFormat("CreativeBlock BB", 34, 0x555555);
			
			format.align = TextFormatAlign.RIGHT
			format.leading = 16
			
			var minAge:int = 5
			var maxAge:int = 13
			
			_dial = new Dial()
			_dial.init(super.screen.content.mcAgeDial,format)
			
			var entry:DialEntry
			var ageStr:String
			
			for (var i:int = 0 ; i<= maxAge-minAge; i++) {
				entry = new DialEntry()
				ageStr = String (minAge + i)
				if (i == maxAge-minAge) ageStr += "+"
				entry.label =  ageStr + " YEARS OLD"
				entry.value = String (minAge + i)
				_dial.addEntry (entry)
			}
			
			_dial.setCurrentEntryByNum(5,false)
		}
		
		public var nextClicked:NativeSignal;
		public var backClicked:NativeSignal;
		
		private var _dial:Dial		
	}
}
