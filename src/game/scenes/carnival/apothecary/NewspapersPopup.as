package game.scenes.carnival.apothecary
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.ui.popup.Popup;
	
	import org.osflash.signals.Signal;
	
	public class NewspapersPopup extends Popup
	{
		public function NewspapersPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			finishSignal = new Signal();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			// setup the transitions 
//			super.transitionIn = new TransitionData();
//			super.transitionIn.duration = .3;
//			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight - 150);
//			super.transitionOut = super.transitionIn.duplicateSwitch();
//			super.autoOpen = false;
//			super.darkenBackground = true;
			
			super.groupPrefix = "scenes/carnival/apothecary/";
			super.screenAsset = "newspapersPopup.swf"
			super.init(container);
			super.load();
		}
		
		override public function loaded():void
		{
			super.preparePopup();

			// center UI
			//super.layout.centerUI(this.screen.content);
			
			// this loads the standard close button
			super.loadCloseButton();
			initEntities();
		
			super.groupReady();
		}
		
		private function initEntities():void
		{
			_grill = ButtonCreator.createButtonEntity(super.screen.content.grill, this, onGrill);
			Timeline(_grill.get(Timeline)).handleLabel("grillOpen", grillOpen, this);
			
			_newspapers = ButtonCreator.createButtonEntity(super.screen.content.newspapers, this, onNewspapers);
			var timeline:Timeline = _newspapers.get(Timeline);
			timeline.handleLabel("scurry1", scurry, true);
			timeline.handleLabel("scurry2", scurry, true);
			timeline.handleLabel("finishNewspapers", onReadAll, true);
		}
		
		private function grillOpen():void
		{
			super.shellApi.triggerEvent("openGrill");
		}
		
		private function scurry():void
		{
			super.shellApi.triggerEvent("scurry");
		}
		
		private function onGrill($entity:Entity):void{
			Timeline(_grill.get(Timeline)).play();
		}
		
		private function onNewspapers($entity:Entity):void
		{
			//super.shellApi.triggerEvent("getPaper");
			Timeline(_newspapers.get(Timeline)).play();
		}
		
		private function onReadAll():void
		{
			finishSignal.dispatch();
			super.close();
		}

		override public function remove():void
		{
			finishSignal.removeAll();
			finishSignal = null;
			super.remove();
		}

		public var finishSignal:Signal;
		private var _grill:Entity;
		private var _newspapers:Entity;
	}
}