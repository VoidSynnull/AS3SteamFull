package game.scenes.examples.basicPopup
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	
	import game.scene.template.PlatformerGameScene;
	
	public class BasicPopup extends PlatformerGameScene
	{
		public function BasicPopup()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/basicPopup/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();

			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			// create a simple entity to display a counter.
			var counter:Entity = new Entity();
			counter.add(new Display(super._hitContainer["counter"]));
			counter.add(new Id("counter"));
			
			super.addEntity(counter);
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "showPopup")
			{
				showPopup();
			}
		}
		
		private function showPopup():void
		{
			var popup:ExamplePopup = super.addChildGroup(new ExamplePopup(super.overlayContainer)) as ExamplePopup;
			popup.id = "examplePopup";
			
			// add a listener to this popup's custom signal.  This listener will get removed in the popup's 'destroy()' method.
			popup.ballReachedTarget.add(handleBallReachedTarget);
			
			// An entity within the popup is available on 'ready'.
			popup.ready.addOnce(tracePopupEntity);
			// ... and is null after 'removed'.  It is cleaned up automatically when the popup is closed.
			popup.removed.addOnce(tracePopupEntity);
		}
		
		private function tracePopupEntity(popup:ExamplePopup):void
		{
			var entity:Entity = popup.getEntityById("popupEntity");
			
			if(entity != null)
			{
				trace("Popup entity found : " + entity.get(Id).id);
			}
			else
			{
				trace("Popup entity null.");
			}
		}
		
		// the popup's signal handler expects a single uint argument.  This requirement is set in the signals creation in ExamplePopup.
		private function handleBallReachedTarget(totalTargetsReached:uint):void
		{
			var counter:Entity = super.getEntityById("counter");
			var displayObject:DisplayObjectContainer = counter.get(Display).displayObject;
			
			displayObject["label"].text = totalTargetsReached;
		}
	}
}