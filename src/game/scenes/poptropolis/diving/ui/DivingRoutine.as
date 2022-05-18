package game.scenes.poptropolis.diving.ui
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.UIView;
	
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class DivingRoutine extends UIView
	{
		public var routineDisplayComplete:Signal;
		public var arrowComplete:Signal
		
		private var _routine:Entity;
		private var _routineClip:MovieClip;
		private var _arrowsClip:MovieClip;
		private var _arrows:Vector.<Entity>;
		private var _currentArrow:Entity;
		private const MAX_ARROWS:int = 4;
		
		
		public function DivingRoutine(container:DisplayObjectContainer=null)
		{
			routineDisplayComplete = new Signal();
			arrowComplete = new Signal();
			
			super(container);
			super.id = "divingRoutine";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "scenes/poptropolis/diving/";
			super.screenAsset = "routine_hud.swf";
			
			// Create this groups container.
			super.init(container);
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{				
			// Call the parent classes loaded() method so it knows this Group is ready.
			super.loaded();
			
			// create routine
			_routineClip = super.screen.content;
			_arrowsClip = _routineClip.arrows;
			
			_routine = EntityUtils.createMovingEntity( this, _routineClip );
			_routine.add( new Tween() );
			Display(_routine.get(Display)).visible = false;
			
			//create arrows
			_arrows = new Vector.<Entity>();
			var arrowClip:MovieClip;
			for (var i:int = 0; i < MAX_ARROWS; i++) 
			{
				arrowClip = _arrowsClip["a" + i]; 
				_arrows.push( EntityUtils.createSpatialEntity( this, arrowClip ) );
				TimelineUtils.convertClip( arrowClip, this , _arrows[i], null, false );
			}
		}	
		
		////////////////////////////// START //////////////////////////////
		
		public function resetRoutine( difficultyLevel:int, currentRoutine:Vector.<int> ):void
		{
			var display:Display = _routine.get(Display);
			display.visible = false;
			
			// update routine
			var arrow:Entity;
			var spatial:Spatial;
			var routineDirection:int;
			difficultyLevel += 2; 
			
			for( var j:int = 0; j < MAX_ARROWS; j++ )
			{
				arrow = _arrows[j];
				if( j < difficultyLevel )
				{
					Display(arrow.get(Display)).visible = true;
					spatial = arrow.get(Spatial);
					routineDirection = currentRoutine[j];
					if( ( routineDirection > 0 && spatial.scaleX > 0 ) || ( routineDirection < 0 && spatial.scaleX < 0 ) )	// set to face position
					{
						spatial.scaleX *= -1;
					}
					Timeline( arrow.get(Timeline) ).reset(false);
				}
				else
				{
					Display(arrow.get(Display)).visible = false;
				}
			}
			
			// adjust x position based on number of visible arrows
			_arrowsClip.x = _arrowsClip.width * ( difficultyLevel/MAX_ARROWS ) * -.5;
			
			// center hud
			spatial = _routine.get(Spatial);
			spatial.x = super.shellApi.viewportWidth/2;
			spatial.y = super.shellApi.viewportHeight/2;
			spatial.scale = 3;
		}
		
		public function fadeIn():void
		{
			//fade in
			var display:Display = _routine.get(Display);
			display.visible = true;
			display.alpha = 0;
			var tween:Tween = _routine.get(Tween);
			tween.to( display, .5, { alpha : 1 });
			
			// set up timer, duration that routione remains in center of screen
			SceneUtil.addTimedEvent( super.parent, new TimedEvent( 3, 1, animateOutRoutine ) );	 // give instructions popup time to animate in
		}
		
		private function animateOutRoutine():void
		{
			// tween to bottom left corner and shrink
			var spatial:Spatial = _routine.get(Spatial);
			var tween:Tween = _routine.get(Tween);
			var smallerScale:Number = 1.5;
			var buffer:int = 10;
			var xPos:int = (spatial.width * smallerScale/spatial.scale) / 2 + buffer;
			var yPos:int = super.shellApi.viewportHeight - ( spatial.height * smallerScale/spatial.scale) / 2 - buffer;
			tween.to( spatial, .5, { x : xPos, y : yPos, scale : smallerScale, onComplete : onRoutineDisplayComplete });
		}
		
		////////////////////////////// UPDATE //////////////////////////////

		public function setCurrentArrow( arrowIndex:int ):void
		{
			_currentArrow = _arrows[arrowIndex];
			var timeline:Timeline = _currentArrow.get(Timeline);
			timeline.handleLabel( "end", onArrowComplete );
		}
	
		public function fillCurrentArrow( isFilling:Boolean ):void
		{
			var timeline:Timeline = _currentArrow.get(Timeline);
			timeline.playing = isFilling;
		}
		
		private function onArrowComplete():void
		{
			// update next arrow
			arrowComplete.dispatch();
		}

		private function onRoutineDisplayComplete():void
		{
			routineDisplayComplete.dispatch();
		}
		
		////////////////////////////// CLOSE //////////////////////////////
		
		public function fadeOut():void
		{
			var display:Display = _routine.get(Display);
			var tween:Tween = _routine.get(Tween);
			tween.to( display, .5, { alpha : 0 });
		}
	}
}





