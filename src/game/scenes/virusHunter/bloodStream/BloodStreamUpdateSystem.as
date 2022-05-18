package game.scenes.virusHunter.bloodStream
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	import game.data.display.BitmapWrapper;
	import game.systems.GameSystem;
	import game.util.DisplayUtils;
	import game.util.Utils;
	
	public class BloodStreamUpdateSystem extends GameSystem
	{
		public function BloodStreamUpdateSystem()
		{
			super(BloodStreamUpdateNode, updateNode);
		}
		
		public function updateNode(node:BloodStreamUpdateNode, time:Number):void
		{
			var update:BloodStreamUpdate = node.bloodStreamUpdate;
			
			update.time += 0.05 * 30 * time;
			update.offsetX = 50 * Math.sin(update.time);
			update.offsetY = 50 * Math.sin(update.time * 0.5);
			
			var display:DisplayObject = node.display.displayObject;
			
			var shading:DisplayObject = display[update.shadingContainer];
			shading.x = update.offsetX;
			shading.y = update.offsetY;
			
			display.x += (-display.parent.mouseX - display.x) / 3 * time;
			display.y += (-display.parent.mouseY - display.y) / 3 * time;
			
			if(Math.abs(display.x) > 140) display.x = display.x > 0 ? 140 : -140;
			if(Math.abs(display.y) > 140) display.y = display.y > 0 ? 140 : -140;
			
			update.segmentWait += time;
			if(update.segmentWait > 0.5)
			{
				update.segmentWait -= 0.5;
				this.createSegment(node);
			}
			
			if (Math.random() < 0.05)
			{
				this.createBloodCell(node);
			}
			
			var wrapper:BitmapWrapper;
			var sprite:Sprite;
			var i:int;
			
			if(update.engaged)
			{
				update.velocityZ += 200 * time;
				
				if(update.velocityZ > 400) update.velocityZ = 400;
			}
			
			for(i = 0; i < update.bloodCells.length; i++)
			{
				var bloodCell:BloodCell = update.bloodCells[i];
				sprite = bloodCell.wrapper.sprite;
				
				sprite.rotation += bloodCell.rotation * 30 * time;
				bloodCell.time += bloodCell.speed * 30 * time;
				
				sprite.scaleX = Math.sin(bloodCell.time);
				if(Math.abs(sprite.scaleX) < 0.2)
				{
					sprite.scaleX = 0.2;
				}
				
				sprite.z -= update.velocityZ * time;
				if (sprite.z < -40)
				{
					sprite.alpha -= 0.2 * 30 * time;
					if (sprite.alpha <= 0)
					{
						update.bloodCells.splice(i, 1);
						i--;
						
						sprite.parent.removeChild(sprite);
						bloodCell.wrapper.destroy();
					}
				}
				else
				{
					sprite.alpha += 0.05 * 30 * time;
				}
			}
			
			for(i = 0; i < update.segments.length; i++)
			{
				wrapper = update.segments[i];
				sprite = wrapper.sprite;
				
				sprite.z -= update.velocityZ * time;
				if (sprite.z < -40)
				{
					sprite.alpha -= 0.2 * 15 * time;
					if (sprite.alpha <= 0)
					{
						update.segments.splice(i, 1);
						i--;
						sprite.parent.removeChild(sprite);
						wrapper.destroy();
					}
				}
				else
				{
					sprite.alpha += 0.05 * 60 * time;
				}
			}
		}
		
		/**
		 * Bitmaps a blood cell clip in the content clip of ship_controls.swf. Trying to avoid constant loading.
		 */
		private function createBloodCell(node:BloodStreamUpdateNode):void
		{
			var bloodCell:BloodCell = new BloodCell();
			
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite(node.bloodStreamUpdate.bloodCell);
			node.bloodStreamUpdate.bloodCells.push(bloodCell);
			bloodCell.wrapper = wrapper;
			
			node.display.displayObject[node.bloodStreamUpdate.bloodCellContainer].addChildAt(wrapper.sprite, 0);
			
			var shading:DisplayObject = node.display.displayObject[node.bloodStreamUpdate.shadingContainer];
			wrapper.sprite.x 		= shading.x + Utils.randNumInRange(-100, 100);
			wrapper.sprite.y 		= shading.y + Utils.randNumInRange(-100, 100);
			wrapper.sprite.alpha 	= 0;
			wrapper.sprite.rotation = Math.random() * 360;
			
			bloodCell.time 		= Math.random() * 2 * Math.PI;
			bloodCell.speed 	= Math.random() * 0.1 + 0.05;
			bloodCell.rotation 	= Math.random() * 4 - 2;
			
			wrapper.sprite.z = 200;
		}
		
		/**
		 * Bitmaps a segment clip in the content clip of ship_controls.swf. Trying to avoid constant loading.
		 */
		private function createSegment(node:BloodStreamUpdateNode):void
		{
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite(node.bloodStreamUpdate.segment);
			node.bloodStreamUpdate.segments.push(wrapper);
			
			node.display.displayObject[node.bloodStreamUpdate.segmentContainer].addChildAt(wrapper.sprite, 0);
			
			var shading:DisplayObject = node.display.displayObject[node.bloodStreamUpdate.shadingContainer];
			wrapper.sprite.x 		= shading.x;
			wrapper.sprite.y 		= shading.y;
			wrapper.sprite.alpha 	= 0;
			wrapper.sprite.rotation = Math.random() * 360;
			
			wrapper.sprite.z = 100;
		}
		
		/*private function loadSegment(node:BloodStreamUpdateNode):void
		{
			var group:DisplayGroup = this.group as DisplayGroup;
			group.shellApi.loadFile(group.shellApi.assetPrefix + group.groupPrefix + "segment.swf", partLoaded, node, false);
		}
		
		private function partLoaded(clip:MovieClip, node:BloodStreamUpdateNode, isBloodCell:Boolean):void
		{
			if(isBloodCell)
			{
				clip.isBloodCell = true;
				clip.x = Utils.randNumInRange(-50, 50);
				clip.y = Utils.randNumInRange(-50, 50);
				node.display.displayObject[node.bloodStreamUpdate.bloodCells].addChildAt(clip, 0);
			}
			else
			{
				clip.isBloodCell = false;
				var shading:DisplayObject = node.display.displayObject[node.bloodStreamUpdate.shadingContainer];
				clip.x = shading.x;
				clip.y = shading.y;
				
				clip.scaleX = clip.scaleY = 0.5;//Math.random() * 0.25 + 0.75;
				
				node.display.displayObject[node.bloodStreamUpdate.segments].addChildAt(clip, 0);
			}
			
			//Real values
			//clip.z 			= 1200;
			clip.alpha 		= 0;
			clip.rotation 	= Math.random()*360;
			//clip.scaleX 	= clip.scaleY = Math.random() * 0.25 + 0.75;
			clip.cacheAsBitmap = true;
			
			//Added?
			clip.velocityZ = 0.3;
			clip.t 		= Math.random() * 2 * Math.PI;
			clip.tSpeed = Math.random() * 0.1 + 0.05;
			clip.vr 	= Math.random() * 4 - 2;
			//node.bloodStreamUpdate.parts.push(clip);
		}*/
			/*
			if (engaged) {
				velocityZ -= 0.8;
			}
			
			var absVelocityZ:Number = Math.abs(velocityZ);
			wait += absVelocityZ*time;
			if (wait > 15) {
				addSegment();
				wait = 0;
			}
			if (Math.random() < absVelocityZ*0.005) {
				addBloodCell();
			}
			
			for (i=0; i<updateArray.length; i++) {
				var clip:MovieClip = updateArray[i];
				clip.z += velocityZ*30*time;
				
				if (clip.isBloodCell) {
					clip.t += clip.tSpeed*30*time;
					clip.scaleX = Math.sin(clip.t);
					if (Math.abs(clip.scaleX) < 0.2) {
						clip.scaleX = 0.2;
					}
					clip.rotation += clip.vr*30*time;
				}
				
				if (clip.z < endZ) {
					clip.alpha -= 0.2*30*time;
					if (clip.alpha <= 0) {
						updateArray.splice(i, 1);
						clip.parent.removeChild(clip);
					}
				}
				else if (clip.alpha < 1) {
					clip.alpha += 0.05*30*time;
				}
			}
			
			startT += 0.05*30*time;
			startX = midX + 100*Math.sin(startT);
			startY = midY + 100*Math.sin(startT*0.5);
			
			//shading.x = startX;
			//shading.y = startY;
			
			//var posX:Number = _mouse.mouseX - _container.x
			
			_container.x += ( (midX - (_mouse.mouseX) - _container.x)/8 )*30*time;
			_container.y += ( (midY - (_mouse.mouseY) - _container.y)/8 )*30*time;
		}
		
		/*private function shadingLoaded(clip:MovieClip):void
		{
			_container.addChildAt(clip, 0);
			clip.x = startX;
			clip.y = startY;
			clip.z = startZ;
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			clip.cacheAsBitmap = true;
			shading = clip;
		}*/
		
		// loaded callback gets the loaded file as its first parameter, followed by any extra arguments passed in.
		/*private function partLoaded(clip:MovieClip, isBloodCell:Boolean):void
		{
			if (isBloodCell) {
				//bloodCells.addChildAt(clip, 0);
				clip.isBloodCell = true;
				clip.x = startX + Math.random()*gameHeight/2 - gameHeight/4;
				clip.y = startY + Math.random()*gameHeight/2 - gameHeight/4;
			}
			else {
				//segments.addChildAt(clip, 0);
				clip.isBloodCell = false;
				clip.x = startX;
				clip.y = startY;
			}
			clip.z = startZ;
			clip.alpha = 0;
			clip.t = Math.random()*2*Math.PI;
			clip.tSpeed = Math.random()*0.1 + 0.05;
			clip.rotation = Math.random()*360;
			clip.vr = Math.random()*4 - 2;
			clip.scaleX = clip.scaleY = Math.random()*0.25 + 0.75;
			clip.cacheAsBitmap = true;
			updateArray.push(clip);
		}
		
		private function addSegment():void
		{
			_group.shellApi.loadFile(_group.shellApi.assetPrefix + _group.groupPrefix + "segment.swf", partLoaded, false);
		}
		
		private function addBloodCell():void
		{
			_group.shellApi.loadFile(_group.shellApi.assetPrefix + _group.groupPrefix + "bloodCell.swf", partLoaded, true);
		}*/
	}
}