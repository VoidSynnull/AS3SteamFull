package game.scenes.start.startScreen.systems
{
	import com.greensock.easing.Back;
	
	import flash.text.TextField;
	
	import game.scenes.start.startScreen.nodes.AgeDialNode;
	import game.systems.GameSystem;
	
	public class AgeDialSystem extends GameSystem
	{
		public function AgeDialSystem()
		{
			super(AgeDialNode, updateNode, nodeAdded);
		}
		
		private function updateNode(node:AgeDialNode, time:Number):void
		{
			if(node.dial.refresh)
			{
				node.dial.refresh = false;
				var selectedIndex:int = node.dial.textPool.length/2-1;
				node.dial.current = node.dial.textPool[selectedIndex];
				node.dial.dialChanged.dispatch(node.dial);
				return;
			}
			//If the dial numbers should move up or down...
			if(node.dial.up || node.dial.down)
			{
				if(node.dial.locked)
				{
					return;
				}
				var offset:Number = node.dial.offset / Number(node.dial.textPool.length -1);
				
				if(node.dial.up)//defaultly works out for selcted index
				{
					node.dial.index--;
					if(node.dial.index < 0)
						node.dial.index += node.dial.values.length;
				}
				else
				{
					offset = -offset;
					node.dial.index++;
					if(node.dial.index >= node.dial.values.length) 
						node.dial.index -= node.dial.values.length;
				}
				
				setText(node, node.dial.Displays);
				moveNumbers(node, offset);
			}
		}
		
		/**
		 * Sets the Y position and text String of the off-screen TextField that's moving into view on the dial.
		 */
		private function setText(node:AgeDialNode, index:int):void
		{
			var offscreenText:TextField = node.dial.textPool[index];
			
			var n:Number = node.dial.textPool.length;
			// (n/2) is the half above/below what is currently shown
			// (n-1) is the factor that pooled objects are spaced over the distance offsetY
			var percent:Number = (n/2)/(n-1);
			var displayIndex:int = node.dial.index;
			//have to adjust the offset of whats the next to be displayed depending on
			//direction and the amount of displays visible at a time
			
			var offset:Number = -node.dial.offset * percent;
			
			if(!node.dial.up)
			{
				displayIndex += node.dial.Displays-1;
				offset = node.dial.offset * percent;
			}
			
			if(displayIndex >= node.dial.values.length)
				displayIndex -= node.dial.values.length;
			
			offscreenText.text = ""+node.dial.values[displayIndex];
			var center:Number = node.dial.axis == "x"?-offscreenText.width/2:-offscreenText.height/2;
			offscreenText[node.dial.axis] = center + offset;
			
			trace(offscreenText.text + " : " + displayIndex);
		}
		
		/**
		 * Tweens all TextFields up/down to position themselves in the correct section of the dial.
		 * On completion, the dial needs to "unlock" itself. The dial is locked during Tweening so the numbers don't have
		 * multiple Tweens applied to each other and go haywire.
		 */
		private function moveNumbers(node:AgeDialNode, offset:Number):void
		{
			node.dial.locked	= true;
			
			var duration:Number = 0.25;
			var text:TextField;
			
			for(var i:int = 0; i < node.dial.textPool.length; i++)
			{
				text = node.dial.textPool[i];
				if(node.dial.axis == "y")
				{
					if(i == 0)
						node.tween.to(text, duration, {y:text.y + offset, ease:Back.easeInOut, onComplete:this.unlock, onCompleteParams:[node]});
					else
						node.tween.to(text, duration, {y:text.y + offset, ease:Back.easeInOut});
				}
				else
				{
					if(i == 0)
						node.tween.to(text, duration, {x:text.x + offset, ease:Back.easeInOut, onComplete:this.unlock, onCompleteParams:[node]});
					else
						node.tween.to(text, duration, {x:text.x + offset, ease:Back.easeInOut});
				}
			}
		}
		
		/**
		 * Tween is complete. Buttons can be pressed to move the TextField numbers now.
		 */
		private function unlock(node:AgeDialNode):void
		{
			node.dial.locked = false;
			
			var selectedIndex:int = node.dial.textPool.length/2-1;// selction should be the middle value
			
			if(node.dial.up)
			{
				//remove from the end and add to the front
				node.dial.textPool.insertAt(0,node.dial.textPool.pop());
			}
			else
			{
				//remove from the front and add to the end
				node.dial.textPool.push(node.dial.textPool.removeAt(0));
			}
			
			node.dial.current = node.dial.textPool[selectedIndex];
			
			node.dial.up 	= false;
			node.dial.down 	= false;
			
			node.dial.dialChanged.dispatch(node.dial);
		}
		
		/**
		 * Sets the current TextField to the one inside the dial's blue center area.
		 */
		private function nodeAdded(node:AgeDialNode):void
		{
			node.dial.current = node.dial.textPool[0];
		}
	}
}