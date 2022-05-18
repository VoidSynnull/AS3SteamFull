/**
 * Parses XML with skin data.
 */

package game.data.animation
{	
	import game.util.ClassUtils;
	import game.util.DataUtils;

	public class AnimationSequenceParser
	{			
		public static function parse(xml:XML):AnimationSequence
		{	
			var sequence:AnimationSequence = new AnimationSequence();
			var animXml:XML;
			var animData:AnimationData;
			
			sequence.loop 	= DataUtils.getBoolean(xml.attribute("loop"));
			sequence.random = DataUtils.getBoolean(xml.attribute("random"));
			
			var animXMLs:XMLList = xml.children();
			for (var i:uint = 0; i < animXMLs.length(); i++)
			{	
				animXml 	= animXMLs[i];
				animData 	= new AnimationData();
				
				var duration:Number = DataUtils.getNumber(animXml.attribute("duration"));
				animData.duration = ( isNaN(duration) )?0:duration;
				animData.animClass = AnimationSequenceParser.checkType( DataUtils.getString(animXml) );
				
				sequence.add( animData );
			}
			
			return(sequence);
		}

		public static function checkType( animType:String ):Class
		{
			var animClass:Class;
			
			switch( animType )
			{
				case DEFAULT:
					animClass = null;
					break;
				case null:
					animClass = null;
					break;
				default:
					animClass = ClassUtils.getClassByName( animType );	// TODO :: should check these
					break;
			}
			
			return animClass;
		}
		
		public static const DEFAULT:String = "default";
	}
}