/**
 * Parses XML with scene data.
 */

package game.data.scene.hit
{
	import game.data.ParamList;
	import game.data.sound.SoundAction;
	import game.util.ClassUtils;
	import game.util.DataUtils;

	public class EmitterHitParser
	{
		private const CLASS_FOLDER_PREFIX:String = "game.particles.emitter.characterCollisions.";
		
		public function parse( xml:XML ):EmitterHitData
		{
			var className:String;
			var data:EmitterHitData = new EmitterHitData();
			var hits:XMLList = xml.children() as XMLList;
			var type:String;
			var hitXML:XML;
			var paramsXML:XMLList;
			var paramList:ParamList;
			
			for (var i:uint = 0; i < hits.length(); i++)
			{	
				hitXML = hits[i];
				paramList = null;
				
				className = DataUtils.getString( hitXML.attribute( "class" ));
				type = DataUtils.getString( hitXML.attribute( "type" ));
				
				if( hitXML.children().length() > 0 )
				{
					paramList = new ParamList( XML( hitXML.params ));
				}
				
				var classPath:String = className;
				if( className.indexOf(".") == -1 )
				{
					classPath = CLASS_FOLDER_PREFIX + className;
				}
				
				switch( type )
				{
					case SoundAction.STEP:
						data.stepClass = ClassUtils.getClassByName( classPath );
						data.stepParams = paramList;
						break;
					
					case SoundAction.IMPACT:
						data.impactClass = ClassUtils.getClassByName( classPath );
						data.impactParams = paramList;
						break;
				}
			}
			
			return data;
		}
	}
}