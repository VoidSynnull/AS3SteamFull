package engine.components
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import game.data.display.BitmapWrapper;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	
	public class Display extends Component
	{
		public function Display( displayObject:* = null, container:DisplayObjectContainer = null, visible:Boolean = true )
		{
			this.displayObject = displayObject;
			if ( container )
			{
				setContainer( container );
			}
			this.visible = visible;
		}
		
		override public function destroy():void
		{
			disposeBitmaps(); // TODO :: Not sure about this, not sure if data is shared or not...
		}
		
		/**
		 * Empty the display, this removes all of the display's children.
		 * Sets invalidate to true.
		 */
		public function empty():void
		{
			disposeBitmaps();
			DisplayUtils.removeAllChildren( displayObject );
			invalidate = true;
		}
		
		/**
		 * Nullify display & container references
		 */
		public function clearReference():void
		{
			displayObject = null;
			this.container = null;
		}

		/**
		 * The <code>DisplayObjectContainer</code>
		 * which is the <code>parent</code> property of this component's
		 * <code>displayObject</code>.
		 * 
		 * @default	null
		 */
		
		//[Deprecated (message="The container for your <code>DisplayObject</code> should always be accessed by its <code>parent</code> property.")]
		public var container:DisplayObjectContainer;
		/*
		public function get container():DisplayObjectContainer
		{
			if( container )
			{
				return _container;
			}
			else if( displayObject )
			{
				return displayObject.parent;
			}
			return null;
		}
		*/

		/**
		 * The <code>DisplayObjectContainer</code> which is the
		 * visual representation of the owning <code>Entity</code>.
		 * Note that since this property must be a <code>DisplayObjectContainer</code>,
		 * simpler <code>DisplayObject</code>s such as <code>Shape</code> or
		 * <code>SimpleButton</code> are ineligible for this role.
		 * 
		 * @default	null
		 */		
		public var displayObject:* = null;

		/**
		 * A general purpose 'dirty' flag. When set, it indicates that this
		 * component has changed in some way, and is in need
		 * of attention. Systems will often test this flag to
		 * determine what work needs to be done. Nodes not
		 * marked as 'dirty' can be skipped over during <code>update()</code>.
		 * 
		 * @default	false
		 */		
		public var invalidate:Boolean = false;

		/**
		 * A flag indicating that the basic positional properties (<code>x</code>, <code>y</code> and <code>rotation</code>)
		 * of this component's <code>displayObject</code> have been updated by
		 * a paired <code>Spatial</code> component.
		 * 
		 * @default	false
		 */		
		public var syncedWithSpatial:Boolean = false;

		/**
		 * When set, this flag indicates that the <code>displayObject</code>
		 * should not be modified by a paired <code>Spatial</code> component.
		 * It functions as a "Do Not Disturb" sign.
		 * <p>Clearing the flag allows
		 * the <code>displayObject's</code> basic positional properties to
		 * be overwritten by a paired <code>Spatial</code> component.</p>
		 * 
		 * @default	false
		 */		
		public var isStatic:Boolean = false;

		/**
		 * When set, this flag indicates that the <code>displayObject's</code>
		 * <code>visible</code> should be overwritten. This overwriting takes place
		 * regardless of the setting of <code>isStatic</code> unless the owning
		 * <code>Entity</code> is sleeping and not paused.
		 * 
		 * @default	true
		 */		
		public var visible:Boolean = true;

		/**
		 * When set, this flag indicates that the <code>displayObject's</code>
		 * <code>alpha</code> should be overwritten. This overwriting takes place
		 * regardless of the setting of <code>isStatic</code>.
		 * 
		 * @default	1.0
		 */		
		public var alpha:Number = 1;
		
		/**
		 * Flag indicates that the <code>displayObject</code> is still in need of bitmap caching.
		 * We use this flag so that we are able to stagger the bitmap caching, 
		 * as multiple calls in a singel frame was cause crashes on mobile.
		 * 
		 * @default	false
		 */
		public var needsCaching:Boolean = false
		
		/**
		 * Indicates if <code>displayObject</code> has been cached as Bitmap.
		 */
		public function get isCached():Boolean { return displayObject.cacheAsBitmap; }

		/////////////////////////////// BITMAPPING ///////////////////////////////
		
		/**
		 * Convert displayObject's content into Bitmaps.
		 * Stores BitmapData for cleanup.
		 * @param quality
		 */
		public function convertToBitmaps( quality:Number = 1):void
		{
			if( displayObject )
			{
				if( _bitmapDatas == null )
				{
					_bitmapDatas = new Vector.<BitmapData>();
				}
				else
				{
					disposeNestedBitmaps()
				}
				BitmapUtils.convertContainer(displayObject, quality, this._bitmapDatas);
			}
		}
		
		public function disposeBitmaps():void
		{
			disposeNestedBitmaps();
			if( bitmapWrapper )
			{
				bitmapWrapper.destroy();
			}
		}
		
		/**
		 * Stores BitmapData created during conversion to Bitmaps.
		 */
		private var _bitmapDatas:Vector.<BitmapData>;
		
		private function disposeNestedBitmaps():void
		{
			if( _bitmapDatas )
			{
				for (var i:int = 0; i < _bitmapDatas.length; i++) 
				{
					_bitmapDatas[i].dispose();
				}
			}
		}

		/////////////////////////////// LAYERING ///////////////////////////////

		/**
		 * Forces the component's <code>displayObject</code> to the bottom of its container's display list,
		 * causing it to appear behind all other children of the container. 
		 * 
		 */		
		public function moveToBack():void
		{
			if ( displayObject )
			{
				if ( container )
				{
					container.setChildIndex( displayObject, 0 );
				}
				else
				{
					displayObject.parent.setChildIndex( displayObject, 0 );
				}
			}
		}
		
		/**
		 * Forces the component's <code>displayObject</code> to the bottom of its container's display list,
		 * causing it to appear behind all other children of the container. 
		 * 
		 */		
		public function setIndex( index:int ):void
		{
			if ( displayObject )
			{
				if ( container )
				{
					container.setChildIndex( displayObject, index );
				}
				else
				{
					displayObject.parent.setChildIndex( displayObject, index );
				}
			}
		}
		
		/**
		 * Forces the component's <code>displayObject</code> to the bottom of its container's display list,
		 * causing it to appear behind all other children of the container. 
		 * 
		 */		
		public function getIndex():Number
		{
			if ( displayObject )
			{
				if ( container )
				{
					return container.getChildIndex( displayObject );
				}
				else
				{
					return  displayObject.parent.getChildIndex( displayObject );
				}
			}
			return NaN;
		}
		
		/**
		 * Forces the component's <code>displayObject</code> to the top of its container's display list,
		 * causing it to appear in front of all other children of the container. 
		 * 
		 */		
		public function moveToFront():void
		{
			if ( displayObject )
			{
				if ( container )
				{
					container.setChildIndex( displayObject, container.numChildren-1 );
				}
				else
				{
					displayObject.parent.setChildIndex( displayObject, displayObject.parent.numChildren-1 );
				}
			}
		}
		
		public function refresh( displayObject:DisplayObject = null, container:DisplayObjectContainer = null ):void
		{
			if( displayObject != null )
			{	
				this.displayObject = displayObject;
			}
			if ( container != null )
			{
				setContainer( container );
			}
		}
		
		/**
		 * Sets container and adds <code>displayObject</code> as its child.
		 * @param	container
		 */
		public function setContainer( container:DisplayObjectContainer = null, index:int = -1):void
		{
			if( container != null )
			{
				this.container = container;
				if ( displayObject != null )
				{
					if ( displayObject.parent != container )
					{
						if( index > -1 )
						{
							this.container.addChildAt( displayObject, index )
						}
						else
						{
							this.container.addChild( displayObject );
						}
					}
				}
			}
			else
			{
				if ( displayObject.parent )
				{
					this.container = displayObject.parent;
					
					if( index > -1 )
					{
						this.container.setChildIndex( displayObject, index )
					}
				}
			}
		}
		
		/**
		 * Quick and dirty rollover boolean, does not account for shape 
		 * @return True if the pointer is within <code>displayObject's</code> bounding rect.
		 */		
		public function isUnderPointer():Boolean 
		{
			var myRect:Rectangle = displayObject.getRect(displayObject);
			return myRect.contains(displayObject.mouseX, displayObject.mouseY);
		}
		
		/**
		 * Get the display object specified by the InstanceData's instancePath.
		 * @param	displayObject
		 * @return
		 */
		/*
		public function getInstance( instanceName:String ):DisplayObject
		{		
			private function parseInstanceName( instanceName:String, instancePath:Vector.<String>, startIndex:int = 0 ):void
			{
				var subInstance:String;
				var endIndex:int = instanceName.indexOf( ".", startIndex );
				
				if ( endIndex > 0 )
				{
					subInstance = instanceName.substring( startIndex, endIndex );
					instancePath.push( subInstance );
					parseInstanceName( instanceName, instancePath, endIndex + 1 ); 
				}
				else
				{
					subInstance = instanceName.substring( startIndex );
					instancePath.push( subInstance );
				}
			}
			
			
			
			for ( var i:int = 0; i < _instancePath.length; i++ )
			{
				instanceName = _instancePath[i];
				if ( instanceClip is MovieClip )
				{
					instanceClip = MovieClip(instanceClip).getChildByName( instanceName );
				}
				else
				{
					trace("Error :: InstanceData :: getInstanceFrom :: invalid instanceName : " + instanceName );
					return null;
				}
			}
			return instanceClip;
		}
		*/

		
		/**
		 * Switch out the current displayObject with the one passed.
		 * Maintains layer order and parentage. 
		 * @param newDisplayObject
		 * 
		 */
		public function swapDisplayObject( newDisplayObject:DisplayObjectContainer ):void
		{
			var index:int = container.getChildIndex( this.displayObject );
			container.removeChildAt( index );
			if( index < container.numChildren )
			{
				container.addChildAt( newDisplayObject, index );
			}
			else
			{
				container.addChild( newDisplayObject );
			}
			this.displayObject = newDisplayObject;
			this.invalidate = true;
		}
		
		/**
		 * Wraps the displayObject in a Sprite.
		 * This is necessary when a loaded swf with no internal Symbols is set as the displayObject. 
		 * @return - returns the Sprite that will wraps the displayObject.
		 */
		public function wrapDisplayObject():Sprite
		{
			var index:int = container.getChildIndex( this.displayObject );
			container.removeChildAt( index );
			var wrapper:Sprite = new Sprite();
			wrapper.addChild( DisplayObjectContainer(this.displayObject) );
			if( index < container.numChildren )
			{
				container.addChildAt( wrapper, index );
			}
			else
			{
				container.addChild( wrapper );
			}
			this.container = wrapper;
			return wrapper;
		}
		
		public var interactive:Boolean = false;
		public var bitmapWrapper:BitmapWrapper;
		
		public function disableMouse():void
		{
			displayObject.mouseEnabled = false;
			displayObject.mouseChildren = false;
		}
		
		public function enableMouse():void
		{
			displayObject.mouseEnabled = true;
			displayObject.mouseChildren = true;
		}
	}
}
