package game.data.animation.entity
{
	import fl.motion.Motion;
	import fl.motion.Source;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.RigAnimationData;
	import game.data.animation.entity.PartAnimationData;
	import game.data.animation.FrameData;
	import game.data.animation.FrameEvent;
	import game.data.animation.TimelineData;
	import game.util.DataUtils;
	
	
	/**
	 * 
	 */
	public class TimelineParser
	{	
		/**
		 * Create frame data from xml
		 * @param	xml
		 * @param	duration
		 * @return
		 */
		public static function parseXML( xml:XML, duration:int ):Vector.<FrameData>
		{
			// Parse frame events
			var frameList:XMLList = xml.children() as XMLList
			
			var frames:Vector.<FrameData> = new Vector.<FrameData>();
			var frameData:FrameData;
			var frameEvent:FrameEvent;
			var eventList:XMLList;
			var paramsXML:XMLList;
			var arg:*;
			
			// create a frameData for every frame
			var i:int = 0;
			for (i; i < duration; i++)
			{
				frameData = new FrameData();
				frameData.index = i;
				frames.push(frameData);
			}
			
			// parse frame events and add to frame data
			var j:int;
			var k:int;
			i = 0;
			for (i; i < frameList.length(); i++)
			{
				var index:Number = Number( frameList[i].attribute("index"));
				frameData = frames[index];
				
				if ( frameList[i].attribute("label") )
				{
					frameData.label = String( frameList[i].attribute("label") );
				}
				
				eventList = frameList[i].children() as XMLList;
				
				j = 0;
				for (j; j < eventList.length(); j++)
				{
					frameEvent = new FrameEvent();
					frameEvent.args = new Array();
					
					if ( eventList[j].attribute("method") )
					{
						frameEvent.type = DataUtils.getString( eventList[j].attribute("method") );
					}
					
					paramsXML = eventList[j].children() as XMLList;
					
					k = 0
					for (k; k < paramsXML.length(); k++)
					{
						arg = paramsXML[k];
						if ( !isNaN(Number(arg)) )
						{
							frameEvent.args.push( DataUtils.getNumber(arg));
						}
						else
						{
							frameEvent.args.push( DataUtils.getString(arg));
						}
					}
					
					frameData.addEvent( frameEvent );
				}
				frames[index] = frameData;
			}
			return frames;
		}
	}
}