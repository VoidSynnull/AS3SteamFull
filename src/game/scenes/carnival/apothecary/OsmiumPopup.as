package game.scenes.carnival.apothecary
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	import org.osflash.signals.Signal;
	
	public class OsmiumPopup extends Popup
	{
		public function OsmiumPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			gotOsmium = new Signal;
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight - 150);
			
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/carnival/apothecary/";
			super.init(container);
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			//super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["osmiumPopup.swf"],false,true,loaded);
		}
		
		override public function loaded():void
		{
			//trace("asset:"+super.getAsset("posterPopup.swf", true));
			super.screen = super.getAsset("osmiumPopup.swf", true) as MovieClip;
			
			//DisplayPositionUtils.centerWithinDimensions(super.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 986, 733.45);
			//this.fitToDimensions(this.screen.background, true);
			
			// this loads the standard close button
			super.loadCloseButton();
			
			
			//super.layout.centerUI(this.screen.content);  // this is returning an error saying that content is not found on __preloader__ ??
			
			//this.centerWithinDimensions(this.screen.content);
			
			super.loaded();
			
			super.shellApi.triggerEvent("box");
			
			initEntities();
		}
		
		private function initEntities():void
		{
			_content = ButtonCreator.createButtonEntity(super.screen.content, this, onContent);
			Timeline(_content.get(Timeline)).handleLabel("getOsmium", getOsmium, true);
			Timeline(_content.get(Timeline)).handleLabel("showOsmium", showOsmium, true);
			Timeline(_content.get(Timeline)).handleLabel("showCard", showCard, true);
		}
		
		private function showOsmium():void
		{
			// play osmium sound
			super.shellApi.triggerEvent("vial");
		}
		
		private function showCard():void
		{
			// play card sound
			super.shellApi.triggerEvent("card");
		}
		
		private function getOsmium():void{
			// send signal
			
			// close popup
			gotOsmium.dispatch();
			this.close();
		}
		
		private function onContent($entity):void
		{
			Timeline(_content.get(Timeline)).play();
		}
		
		private var _content:Entity;
		public var gotOsmium:Signal;
	}
}