package game.data.character.part
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.util.DataUtils;

	public class InstanceData
	{	
		/**
		 * Use to locate clips with a part's display
		 * @param	instanceName
		 * @param	partId
		 */
		public function InstanceData( instanceName:String = "", partId:String = "" )
		{
			_instancePath = new Vector.<String>();
			this.instanceName = instanceName;
			
			this.partId = DataUtils.getString(partId);
		}
		
		private var _instancePath:Vector.<String>;
		public var partId:String;	// used with part character Part specifc systems
		public function set instanceName( value:String ):void
		{
			_instancePath.length = 0;
			parseInstanceName( value, _instancePath, 0 );
		}
		
		/**
		 * Recursively creates an instance path, using the Vector index as the instance depth
		 * @param	instanceName
		 * @param	instancePath
		 * @param	startIndex
		 */
		private function parseInstanceName( instanceName:String, instancePath:Vector.<String>, startIndex:int = 0 ):void
		{
			var subInstance:String;
			var endIndex:int = instanceName.indexOf( ".", startIndex );
			
			if ( endIndex > 0 )
			{
				subInstance = instanceName.substring( startIndex, endIndex );
				instancePath.push( subInstance );
				parseInstanceName( instanceName, instancePath, endIndex + 1 ); 
			}
			else
			{
				subInstance = instanceName.substring( startIndex );
				instancePath.push( subInstance );
			}
		}
		
		/**
		 * Get the display object specified by the InstanceData's instancePath.
		 * @param	displayObject
		 * @return
		 */
		public function getInstanceFrom( displayObject:DisplayObjectContainer ):DisplayObject
		{
			var instanceClip:DisplayObject = DisplayObject(displayObject);
			var instanceName:String;
			
			for ( var i:int = 0; i < _instancePath.length; i++ )
			{
				instanceName = _instancePath[i];
				if ( instanceClip is MovieClip )
				{
					instanceClip = MovieClip(instanceClip).getChildByName( instanceName);
				}
				else
				{
					trace("Error :: InstanceData :: getInstanceFrom :: invalid instanceName : " + instanceName );
					return null;
				}
			}
			return instanceClip;
		}

		public function getChildEntity( entity:Entity ):Entity
		{
			
			return null;;
		}
	}
}