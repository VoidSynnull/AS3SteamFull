package game.data.character.part
{
	import game.util.DataUtils;
	public class ColorableData
	{	
		/**
		 * Specifies a clip that can be colored. 
		 * Specific color can be targeted using the colorId, this will need to match a ColorAspectData id.  
		 * @param	colorId
		 * @param	instanceName
		 */
		public function ColorableData( colorId:String = "", instanceName:String = "" )
		{
			this.colorId = DataUtils.getString(colorId);
			
			instances = new Vector.<InstanceData>();
			if ( DataUtils.validString(instanceName) )
			{
				instances.push( new InstanceData( instanceName ) );
			}
		}
		
		public var colorId:String;
		public var darken:Number;
		public var instances:Vector.<InstanceData>;
	}
}