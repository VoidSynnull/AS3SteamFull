package game.systems.ui
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.ui.MouseCursorData;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	
	import game.components.entity.Parent;
	import game.components.ui.CursorLabel;
	import game.components.ui.NavigationArrow;
	import game.data.ui.ToolTipData;
	import game.data.ui.ToolTipType;
	import game.nodes.ui.CursorLabelNode;
	import game.nodes.ui.CursorNode;
	import game.nodes.ui.CursorToolTipNode;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class CursorSystem extends ListIteratingSystem
	{
		public function CursorSystem(toolTipData:Dictionary)
		{
			super(CursorNode, updateNode);
			_toolTipData = toolTipData;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_cursorToolTips = systemManager.getNodeList(CursorToolTipNode);
			_cursorLabelNodes = systemManager.getNodeList(CursorLabelNode);
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(CursorToolTipNode);
			systemManager.releaseNodeList(CursorLabelNode);
			_cursorToolTips = null;
			_cursorLabelNodes = null;
			super.removeFromEngine(systemManager);
		}
		
		private function updateNode(node:CursorNode, time:Number):void
		{
			var currentType:String = node.cursor.defaultType;
			var label:String = "";			
			if(node.input.lockInput || node.input.lockPosition)
			{
				currentType = ToolTipType.WAIT;
			}
			else
			{
				var cursorToolTipNode:CursorToolTipNode;
				var parent:Parent;
				var display:Display;

				for(cursorToolTipNode = _cursorToolTips.head; cursorToolTipNode; cursorToolTipNode = cursorToolTipNode.next)
				{	
					if(EntityUtils.sleeping(cursorToolTipNode.entity))
					{
						continue;
					}
					
					if(cursorToolTipNode.toolTipActive.useParentDisplayForHitTest)
					{
						if(cursorToolTipNode.parent != null)
						{
							display = cursorToolTipNode.parent.parent.get(Display);
						}
						else
						{
							display = cursorToolTipNode.display;
						}
					}
					else
					{
						display = cursorToolTipNode.display;
					}
					
					if(display != null && display.displayObject != null)
					{
						
						
						if(display.displayObject.hitTestPoint(node.spatial.x * super.group.shellApi.viewportScale, node.spatial.y * super.group.shellApi.viewportScale))
						{
							currentType = cursorToolTipNode.toolTip.type;
							
							if(!DataUtils.isNull(cursorToolTipNode.toolTip.label))
							{
								label = cursorToolTipNode.toolTip.label;
							}
							break;
						}
					}
				}
			}
			
			node.cursor.type = currentType;
			
			var currentData:ToolTipData = _toolTipData[node.cursor.type];
			var cursorLabelNode:CursorLabelNode = _cursorLabelNodes.head;
			
			if(cursorLabelNode != null && cursorLabelNode.cursorLabel.textField.text != label)
			{
				var cursorLabel:CursorLabel = cursorLabelNode.cursorLabel;
				
				cursorLabel.textField.text = label.toUpperCase();
				cursorLabel.textField.x = -cursorLabel.textField.width * .5;
				cursorLabel.textField.y = -cursorLabel.textField.height * .5 + cursorLabel.offsetY;
			}
			
			if ((node.cursor._invalidate) || (_forceValidation))
			{
				_forceValidation = false;
				var sheet:Vector.<BitmapData> = node.spriteSheet.retrieve(node.cursor.type);
				var toolTipData:ToolTipData = _toolTipData[node.cursor.type];
				if(toolTipData == null)
					return;
				if(sheet == null)
				{
					super.group.shellApi.loadFile(super.group.shellApi.assetPrefix + toolTipData.asset, cursorLoaded, node, currentType);
				}
				else if(!currentData.transparentOnUp)
				{
					setNativeCursor(node, sheet);
				}
			}
			
			if(currentData.transparentOnUp)
			{
				if(node.cursor.transparent == node.input.inputActive || node.cursor._invalidate)
				{
					node.cursor.transparent = !node.input.inputActive;
					
					var currentSheet:Vector.<BitmapData>;
					
					if(node.cursor.transparent)
					{
						currentSheet = node.spriteSheet.retrieve(node.cursor.type + "_transparent");
					}
					else
					{
						currentSheet = node.spriteSheet.retrieve(node.cursor.type);
					}
					
					if(currentSheet)
					{			
						setNativeCursor(node, currentSheet);
					}
					else
					{
						node.display.visible = true;
						
						if(node.cursor.transparent)
						{
							node.display.alpha = .4;
						}
						else
						{
							node.display.alpha = 1;
						}
					}
				}
			}
			
			node.cursor._invalidate = false;
		}
		
		private function setNativeCursor(node:CursorNode, sheet:Vector.<BitmapData>):void
		{
			var cursorData:MouseCursorData = node.cursor._cursorData;
			var toolTipData:ToolTipData = _toolTipData[node.cursor.type];
			
			cursorData.data = sheet;
			cursorData.hotSpot = toolTipData.hotSpot;
			
			Mouse.registerCursor("customCursor", cursorData);
			Mouse.cursor = "customCursor";
			
			if(node.display.container.contains(node.display.displayObject))
			{
				node.display.container.removeChild(node.display.displayObject);
			}
			
			Mouse.show();
		}
		
		private function cursorLoaded(clip:MovieClip, node:CursorNode, loadedType:String):void
		{
			if((node.cursor == null) || node.cursor.type != loadedType || clip == null)
			{
				return;
			}
			
			var toolTipData:ToolTipData = _toolTipData[node.cursor.type];
			
			if(toolTipData.nativeCursor && !this.neverUseNativeCursors)
			{
				// Pass the cursor bitmap to a BitmapData Vector
				var bitmapDatas:Vector.<BitmapData> = new Vector.<BitmapData>(clip.totalFrames, true);
				var bitmapData:BitmapData;
				
				for(var n:int = 0; n < clip.totalFrames; n++)
				{
					clip.gotoAndStop(n + 1);
					bitmapData = new BitmapData(MAX_CURSOR_WIDTH, MAX_CURSOR_HEIGHT, true, 0x00000000);
					bitmapData.draw(clip);
					bitmapDatas[n] = bitmapData;
				}
				
				node.cursor._cursorData.frameRate = CURSOR_FRAMERATE;
				
				node.spriteSheet.add(bitmapDatas, node.cursor.type);
				
				if(toolTipData.transparentOnUp)
				{
					var alphaTransform:ColorTransform = new ColorTransform();
					alphaTransform.alphaMultiplier = .4; 
					var rec:Rectangle;
					
					bitmapDatas = new Vector.<BitmapData>(clip.totalFrames, true);
					
					for(n = 0; n < clip.totalFrames; n++)
					{
						clip.gotoAndStop(n + 1);
						bitmapData = new BitmapData(MAX_CURSOR_WIDTH, MAX_CURSOR_HEIGHT, true, 0x00000000);
						rec = new Rectangle(0, 0, bitmapData.width, bitmapData.height);
						bitmapData.draw(clip);
						bitmapData.colorTransform(rec, alphaTransform);
						bitmapDatas[n] = bitmapData;
					}

					node.spriteSheet.add(bitmapDatas, node.cursor.type + "_transparent");
				}

				node.spatialOffset.x = 0;
				node.spatialOffset.y = 0;
				
				setNativeCursor(node, bitmapDatas);
			}
			else
			{
				if(node.display.container.contains(node.display.displayObject))
				{
					node.display.container.removeChild(node.display.displayObject);
				}
				node.display.displayObject = Sprite(node.display.container.addChild(clip));
				node.display.displayObject.mouseChildren = false;
				node.display.displayObject.mouseEnabled = false;
				node.display.visible = true;
				node.spatialOffset.x = -toolTipData.hotSpot.x;
				node.spatialOffset.y = -toolTipData.hotSpot.y;
				
				// reset the cursor display here so it is instantly updated and doesn't cause a 'jump' to the correct opacity and position offset.
				if(!toolTipData.transparentOnUp)
				{
					node.display.alpha = 1;
				}
				
				if(toolTipData.dynamic)
				{
					// for complex cursors like navigation arrow let it's system show it when ready.
					node.display.visible = false;
				}
				
				// hide this until the rendersystem picks it up so we don't see it 'flash' in the default state.
				clip.visible = false;
				clip.x = node.spatial.x - toolTipData.hotSpot.x;
				clip.y = node.spatial.y - toolTipData.hotSpot.y;
				
				if(clip.totalFrames > 1)
				{
					TimelineUtils.convertClip(MovieClip(node.display.displayObject), null, node.entity);
				}
				Mouse.cursor = MouseCursor.AUTO;
				Mouse.hide();
			}
			
			if(node.cursor.type == ToolTipType.NAVIGATION_ARROW)
			{
				if(!node.entity.has(NavigationArrow))
				{
					node.entity.add(new NavigationArrow());
				}
			}
			else
			{
				if(node.entity.has(NavigationArrow))
				{
					node.entity.remove(NavigationArrow);
					node.spatial.rotation = 0;
				}
			}
		}
		
		public function forceValidation():void
		{
			_forceValidation = true;
		}
		
		public var neverUseNativeCursors:Boolean = false;
		
		private var _cursorToolTips:NodeList;
		private var _cursorLabelNodes:NodeList;
		private var _toolTipData:Dictionary;
		private const CURSOR_FRAMERATE:uint = 32;
		private const MAX_CURSOR_WIDTH:uint = 32;
		private const MAX_CURSOR_HEIGHT:uint = 32;
		private var _forceValidation:Boolean = false;
	}
}