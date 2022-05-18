package game.scenes.examples.basicPopup
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	import game.util.DisplayPositions;
	
	import org.osflash.signals.Signal;
	
	public class ExamplePopup extends Popup
	{
		public function ExamplePopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// do any cleanup required in this Group before calling the super classes destroy method
			this.ballReachedTarget.removeAll();
			this.ballReachedTarget = null;
			
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the signal that a parent group (the scene) will use to receive messages from this popup.
			//  This uses a Signal with a single uint parameter.
			// NOTE - This signal MUST be manually removed in a destroy method.
			this.ballReachedTarget = new Signal(uint);
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/examples/basicPopup/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.loadFiles(new Array("examplePopup.swf"), false, true, loaded);
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("examplePopup.swf", true) as MovieClip;
			// this loads the standard close button
			super.loadCloseButton();
			
			/**
			 * The following methods adjust the position and size of art to accomodate different screen sizes and aspect ratios.  Depending on the intent
			 *   of the artist various methods can be used to deal with different screen layouts.
			 * 
			 * ***** THE FOLLOWING METHODS ASSUME THE ART TO BE TOP LEFT REGISTERED! ******
			 */
			
			// this centers the art 
			super.centerWithinDimensions(super.screen.center);
			
			/**
			 * 'pinToEdge' will allow you to push a ui element to the edge of the screen no matter the screen size.  
			 *     An offset can be added if needed to add 'padding' from the edge.
			 */
			super.pinToEdge(screen.pinLeft, DisplayPositions.LEFT_CENTER);
			screen.pinLeft.label.text = "pin left center";
			super.pinToEdge(screen.pinRight, DisplayPositions.RIGHT_CENTER);
			screen.pinRight.label.text = "pin right center";
			super.pinToEdge(screen.pinTop, DisplayPositions.TOP_LEFT);
			screen.pinTop.label.text = "pin top left";
			super.pinToEdge(screen.pinBottom, DisplayPositions.BOTTOM_RIGHT, 20, 20);
			screen.pinBottom.label.text = "pin bottom right offset";
			
			/**
			 * 'fitToDimensions' will either stretch to fit a displayObject to a specified width and height or scale it to fit while maintaining aspect ratio.  
			 *   The art will fit within the container with now overflow.  Defaults to the viewport size and no stretching.
			 */
			//  fit AND stretch to fill entire screen 
			super.fitToDimensions(super.screen.stretch, true);
			
			// fit to screen but do not stretch
			super.fitToDimensions(super.screen.fit);
			
			/**
			 * 'fillDimensions' works like fit except that it will ensure that the entire screen is filled while keeping the original aspect ratio (no stretching).  
			 *  This means that the art may 'overflow' the sides of the popup.
			 */
			super.fillDimensions(super.screen.fill);
			
			// any entities or systems created within this group will automatically be removed on close.  As a test we'll create a test entity inside and trace it from the scene.
			var popupEntity:Entity = new Entity();
			popupEntity.add(new Id("popupEntity"));
			popupEntity.add(new Spatial());
			popupEntity.add(new Display(super.screen.ball));
			popupEntity.add(new Tween());
			
			super.addEntity(popupEntity);
			
			applyTween(popupEntity);
			
			super.loaded();
		}
		
		private function applyTween(entity:Entity):void
		{
			var tween:Tween = entity.get(Tween);
			
			tween.to(entity.get(Spatial), 2, { x:(Math.random() * super.shellApi.viewportWidth),      // x and y target are picked anywhere within the screen
				y:(Math.random() * super.shellApi.viewportHeight), 
				ease:Sine.easeInOut,  								      // use the Sine.easeInOut type of transitions.  See more examples at http://www.greensock.com/tweenmax/
				onComplete:applyTween,  								  // call this method again on the same entity when it completes.
				onCompleteParams:[entity] });
			
			ballReachedTarget.dispatch(++_totalReached);
		}
		
		public var ballReachedTarget:Signal;
		private var _totalReached:uint = 0;
	}
}