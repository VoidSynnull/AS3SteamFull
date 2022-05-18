package game.util
{
	import flash.display.MovieClip;
	
	import engine.ShellApi;

	public class SceneMergeUtils
	{
		public static function offsetPosition(offsetX:Number, offsetY:Number, shellApi:ShellApi, file:*, url:String, originalFile:*, originalUrl:String):Boolean
		{
			if(url.indexOf("npcs.xml") > -1)
			{
				for each (var position_node:XML in file..position)
				{
					position_node.x = parseInt(position_node.x) + offsetX;
					position_node.y = parseInt(position_node.y) + offsetY;
				}
			}
			else if(url.indexOf(".swf") > -1)
			{
				if(url.indexOf("interactive.swf") > -1 || url.indexOf("hits.swf") > -1)
				{
					if(!originalFile)
					{
						if(url.indexOf("interactive.swf") > -1)
						{
							originalUrl = originalUrl.replace("interactive.swf", "hits.swf");
						}
						else if(url.indexOf("hits.swf") > -1)
						{
							originalUrl = originalUrl.replace("hits.swf", "interactive.swf");
						}
						
						originalFile = shellApi.getFile(originalUrl);
					}
					
					var nextChild:MovieClip;
					var addedChild:MovieClip;
					// if ad is aligned bottom center then adjust
					
					//var topPos:int = originalFile.numChildren;
					for (var i:int = file.numChildren-1; i != -1; i--)
					{
						nextChild = file.getChildAt(i);						
						if(nextChild.name == "bitmapHits")
						{
							addedChild = originalFile.bitmapHits.addChild(file.bitmapHits);
						}
						else
						{
							/*
							if ( topPos == originalFile.numChildren)
								addedChild = originalFile.addChild(nextChild);
							else
								addedChild = originalFile.addChildAt(nextChild, topPos);
							originalFile[addedChild.name] = addedChild;
							*/
							addedChild = originalFile.addChild(nextChild);
							originalFile[addedChild.name] = addedChild;
						}
						// set added child alpha to original alpha
						//addedChild.alpha = nextChild.alpha;
						addedChild.x += offsetX;
						addedChild.y += offsetY;
					}
					
					return(false);
				}
				else
				{
					file.x += offsetX;
					file.y += offsetY;
				}
			}
			
			return(true);
		}
	}
}