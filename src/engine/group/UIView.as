package engine.group
{
	/**
	 * The base class for ui screens/views.
	 * 
	 * This type of group is intended to be used to serve as the 'view' of a ui group.  This should not interact with the game outside the display of ui elements for this view.
	 * Multiple UIView's can exist within a scene.
	 */
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import engine.managers.SoundManager;
	
	import game.data.ui.ToolTipType;
	import game.managers.LayoutManager;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.DisplayAlignment;
	import game.util.DisplayPositionUtils;
	import game.util.DisplayPositions;

	public class UIView extends DisplayGroup
	{
		public function UIView(container:DisplayObjectContainer = null)
		{			
			super(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			if( DataUtils.validString( this.screenAsset ) )
			{
				super.loadFiles(new Array( this.screenAsset), false, true, this.loaded );
			}
		}
		
		/**
		 * IUView utility to fit and center a DisplayObject to the screen, regardless of screen dimensions.
		 * @param content - DisplayObject located in a UI/non-scene related container.
		 * @param bounds - Rectangle specifying area of your DisplayObject you want to have viewable, defaults to the DisplayObject's full bounds if no bounds are specified.
		 * @param blackoutExcess - If true, the surrounding area around the bounds Rectangle will be blacked out.
		 */
		public function letterbox(content:DisplayObject, bounds:Rectangle = null, blackoutExcess:Boolean = true):void
		{
			var area:Rectangle = new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight);
			
			bounds = DisplayAlignment.fitAndAlign(content, area, bounds);
			
			if(blackoutExcess)
			{
				var shape:Shape = new Shape();
				shape.graphics.beginFill(0);
				shape.graphics.drawRect(area.x, area.y, area.width, area.height);
				shape.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
				shape.graphics.endFill();
				this.screen.addChild(shape);
			}
		}
		
		/**
		 * Called when all assets and data for this group have been loaded.
		 */
		override public function loaded():void
		{
			// assign screen asset if specified, and hasn't already been assigned
			setupScreen();
			
			super.loaded();
		}

		protected function setupScreen():void
		{
			if( _screen == null )
			{
				if( DataUtils.validString( this.screenAsset ) )
				{
					_screen = super.getAsset( this.screenAsset, true) as MovieClip;
					super.groupContainer.addChild(_screen);
				} 
			}
		}
		
		override public function destroy():void
		{
			_screen = null;
			// destroy will automatically cleanup any buttons on this screen and call their 'destroy()' method.
			super.destroy();
		}
		
		public function pinToEdge( displayObject:DisplayObjectContainer = null, displayPositions:String = "", paddingX:Number = 0, paddingY:Number = 0):void
		{
			if ( shellApi.viewportWidth && shellApi.viewportHeight )
			{
				displayObject = (displayObject) ? displayObject : super.groupContainer;
				displayPositions = (DataUtils.validString(displayPositions)) ? displayPositions : DisplayPositions.CENTER;

				DisplayPositionUtils.position( displayObject, displayPositions, super.shellApi.viewportWidth, super.shellApi.viewportHeight, paddingX, paddingY);
			}
			else
			{
				trace( "Error :: UIView :: pinToEdge :: viewport has not been defined." );
			}
		}
		
		public function pinToEdgeAbsolute( displayObject:DisplayObjectContainer = null, displayPositions:String = "", paddingX:Number = 0, paddingY:Number = 0):void
		{
			if ( shellApi.viewportWidth && shellApi.viewportHeight )
			{
				displayObject = (displayObject) ? displayObject : super.groupContainer;
				displayPositions = (DataUtils.validString(displayPositions)) ? displayPositions : DisplayPositions.CENTER;
				
				DisplayPositionUtils.positionAbsolute( displayObject, displayPositions, super.shellApi.viewportWidth, super.shellApi.viewportHeight, paddingX, paddingY);
			}
			else
			{
				trace( "Error :: UIView :: pinToEdge :: viewport has not been defined." );
			}
		}
		
		public function getEdgePosition( displayPositions:String, paddingX:Number = 0, paddingY:Number = 0):Point
		{
			if ( shellApi.viewportWidth && shellApi.viewportHeight )
			{
				return DisplayPositionUtils.getPosition( displayPositions, super.shellApi.viewportWidth, super.shellApi.viewportHeight, paddingX, paddingY);
			}
			else
			{
				trace( "Error :: UIView :: getEdgePosition :: viewport has not been defined." );
				return null;
			}
		}
		
		public function fitToDimensions(displayObject:DisplayObject, stretch:Boolean = false, width:Number = NaN, height:Number = NaN, center:Boolean = true):void 
		{
			if(isNaN(width)) { width = super.shellApi.viewportWidth; }
			if(isNaN(height)) { height = super.shellApi.viewportHeight; }
			
			if(stretch)
			{
				displayObject.width = width;
				displayObject.height = height;
			}
			else
			{
				DisplayPositionUtils.fitToDimensions(displayObject, width, height, center);
			}
		}
		
		public function fitToSingleDimension(displayObject:DisplayObject, fitHorizontally:Boolean = true, dimensionLength:Number = NaN):void 
		{
			if(isNaN(dimensionLength)) 
			{ 
				dimensionLength = fitHorizontally ? super.shellApi.viewportWidth : super.shellApi.viewportHeight;
			}
			
			DisplayPositionUtils.fitToSingleDimension(displayObject, dimensionLength, fitHorizontally);
		}
		
		public function fillDimensions(displayObject:DisplayObject, width:Number = NaN, height:Number = NaN):void
		{
			if(isNaN(width)) { width = super.shellApi.viewportWidth; }
			if(isNaN(height)) { height = super.shellApi.viewportHeight; }
			
			DisplayPositionUtils.fillDimensions(displayObject, width, height);
		}
		
		public function updateDefaultCursor(restore:Boolean = false):void
		{
			if(_defaultCursor != null)
			{
				if(restore)
				{
					super.shellApi.defaultCursor = _previousDefaultCursor;
				}
				else
				{
					_previousDefaultCursor = super.shellApi.defaultCursor;
					super.shellApi.defaultCursor = _defaultCursor;
				}
			}
		}
		
		public function centerWithinDimensions(displayObject:DisplayObject, width:Number = NaN, height:Number = NaN):void
		{
			if(isNaN(width)) { width = super.shellApi.viewportWidth; }
			if(isNaN(height)) { height = super.shellApi.viewportHeight; }
			
			DisplayPositionUtils.centerWithinDimensions(displayObject, width, height, displayObject.width, displayObject.height);
		}
		
		/**
		 * Causes the <code>SoundManager</code> to begin playback
		 * of the standard button click sound stored in <code>SoundManager.STANDARD_BUTTON_CLICK_FILE</code>.
		 */	
		public function playClick(...args):void 
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + SoundManager.STANDARD_BUTTON_CLICK_FILE);
		}
		
		/**
		 * Causes the <code>SoundManager</code> to begin playback
		 * of the standard close button/cancel button click sound stored in <code>SoundManager.STANDARD_CLOSE_CANCEL_FILE</code>.
		 */	
		public function playCancel(...args):void 
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + SoundManager.STANDARD_CLOSE_CANCEL_FILE);
		}
		
		/**
		 * The 'screen' contains a reference to a UIViews primary asset.  This is only applicable to UIViews that use a base asset.swf to contain buttons and other assets.
		 */
		private var _screen:DisplayObjectContainer;
		public function get screen():* { return(_screen); }
		public function set screen(screen:*):void { _screen = screen; }
		public var screenAsset:String;	// name of asset you will use as screen
		private var _previousDefaultCursor:String;
		protected var _defaultCursor:String = ToolTipType.ARROW;
		
		[Inject]
		public var layout:LayoutManager;
	}
}
