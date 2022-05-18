package game.ui.toolTips
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.group.UIView;
	
	import game.components.ui.ToolTip;
	import game.data.display.BitmapWrapper;
	import game.data.text.TextStyleData;
	import game.data.ui.ToolTipData;
	import game.util.DataUtils;
	import game.util.DisplayPositions;
	import game.util.PlatformUtils;
	import game.util.TextUtils;
	
	/**
	 * ...
	 * @author gabriel/billy
	 * 
	 * Tooltip view.
	 */
	
	public class ToolTipView extends UIView
	{
		public function ToolTipView(container:DisplayObjectContainer = null, toolTipData:Dictionary = null)
		{
			super(container);
			_toolTipData = toolTipData;
		}
		
		override public function destroy():void
		{						
			super.destroy();
		}		
				
		public function loadToolTipAsset(toolTip:Entity):void
		{
			var toolTipComponent:ToolTip = toolTip.get(ToolTip);
			var toolTipData:ToolTipData = _toolTipData[toolTipComponent.type];
			
			toolTipComponent.loadingAsset = true;
			super.shellApi.loadFile(super.shellApi.assetPrefix + toolTipData.asset, toolTipLoaded, toolTip);
		}
		
		private function toolTipLoaded(displayObject:DisplayObjectContainer, toolTip:Entity):void
		{
			// RLH: fixes error when deleting door entity (tooltip doesn't seem to get removed with it)
			if (toolTip.get(Display) == null)
			{
				trace( this," :: ERROR :: toolTipLoaded : failed to retrive asset." );
				return;
			}
			
			toolTip.get(Display).displayObject = super.groupContainer.addChild(displayObject);
			// tooltips should be hidden initially and only revealed when the player is close enough to them.
			toolTip.get(Display).alpha = 0;
			
			var toolTipComponent:ToolTip = toolTip.get(ToolTip);
			toolTipComponent.loadingAsset = false;
			
			// TODO :: If tool tip icon animated should probably run througn animation system?
			
			var spatialOffset:SpatialOffset = toolTip.get(SpatialOffset);
			
			if(spatialOffset == null)
			{
				spatialOffset = new SpatialOffset();
				toolTip.add(spatialOffset);
			}
			
			var spatial:Spatial = toolTip.get(Spatial);
			
			spatialOffset.x -= displayObject.width * .5 * (spatial.scaleX + spatialOffset.scaleX);
			spatialOffset.y -= displayObject.height * .5 * (spatial.scaleY + spatialOffset.scaleY);
			
			// if a label has been given, create label
			if( DataUtils.validString(toolTipComponent.label) )
			{
				addLabel( displayObject, toolTipComponent.label, super.shellApi.textManager.getStyleData( "ui", "tooltip" ), DisplayPositions.TOP_CENTER);
			}
			
			displayObject.mouseEnabled = false;
			displayObject.mouseChildren = false;
			
			/*
			if(displayObject["tf"] == null)
			{
				
				//if(label != null)
				//{
				//var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 14, 0xD5E1FF);
				//addLabel(displayObject, label, labelFormat);
				//}
				
				if(displayObject["label"] != null)
				{
					var labelText:TextField = (displayObject["label"] as TextField);
					labelText.mouseEnabled = false;
					labelText.text = label;
				}
			}
			else
			{
				var tf:TextField = (displayObject["tf"] as TextField);
				tf.mouseEnabled = false;
				tf.text = label;
				
				// adjust for Arrows bg shapes
				var url:String = displayObject.loaderInfo.url
				var horizArrow:Boolean = (url.indexOf ("Left") != -1 || url.indexOf ("Right") != -1) 
				var verticalArrow:Boolean = (url.indexOf ("Down") != -1 || url.indexOf ("Up") != -1) 
				
				var margin:Number =  BASE_TEXT_MARGIN  //+ tf.width / 50 // slightly more margin for large word balloons
				var newBgHeight:Number = tf.textHeight + margin*2
				var newBgWidth:Number =  tf.textWidth + margin*2
				
				if (verticalArrow){
					newBgHeight -= margin * 1.8
				} else if (horizArrow)  {
					newBgWidth -= margin  
				}
				
				displayObject.bg.width = newBgWidth
				displayObject.bg.height = newBgHeight
				var b:Rectangle = displayObject.bg.getBounds (displayObject);
				tf.x = -tf.width/2 
				tf.y = b.top + margin * .78 
				
				var bgArrowPoint:Sprite
				if (verticalArrow)	 {
					bgArrowPoint = displayObject["bgArrowPoint"]
					if (bgArrowPoint) {
						bgArrowPoint.width = newBgWidth + 30 * 2
						bgArrowPoint.y = b.bottom - 3
					}
				} else if (horizArrow) {
					tf.x -= margin * .2
					bgArrowPoint = displayObject["bgArrowPoint"]
					if (bgArrowPoint) {
						bgArrowPoint.height = newBgHeight + 20 * 2
						bgArrowPoint.x = b.left + 1
					}
				}
			}
			*/
		}
		
		public function addLabel(displayObject:DisplayObjectContainer, label:String, style:TextStyleData = null, position:String = "" ):void
		{
			var tf:TextField = new TextField();
			
			if( style ) { TextUtils.applyStyle(style, tf); }
			tf.embedFonts = true
			tf.antiAliasType = AntiAliasType.NORMAL;
			tf.text = label;
			tf.autoSize = TextFieldAutoSize.CENTER;
			
			tf.x = 0;
			tf.y = 0;

			var deltaX:Number = displayObject.width / displayObject.scaleX - tf.width;
			var deltaY:Number = displayObject.height / displayObject.scaleY - tf.height;
			
			tf.x = deltaX * .5;
			tf.y = deltaY * .5;
			
			//refer to position vaue for placement
			if( DisplayPositions.TOP_CENTER )
			{
				tf.y = displayObject.y - tf.height;
			}
			
			// NOTE :: Applying filter after repositioning looks better for some reason. -bard
			tf.filters = [filterMobile];

			if( tf.filters.length > 0 && PlatformUtils.isMobileOS )
			{
				super.convertToBitmapSprite( tf, displayObject, false, 2 );
				tf.filters = null;
			}
			else
			{
				displayObject.addChild(tf);
			}
		}
		
		private var _toolTipData:Dictionary;
		
		
		
		private static const BASE_TEXT_MARGIN:int = 14;
		private var filterMobile:DropShadowFilter = new DropShadowFilter(0, 0, 0xFFFFFF, 1, 3, 3, 12, BitmapFilterQuality.HIGH);
	
	}
}
