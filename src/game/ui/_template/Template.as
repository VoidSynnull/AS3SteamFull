package game.ui._template
{
	import engine.creators.InteractionCreator;
	import engine.group.UIView;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import game.ui.elements.Button;
	
	import org.osflash.signals.natives.NativeSignal;
	
	public class Template extends UIView
	{
		public function Template()
		{
			super();
		}
		
		override public function destroy():void
		{
			// remove all references to this screen's signals in here.
			okClicked.removeAll();		
			// destroy will automatically cleanup any buttons on this screen and call their 'destroy()' method.
			super.destroy();
		}		
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "ui/template/";
			// call 'init()' to create the group container
			super.init(container);
			// load this screen's assets.
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.shellApi.fileLoadComplete.addOnce(loaded);
			// this array should have all assets needed that live in ui/template
			super.loadFiles(new Array("screen.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			// get the asset movieclip(s) from the loaded assets and remove from cache.
			super.screen = super.getAsset("screen.swf", true) as MovieClip;
			
			// reposition for device
			super.ui.fitUI(super.screen);
			
			// add the movieclip to this groups container so it will be rendered.
			super.groupContainer.addChild(super.screen);
			
			// create a common TextFormat to use for our buttons.
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 14, 0xD5E1FF);
			
			// Associate the button movieclips in screen.swf with 'Button' ui elements to give them interaction.
			var okButton:Button = super.ui.buttonCreator.create(super.screen.content.okButton, [InteractionCreator.CLICK], this);
			okClicked = okButton.click;
			super.ui.buttonCreator.addLabel(super.screen.content.okButton, "Ok!", labelFormat);
			
			// Call the parent classes loaded() method so it knows this Group is ready.
			super.loaded();
		}
		
		// This signal will communicate with the scene or other ui that mediates this uiview (create/destroy/intercept ui signals that affect game.)
		public var okClicked:NativeSignal;
	}
}
