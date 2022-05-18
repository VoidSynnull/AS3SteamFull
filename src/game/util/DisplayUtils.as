package game.util
{
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.DisplayGroup;
	
	import game.data.display.BitmapWrapper;

	public class DisplayUtils
	{
		/**
		 * Iterates through a Display Object and destroys it. If the Display Object is a Bitmap, its Bitmap Data
		 * will be disposed. If it's a Display Object Container, its children will be removed and checked for
		 * other Bitmaps and Bitmap Data.
		 * 
		 * @param Display: The Display Object to destroy.
		 */
		public static function destroyDisplayObject(display:DisplayObject):void
		{
			if(!display) return;
			
			if(display.parent) display.parent.removeChild(display);
			
			if(display is Bitmap)
			{
				var bitmap:Bitmap = display as Bitmap;
				if(bitmap.bitmapData)
				{
					bitmap.bitmapData.dispose();
					bitmap.bitmapData = null;
				}
			}
			else if(display is DisplayObjectContainer)
			{
				//Cast as Display Object Container to access children.
				var container:DisplayObjectContainer = display as DisplayObjectContainer;
				
				if(container is MovieClip)
				{
					MovieClip(container).gotoAndStop(1);
				}
				/**
				 * The beginning of destroyDisplayObject() removes the Display Object from its parent, so this
				 * should loop until it has no children.
				 */
				while(container.numChildren > 0)
				{
					DisplayUtils.destroyDisplayObject(container.getChildAt(0));
				}
			}
		}
		
		/**
		 * Checks to see if there are any Symbols with instance names within the display object.
		 * Only checks the immediate children, since to reach nested children would require an instance name. 
		 */
		public static function hasInstances( displayObject:DisplayObjectContainer):Boolean
		{
			var total:int = displayObject.numChildren;
			var child:DisplayObject;
			var n:int = 0
			for(n; n < total; n++)
			{
				child = DisplayObjectContainer(displayObject).getChildAt(n);
				if(child.name.indexOf("instance") < 0)
				{
					// TODO :: this might not work if someone renames the name property
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Removals all children from 
		 * @param	target
		 */
		public static function removeAllChildren( element:DisplayObjectContainer):void
		{
			while ( element.numChildren > 0 )
			{
				element.removeChildAt(0);
			}
		}
		
		public static function replaceClip(disp:DisplayObject, suffix:String=""):DisplayObject
		{
			if(!DataUtils.validString(suffix))
			{
				return disp;
			}
			var replacement:MovieClip = new MovieClip();
			var container:DisplayObjectContainer = disp.parent;
			DisplayUtils.swap(replacement, disp);
			replacement.name = disp.name+suffix;
			replacement.x = disp.x;
			replacement.y = disp.y;
			//replacement.addChild(disp);
			//disp.x = disp.y = 0;
			///*
			replacement.scaleX = disp.scaleX;
			replacement.scaleY = disp.scaleY;
			if(disp is MovieClip)
			{
				var clip:MovieClip = MovieClip(disp);
				while(clip.numChildren > 0)
				{
					var child:DisplayObject = clip.getChildAt(0);
					replacement.addChild(child);
					if(child is MovieClip)
					{
						replacement[child.name] = child;
					}
				}
			}
			else
			{
				replacement.addChild(disp);
			}
			//*/
			container[replacement.name] = replacement;
			return replacement;
		}
		
		/**
		 * Replaces one DisplayObject with another, maintaining parentage.
		 * Does not maintain children, use swapChildren to maintain children.
		 * @param	swapTo
		 * @param	swapFrom
		 */
		public static function swap(replacement:DisplayObject, current:DisplayObject):DisplayObject
		{
			var parent:DisplayObjectContainer = current.parent;
			if(parent)
			{
				var index:int = parent.getChildIndex(current);
				parent.removeChildAt(index);
				
				/*
				In most cases, this will ONLY fail when the replacement is a MovieClip
				that's ACTUALLY a loaded SWF that can't have its name changed.
				*/
				try
				{
					replacement.name = current.name;
				} 
				catch(error:Error) 
				{
					/*
					If it can't have its name changed, then replace it. If the SWF only has 1 frame, then take all of its children
					out and put them in a replacement Sprite that CAN be renamed.
					*/
					var clip:MovieClip = replacement as MovieClip;
					if(clip.totalFrames == 1)
					{
						var sprite:Sprite = new Sprite();
						while(clip.numChildren)
						{
							sprite.addChild(clip.removeChildAt(0));
						}
						replacement 		= sprite;
						replacement.name 	= current.name;
					}
				}
				
				if(index != parent.numChildren)
				{
					parent.addChildAt(replacement, index);
				}
				else
				{
					parent.addChild(replacement);
				}
				
				
				if(parent is MovieClip)
				{
					parent[current.name] = replacement;
				}
				
				return replacement;
			}
			return null;
		}
		
		/**
		 * Replaces one DisplayObject with another, maintaining parentage.
		 * Does not maintain children, use swapChildren to maintain children.
		 * @param	swapTo
		 * @param	swapFrom
		 */
		public static function wrap( displayObject:DisplayObject ):DisplayObject
		{
			var parentContainer:DisplayObjectContainer = displayObject.parent;
			var wrapper:Sprite = new Sprite();
			if( parentContainer )
			{
				var index:int = parentContainer.getChildIndex( displayObject );
				parentContainer.removeChildAt( index );
				wrapper.addChild( displayObject );
				if( index != parentContainer.numChildren)
				{
					parentContainer.addChildAt( wrapper, index );
				}
				else
				{
					parentContainer.addChild( wrapper );
				}
				return wrapper;
			}
			else
			{
				wrapper.addChild( displayObject );
				return wrapper;
			}
		}
		
		/**
		 * Moves children from swapFrom container into swapTo container
		 * @param	swapTo
		 * @param	swapFrom
		 */
		public static function swapChildren(swapTo:DisplayObjectContainer, swapFrom:DisplayObjectContainer):void
		{
			DisplayUtils.removeAllChildren(swapTo);
			var numChildren:int = swapFrom.numChildren;
			for ( var i:uint = 0; i < numChildren; i++ )
			{
				try
				{
					swapTo.addChild(swapFrom.getChildAt(0));
				}
				catch (error:Error)
				{
					trace("Error :: Utils :: swapChildren :: " + Loader(swapFrom).contentLoaderInfo.url + " is likely AVM1 content (AS1 or AS2), needs to be published as AVM2 (AS3) content");
				}
			}
		}
		
		public static function moveToTop( displayObject:DisplayObject ):void
		{
			if( displayObject.parent )
			{
				displayObject.parent.addChild( displayObject );
			}
		}
		
		public static function moveToBack( displayObject:DisplayObject ):void
		{
			if( displayObject.parent )
			{
				displayObject.parent.addChildAt( displayObject, 0 );
			}
		}
		
		/**
		 * Relayers a DisplayObject's depth in reference to another DisplayObject.
		 * The option to relayer over or under the referenced DisplayObject is specified by the isOver param.
		 * @param displayObject - the DisplayObject you wish to relayer
		 * @param referenceDisplay - the DisplayObject whose current layer you wish to use as a reference
		 * @param isOver - flag determining whether the displayObject is relayered above or below the referenced DisplayObject's layer.
		 * 
		 */
		public static function moveToOverUnder( displayObject:DisplayObject, referenceDisplay:DisplayObject, isOver:Boolean = true ):void
		{
			if( displayObject.parent == referenceDisplay.parent )
			{
				var currentIndex:int = referenceDisplay.parent.getChildIndex( displayObject );
				var refIndex:int = referenceDisplay.parent.getChildIndex( referenceDisplay );
				if( isOver )
				{
					if( currentIndex > refIndex )
					{
						displayObject.parent.setChildIndex( displayObject, refIndex + 1 );
					}
					else
					{
						displayObject.parent.setChildIndex( displayObject, refIndex );
					}
				}
				else
				{
					if( currentIndex > refIndex )
					{
						displayObject.parent.setChildIndex( displayObject, refIndex );
					}
					else
					{
						displayObject.parent.setChildIndex( displayObject, refIndex - 1 );
					}
				}
			}
		}
		
		public static function convertToBitmapSprite(display:DisplayObject, bounds:Rectangle = null, quality:Number = NaN, swapDisplay:Boolean = true, container:DisplayObjectContainer = null):BitmapWrapper
		{
			if(isNaN(quality)) { quality = PerformanceUtils.defaultBitmapQuality; }
			
			var sprite:Sprite = BitmapUtils.createBitmapSprite(display, quality, bounds); 
			
			if(!container) container = display.parent;
			if(container is Loader) container = null;
			
			if(container)
			{
				if(swapDisplay)
				{
					DisplayUtils.swap(sprite, display);
				}
				else
				{
					container.addChild(sprite);
				}
			}
			
			var wrapper:BitmapWrapper 	= new BitmapWrapper();
			wrapper.sprite 				= sprite;
			wrapper.bitmap 				= sprite.getChildAt(0) as Bitmap;
			wrapper.data 				= wrapper.bitmap.bitmapData;
			wrapper.source 				= display;
			
			return wrapper;
		}
		
		/**
		 * Converts a display object to a bitmap with the scaling and rotation applied directly to the bitmapData.  
		 * 		This gets rid of the pixilation caused by the above method but the reg point will be different than 
		 * 		the original so you need to factor that in when moving it around.
		 *  @param : displayObject : The source displayObject to be bitmapped.
		 *  @param : moveToFront : Should this new bitmap be moved to the front of the display index?
		 *  @returns : BitmapWrapper - contains references to the new bitmap, the original displayObject source, and the Sprite wrapper and tile bitmaps if applicable.  The bitmapData
		 *                MUST be disposed by call BitmapWrapper.destroy() before leaving a scene.
		 */
		public static function convertToBitmap(display:DisplayObject, transparent:Boolean=true, fill:Number=0x00000000, container:DisplayObjectContainer = null, clipRectangle:Rectangle = null, swapDisplay:Boolean = true, quality:Number = 1):BitmapWrapper 
		{
			var bitmap:Bitmap = BitmapUtils.createBitmap(display, quality);
			
			if(!container) container = display.parent;
			if(container is Loader) container = null;
			
			if(container)
			{
				if(swapDisplay)
				{
					DisplayUtils.swap(bitmap, display);
				}
				else
				{
					container.addChild(bitmap);
				}
			}
			
			var wrapper:BitmapWrapper = new BitmapWrapper();
			wrapper.bitmap 				= bitmap;
			wrapper.data 				= bitmap.bitmapData;
			wrapper.source 				= display;
			
			return wrapper;
		}
		
		/**
		 * This method replaces the Display.displayObject of an entity with a bitmap using one of the above two methods to convert it.
		 * 	    The bitmapData will automatically be disposed when this entity is removed from the game.
		 */
		public static function bitmapDisplayComponent(entity:Entity, wrapInSprite:Boolean = true, quality:Number = NaN, transparent:Boolean=true, fill:Number=0x00000000):void
		{
			if(isNaN(quality)) { quality = PerformanceUtils.defaultBitmapQuality; }
			
			var display:Display = entity.get(Display);			
			if(display && display.displayObject != null)
			{
				if(wrapInSprite)
				{
					var sprite:Sprite = BitmapUtils.createBitmapSprite(display.displayObject, quality, null, transparent, fill);
					swap(sprite, display.displayObject);
					display.displayObject = sprite;
				}
				else
				{
					var bitmap:Bitmap = BitmapUtils.createBitmap(display.displayObject, quality, null, transparent, fill);
					swap(bitmap, display.displayObject);
					display.displayObject = bitmap;
				}
			}
		}
		
		/**
		 * This method takes a source displayObject and converts it to a grid of bitmapped tiles wrapped inside a sprite.  This allows larger images to be broken up into a 
		 *   multiple bitmaps rather than a single large one.
		 */
		public static function convertToTiledBitmap(display:DisplayObject, tileWidth:Number, tileHeight:Number, quality:Number = NaN, overlap:Number = 0, bounds:Rectangle = null, transparent:Boolean=true, fillColor:Number = 0):BitmapWrapper
		{						
			if(isNaN(quality)) { quality = PerformanceUtils.defaultBitmapQuality; }
			
			// Use the bounds of the source bitmap to determine the size of the bitmapData needed to contain it.
			var displayBounds:Rectangle = display.getBounds(display);
			
			if(bounds)
			{
				if(displayBounds.left < bounds.left) 	displayBounds.left 		= bounds.left;
				if(displayBounds.top < bounds.top) 		displayBounds.top 		= bounds.top;
				if(displayBounds.right > bounds.right) 	displayBounds.right 	= bounds.right;
				if(displayBounds.bottom > bounds.bottom) displayBounds.bottom 	= bounds.bottom;
			}
			
			var data:Array = [];
			var sprite:Sprite = BitmapUtils.createBitmapSpriteTiled(display, tileWidth, tileHeight, quality, displayBounds, transparent, fillColor, overlap);
			
			for(var index:int = sprite.numChildren - 1; index >= 0; --index)
			{
				var bitmap:Bitmap = sprite.getChildAt(index) as Bitmap;
				data.push(bitmap.bitmapData);
			}
			
			var wrapper:BitmapWrapper 	= new BitmapWrapper();
			wrapper.tileData 			= data;
			wrapper.sprite 				= sprite;
			
			return wrapper;
		}
		
		/*
		private static function adjustTransparentPixel(data:BitmapData, x:int, y:int):void
		{
			var pixelColor:uint = data.getPixel32(x, y);
			var alpha:uint = pixelColor >> 24 & 255;
			var newColor:uint;
			
			// pixel is transparent (or invisible)
			if ( alpha < 255 ) 
			{
				newColor = 0x00000000;
				//newColor = 0xff000000 + data.getPixel(x, y);
				
				//var alpha32:int = ((pixelColor >> 24) & 0xff) * .5;
				//var red32:int = pixelColor >> 16 & 0xff;
				//var green32:int = pixelColor >> 8 & 0xff;
				//var blue32:int = pixelColor & 0xff;
				
				//newColor = alpha32 << 24 | red32 << 16 | green32 << 8 | blue32;
				
				data.setPixel32(x, y, newColor);
			}
			else
			{
				newColor = 0xff0000ff;
			}
		}
		*/
		/**
		 * Positions element using provide params
		 * @param	element
		 * @param	edge : constants that are accessible from DisplayPositions (BOTTOM_LEFT, BOTTOM_RIGHT, BOTTOM_CENTER, TOP_LEFT, etc.)
		 * @param	width
		 * @param	height
		 * @param	paddingX
		 * @param	paddingY
		 * @param	offsetX
		 * @param	offsetY
		 */
		public static function getBounds( element:DisplayObject, orientation:String):Rectangle
		{
			var bounds:Rectangle = new Rectangle();
			
			switch(orientation)
			{
				case DisplayPositions.BOTTOM_LEFT :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = bounds.width;
					bounds.topLeft.x = bounds.x = bounds.left = 0;
					bounds.bottomRight.y = bounds.bottom = 0;
					bounds.topLeft.y = bounds.y = bounds.top = -bounds.height;
					break;
				
				case DisplayPositions.BOTTOM_RIGHT :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = 0;
					bounds.topLeft.x = bounds.x = bounds.left = -bounds.width;
					bounds.bottomRight.y = bounds.bottom = 0;
					bounds.topLeft.y = bounds.y = bounds.top = -bounds.height;
					break;
				
				case DisplayPositions.BOTTOM_CENTER :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = bounds.width/2;
					bounds.topLeft.x = bounds.x = bounds.left = -bounds.right;
					bounds.bottomRight.y = bounds.bottom = 0;
					bounds.topLeft.y = bounds.y = bounds.top = -bounds.height;
					break;				
				
				case DisplayPositions.TOP_LEFT :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = bounds.width;
					bounds.topLeft.x = bounds.x = bounds.left = 0;
					bounds.bottomRight.y = bounds.bottom = bounds.height;
					bounds.topLeft.y = bounds.y = bounds.top = 0;
					break;
				
				case DisplayPositions.TOP_RIGHT :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = 0;
					bounds.topLeft.x = bounds.x = bounds.left = -bounds.width;
					bounds.bottomRight.y = bounds.bottom = bounds.height;
					bounds.topLeft.y = bounds.y = bounds.top = 0;
					break;
				
				case DisplayPositions.TOP_CENTER :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = bounds.width/2;
					bounds.topLeft.x = bounds.x = bounds.left = -bounds.right;
					bounds.bottomRight.y = bounds.bottom = bounds.height;
					bounds.topLeft.y = bounds.y = bounds.top = 0;
					break;				
				
				case DisplayPositions.CENTER :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = bounds.width/2;
					bounds.topLeft.x = bounds.x = bounds.left = -bounds.right;
					bounds.bottomRight.y = bounds.bottom = bounds.height/2;
					bounds.topLeft.y = bounds.y = bounds.top = -bounds.bottom;
					break;
				
				case DisplayPositions.LEFT_CENTER :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = bounds.width;
					bounds.topLeft.x = bounds.x = bounds.left = 0;
					bounds.bottomRight.y = bounds.bottom = bounds.height/2;
					bounds.topLeft.y = bounds.y = bounds.top = -bounds.bottom;
					break;
				
				case DisplayPositions.RIGHT_CENTER :
					bounds.size.x = bounds.width = element.width;
					bounds.size.y = bounds.height = element.height;
					bounds.bottomRight.x = bounds.right = 0;
					bounds.topLeft.x = bounds.x = bounds.left = -bounds.width;
					bounds.bottomRight.y = bounds.bottom = bounds.height/2;
					bounds.topLeft.y = bounds.y = bounds.top = -bounds.bottom;
					break;
			}
			
			return bounds
		}
		
		// specify a custom bouncy scale.  Totaltime is the total time of the transition in seconds.
		public static function customBounceTransition(tween:*, property:*, maxScale:Number = 1.5, totalTime:Number = .45, finalScale:Number = 1, axis:String = null, callback:Function = null):void
		{		
			var scaleOrder:Array = [maxScale * finalScale, .9 * finalScale, 1.05 * finalScale, finalScale];
			
			var transitionLength:Number = .45;
			var transitionMultiplier:Number = 1;
			
			var expandTime:Number = .15;
			var contractTime:Number = .10;
			
			if(transitionLength != totalTime)
			{
				transitionMultiplier = totalTime / transitionLength;
				expandTime *= transitionMultiplier;
				contractTime *= transitionMultiplier;
			}
			
			if (axis == "x")
			{
				tween.to(property, expandTime, { delay : 0, scaleX : scaleOrder[0], ease : Linear.easeNone });
				tween.to(property, contractTime, { delay : expandTime, scaleX : scaleOrder[1], ease : Linear.easeNone });
				tween.to(property, expandTime + contractTime, { scaleX : scaleOrder[2], ease : Linear.easeNone });
				tween.to(property, expandTime + contractTime * 2, { scaleX : scaleOrder[3], ease : Linear.easeNone, onComplete : callback } );
			}
			else if (axis == "y")
			{
				tween.to(property, expandTime, { delay : 0, scaleY : scaleOrder[0], ease : Linear.easeNone });
				tween.to(property, contractTime, { delay : expandTime, scaleY : scaleOrder[1], ease : Linear.easeNone });
				tween.to(property, expandTime + contractTime, { scaleY : scaleOrder[2], ease : Linear.easeNone });
				tween.to(property, expandTime + contractTime * 2, { scaleY : scaleOrder[3], ease : Linear.easeNone, onComplete : callback } );
			}
			else
			{
				tween.to(property, expandTime, { delay : 0, scaleX : scaleOrder[0], scaleY : scaleOrder[0], ease : Linear.easeNone });
				tween.to(property, contractTime, { delay : expandTime, scaleX : scaleOrder[1], scaleY : scaleOrder[1], ease : Linear.easeNone });
				tween.to(property, expandTime + contractTime, { scaleX : scaleOrder[2], scaleY : scaleOrder[2], ease : Linear.easeNone });
				tween.to(property, expandTime + contractTime * 2, { scaleX : scaleOrder[3], scaleY : scaleOrder[3], ease : Linear.easeNone, onComplete : callback } );
			}
		}
		
		public static function stopAllClips(clip:MovieClip):void 
		{
			if (clip) 
			{ 
				clip.gotoAndStop(1);
				
				for (var index:int = clip.numChildren - 1; index > -1; --index) 
				{ 
					var child:DisplayObject = clip.getChildAt(index); 
					
					if (child is MovieClip) 
					{
						stopAllClips(clip);
					}
				}
			}
		}
		
		/**
		 * Converts the <code>point</code>'s (x, y) position inside <code>container1</code>'s local coordinate space into an
		 * (x, y) position relative to <code>container2</code>'s local coordinate space.
		 * 
		 * <p>This could be used to move a DisplayObject into a new container, change its (x, y), and still maintain
		 * its visual position on-screen.</p>
		 */
		public static function localToLocalPoint(point:Point, container1:DisplayObject, container2:DisplayObject):Point
		{
			return (container1 == container2) ? point : container2.globalToLocal(container1.localToGlobal(point));
		}
		
		/**
		 * Converts the <code>display</code>'s (x, y) position inside its parent's local coordinate space into an (x, y)
		 * position relative to <code>container</code>'s local coordinate space.
		 * 
		 * <p>This could be used to move a DisplayObject into a new container, change its (x, y), and still maintain
		 * its visual position on-screen.</p>
		 */
		public static function localToLocal(display:DisplayObject, container:DisplayObject):Point
		{
			return (display.parent == container) ? new Point(display.x, display.y) : container.globalToLocal(display.localToGlobal(new Point()));
		}
		
		/**
		 * Returns an accurate Point of where the mouse's X and Y are relative to a given DisplayObject. Because
		 * <code>display.mouseX</code> and <code>display.mouseY</code> return values that don't factor in a
		 * DisplayObject's scale or rotation, you may end up getting inaccurate X and Y mouse values.
		 */
		public static function mouseXY(display:DisplayObject):Point
		{
			var radians:Number	= Math.atan2(display.mouseY * display.scaleY, display.mouseX * display.scaleX);
			var radius:Number	= display.mouseX * display.scaleX / Math.cos(radians);
			
			radians += GeomUtils.degreeToRadian(display.rotation);
			
			var x:Number = Math.cos(radians) * -radius;// * display.scaleX;
			var y:Number = Math.sin(radians) * -radius;// * display.scaleY;
			
			return new Point(x, y);
		}
		
		public static function fitDisplayToScreen(group:DisplayGroup, displayObject:DisplayObject, baseSize:Point = null, createBorder:Boolean = true, viewPortSize:Point = null):Number
		{
			if(baseSize == null)
				baseSize = new Point(displayObject.width, displayObject.height);
			
			if(viewPortSize == null)
				viewPortSize = new Point(group.shellApi.viewportWidth, group.shellApi.viewportHeight);
			
			var widthRatio:Number = viewPortSize.x / baseSize.x;
			var heightRatio:Number = viewPortSize.y / baseSize.y;
			
			var minRatio:Number = Math.min(widthRatio, heightRatio);
			
			var displaySize:Point = PointUtils.times(baseSize, minRatio);
			
			displayObject.scaleX = displayObject.scaleY = minRatio;
			
			var heightDifference:Number = Math.abs(viewPortSize.y - displaySize.y);
			var widthDifference:Number = Math.abs(viewPortSize.x - displaySize.x);
			
			var clip:MovieClip = new MovieClip();
			
			if(heightRatio > widthRatio)
			{
				heightDifference /= 2;
				if(createBorder)
				{
					clip.graphics.beginFill(0);
					clip.graphics.drawRect(0,0,viewPortSize.x, heightDifference);
					clip.graphics.drawRect(0, displaySize.y + heightDifference, viewPortSize.x, heightDifference);
					clip.graphics.endFill();
				}
				displayObject.y = heightDifference;
			}
			else
			{
				widthDifference /= 2;
				if(createBorder)
				{
					clip.graphics.beginFill(0);
					clip.graphics.drawRect(0,0,widthDifference, viewPortSize.y);
					clip.graphics.drawRect( displaySize.x + widthDifference, 0, widthDifference, viewPortSize.y);
					clip.graphics.endFill();
				}
				displayObject.x = widthDifference;
			}
			if(createBorder)
				EntityUtils.createSpatialEntity(group, clip, displayObject.parent).add(new Id("border"));
			return minRatio;
		}
	}
}