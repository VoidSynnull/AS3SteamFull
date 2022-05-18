package game.ui.profile
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextFormat;
	
	import engine.creators.InteractionCreator;
	import engine.group.UIView;
	
	import game.creators.ui.ButtonCreator;
	import game.ui.elements.BasicButton;
	
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	/**
	 * ...
	 * @author gabriel
	 * 
	 * UI for selecting your age.
	 */

	public class GenderSelection extends UIView
	{
		
		public function GenderSelection()
		{
			super();
		}
		
		override public function destroy():void
		{		
			selectionMade.removeAll();
			super.destroy();
		}		
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "ui/profile/";
			super.init(container);
			selectionMade = new Signal()
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("genderSelection.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			// get the screen movieclip from the loaded assets.
			super.screen = super.getAsset("genderSelection.swf", true) as MovieClip;
			super.groupContainer.addChild(super.screen);
			
			// reposition for device
			super.layout.fitUI(super.screen);
			super.screen.content.tfTitle.text = "Choose your gender"

			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
			
			var boyButton:BasicButton = ButtonCreator.createBasicButton(super.screen.content.boyButton, [InteractionCreator.CLICK], this);
			boyClicked = boyButton.click;
			boyClicked.add (onBoyClicked)
			ButtonCreator.addLabel(super.screen.content.boyButton, "BOY", labelFormat);
			
			var girlButton:BasicButton = ButtonCreator.createBasicButton(super.screen.content.girlButton, [InteractionCreator.CLICK], this);
			girlClicked = girlButton.click;
			girlClicked.add (onGirlClicked)
			ButtonCreator.addLabel(super.screen.content.girlButton, "GIRL", labelFormat);
			
			super.loaded()
		}
		
		private function onBoyClicked (e:Event): void {
			selectionMade.dispatch(new Event("boy"))
		}
		
		private function onGirlClicked (e:Event): void {
			selectionMade.dispatch(new Event("girl"))
		}
				
		protected var boyClicked:NativeSignal;
		protected var girlClicked:NativeSignal;
		public var selectionMade:Signal
	}
}
