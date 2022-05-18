package game.scenes.hub.profile.systems 
{
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.hub.profile.nodes.StickerNode;
	import game.scenes.hub.profile.popups.StickerWallPopup;
	import game.systems.SystemPriorities;
	
	public class StickerDragSystem extends System
	{
		private var _stickers:NodeList;
		private var wall:MovieClip;
		
		private var sticker:StickerNode;
		private var spatial:Spatial;
		private var distX:Number;
		private var distY:Number;
		private var offsetX:Number;
		private var offsetY:Number;
		private var extraOffsetX:Number;
		private var gridDistance:Number = 70;
		private var buffer:Number = 10;
				
		public function StickerDragSystem()
		{
			super._defaultPriority = SystemPriorities.preRender;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_stickers = systemManager.getNodeList( StickerNode );
			wall = StickerWallPopup(super.group).wall as MovieClip;
		}
		
		override public function update( time:Number ):void
		{		
			var bitmap:Bitmap;
			for(sticker = _stickers.head; sticker; sticker = sticker.next)
			{
				if(sticker.sticker.moving){
					spatial = sticker.spatial;
					if(spatial.x > wall.x - buffer && spatial.x < wall.x+wall.width + buffer){
						if(spatial.y > wall.y - buffer && spatial.y < wall.y+wall.height + buffer){
							bitmap = sticker.display.displayObject.getChildAt(0);
							distX = sticker.spatial.x - wall.x;
							distY = sticker.spatial.y - wall.y;
							offsetX = roundToNearest(gridDistance, distX);
							offsetY = roundToNearest(gridDistance, distY);
							if((offsetY/gridDistance) % 2 == 0){
								extraOffsetX = gridDistance/2;
								offsetX += extraOffsetX;
							} else {
								extraOffsetX = 0;
							}
							bitmap.x = (offsetX - distX) - (bitmap.width/2);
							bitmap.y = (offsetY - distY) - (bitmap.height/2);
						}
					}
				}
			}
		}
		
		private function roundToNearest(roundTo:Number, value:Number):Number
		{
			return Math.round(value/roundTo)*roundTo;
		}
				
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( StickerNode );
			_stickers = null;
		}
	}
}




