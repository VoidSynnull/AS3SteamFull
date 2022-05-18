package game.systems.ui
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Engine;
	
	import game.components.ui.ProgressBar;
	import game.nodes.ui.ProgressBarNode;
	import game.systems.GameSystem;
	
	public class ProgressBarSystem extends GameSystem
	{
		public function ProgressBarSystem()
		{
			super(ProgressBarNode, updateNode, nodeAdded);
		}
		
		private function nodeAdded(node:ProgressBarNode):void
		{
			var progressBar:ProgressBar = node.progressBar;
			var barDisplay:DisplayObjectContainer = node.display.displayObject[progressBar.barAsset];
			
			progressBar.barMaxScaleX = barDisplay.scaleX;
			if(barDisplay.scaleX != progressBar.barMaxScaleX * progressBar.percent)
			{
				barDisplay.scaleX = progressBar.barMaxScaleX * progressBar.percent;
			}
		}
		
		private function updateNode(node:ProgressBarNode, time:Number):void
		{
			var progressBar:ProgressBar = node.progressBar;
			var barDisplay:DisplayObjectContainer = node.display.displayObject[progressBar.barAsset];
			
			if(progressBar.sourceComponent != null)
			{
				var sourceValue:Number = progressBar.sourceComponent[progressBar.sourceProperty];
				progressBar.percent = (progressBar.range - sourceValue) / progressBar.range;
			}
			
			if(progressBar.percent > progressBar.range)
			{
				progressBar.percent = progressBar.range;
			}
			else if(progressBar.percent < 0)
			{
				progressBar.percent = 0;
			}
			
			var adjustedScaleX:Number = progressBar.barMaxScaleX * progressBar.percent;
			if(barDisplay.scaleX != adjustedScaleX)
			{
				if(Math.abs(barDisplay.scaleX - adjustedScaleX) > progressBar.scaleRate)
				{
					if(barDisplay.scaleX > adjustedScaleX)
					{
						barDisplay.scaleX -= progressBar.scaleRate;
					}
					else if(barDisplay.scaleX < adjustedScaleX)
					{
						barDisplay.scaleX += progressBar.scaleRate;
					}
				}
				else
				{
					barDisplay.scaleX = adjustedScaleX;
				}
				
				if(node.display.alpha < 1)
				{
					node.display.alpha += .1;
				}
			}
			else if(progressBar.hideWhenInactive && node.display.alpha > 0)
			{
				progressBar.hideWaitTime += time;
				
				if(progressBar.hideWaitTime >= progressBar.hideWait)
				{
					if(node.display.alpha > 0)
					{
						node.display.alpha -= .1;
					}
					
					if(node.display.alpha <= 0)
					{
						progressBar.hideWaitTime = 0;
					}
				}
				else if(node.display.alpha < 1)
				{
					node.display.alpha += .1;
				}
			}
			if(progressBar.reset == true){
				barDisplay.scaleX = 0;
				progressBar.reset = false;
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ProgressBarNode);
			super.removeFromEngine(systemManager);
		}
	}
}
